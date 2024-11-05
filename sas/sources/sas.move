
/// Module: sas
module sas::sas {
    // === Imports ===
    use sui::{
        tx_context::{sender},
        url,
        clock::{Self, Clock},
    };
    use std::string;
    
    use sas::admin::{Admin};
    use sas::schema::{Self, Schema, Request, ResolverBuilder};
    use sas::schema_registry::{SchemaRegistry};
    use sas::attestation;
    use sas::attestation_registry::{AttestationRegistry};

    // === Errors ===
    const EExpired: u64 = 0;
    const ERefIdNotFound: u64 = 1;
    const EHasResolver: u64 = 2;

    // === Constants ===
    const ATT_TYPE_ATTEST: u8 = 0;
    const ATT_TYPE_ATTEST_WITH_RESOLVER: u8 = 1;

    // === Public Functions ===
    public fun register_schema(
        schema_registry: &mut SchemaRegistry, 
        schema: vector<u8>, 
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        revokable: bool,
        ctx: &mut TxContext
    ): Admin {
        schema::new(
            schema_registry, 
            schema, 
            name, 
            description, 
            url, 
            revokable, 
            ctx
        )
    }

    public fun register_schema_with_resolver(
        schema_registry: &mut SchemaRegistry,
        schema: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        revokable: bool,
        ctx: &mut TxContext,
    ): (ResolverBuilder, Admin) {
        schema::new_with_resolver(
            schema_registry, 
            schema, 
            name, 
            description, 
            url, 
            revokable, 
            ctx
        )
    }

    public fun attest(
        schema_record: &mut Schema,
        attestation_registry: &mut AttestationRegistry,
        ref_attestation: address,
        recipient: address,
        expiration_time: u64,
        data: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        time: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!schema_record.has_resolver(), EHasResolver);
        if (ref_attestation != @0x0) {
            assert!(attestation_registry.is_exist(ref_attestation), ERefIdNotFound);
        };
        
        let attestor = ctx.sender();

        if (expiration_time != 0) {
            assert!(time.timestamp_ms() < expiration_time, EExpired);
        };

        let attestation_address = attestation::create_attestation(
            object::id_address(schema_record),
            ref_attestation,
            clock::timestamp_ms(time),
            expiration_time,
            schema_record.revokable(),
            attestor,
            recipient,
            data,
            string::utf8(name),
            string::utf8(description),
            url::new_unsafe_from_bytes(url),
            ATT_TYPE_ATTEST,
            ctx
        );

        attestation_registry.registry(attestation_address, schema_record.addy());
    }

    public fun attest_with_resolver(
        schema_record: &mut Schema,
        attestation_registry: &mut AttestationRegistry,
        ref_attestation: address,
        recipient: address,
        expiration_time: u64,
        data: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        time: &Clock,
        request: Request,
        ctx: &mut TxContext
    ) {
        if (ref_attestation != @0x0) {
            assert!(attestation_registry.is_exist(ref_attestation), ERefIdNotFound);
        };

        let attestor = ctx.sender();

        if (expiration_time != 0) {
            assert!(time.timestamp_ms() < expiration_time, EExpired);
        };

        schema::finish_attest( schema_record, request);

        let attestation_address = attestation::create_attestation(
            object::id_address(schema_record),
            ref_attestation,
            clock::timestamp_ms(time),
            expiration_time,
            schema_record.revokable(),
            attestor,
            recipient,
            data,
            string::utf8(name),
            string::utf8(description),
            url::new_unsafe_from_bytes(url),
            ATT_TYPE_ATTEST_WITH_RESOLVER,
            ctx
        );

        attestation_registry.registry(attestation_address, schema_record.addy());
    }

    public fun revoke(
        admin: &Admin,
        attestation_registry: &mut AttestationRegistry,
        schema_record: &Schema,
        attestation: address,
        ctx: &mut TxContext
    ) {
        attestation_registry.revoke(admin, schema_record, attestation, ctx);
    }
}
