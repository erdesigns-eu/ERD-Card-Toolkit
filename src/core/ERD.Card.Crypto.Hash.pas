unit ERD.Card.Crypto.Hash;

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
  /// <summary>Optional SHA-1 capability for explicitly specified legacy key derivation.</summary>
  /// <remarks>Inputs are borrowed; returns independent storage. SHA-1 is not a modern signature algorithm.</remarks>
  ICardHashProvider = interface
    ['{97107784-4432-4198-A9FC-A703E501679E}']
    /// <summary>Hashes zero through one MiB of borrowed bytes using SHA-1.</summary>
    /// <param name="AData">Unmodified input; never logged.</param>
    /// <returns>Owned twenty-byte digest.</returns>
    function Sha1(const AData: TBytes): TBytes;
  end;

implementation

end.
