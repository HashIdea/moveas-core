module sas::attestation {
    // === Imports ===
    use sui::{
        url::{Url},
        event::{emit},
    };
    use std::string;

    // === Events ===
    public struct AttestationCreated has copy, drop {
        /// 0: Attest, 1: AttestWithResolver
        event_type: u8,
        id: address,
        schema: address,
        ref_attestation: address,
        time: u64,
        expiration_time: u64,
        revokable: bool,
        attestor: address,
        recipient: address,
        data: vector<u8>,
        name: string::String,
        description: string::String,
        url: Url,
    }

    // === Structs ===
    public struct Attestation has key {
        id: UID,
        schema: address,
        ref_attestation: address,
        time: u64,
        expiration_time: u64,
        // revocation_time: u64,
        revokable: bool,
        attestor: address,
        // recipient: address,
        data: vector<u8>,
        name: string::String,
        description: string::String,
        url: Url,
    }

    // === Public-View Functions ===
    public fun schema(self: &Attestation): address {
        self.schema
    }

    public fun ref_attestation(self: &Attestation): address {
        self.ref_attestation
    }

    public fun attestor(self: &Attestation): address {
        self.attestor
    }

    public fun time(self: &Attestation): u64 {
        self.time
    }

    public fun revokable(self: &Attestation): bool {
        self.revokable
    }

    public fun expiration_time(self: &Attestation): u64 {
        self.expiration_time
    }

    public fun data(self: &Attestation): vector<u8> {
        self.data
    }

    public fun name(self: &Attestation): string::String {
        self.name
    }

    public fun description(self: &Attestation): string::String {
        self.description
    }

    public fun url(self: &Attestation): Url {
        self.url
    }

    public(package) fun create_attestation(
        schema: address,
        ref_attestation: address,
        time: u64,
        expiration_time: u64,
        revokable: bool,
        attestor: address,
        recipient: address,
        data: vector<u8>,
        name: string::String,
        description: string::String,
        url: Url,
        event_type: u8,
        ctx: &mut TxContext
    ): address {
        let id = object::new(ctx);
        let attest = Attestation {
            id,
            schema,
            ref_attestation,
            time,
            expiration_time,
            revokable,
            attestor,
            data,
            name,
            description,
            url,
        };

        let attestation_address = object::id_address(&attest);
        
        emit(AttestationCreated {
            event_type,
            id: attestation_address,
            schema,
            ref_attestation,
            time,
            expiration_time,
            revokable,
            attestor,
            recipient,
            data,
            name,
            description,
            url,
        });

       transfer::transfer(attest, recipient);

        attestation_address
    }

}