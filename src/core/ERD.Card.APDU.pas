unit ERD.Card.APDU;

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
  /// <summary>The size in bytes of the CLA, INS, P1 and P2 command header.</summary>
  ApduHeaderSize = 4;
  /// <summary>The largest command data length supported by short APDUs, in bytes.</summary>
  ApduMaxShortDataLength = 255;
  /// <summary>The largest command data length supported by extended APDUs, in bytes.</summary>
  ApduMaxExtendedDataLength = 65535;
  /// <summary>The largest short expected response length, represented on the wire by zero.</summary>
  ApduMaxShortLe = 256;
  /// <summary>The largest extended response data length, represented on the wire by two zero bytes.</summary>
  ApduMaxExtendedLe = 65536;
  /// <summary>The response status word indicating normal processing, hexadecimal 9000.</summary>
  ApduStatusSuccess = $9000;

type
  /// <summary>Describes why an APDU cannot be decoded or encoded.</summary>
  TApduErrorCode = (
    /// <summary>No error occurred.</summary>
    aecNone,
    /// <summary>The command does not contain its complete four-byte header.</summary>
    aecHeaderTruncated,
    /// <summary>The extended length field is incomplete.</summary>
    aecLengthTruncated,
    /// <summary>The available bytes do not match Lc and the permitted Le sizes.</summary>
    aecDataLengthMismatch,
    /// <summary>A command length or command record is not valid for its encoding.</summary>
    aecInvalidCommand,
    /// <summary>The response does not contain both status bytes.</summary>
    aecResponseTruncated,
    /// <summary>The response data exceeds 65536 bytes.</summary>
    aecResponseTooLong
  );

  /// <summary>Reports an APDU error without retaining potentially sensitive input.</summary>
  TApduError = record
    /// <summary>The failure category; aecNone on success.</summary>
    Code: TApduErrorCode;
    /// <summary>
    /// The zero-based offending byte position, or the input length for missing bytes.
    /// Minus one means success or an invalid record with no corresponding input byte.
    /// </summary>
    Offset: Integer;
  end;

  /// <summary>A command APDU with its header, data and optional expected response length.</summary>
  /// <remarks>
  /// Data uses bytes, not hexadecimal text. Lc is derived from Data.
  /// Ordinary record assignment shares the dynamic array; clone Data before editing
  /// a copy. The codec allocates independent output and does not retain input.
  /// </remarks>
  TApduCommand = record
    /// <summary>The instruction class byte; interpreted by the selected card application.</summary>
    CLA: Byte;
    /// <summary>The instruction byte; interpreted by the selected card application.</summary>
    INS: Byte;
    /// <summary>The first instruction parameter.</summary>
    P1: Byte;
    /// <summary>The second instruction parameter.</summary>
    P2: Byte;
    /// <summary>Command data without length fields or trailing Le bytes.</summary>
    Data: TBytes;
    /// <summary>Whether Le is present; false requires Le to be zero when encoding.</summary>
    HasLe: Boolean;
    /// <summary>
    /// Expected response data bytes: 1..256 for short or 1..65536 for extended APDUs.
    /// Zero denotes absence, not the wire representation of the maximum length.
    /// </summary>
    Le: Cardinal;
    /// <summary>
    /// Whether to use extended length fields. A header-only command must be short.
    /// Small data or Le values may explicitly use extended encoding.
    /// </summary>
    IsExtended: Boolean;
  end;

  /// <summary>A response APDU containing data and an uninterpreted status word.</summary>
  /// <remarks>
  /// A syntactically valid response is not necessarily a successful card operation.
  /// Ordinary record assignment shares Data; clone it before editing a copy.
  /// </remarks>
  TApduResponse = record
    /// <summary>The response bytes excluding SW1 and SW2; may be empty.</summary>
    Data: TBytes;
    /// <summary>The status word, with SW1 in the high byte and SW2 in the low byte.</summary>
    StatusWord: Word;
  end;

  /// <summary>Reports an invalid APDU without including command or response contents.</summary>
  EApduFormatError = class(EConvertError)
  private
    FError: TApduError;
  public
    /// <summary>Creates an exception containing a structured APDU failure.</summary>
    /// <param name="AError">The failure code and zero-based byte offset.</param>
    constructor Create(const AError: TApduError); reintroduce;
    /// <summary>The failure code and offset; encoding errors use offset minus one.</summary>
    property Error: TApduError read FError;
  end;

  /// <summary>Encodes and decodes ISO 7816 short and extended command/response syntax.</summary>
  /// <remarks>
  /// Stateless, with no hardware, UI, application-selection or instruction semantics.
  /// Independent calls are safe on different threads when callers do not mutate
  /// input arrays concurrently. No automatic GET RESPONSE or retries are performed.
  /// </remarks>
  TApduCodec = class
  public
    /// <summary>Decodes command cases 1, 2S, 3S, 4S, 2E, 3E and 4E.</summary>
    /// <param name="ABytes">The complete binary command APDU.</param>
    /// <param name="ACommand">An independent decoded command, or a cleared record on failure.</param>
    /// <param name="AError">The error and offset; aecNone and minus one on success.</param>
    /// <returns>True if all input bytes match one supported command layout.</returns>
    /// <remarks>
    /// Invalid input does not raise a conversion exception; allocation failures may propagate.
    /// ABytes must not alias ACommand.Data because out parameters are cleared on entry.
    /// </remarks>
    class function TryDecodeCommand(const ABytes: TBytes;
      out ACommand: TApduCommand; out AError: TApduError): Boolean; static;
    /// <summary>Decodes a complete binary command APDU.</summary>
    /// <param name="ABytes">The complete binary command APDU.</param>
    /// <returns>An independent command record with explicit Le presence and encoding.</returns>
    /// <exception cref="EApduFormatError">The bytes do not form a supported command APDU.</exception>
    class function DecodeCommand(const ABytes: TBytes): TApduCommand; static;
    /// <summary>Encodes a command using its explicitly selected short or extended form.</summary>
    /// <param name="ACommand">The command; Data and Le must fit its encoding and presence flags.</param>
    /// <returns>A new byte array containing only the encoded command.</returns>
    /// <exception cref="EApduFormatError">The record contains invalid or conflicting lengths or flags.</exception>
    class function EncodeCommand(const ACommand: TApduCommand): TBytes; static;
    /// <summary>Splits response bytes into data and the final two status bytes.</summary>
    /// <param name="ABytes">The complete response, with at most 65536 data bytes.</param>
    /// <param name="AResponse">An independent response, or a cleared record on failure.</param>
    /// <param name="AError">The error and offset; aecNone and minus one on success.</param>
    /// <returns>True if the response length is valid, regardless of its status word.</returns>
    /// <remarks>ABytes must not alias AResponse.Data because out parameters are cleared on entry.</remarks>
    class function TryDecodeResponse(const ABytes: TBytes;
      out AResponse: TApduResponse; out AError: TApduError): Boolean; static;
    /// <summary>Decodes response data and a status word without interpreting card success.</summary>
    /// <param name="ABytes">The complete binary response APDU.</param>
    /// <returns>An independent response record.</returns>
    /// <exception cref="EApduFormatError">The response is missing status bytes or exceeds the maximum length.</exception>
    class function DecodeResponse(const ABytes: TBytes): TApduResponse; static;
    /// <summary>Appends a response status word to its data.</summary>
    /// <param name="AResponse">The response with at most 65536 data bytes.</param>
    /// <returns>A new byte array containing data followed by SW1 and SW2.</returns>
    /// <exception cref="EApduFormatError">The response data exceeds the maximum length.</exception>
    class function EncodeResponse(const AResponse: TApduResponse): TBytes; static;
  end;

