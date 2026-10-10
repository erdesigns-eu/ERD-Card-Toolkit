unit ERD.Card.Crypto.EAC;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Crypto;

type
  /// <summary>Explicit standardized PACE ECDH Generic Mapping domain parameters.</summary>
  TCardPaceCurve = (
    /// <summary>NIST P-256, standardized parameter identifier 12.</summary>
    ppcNistP256,
    /// <summary>Brainpool P256r1, standardized parameter identifier 13.</summary>
    ppcBrainpoolP256);

  /// <summary>One owned PACE Generic Mapping key agreement; native private scalars never leave the context.</summary>
  /// <remarks>Single-use, single-thread context. Validate points, infinity, subgroup and reflection before derivation.</remarks>
  ICardPaceAgreement = interface
    ['{6F90374E-615A-4C3D-B3B8-7340C36C6B39}']
    /// <summary>Returns the mapping public point using the original curve generator.</summary>
    /// <returns>Owned 65-byte uncompressed SEC1 point.</returns>
    function MappingPublicKey: TBytes;
    /// <summary>Maps the original generator as nonce*G plus the mapping ECDH point and generates the second public key.</summary>
    /// <param name="ACardMappingKey">Exact valid 65-byte uncompressed card mapping point.</param>
    /// <param name="ANonce">Exact 16-byte decrypted nonce, including zero when mapping remains non-infinite.</param>
    /// <returns>Owned 65-byte uncompressed agreement point; this step can be used once.</returns>
    function MapAndGenerate(const ACardMappingKey, ANonce: TBytes): TBytes;
    /// <summary>Derives the agreement point's affine X coordinate without exporting the private scalar.</summary>
    /// <param name="ACardAgreementKey">Valid uncompressed card point, distinct from the terminal point.</param>
    /// <returns>Owned exact 32-byte shared secret; this step can be used once.</returns>
    function Agree(const ACardAgreementKey: TBytes): TBytes;
  end;

  /// <summary>Maintained native primitives for ICAO BAC and PACE, extending the unchanged AES provider contract.</summary>
  /// <remarks>No cipher, digest or elliptic-curve arithmetic is implemented in the protocol layer.
  /// Borrowed inputs are not modified; independent secret outputs must be cleared by their owner.</remarks>
  ICardEacProvider = interface(ICardAesProvider)
    ['{043C3B90-BC51-4E50-BE2F-24A1D9CAB63E}']
    /// <summary>Calculates the ICAO profile's SHA-1 digest through the native cryptographic library.</summary>
    /// <param name="AData">Zero through one MiB of borrowed data.</param>
    /// <returns>Owned 20-byte digest.</returns>
    function Sha1(const AData: TBytes): TBytes;
    /// <summary>Performs complete-block three-key Triple DES CBC without padding.</summary>
    /// <param name="AKey">Exactly 24 bytes; BAC expands K1,K2 to K1,K2,K1 explicitly.</param>
    /// <param name="AIv">Exactly eight bytes, not modified.</param>
    /// <param name="AData">Positive multiple of eight, at most one MiB.</param>
    /// <param name="AEncrypt">True for encryption, false for decryption.</param>
    /// <returns>Owned exact-length ciphertext/plaintext.</returns>
    function TripleDesCbc(const AKey, AIv, AData: TBytes;
      const AEncrypt: Boolean): TBytes;
    /// <summary>Creates one Generic Mapping context with explicit fresh, uniformly sampled private scalars.</summary>
    /// <param name="ACurve">One implemented standardized 256-bit curve.</param>
    /// <param name="AMappingSecret">Exact 32-byte positive scalar below the curve order; copied by native storage.</param>
    /// <param name="AAgreementSecret">A separate fresh scalar under the same bound.</param>
    /// <returns>Owned context retaining the provider/library for its complete lifetime.</returns>
    /// <remarks>Document readers obtain scalars using this provider's CSPRNG with bounded rejection sampling.
    /// Explicit scalars also permit published-vector tests; never use test scalars in hardware sessions.</remarks>
    function CreatePaceAgreement(const ACurve: TCardPaceCurve;
      const AMappingSecret, AAgreementSecret: TBytes): ICardPaceAgreement;
  end;

implementation

end.
