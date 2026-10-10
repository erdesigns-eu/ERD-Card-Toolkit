unit ERD.Card.Contactless.Type2;

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

const
  /// <summary>Bytes per original Ultralight/NTAG storage page.</summary>
  Type2PageBytes = 4;
  /// <summary>First user-data page for the explicitly supported models.</summary>
  Type2FirstUserPage = 4;

type
  /// <summary>Invalid Type 2 model or page; no card data is retained in the message.</summary>
  EType2DataError = class(EConvertError);
  /// <summary>Explicit memory model; caller identification is required before hardware operations.</summary>
  TType2TagModel = (
    /// <summary>Original MF0ICU1 Ultralight: 16 total pages, 48 user bytes.</summary>
    ttmUltralight,
    /// <summary>MF0UL11 Ultralight EV1: 20 total pages, 48 user bytes.</summary>
    ttmUltralightEv1_48,
    /// <summary>MF0UL21 Ultralight EV1: 41 total pages, 128 user bytes.</summary>
    ttmUltralightEv1_128,
    /// <summary>NTAG213: 45 total pages, 144 user bytes.</summary>
    ttmNtag213,
    /// <summary>NTAG215: 135 total pages, 504 user bytes.</summary>
    ttmNtag215,
    /// <summary>NTAG216: 231 total pages, 888 user bytes.</summary>
    ttmNtag216,
    /// <summary>NTAG210: 20 total pages, 48 user bytes; enum appended to preserve existing ordinals.</summary>
    ttmNtag210,
    /// <summary>NTAG212: 41 total pages, 128 user bytes; enum appended to preserve existing ordinals.</summary>
    ttmNtag212);

  /// <summary>Complete user-data snapshot; passwords, counters and configuration are excluded.</summary>
  /// <remarks>Ordinary record assignment shares Data. Copy the buffer before editing an assigned copy.
  /// This is raw reader-visible memory, not an NDEF interpretation or an authenticity assertion.</remarks>
  TType2UserMemory = record
    /// <summary>Caller-selected layout used for the read.</summary>
    Model: TType2TagModel;
    /// <summary>First page, always Type2FirstUserPage for supported layouts.</summary>
    FirstPage: Byte;
    /// <summary>Number of successfully read pages; complete snapshots only.</summary>
    PageCount: Integer;
    /// <summary>Independent four-byte pages concatenated in ascending page order.</summary>
    Data: TBytes;
  end;

  /// <summary>Stateless bounds for original Ultralight, Ultralight EV1 and NTAG210/212/213/215/216.</summary>
  TType2Layout = class
  public
    /// <summary>Returns physical page capacity, including protected/configuration regions.</summary>
    /// <param name="AModel">Explicit supported model.</param>
    /// <returns>16, 20, 41, 45, 135 or 231 pages.</returns>
    /// <exception cref="EType2DataError">Model is invalid.</exception>
    class function PageCount(const AModel: TType2TagModel): Integer; static;
    /// <summary>Returns the last user-data page, excluding lock/password/configuration pages.</summary>
    /// <param name="AModel">Explicit supported model.</param>
    /// <returns>15, 35, 39, 129 or 225 as appropriate to the model.</returns>
    /// <exception cref="EType2DataError">Model is invalid.</exception>
    class function LastUserPage(const AModel: TType2TagModel): Integer; static;
    /// <summary>Returns the complete user-data capacity in bytes.</summary>
    /// <param name="AModel">Explicit supported model.</param>
    /// <returns>48, 128, 144, 504 or 888 bytes.</returns>
    /// <exception cref="EType2DataError">Model is invalid.</exception>
    class function UserByteCount(const AModel: TType2TagModel): Integer; static;
    /// <summary>Checks whether an in-range page belongs to the permitted user-data region.</summary>
    /// <param name="AModel">Explicit supported model.</param>
    /// <param name="APage">Physical page number within the selected layout.</param>
    /// <returns>True for pages four through LastUserPage; does not establish lock/authentication state.</returns>
    /// <exception cref="EType2DataError">Model or page is invalid.</exception>
    class function IsUserPage(const AModel: TType2TagModel;
      const APage: Integer): Boolean; static;
  end;

implementation

procedure Fail;
begin
  raise EType2DataError.Create('Invalid Type 2 model or page.');
end;

class function TType2Layout.PageCount(const AModel: TType2TagModel): Integer;
begin
  case AModel of
    ttmUltralight:
      Result := 16;
    ttmUltralightEv1_48:
      Result := 20;
    ttmUltralightEv1_128:
      Result := 41;
    ttmNtag213:
      Result := 45;
    ttmNtag215:
      Result := 135;
    ttmNtag216:
      Result := 231;
    ttmNtag210:
      Result := 20;
    ttmNtag212:
      Result := 41;
  else
    Fail;
    Result := 0;
  end;
end;

class function TType2Layout.LastUserPage(const AModel: TType2TagModel): Integer;
begin
  case AModel of
    ttmUltralight, ttmUltralightEv1_48:
      Result := 15;
    ttmUltralightEv1_128:
      Result := 35;
    ttmNtag213:
      Result := 39;
    ttmNtag215:
      Result := 129;
    ttmNtag216:
      Result := 225;
    ttmNtag210:
      Result := 15;
    ttmNtag212:
      Result := 35;
  else
    Fail;
    Result := 0;
  end;
end;

class function TType2Layout.UserByteCount(const AModel: TType2TagModel)
  : Integer;
begin
  Result := (LastUserPage(AModel) - Type2FirstUserPage + 1) * Type2PageBytes;
end;

class function TType2Layout.IsUserPage(const AModel: TType2TagModel;
  const APage: Integer): Boolean;
begin
  if (APage < 0) or (APage >= PageCount(AModel)) then
    Fail;
  Result := (APage >= Type2FirstUserPage) and (APage <= LastUserPage(AModel));
end;

end.