implementation

procedure SetError(out AError: TApduError; const ACode: TApduErrorCode;
  const AOffset: Integer);
begin
  AError.Code := ACode;
  AError.Offset := AOffset;
end;

procedure RaiseFormatError(const ACode: TApduErrorCode);
var
  Error: TApduError;
begin
  SetError(Error, ACode, -1);
  raise EApduFormatError.Create(Error);
end;

function ReadLength(const ABytes: TBytes; const AOffset: Integer): Integer;
begin
  Result := (Integer(ABytes[AOffset]) shl 8) or ABytes[AOffset + 1];
end;

constructor EApduFormatError.Create(const AError: TApduError);
begin
  inherited CreateFmt('Invalid APDU: error %d at byte offset %d.',
    [Ord(AError.Code), AError.Offset]);
  FError := AError;
end;

class function TApduCodec.TryDecodeCommand(const ABytes: TBytes;
  out ACommand: TApduCommand; out AError: TApduError): Boolean;
var
  Size: Integer;
  DataStart: Integer;
  DataSize: Integer;
  ExpectedSize: Integer;
  ExpectedLe: Cardinal;
  HasLe: Boolean;
  Extended: Boolean;
begin
  ACommand := Default(TApduCommand);
  SetError(AError, aecNone, -1);
  if Length(ABytes) > ApduMaxExtendedDataLength + 9 then
  begin
    SetError(AError, aecDataLengthMismatch, ApduMaxExtendedDataLength + 9);
    Exit(False);
  end;
  Size := Length(ABytes);
  if Size < ApduHeaderSize then
  begin
    SetError(AError, aecHeaderTruncated, Size);
    Exit(False);
  end;

  DataStart := ApduHeaderSize;
  DataSize := 0;
  ExpectedLe := 0;
  HasLe := False;
  Extended := False;
  if Size = 5 then
  begin
    HasLe := True;
    ExpectedLe := ABytes[4];
    if ExpectedLe = 0 then
      ExpectedLe := ApduMaxShortLe;
  end
  else if Size > 5 then
  begin
    if ABytes[4] <> 0 then
    begin
      DataStart := 5;
      DataSize := ABytes[4];
      ExpectedSize := DataStart + DataSize;
      if (Size <> ExpectedSize) and (Size <> ExpectedSize + 1) then
      begin
        if Size < ExpectedSize then
          SetError(AError, aecDataLengthMismatch, Size)
        else
          SetError(AError, aecDataLengthMismatch, ExpectedSize + 1);
        Exit(False);
      end;
      HasLe := Size = ExpectedSize + 1;
      if HasLe then
      begin
        ExpectedLe := ABytes[ExpectedSize];
        if ExpectedLe = 0 then
          ExpectedLe := ApduMaxShortLe;
      end;
    end
    else
    begin
      Extended := True;
      if Size < 7 then
      begin
        SetError(AError, aecLengthTruncated, Size);
        Exit(False);
      end;
      if Size = 7 then
      begin
        HasLe := True;
        ExpectedLe := ReadLength(ABytes, 5);
        if ExpectedLe = 0 then
          ExpectedLe := ApduMaxExtendedLe;
      end
      else
      begin
        DataStart := 7;
        DataSize := ReadLength(ABytes, 5);
        if DataSize = 0 then
        begin
          SetError(AError, aecInvalidCommand, 5);
          Exit(False);
        end;
        ExpectedSize := DataStart + DataSize;
        if (Size <> ExpectedSize) and (Size <> ExpectedSize + 2) then
        begin
          if Size < ExpectedSize then
            SetError(AError, aecDataLengthMismatch, Size)
          else if Size = ExpectedSize + 1 then
            SetError(AError, aecLengthTruncated, Size)
          else
            SetError(AError, aecDataLengthMismatch, ExpectedSize + 2);
          Exit(False);
        end;
        HasLe := Size = ExpectedSize + 2;
        if HasLe then
        begin
          ExpectedLe := ReadLength(ABytes, ExpectedSize);
          if ExpectedLe = 0 then
            ExpectedLe := ApduMaxExtendedLe;
        end;
      end;
    end;
  end;

  ACommand.CLA := ABytes[0];
  ACommand.INS := ABytes[1];
  ACommand.P1 := ABytes[2];
  ACommand.P2 := ABytes[3];
  ACommand.Data := Copy(ABytes, DataStart, DataSize);
  ACommand.HasLe := HasLe;
  ACommand.Le := ExpectedLe;
  ACommand.IsExtended := Extended;
  Result := True;
