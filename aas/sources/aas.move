module aas::aas {
    use std::error;
    use std::signer;
    use std::string::{Self, String};

    use aas::schema;
    use aas::attestation;
    
    /*********** Error Codes ***********/
    
    const ESTRING_TOO_LONG: u64 = 1;
    const ENOT_SCHEMA_CREATOR: u64 = 2;
    const E_NOT_REVOKABLE: u64 = 3;
    const EATTESTATION_NOT_FOUND: u64 = 4;
    const EATTESTATION_ALREADY_REVOKED: u64 = 5;
    const EATTESTATIONS_NOT_EXIST_AT_ADDRESS: u64 = 6;
    const ESCHEMA_NOT_FOUND: u64 = 7;

    /*********** Entry Functions ***********/

    /// Create a new schema
    public entry fun create_schema(
        creator: &signer, 
        schema: vector<u8>, 
        name: String, 
        description: String, 
        uri: String, 
        revokable: bool,
        resolver: address,
    ) {
        create_schema_and_get_schema_address(creator, schema, name, description, uri, revokable, resolver);
    }

    /// Create a new attestation
    public entry fun create_attestation(
        attester: &signer, 
        recipient: address,
        schema_addr: address, 
        ref_attestation: address, 
        expiration_time: u64, 
        revokable: bool, 
        data: vector<u8>
    ) {
        create_attestation_and_get_address(attester, recipient, schema_addr, ref_attestation, expiration_time, revokable, data);
    }

    /// Revoke an attestation
    public entry fun revoke_attestation(
        admin: &signer,
        schema_addr: address,
        attestation: address,
    ) {
        assert!(schema::schema_exists(schema_addr), error::invalid_argument(ESCHEMA_NOT_FOUND));
        assert!(attestation::attestation_exists(attestation), error::invalid_argument(EATTESTATION_NOT_FOUND));
        
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == schema::schema_creator(schema_addr), error::invalid_argument(ENOT_SCHEMA_CREATOR));
        assert!(schema::schema_revokable(schema_addr), error::invalid_argument(E_NOT_REVOKABLE));

        attestation::revoke_attestation(attestation);
    }

    /*********** Public Functions ***********/

    public fun create_schema_and_get_schema_address(
        creator: &signer, 
        schema: vector<u8>, 
        name: String, 
        description: String, 
        uri: String, 
        revokable: bool,
        resolver: address,
    ): address {
        assert!(string::length(&name) < 128, error::invalid_argument(ESTRING_TOO_LONG));
        assert!(string::length(&description) < 512, error::invalid_argument(ESTRING_TOO_LONG));
        assert!(string::length(&uri) < 512, error::invalid_argument(ESTRING_TOO_LONG));

        schema::create_schema(signer::address_of(creator), name, description, uri, revokable, resolver, schema)
    }

    public fun create_attestation_and_get_address(
        attester: &signer, 
        recipient: address,
        schema_addr: address, 
        ref_attestation: address, 
        expiration_time: u64, 
        revokable: bool, 
        data: vector<u8>
    ): address {
        assert!(!attestation::attestation_exists(ref_attestation), error::invalid_argument(EATTESTATIONS_NOT_EXIST_AT_ADDRESS));
        assert!(schema::schema_exists(schema_addr), error::invalid_argument(ESCHEMA_NOT_FOUND));
        
        attestation::create_attestation(signer::address_of(attester), recipient, schema_addr, ref_attestation, expiration_time, revokable, data)
    }

}