{*******************************************************}
{                                                       }
{                       untATR                          }
{                     Author: ERD                       }
{                                                       }
{        SmartCard ATR (Answer to Reset) Parser         }
{                                                       }
{*******************************************************}

unit untATR;

interface

uses
  WinApi.Windows,
  System.SysUtils,
  System.Classes,
  System.AnsiStrings,
  untBIN;

type
  {*******************************************************}
  {                    ATR Data Record                    }
  {*******************************************************}
  ATRDataRec = packed record
    IsPresent : Boolean;
    Data      : Byte;

    procedure Clear;
  end;

  {*******************************************************}
  {               Array of ATR Data Record                }
  {*******************************************************}
  ATRTrecArray = array of ATRDataRec;

  {*******************************************************}
  {                  ATR T Data Record                    }
  {*******************************************************}
  ATRTRec = packed record
    TA : ATRTrecArray;
    TB : ATRTrecArray;
    TC : ATRTrecArray;
    TD : ATRTrecArray;

    procedure Clear;
    function AddRow(PRes: Byte) : Integer;
    function RowCount : Integer;

    procedure SetTA(B: Byte);
    procedure SetTB(B: Byte);
    procedure SetTC(B: Byte);
    procedure SetTD(B: Byte);

    function LastTA : ATRDataRec;
    function LastTB : ATRDataRec;
    function LastTC : ATRDataRec;
    function LastTD : ATRDataRec;
  end;

  {*******************************************************}
  {                     ATR Record                        }
  {*******************************************************}
  ATRrec = packed record
    Valid : Boolean;
    TS    : Byte;
    T0    : Byte;
    T     : ATRTrec;
    TCK   : Byte;

    InterfaceBytesCount : Integer;
    HistoricalBytesCount : Integer;
    HistoricalBytes : AnsiString;
    IsHistoricalBytesTLV : Boolean;

    IsTCKPresent : Boolean;
    IsTCKCorrect : Boolean;

    procedure Clear;
    procedure Load(ATR: AnsiString);
  end;

  {*******************************************************}
  {                ATR (Answer to Reset)                  }
  {*******************************************************}
  TATR = packed record
    atr_scheme   : TCardScheme;
    atr_type     : TCardType;
    atr_country  : TCountryCode;
    atr_issuer   : AnsiString;
    atr_category : AnsiString;
    atr_value    : AnsiString;
  end;

implementation

{*******************************************************}
{                    ATR Data Record                    }
{*******************************************************}
procedure ATRDataRec.Clear;
begin
  IsPresent := False;
  Data := 0;
end;

{*******************************************************}
{                  ATR T Data Record                    }
{*******************************************************}
procedure ATRTRec.Clear;
begin
  SetLength(TA, 0);
  SetLength(TB, 0);
  SetLength(TC, 0);
  SetLength(TD, 0);
end;

function ATRTRec.AddRow(PRes: Byte) : Integer;
begin
  Result := 0;

  SetLength(TA, Length(TA) + 1);
  SetLength(TB, Length(TB) + 1);
  SetLength(TC, Length(TC) + 1);
  SetLength(TD, Length(TD) + 1);

  TA[Length(TA) - 1].Clear;
  if (PRes and $01) <> 0 then TA[Length(TA) - 1].IsPresent := True;
  TB[length(TB) - 1].Clear;
  if (PRes and $02) <> 0 then TB[Length(TB) - 1].IsPresent := True;
  TC[length(TC) - 1].Clear;
  if (PRes and $04) <> 0 then TC[Length(TC) - 1].IsPresent := True;
  TD[length(TD) - 1].Clear;
  if (PRes and $08) <> 0 then TD[Length(TD) - 1].IsPresent := True;

  if LastTA.IsPresent then Result := Result + 1;
  if LastTB.IsPresent then Result := Result + 1;
  if LastTC.IsPresent then Result := Result + 1;
  if LastTD.IsPresent then Result := Result + 1;
end;

function ATRTRec.RowCount : Integer;
begin
  Result := Length(TA);
end;