end;

class function TApduCodec.DecodeCommand(const ABytes: TBytes): TApduCommand;
var
  Error: TApduError;
begin
  if not TryDecodeCommand(ABytes, Result, Error) then
    raise EApduFormatError.Create(Error);
end;

class function TApduCodec.EncodeCommand(const ACommand: TApduCommand): TBytes;
var
  DataSize: Integer;
  DataStart: Integer;
  Size: Integer;
  I: Integer;
begin
  Result := nil;
  if Length(ACommand.Data) > ApduMaxExtendedDataLength then
    RaiseFormatError(aecInvalidCommand);
  DataSize := Length(ACommand.Data);
  if (not ACommand.HasLe) and (ACommand.Le <> 0) then
    RaiseFormatError(aecInvalidCommand);
  if ACommand.HasLe and (ACommand.Le = 0) then
    RaiseFormatError(aecInvalidCommand);
  if ACommand.IsExtended then
  begin
    if (DataSize > ApduMaxExtendedDataLength) or
      (ACommand.Le > ApduMaxExtendedLe) or
      ((DataSize = 0) and (not ACommand.HasLe)) then
      RaiseFormatError(aecInvalidCommand);
  end
  else if (DataSize > ApduMaxShortDataLength) or
    (ACommand.Le > ApduMaxShortLe) then
    RaiseFormatError(aecInvalidCommand);

  DataStart := ApduHeaderSize;
  Size := ApduHeaderSize;
  if DataSize > 0 then
  begin
    if ACommand.IsExtended then
      DataStart := 7
    else
      DataStart := 5;
    Size := DataStart + DataSize;
    if ACommand.HasLe then
    begin
      if ACommand.IsExtended then
        Inc(Size, 2)
      else
        Inc(Size);
    end;
  end
  else if ACommand.HasLe then
  begin
    if ACommand.IsExtended then
      Size := 7
    else
      Size := 5;
  end;

  SetLength(Result, Size);
  Result[0] := ACommand.CLA;
  Result[1] := ACommand.INS;
  Result[2] := ACommand.P1;
  Result[3] := ACommand.P2;
  if DataSize > 0 then
  begin
    if ACommand.IsExtended then
    begin
      Result[4] := 0;
      Result[5] := Byte(DataSize shr 8);
      Result[6] := Byte(DataSize and $FF);
    end
    else
      Result[4] := Byte(DataSize);
    for I := 0 to DataSize - 1 do
      Result[DataStart + I] := ACommand.Data[I];
  end;
  if ACommand.HasLe then
  begin
    if ACommand.IsExtended then
    begin
      if DataSize = 0 then
        Result[4] := 0;
      Result[Size - 2] := Byte((ACommand.Le shr 8) and $FF);
      Result[Size - 1] := Byte(ACommand.Le and $FF);
    end
    else
      Result[Size - 1] := Byte(ACommand.Le and $FF);
  end;
