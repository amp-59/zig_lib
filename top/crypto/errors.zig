pub const AuthenticationError = error{
    /// MAC verification failed - The tag doesn't verify for the given ciphertext and secret key
    AuthenticationFailed,
};
pub const OutputTooLongError = error{
    /// The requested output length is too long for the chosen algorithm
    OutputTooLong,
};
pub const IdentityElementError = error{
    /// Finite field operation returned the identity element
    IdentityElement,
};
pub const EncodingError = error{
    /// Encoded input cannot be decoded
    InvalidEncoding,
};
pub const SignatureVerificationError = error{
    /// The signature doesn't verify for the given message and public key
    SignatureVerificationFailed,
};
pub const KeyMismatchError = error{
    /// Both a public and secret key have been provided, but they are incompatible
    KeyMismatch,
};
pub const NonCanonicalError = error{
    /// Encoded input is not in canonical form
    NonCanonical,
};
pub const NotSquareError = error{
    /// Square root has no solutions
    NotSquare,
};
pub const PasswordVerificationError = error{
    /// Verification string doesn't match the provided password and parameters
    PasswordVerificationFailed,
};
pub const WeakParametersError = error{
    /// Parameters would be insecure to use
    WeakParameters,
};
pub const WeakPublicKeyError = error{
    /// Public key would be insecure to use
    WeakPublicKey,
};
/// Any error related to cryptography operations
pub const Error = AuthenticationError || OutputTooLongError ||
    IdentityElementError || EncodingError || SignatureVerificationError ||
    KeyMismatchError || NonCanonicalError || NotSquareError ||
    PasswordVerificationError || WeakParametersError || WeakPublicKeyError;