function ATRTRec.LastTA : ATRDataRec;
begin
  Result := TA[Length(TA) - 1];
end;

function ATRTRec.LastTB : ATRDataRec;
begin
  Result := TB[Length(TB) - 1];
end;

function ATRTRec.LastTC : ATRDataRec;
begin
  Result := TC[Length(TC) - 1];
end;

function ATRTRec.LastTD : ATRDataRec;
begin
  Result := TD[Length(TD) - 1];
end;

procedure ATRTRec.SetTA(B: Byte);
begin
  if Length(TA) = 0 then Exit;
  TA[Length(TA) - 1].IsPresent := True;
  TA[Length(TA) - 1].Data := B;
end;

procedure ATRTRec.SetTB(B: Byte);
begin
  if Length(TB) = 0 then Exit;
  TB[Length(TB) - 1].IsPresent := True;
  TB[Length(TB) - 1].Data := B;
end;

procedure ATRTRec.SetTC(B: Byte);
begin
  if Length(TC) = 0 then Exit;
  TC[Length(TC) - 1].IsPresent := True;
  TC[Length(TC) - 1].Data := B;
end;

procedure ATRTRec.SetTD(B: Byte);
begin
  if Length(TD) = 0 then Exit;
  TD[Length(TD) - 1].IsPresent := True;
  TD[Length(TD) - 1].Data := B;
end;

{*******************************************************}
{                     ATR Record                        }
{*******************************************************}
procedure ATRrec.Clear;
begin
  Valid := False;
  TS := 0;
  T0 := 0;
  T.Clear;
  InterfaceBytesCount := 0;
end;

procedure ATRrec.Load(ATR: AnsiString);
var
  R  : Byte;
  TI : Byte;
  I  : Integer;
  K  : Integer;
begin
  Clear;
  Valid := False;

  if Length(ATR) < 2 then Exit;

  TS := Byte(ATR[1]);
  if (TS <> $3B) and (TS <> $3F) then Exit;

  InterfaceBytesCount := 0;

  T0 := Byte(ATR[2]);

  HistoricalBytesCount := T0 and $0F;
  TI := T0 and $F0 shr 4;

  // Parse TA TB TC TD structure
  while TI <> 0 do
  begin
    K := 2 + InterfaceBytesCount + 1;
    InterfaceBytesCount := InterfaceBytesCount + T.AddRow(TI);
    if Length(ATR) < K then Exit;

    if T.LastTA.IsPresent then
    begin
      T.SetTA(Byte(ATR[K]));
      K := K + 1;
    end;

    if T.LastTB.IsPresent then
    begin
      T.SetTB(Byte(ATR[K]));
      K := K + 1;
    end;

    if T.LastTC.IsPresent then
    begin
      T.SetTC(Byte(ATR[K]));
      K := K + 1;
    end;

    if T.LastTD.IsPresent then
    begin
      T.SetTD(Byte(ATR[K]));
    end;

    TI := T.lastTD.Data and $F0 shr 4;
  end;

  // Get Historical Bytes
  HistoricalBytes := Copy(ATR, 2 + InterfaceBytesCount + 1, HistoricalBytesCount);
  IsHistoricalBytesTLV := False;
  if Length(HistoricalBytes) > 0 then IsHistoricalBytesTLV := HistoricalBytes[1] = #00;

  // Check ATR Length
  K := 2 + InterfaceBytesCount + HistoricalBytesCount;
  if T.RowCount > 1 then K := K + 1;
  if Length(ATR) <> K then Exit;

  // Calculate TCK
  IsTCKPresent := False;
  IsTCKCorrect := True;
  if T.RowCount > 1 then
  begin
    TCK := Byte(ATR[2 + InterfaceBytesCount + HistoricalBytesCount + 1]);
    IsTCKPresent := True;

    R := 0;
    for I := 2 to 2 + InterfaceBytesCount + HistoricalBytesCount do
      R := R xor Byte(ATR[I]);

    if R = TCK then
      IsTCKCorrect := True
    else
      IsTCKCorrect := False;
  end;

  Valid := True;
end;

end.
