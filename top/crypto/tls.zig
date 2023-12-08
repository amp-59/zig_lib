const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const file = @import("../file.zig");
const builtin = @import("../builtin.zig");
const dh = @import("dh.zig");
const auth = @import("auth.zig");
const hash = @import("hash.zig");
const aead = @import("aead.zig");
const kyber = @import("kyber.zig");
const ecdsa = @import("ecdsa.zig");
const utils = @import("utils.zig");
pub const ProtocolVersion = enum(u16) {
    tls_1_2 = 0x0303,
    tls_1_3 = 0x0304,
    _,
    const tls_1_2: [2]u8 = .{ 0x3, 0x3 };
    const tls_1_3: [2]u8 = .{ 0x3, 0x4 };
};
pub const ContentType = enum(u8) {
    invalid = 0,
    change_cipher_spec = 20,
    alert = 21,
    handshake = 22,
    application_data = 23,
    _,
    const invalid: u8 = 0x0;
    const change_cipher_spec: u8 = 0x14;
    const alert: u8 = 0x15;
    const handshake: u8 = 0x16;
    const application_data: u8 = 0x17;
};
pub const HandshakeType = enum(u8) {
    client_hello = 1,
    server_hello = 2,
    new_session_ticket = 4,
    end_of_early_data = 5,
    encrypted_extensions = 8,
    certificate = 11,
    certificate_request = 13,
    certificate_verify = 15,
    finished = 20,
    key_update = 24,
    message_hash = 254,
    _,
    const client_hello: u8 = 0x1;
    const server_hello: u8 = 0x2;
    const new_session_ticket: u8 = 0x4;
    const end_of_early_data: u8 = 0x5;
    const encrypted_extensions: u8 = 0x8;
    const certificate: u8 = 0xb;
    const certificate_request: u8 = 0xd;
    const certificate_verify: u8 = 0xf;
    const finished: u8 = 0x14;
    const key_update: u8 = 0x18;
    const message_hash: u8 = 0xfe;
};
pub const ExtensionType = enum(u16) {
    server_name = 0,
    max_fragment_len = 1,
    status_request = 5,
    supported_groups = 10,
    signature_algorithms = 13,
    use_srtp = 14,
    heartbeat = 15,
    application_layer_protocol_negotiation = 16,
    signed_certificate_timestamp = 18,
    client_certificate_type = 19,
    server_certificate_type = 20,
    padding = 21,
    pre_shared_key = 41,
    early_data = 42,
    supported_versions = 43,
    cookie = 44,
    psk_key_exchange_modes = 45,
    certificate_authorities = 47,
    oid_filters = 48,
    post_handshake_auth = 49,
    signature_algorithms_cert = 50,
    key_share = 51,
    _,
    const server_name: [2]u8 = .{ 0x0, 0x0 };
    const max_fragment_len: [2]u8 = .{ 0x0, 0x1 };
    const status_request: [2]u8 = .{ 0x0, 0x5 };
    const supported_groups: [2]u8 = .{ 0x0, 0xa };
    const signature_algorithms: [2]u8 = .{ 0x0, 0xd };
    const use_srtp: [2]u8 = .{ 0x0, 0xe };
    const heartbeat: [2]u8 = .{ 0x0, 0xf };
    const application_layer_protocol_negotiation: [2]u8 = .{ 0x0, 0x10 };
    const signed_certificate_timestamp: [2]u8 = .{ 0x0, 0x12 };
    const client_certificate_type: [2]u8 = .{ 0x0, 0x13 };
    const server_certificate_type: [2]u8 = .{ 0x0, 0x14 };
    const padding: [2]u8 = .{ 0x0, 0x15 };
    const pre_shared_key: [2]u8 = .{ 0x0, 0x29 };
    const early_data: [2]u8 = .{ 0x0, 0x2a };
    const supported_versions: [2]u8 = .{ 0x0, 0x2b };
    const cookie: [2]u8 = .{ 0x0, 0x2c };
    const psk_key_exchange_modes: [2]u8 = .{ 0x0, 0x2d };
    const certificate_authorities: [2]u8 = .{ 0x0, 0x2f };
    const oid_filters: [2]u8 = .{ 0x0, 0x30 };
    const post_handshake_auth: [2]u8 = .{ 0x0, 0x31 };
    const signature_algorithms_cert: [2]u8 = .{ 0x0, 0x32 };
    const key_share: [2]u8 = .{ 0x0, 0x33 };
};
pub const AlertLevel = enum(u8) {
    warning = 1,
    fatal = 2,
    _,
};
pub const AlertDescription = enum(u8) {
    close_notify = 0,
    unexpected_message = 10,
    bad_record_mac = 20,
    record_overflow = 22,
    handshake_failure = 40,
    bad_certificate = 42,
    unsupported_certificate = 43,
    certificate_revoked = 44,
    certificate_expired = 45,
    certificate_unknown = 46,
    illegal_parameter = 47,
    unknown_ca = 48,
    access_denied = 49,
    decode_error = 50,
    decrypt_error = 51,
    protocol_version = 70,
    insufficient_security = 71,
    internal_error = 80,
    inappropriate_fallback = 86,
    user_canceled = 90,
    missing_extension = 109,
    unsupported_extension = 110,
    unrecognized_name = 112,
    bad_certificate_status_response = 113,
    unknown_psk_identity = 115,
    certificate_required = 116,
    no_application_protocol = 120,
    _,
};
pub const SignatureScheme = struct {
    const rsa_pkcs1_sha256: [2]u8 = .{ 0x04, 0x01 };
    const rsa_pkcs1_sha384: [2]u8 = .{ 0x05, 0x01 };
    const rsa_pkcs1_sha512: [2]u8 = .{ 0x06, 0x01 };
    const ecdsa_secp256r1_sha256: [2]u8 = .{ 0x04, 0x03 };
    const ecdsa_secp384r1_sha384: [2]u8 = .{ 0x05, 0x03 };
    const ecdsa_secp521r1_sha512: [2]u8 = .{ 0x06, 0x03 };
    const rsa_pss_rsae_sha256: [2]u8 = .{ 0x08, 0x04 };
    const rsa_pss_rsae_sha384: [2]u8 = .{ 0x08, 0x05 };
    const rsa_pss_rsae_sha512: [2]u8 = .{ 0x08, 0x06 };
    const ed25519: [2]u8 = .{ 0x08, 0x07 };
    const ed448: [2]u8 = .{ 0x08, 0x08 };
    const rsa_pss_pss_sha256: [2]u8 = .{ 0x08, 0x09 };
    const rsa_pss_pss_sha384: [2]u8 = .{ 0x08, 0x0a };
    const rsa_pss_pss_sha512: [2]u8 = .{ 0x08, 0x0b };
    const rsa_pkcs1_sha1: [2]u8 = .{ 0x02, 0x01 };
    const ecdsa_sha1: [2]u8 = .{ 0x02, 0x03 };
};
pub const NamedGroup = enum(u16) {
    const secp256r1: [2]u8 = .{ 0x00, 0x17 };
    const secp384r1: [2]u8 = .{ 0x00, 0x18 };
    const secp521r1: [2]u8 = .{ 0x00, 0x19 };
    const x25519: [2]u8 = .{ 0x00, 0x1D };
    const x448: [2]u8 = .{ 0x00, 0x1E };
    const ffdhe2048: [2]u8 = .{ 0x01, 0x00 };
    const ffdhe3072: [2]u8 = .{ 0x01, 0x01 };
    const ffdhe4096: [2]u8 = .{ 0x01, 0x02 };
    const ffdhe6144: [2]u8 = .{ 0x01, 0x03 };
    const ffdhe8192: [2]u8 = .{ 0x01, 0x04 };
    const x25519_kyber512d00: [2]u8 = .{ 0xFE, 0x30 };
    const x25519_kyber768d00: [2]u8 = .{ 0x63, 0x99 };
};
pub const CipherSuite = enum(u16) {
    const AES_128_GCM_SHA256: [2]u8 = .{ 0x13, 0x01 };
    const AES_256_GCM_SHA384: [2]u8 = .{ 0x13, 0x02 };
    const CHACHA20_POLY1305_SHA256: [2]u8 = .{ 0x13, 0x03 };
    const AES_128_CCM_SHA256: [2]u8 = .{ 0x13, 0x04 };
    const AES_128_CCM_8_SHA256: [2]u8 = .{ 0x13, 0x05 };
    const AEGIS_256_SHA384: [2]u8 = .{ 0x13, 0x06 };
    const AEGIS_128L_SHA256: [2]u8 = .{ 0x13, 0x07 };
};
pub const CertificateType = enum(u8) {
    X509 = 0,
    RawPublicKey = 2,
    _,
};
pub const KeyUpdateRequest = enum(u8) {
    update_not_requested = 0,
    update_requested = 1,
    _,
};
pub fn HandshakeCipherT(comptime AeadType: type, comptime HashType: type) type {
    return struct {
        handshake_secret: [Hkdf.prk_len]u8,
        master_secret: [Hkdf.prk_len]u8,
        client_handshake_key: [AEAD.key_len]u8,
        server_handshake_key: [AEAD.key_len]u8,
        client_finished_key: [Hmac.mac_len]u8,
        server_finished_key: [Hmac.mac_len]u8,
        client_handshake_iv: [AEAD.nonce_len]u8,
        server_handshake_iv: [AEAD.nonce_len]u8,
        transcript_hash: Hash,
        pub const AEAD = AeadType;
        pub const Hash = HashType;
        pub const Hmac = auth.GenericHmac(Hash);
        pub const Hkdf = auth.GenericHkdf(Hmac);
    };
}
pub const HandshakeCipher = union(enum) {
    AES_128_GCM_SHA256: HandshakeCipherT(aead.Aes128Gcm, hash.Sha256),
    AES_256_GCM_SHA384: HandshakeCipherT(aead.Aes256Gcm, hash.Sha384),
    CHACHA20_POLY1305_SHA256: HandshakeCipherT(aead.ChaCha20Poly1305, hash.Sha256),
    // AEGIS_256_SHA384: HandshakeCipherT(auth.Aegis256, hash.Sha384),
    // AEGIS_128L_SHA256: HandshakeCipherT(auth.Aegis128L, hash.Sha256),
};
pub fn ApplicationCipherT(comptime AeadType: type, comptime HashType: type) type {
    return struct {
        client_secret: [Hash.len]u8,
        server_secret: [Hash.len]u8,
        client_key: [AEAD.key_len]u8,
        server_key: [AEAD.key_len]u8,
        client_iv: [AEAD.nonce_len]u8,
        server_iv: [AEAD.nonce_len]u8,
        pub const AEAD = AeadType;
        pub const Hash = HashType;
        pub const Hmac = auth.hmac.Hmac(Hash);
        pub const Hkdf = auth.GenericHkdf(Hmac);
    };
}
pub const ApplicationCipher = union(enum) {
    AES_128_GCM_SHA256: ApplicationCipherT(aead.Aes128Gcm, hash.Sha256),
    AES_256_GCM_SHA384: ApplicationCipherT(aead.Aes256Gcm, hash.Sha384),
    CHACHA20_POLY1305_SHA256: ApplicationCipherT(aead.ChaCha20Poly1305, hash.Sha256),
    //AEGIS_256_SHA384: ApplicationCipherT(aead.Aegis256, hash.Sha384),
    //AEGIS_128L_SHA256: ApplicationCipherT(aead.Aegis128L, hash.Sha256),
};
pub const close_notify_alert: [2]u8 = .{
    @intFromEnum(AlertLevel.warning),
    @intFromEnum(AlertDescription.close_notify),
};
pub const retry: [32]u8 = .{
    0xCF, 0x21, 0xAD, 0x74, 0xE5, 0x9A, 0x61, 0x11,
    0xBE, 0x1D, 0x8C, 0x02, 0x1E, 0x65, 0xB8, 0x91,
    0xC2, 0xA2, 0x11, 0x16, 0x7A, 0xBB, 0x8C, 0x5E,
    0x07, 0x9E, 0x09, 0xE2, 0xC8, 0xA8, 0x33, 0x9C,
};
fn write16(ptr: [*]u8, data: u16) [*]u8 {
    ptr[0..2].* = @bitCast(@byteSwap(data));
    return ptr + 2;
}
fn write24(ptr: [*]u8, data: u24) [*]u8 {
    ptr[0..3].* = @bitCast(@byteSwap(data));
    return ptr + 3;
}
pub fn init(host: []const u8, seed: *[192]u8, buf: [*]u8) !void {
    @setRuntimeSafety(false);
    const host_len: u16 = @intCast(host.len);

    const x25519_kp: dh.X25519.KeyPair =
        try dh.X25519.KeyPair.create(seed[0..32].*);

    const secp256r1_kp: ecdsa.EcdsaP256Sha256.KeyPair =
        try ecdsa.EcdsaP256Sha256.KeyPair.create(seed[32..64].*);

    const kyber768_kp: kyber.Kyber768.KeyPair =
        try kyber.Kyber768.KeyPair.create(seed[64..128].*);

    var ptr: [*]u8 = buf;

    // Hello:
    ptr[0] = ContentType.handshake;
    ptr[1] = 0x03;
    ptr[2] = 0x01;

    ptr = write16(ptr + 3, 1472 +% host_len);
    ptr[0] = HandshakeType.client_hello;

    ptr = write24(ptr + 1, 1468 +% host_len);
    ptr[0..2].* = ProtocolVersion.tls_1_2;

    ptr[2..34].* = seed[128..160].*; // hello_rand
    ptr += 34;

    ptr[0] = 32;
    ptr += 1;
    ptr[0..32].* = seed[160..192].*; // session_id
    ptr += 32;

    // Cipher suite:
    ptr = write16(ptr, 10);
    {
        ptr[0..2].* = CipherSuite.AEGIS_128L_SHA256;
        ptr[2..4].* = CipherSuite.AEGIS_256_SHA384;
        ptr[4..6].* = CipherSuite.AES_128_GCM_SHA256;
        ptr[6..8].* = CipherSuite.AES_256_GCM_SHA384;
        ptr[8..10].* = CipherSuite.CHACHA20_POLY1305_SHA256;
        ptr += 10;
    }

    // Compression:
    ptr = write16(ptr, 256);
    ptr = write16(ptr, 1385 +% host_len);

    // Versions:
    ptr[0..2].* = ExtensionType.supported_versions;
    ptr = write16(ptr + 2, 3);
    {
        ptr[0] = 2;
        ptr[1..3].* = ProtocolVersion.tls_1_3;
        ptr += 3;
    }

    // Algorithms:
    ptr[0..2].* = ExtensionType.signature_algorithms;
    ptr = write16(ptr + 2, 22);
    {
        ptr = write16(ptr, 20);
        ptr[0..2].* = SignatureScheme.ecdsa_secp256r1_sha256;
        ptr[2..4].* = SignatureScheme.ecdsa_secp384r1_sha384;
        ptr[4..6].* = SignatureScheme.ecdsa_secp521r1_sha512;
        ptr[6..8].* = SignatureScheme.rsa_pss_rsae_sha256;
        ptr[8..10].* = SignatureScheme.rsa_pss_rsae_sha384;
        ptr[10..12].* = SignatureScheme.rsa_pss_rsae_sha512;
        ptr[12..14].* = SignatureScheme.rsa_pkcs1_sha256;
        ptr[14..16].* = SignatureScheme.rsa_pkcs1_sha384;
        ptr[16..18].* = SignatureScheme.rsa_pkcs1_sha512;
        ptr[18..20].* = SignatureScheme.ed25519;
        ptr += 20;
    }

    // Groups:
    ptr[0..2].* = ExtensionType.supported_groups;
    ptr = write16(ptr + 2, 8);
    {
        ptr = write16(ptr, 6);
        ptr[0..2].* = NamedGroup.x25519_kyber768d00;
        ptr[2..4].* = NamedGroup.secp256r1;
        ptr[4..6].* = NamedGroup.x25519;
        ptr += 6;
    }

    // Key share:
    ptr[0..2].* = ExtensionType.key_share;
    ptr = write16(ptr + 2, 1327);
    {
        ptr = write16(ptr, 1325);
        // x25519:
        ptr[0..2].* = NamedGroup.x25519;
        ptr = write16(ptr + 2, 32);
        ptr[0..32].* = x25519_kp.public_key;
        ptr += 32;

        // secp256r1:
        ptr[0..2].* = NamedGroup.secp256r1;
        ptr = write16(ptr + 2, 65);
        ptr[0..65].* = secp256r1_kp.public_key.toUncompressedSec1();
        ptr += 65;

        // x25519_kyber768d00:
        ptr[0..2].* = NamedGroup.x25519_kyber768d00;
        ptr = write16(ptr + 2, 32 + 1184);
        ptr[0..32].* = x25519_kp.public_key;
        ptr += 32;
        ptr[0..1184].* = kyber768_kp.public_key.toBytes();
        ptr += 1184;
    }

    // Server name:
    ptr[0..2].* = ExtensionType.server_name;
    ptr = write16(ptr + 2, host_len +% 5);
    {
        ptr = write16(ptr, host_len +% 3);
        ptr[0] = 0;
        ptr += 1;
        ptr = write16(ptr, host_len);
    }
}