end;

class function TApduCodec.TryDecodeResponse(const ABytes: TBytes;
  out AResponse: TApduResponse; out AError: TApduError): Boolean;
var
  Size: Integer;
begin
  AResponse := Default(TApduResponse);
  SetError(AError, aecNone, -1);
  if Length(ABytes) > ApduMaxExtendedLe + 2 then
  begin
    SetError(AError, aecResponseTooLong, ApduMaxExtendedLe + 2);
    Exit(False);
  end;
  Size := Length(ABytes);
  if Size < 2 then
  begin
    SetError(AError, aecResponseTruncated, Size);
    Exit(False);
  end;
  AResponse.Data := Copy(ABytes, 0, Size - 2);
  AResponse.StatusWord := Word(ReadLength(ABytes, Size - 2));
  Result := True;
end;

class function TApduCodec.DecodeResponse(const ABytes: TBytes): TApduResponse;
var
  Error: TApduError;
begin
  if not TryDecodeResponse(ABytes, Result, Error) then
    raise EApduFormatError.Create(Error);
end;

class function TApduCodec.EncodeResponse(const AResponse: TApduResponse): TBytes;
var
  I: Integer;
  DataSize: Integer;
begin
  Result := nil;
  if Length(AResponse.Data) > ApduMaxExtendedLe then
    RaiseFormatError(aecResponseTooLong);
  DataSize := Length(AResponse.Data);
  SetLength(Result, DataSize + 2);
  for I := 0 to DataSize - 1 do
    Result[I] := AResponse.Data[I];
  Result[DataSize] := Byte(AResponse.StatusWord shr 8);
  Result[DataSize + 1] := Byte(AResponse.StatusWord and $FF);
end;

end.
