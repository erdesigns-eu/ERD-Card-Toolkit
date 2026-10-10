unit ERD.Card.Crypto.RSA;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  /// <summary>Provisioned RSA PKCS#1 v1.5 SHA-1 signing and verification for explicit legacy GP profiles.</summary>
  /// <remarks>Backends may retain native keys or delegate to an HSM; input is borrowed and never logged.</remarks>
  ICardRsaProvider = interface
    ['{974CCCFB-7A81-44C9-B29C-F4D62C30BD9A}']
    /// <summary>Signs the SHA-1 digest of supplied data with the provisioned private key.</summary>
    /// <param name="AData">Zero through one MiB of unmodified protocol data.</param>
    /// <returns>Independent modulus-sized PKCS#1 v1.5 signature.</returns>
    function SignSha1(const AData: TBytes): TBytes;
    /// <summary>Verifies a SHA-1 PKCS#1 v1.5 signature using the provisioned public key.</summary>
    /// <param name="AData">Exact signed protocol data, including its framing.</param>
    /// <param name="ASignature">Modulus-sized signature; other sizes return false.</param>
    /// <returns>True only for a valid signature; backend failures raise a crypto exception.</returns>
    function VerifySha1(const AData, ASignature: TBytes): Boolean;
  end;

implementation

end.
