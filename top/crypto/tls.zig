const mem = @import("../mem.zig");
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
pub fn initOld(host: anytype, seed: *[192]u8, buf: [*]u8) !void {
    @setRuntimeSafety(false);
    const host_len: u16 = @intCast(host.len);
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
    @as(Size24, @ptrCast(buf)).* = @as(u24, @bitCast([3]u8{ @intFromEnum(ContentType.handshake), 0x03, 0x01 }));
    var pos: u16 = 3;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, @intCast(1472 +% host_len)));
    pos +%= 2;
    buf[pos] = @intFromEnum(HandshakeType.client_hello);
    pos +%= 1;
    @as(Size24, @ptrCast(buf + pos)).* = @byteSwap(@as(u24, @intCast(1468 +% host_len)));
    pos +%= 3;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(ProtocolVersion.tls_1_2));
    pos +%= 2;
    @as(*[32]u8, @ptrCast(buf + pos)).* = hello_rand;
    pos +%= 32;
    buf[pos] = 32;
    pos +%= 1;
    @as(*[32]u8, @ptrCast(buf + pos)).* = legacy_session_id;
    pos +%= 32;

    // Cipher suite:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 10));
    pos +%= 2;
    @as(*[10]u8, @ptrCast(buf + pos)).* = @as([10]u8, @bitCast([5]u16{
        @byteSwap(@intFromEnum(CipherSuite.AEGIS_128L_SHA256)),
        @byteSwap(@intFromEnum(CipherSuite.AEGIS_256_SHA384)),
        @byteSwap(@intFromEnum(CipherSuite.AES_128_GCM_SHA256)),
        @byteSwap(@intFromEnum(CipherSuite.AES_256_GCM_SHA384)),
        @byteSwap(@intFromEnum(CipherSuite.CHACHA20_POLY1305_SHA256)),
    }));
    pos +%= 10;

    // Compression:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 0x0100));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(1385 +% host_len);
    pos +%= 2;

    // Versions:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(ExtensionType.supported_versions));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 3));
    pos +%= 2;
    @as(*[3]u8, @ptrCast(buf + pos)).* = [_]u8{ 0x02, 0x03, 0x04 };
    pos +%= 3;

    // Algorithms:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(ExtensionType.signature_algorithms));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 22));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 20));
    pos +%= 2;
    @as(*align(1) [10]u16, @ptrCast(buf + pos)).* = .{
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
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(ExtensionType.supported_groups));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 8));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 6));
    pos +%= 2;
    @as(*align(1) [3]u16, @ptrCast(buf + pos)).* = .{
        @byteSwap(@intFromEnum(NamedGroup.x25519_kyber768d00)),
        @byteSwap(@intFromEnum(NamedGroup.secp256r1)),
        @byteSwap(@intFromEnum(NamedGroup.x25519)),
    };
    pos +%= 6;

    // Key share extension:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(ExtensionType.key_share));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(1466 -% pos);
    pos +%= 2;

    // Key share payload total length: 1325
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 1325));
    pos +%= 2;

    // x25519:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(NamedGroup.x25519));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 32));
    pos +%= 2;
    @as(*[32]u8, @ptrCast(buf + pos)).* = x25519_kp.public_key;
    pos +%= 32;

    // secp256r1:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(NamedGroup.secp256r1));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 65));
    pos +%= 2;
    @as(*[65]u8, @ptrCast(buf + pos)).* = secp256r1_kp.public_key.toUncompressedSec1();
    pos +%= 65;

    // x25519_kyber768d00:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(NamedGroup.x25519_kyber768d00));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@as(u16, 1216));
    pos +%= 2;
    @as(*[32]u8, @ptrCast(buf + pos)).* = x25519_kp.public_key;
    pos +%= 32;
    @as(*[1184]u8, @ptrCast(buf + pos)).* = kyber768_kp.public_key.toBytes();
    pos +%= 1184;

    // Server name:
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(@intFromEnum(ExtensionType.server_name));
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(host_len + 5);
    pos +%= 2;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(host_len + 3);
    pos +%= 2;
    buf[pos] = 0;
    pos +%= 1;
    @as(Size16, @ptrCast(buf + pos)).* = @byteSwap(host_len);
    pos +%= 2;
}
pub fn init(host: anytype, seed: *[192]u8, buf: [*]u8) !void {
    @setRuntimeSafety(false);
    const host_len: u16 = @intCast(host.len);
    const hello_rand: *[32]u8 = seed[0..32];
    const legacy_session_id: *[32]u8 = seed[32..64];
    const x25519_kp_seed: *[32]u8 = seed[64..96];
    const secp256r1_kp_seed: *[32]u8 = seed[96..128];
    const kyber768_kp_seed: *[64]u8 = seed[128..192];
    const x25519_kp: dh.X25519.KeyPair =
        dh.X25519.KeyPair.create(x25519_kp_seed.*) catch |err| switch (err) {
        error.IdentityElement => {
            return error.InsufficientEntropy;
        },
    };
    const secp256r1_kp: ecdsa.EcdsaP256Sha256.KeyPair =
        ecdsa.EcdsaP256Sha256.KeyPair.create(secp256r1_kp_seed.*) catch |err| switch (err) {
        error.IdentityElement => {
            return error.InsufficientEntropy;
        },
    };
    const kyber768_kp: kyber.Kyber768.KeyPair =
        kyber.Kyber768.KeyPair.create(kyber768_kp_seed.*) catch |err| switch (err) {
        error.IdentityElement => {
            return error.InsufficientEntropy;
        },
    };

    var ptr: [*]u8 = buf;

    ptr = write8(ptr, @intFromEnum(ContentType.handshake));
    ptr = write8(ptr, 0x03);
    ptr = write8(ptr, 0x01);

    ptr = write16(ptr, 1472 +% host_len);
    ptr = write8(ptr, @intFromEnum(HandshakeType.client_hello));

    ptr = write24(ptr, 1468 +% host_len);

    ptr = write16(ptr, @intFromEnum(ProtocolVersion.tls_1_2));
    ptr[0..32].* = hello_rand.*;
    ptr += 32;

    ptr = write8(ptr, 32);
    ptr[0..32].* = legacy_session_id.*;
    ptr += 32;

    // Cipher suite:
    ptr = write16(ptr, 10);
    {
        ptr = write16(ptr, @intFromEnum(CipherSuite.AEGIS_128L_SHA256));
        ptr = write16(ptr, @intFromEnum(CipherSuite.AEGIS_256_SHA384));
        ptr = write16(ptr, @intFromEnum(CipherSuite.AES_128_GCM_SHA256));
        ptr = write16(ptr, @intFromEnum(CipherSuite.AES_256_GCM_SHA384));
        ptr = write16(ptr, @intFromEnum(CipherSuite.CHACHA20_POLY1305_SHA256));
    }

    // Compression:
    ptr = write16(ptr, 0x100);
    ptr = write16(ptr, 1385 +% host_len);

    // Versions:
    ptr = write16(ptr, @intFromEnum(ExtensionType.supported_versions));
    ptr = write16(ptr, 3);
    {
        ptr = write8(ptr, 0x02);
        ptr = write8(ptr, 0x03);
        ptr = write8(ptr, 0x04);
    }

    // Algorithms:
    ptr = write16(ptr, @intFromEnum(ExtensionType.signature_algorithms));
    ptr = write16(ptr, 22);
    {
        ptr = write16(ptr, 20);
        ptr = write16(ptr, @intFromEnum(SignatureScheme.ecdsa_secp256r1_sha256));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.ecdsa_secp384r1_sha384));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.ecdsa_secp521r1_sha512));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.rsa_pss_rsae_sha256));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.rsa_pss_rsae_sha384));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.rsa_pss_rsae_sha512));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.rsa_pkcs1_sha256));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.rsa_pkcs1_sha384));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.rsa_pkcs1_sha512));
        ptr = write16(ptr, @intFromEnum(SignatureScheme.ed25519));
    }

    // Groups:
    ptr = write16(ptr, @intFromEnum(ExtensionType.supported_groups));
    ptr = write16(ptr, 8);
    {
        ptr = write16(ptr, 6);
        ptr = write16(ptr, @intFromEnum(NamedGroup.x25519_kyber768d00));
        ptr = write16(ptr, @intFromEnum(NamedGroup.secp256r1));
        ptr = write16(ptr, @intFromEnum(NamedGroup.x25519));
    }

    // Key share extension:
    ptr = write16(ptr, @intFromEnum(ExtensionType.key_share));
    ptr = write16(ptr, 1466 -% len(ptr, buf));

    // Key share payload
    ptr = write16(ptr, 1325);
    {
        // x25519:
        ptr = write16(ptr, @intFromEnum(NamedGroup.x25519));
        ptr = write16(ptr, 32);
        ptr[0..32].* = x25519_kp.public_key;
        ptr += 32;

        // secp256r1:
        ptr = write16(ptr, @intFromEnum(NamedGroup.secp256r1));
        ptr = write16(ptr, 65);
        ptr[0..65].* = secp256r1_kp.public_key.toUncompressedSec1();
        ptr += 65;

        // x25519_kyber768d00:
        ptr = write16(ptr, @intFromEnum(NamedGroup.x25519_kyber768d00));
        ptr = write16(ptr, 32 + 1184);
        ptr[0..32].* = x25519_kp.public_key;
        ptr += 32;
        ptr[0..1184].* = kyber768_kp.public_key.toBytes();
        ptr += 1184;
    }

    // Server name:
    ptr = write16(ptr, @intFromEnum(ExtensionType.server_name));
    ptr = write16(ptr, host_len +% 5);
    {
        ptr = write16(ptr, host_len +% 3);
        ptr = write8(ptr, 0);
        ptr = write16(ptr, host_len);
    }
}

fn write8(ptr: [*]u8, data: u8) [*]u8 {
    ptr[0] = data;
    return ptr + 1;
}
fn write16(ptr: [*]u8, data: u16) [*]u8 {
    ptr[0..2].* = @bitCast(@byteSwap(data));
    return ptr + 2;
}
fn write24(ptr: [*]u8, data: u24) [*]u8 {
    ptr[0..3].* = @bitCast(@byteSwap(data));
    return ptr + 3;
}
fn len(ptr: [*]u8, buf: [*]u8) u16 {
    return @truncate(@intFromPtr(ptr) -% @intFromPtr(buf));
}
