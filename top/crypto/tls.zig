const mem = @import("../mem.zig");
const file = @import("../file.zig");
const builtin = @import("../builtin.zig");
const dh = @import("./dh.zig");
const auth = @import("./auth.zig");
const hash = @import("./hash.zig");
const aead = @import("./aead.zig");
const kyber = @import("./kyber.zig");
const ecdsa = @import("./ecdsa.zig");
const utils = @import("./utils.zig");
pub const ProtocolVersion = enum(u16) {
    tls_1_2 = 0x0303,
    tls_1_3 = 0x0304,
    _,
};
pub const ContentType = enum(u8) {
    invalid = 0,
    change_cipher_spec = 20,
    alert = 21,
    handshake = 22,
    application_data = 23,
    _,
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
pub const SignatureScheme = enum(u16) {
    rsa_pkcs1_sha256 = 0x0401,
    rsa_pkcs1_sha384 = 0x0501,
    rsa_pkcs1_sha512 = 0x0601,
    ecdsa_secp256r1_sha256 = 0x0403,
    ecdsa_secp384r1_sha384 = 0x0503,
    ecdsa_secp521r1_sha512 = 0x0603,
    rsa_pss_rsae_sha256 = 0x0804,
    rsa_pss_rsae_sha384 = 0x0805,
    rsa_pss_rsae_sha512 = 0x0806,
    ed25519 = 0x0807,
    ed448 = 0x0808,
    rsa_pss_pss_sha256 = 0x0809,
    rsa_pss_pss_sha384 = 0x080a,
    rsa_pss_pss_sha512 = 0x080b,
    rsa_pkcs1_sha1 = 0x0201,
    ecdsa_sha1 = 0x0203,
    _,
};
pub const NamedGroup = enum(u16) {
    secp256r1 = 0x0017,
    secp384r1 = 0x0018,
    secp521r1 = 0x0019,
    x25519 = 0x001D,
    x448 = 0x001E,
    ffdhe2048 = 0x0100,
    ffdhe3072 = 0x0101,
    ffdhe4096 = 0x0102,
    ffdhe6144 = 0x0103,
    ffdhe8192 = 0x0104,
    x25519_kyber512d00 = 0xFE30,
    x25519_kyber768d00 = 0x6399,
    _,
};
pub const CipherSuite = enum(u16) {
    AES_128_GCM_SHA256 = 0x1301,
    AES_256_GCM_SHA384 = 0x1302,
    CHACHA20_POLY1305_SHA256 = 0x1303,
    AES_128_CCM_SHA256 = 0x1304,
    AES_128_CCM_8_SHA256 = 0x1305,
    AEGIS_256_SHA384 = 0x1306,
    AEGIS_128L_SHA256 = 0x1307,
    _,
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
pub fn init(host: anytype, buf: [*]u8) !void {
    @setRuntimeSafety(false);
    var seed: [192]u8 = undefined;
    if (false) {
        utils.bytes(&seed);
    }
    const host_len: u16 = @intCast(u16, host.len);
    const hello_rand: [32]u8 = seed[0..32].*;
    const legacy_session_id: [32]u8 = seed[32..64].*;
    const x25519_kp_seed: [32]u8 = seed[64..96].*;
    const secp256r1_kp_seed: [32]u8 = seed[96..128].*;
    const kyber768_kp_seed: [64]u8 = seed[128..192].*;
    const x25519_kp: dh.X25519.KeyPair =
        dh.X25519.KeyPair.create(x25519_kp_seed) catch |err| switch (err) {
        error.IdentityElement => {
            return error.InsufficientEntropy;
        },
    };
    const secp256r1_kp: ecdsa.EcdsaP256Sha256.KeyPair =
        ecdsa.EcdsaP256Sha256.KeyPair.create(secp256r1_kp_seed) catch |err| switch (err) {
        error.IdentityElement => {
            return error.InsufficientEntropy;
        },
    };
    const kyber768_kp: kyber.Kyber768.KeyPair =
        kyber.Kyber768.KeyPair.create(kyber768_kp_seed) catch |err| switch (err) {
        error.IdentityElement => {
            return error.InsufficientEntropy;
        },
    };
    const Size16 = *align(1) u16;
    const Size24 = *align(1) u24;
    @ptrCast(Size24, buf).* = @bitCast(u24, [3]u8{ @intFromEnum(ContentType.handshake), 0x03, 0x01 });
    var pos: u16 = 3;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intCast(u16, 1472 +% host_len));
    pos +%= 2;
    buf[pos] = @intFromEnum(HandshakeType.client_hello);
    pos +%= 1;
    @ptrCast(Size24, buf + pos).* = @byteSwap(@intCast(u24, 1468 +% host_len));
    pos +%= 3;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(ProtocolVersion.tls_1_2));
    pos +%= 2;
    @ptrCast(*[32]u8, buf + pos).* = hello_rand;
    pos +%= 32;
    buf[pos] = 32;
    pos +%= 1;
    @ptrCast(*[32]u8, buf + pos).* = legacy_session_id;
    pos +%= 32;

    // Cipher suite:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 10));
    pos +%= 2;
    @ptrCast(*[10]u8, buf + pos).* = @bitCast([10]u8, [5]u16{
        @byteSwap(@intFromEnum(CipherSuite.AEGIS_128L_SHA256)),
        @byteSwap(@intFromEnum(CipherSuite.AEGIS_256_SHA384)),
        @byteSwap(@intFromEnum(CipherSuite.AES_128_GCM_SHA256)),
        @byteSwap(@intFromEnum(CipherSuite.AES_256_GCM_SHA384)),
        @byteSwap(@intFromEnum(CipherSuite.CHACHA20_POLY1305_SHA256)),
    });
    pos +%= 10;

    // Compression:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 0x0100));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(1385 +% host_len);
    pos +%= 2;

    // Versions:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(ExtensionType.supported_versions));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 3));
    pos +%= 2;
    @ptrCast(*[3]u8, buf + pos).* = [_]u8{ 0x02, 0x03, 0x04 };
    pos +%= 3;

    // Algorithms:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(ExtensionType.signature_algorithms));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 22));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 20));
    pos +%= 2;
    @ptrCast(*align(1) [10]u16, buf + pos).* = .{
        @byteSwap(@intFromEnum(SignatureScheme.ecdsa_secp256r1_sha256)),
        @byteSwap(@intFromEnum(SignatureScheme.ecdsa_secp384r1_sha384)),
        @byteSwap(@intFromEnum(SignatureScheme.ecdsa_secp521r1_sha512)),
        @byteSwap(@intFromEnum(SignatureScheme.rsa_pss_rsae_sha256)),
        @byteSwap(@intFromEnum(SignatureScheme.rsa_pss_rsae_sha384)),
        @byteSwap(@intFromEnum(SignatureScheme.rsa_pss_rsae_sha512)),
        @byteSwap(@intFromEnum(SignatureScheme.rsa_pkcs1_sha256)),
        @byteSwap(@intFromEnum(SignatureScheme.rsa_pkcs1_sha384)),
        @byteSwap(@intFromEnum(SignatureScheme.rsa_pkcs1_sha512)),
        @byteSwap(@intFromEnum(SignatureScheme.ed25519)),
    };
    pos +%= 20;

    // Groups:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(ExtensionType.supported_groups));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 8));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 6));
    pos +%= 2;
    @ptrCast(*align(1) [3]u16, buf + pos).* = .{
        @byteSwap(@intFromEnum(NamedGroup.x25519_kyber768d00)),
        @byteSwap(@intFromEnum(NamedGroup.secp256r1)),
        @byteSwap(@intFromEnum(NamedGroup.x25519)),
    };
    pos +%= 6;

    // Key share extension:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(ExtensionType.key_share));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(1466 -% pos);
    pos +%= 2;

    // Key share payload total length: 1325
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 1325));
    pos +%= 2;

    // x25519:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(NamedGroup.x25519));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 32));
    pos +%= 2;
    @ptrCast(*[32]u8, buf + pos).* = x25519_kp.public_key;
    pos +%= 32;

    // secp256r1:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(NamedGroup.secp256r1));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 65));
    pos +%= 2;
    @ptrCast(*[65]u8, buf + pos).* = secp256r1_kp.public_key.toUncompressedSec1();
    pos +%= 65;

    // x25519_kyber768d00:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(NamedGroup.x25519_kyber768d00));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(@as(u16, 1216));
    pos +%= 2;
    @ptrCast(*[32]u8, buf + pos).* = x25519_kp.public_key;
    pos +%= 32;
    @ptrCast(*[1184]u8, buf + pos).* = kyber768_kp.public_key.toBytes();
    pos +%= 1184;

    // Server name:
    @ptrCast(Size16, buf + pos).* = @byteSwap(@intFromEnum(ExtensionType.server_name));
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(host_len + 5);
    pos +%= 2;
    @ptrCast(Size16, buf + pos).* = @byteSwap(host_len + 3);
    pos +%= 2;
    buf[pos] = 0;
    pos +%= 1;
    @ptrCast(Size16, buf + pos).* = @byteSwap(host_len);
    pos +%= 2;

    builtin.assertEqual(u64, pos, 1477);
}
