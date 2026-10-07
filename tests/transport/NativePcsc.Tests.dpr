program NativePcscTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes,
  ERD.Card.PCSC.Api,
  ERD.Card.PCSC.Windows;

// These exports exist only in the Linux test shim. Do not run against Windows DLLs.
procedure Configure(AMode: Integer); cdecl;
  external 'winscard.dll' name 'CardTestConfigure';
function NativeCount(AKind: Integer): Integer; cdecl;
  external 'winscard.dll' name 'CardTestCount';

var
  Checks: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure TestNativeBoundary;
var
  Api: IPcscApi;
  Context: TPcscHandle;
  Card: TPcscHandle;
  Protocol: Cardinal;
  Names: TPcscReaderNames;
  Name: UnicodeString;
  Bytes: TBytes;
  Snapshot: TPcscReaderSnapshot;
  I: Integer;
begin
  Configure(0);
  Api := CreateSystemPcscApi;
  Check(Api.Establish(Context) = PcscSuccess, 'Native context call');
  Check(Context = TPcscHandle(UInt64($100000001)), 'Native context preserves high bits');
  Check(Api.ListReaders(Context, Names) = PcscSuccess, 'Native two-stage discovery');
  Name := 'R' + UnicodeString(WideChar($00E9));
  Check((Length(Names) = 2) and (Names[0] = Name) and (Names[1] = 'B'), 'Bounded UTF-16 MULTI_SZ');
  Check(Api.Connect(Context, Name, psmShared, 3, Card, Protocol) = PcscSuccess, 'Native Unicode connect');
  Check((Card = TPcscHandle(UInt64($200000003))) and (Protocol = 2), 'Native card/protocol outputs');
  Check(Api.BeginTransaction(Card) = PcscSuccess, 'Native begin transaction');
  Check(Api.Transmit(Card, Protocol, HexToBytes('00A4000000'), 258, Bytes) = PcscSuccess, 'Native PCI and command length');
  Check((BytesToHex(Bytes) = '9000') and (NativeCount(0) = 1), 'Native response and exactly one send');
  Check(Api.ReadAtr(Card, Bytes) = PcscSuccess, 'Nullable native status parameters');
  Check(BytesToHex(Bytes) = '3B800181', 'Native ATR size');
  Check(Api.WaitStatus(Context, Name, PcscStateChanged, 250, Snapshot) = PcscSuccess, 'Native status record input');
  Check((Snapshot.State = $12340020) and (BytesToHex(Snapshot.Atr) = '3B800181') and
    (Snapshot.ReaderName = Name), 'Native state counter, normalization and ATR');
  Check(Api.Cancel(Context) = PcscSuccess, 'Native cancellation');
  for I := 0 to 3 do
    Check(Api.EndTransaction(Card, TPcscDisposition(I)) = PcscSuccess, 'Native disposition mapping');
  Check(Api.Disconnect(Card, pcdLeave) = PcscSuccess, 'Native disconnect');
  Check(Api.Release(Context) = PcscSuccess, 'Native release');
  Configure(1);
  Check(Api.ListReaders(Context, Names) = PcscInternalError, 'Malformed MULTI_SZ rejected');
  Check(Length(Names) = 0, 'Malformed discovery clears output');
  Configure(2);
  Check(Api.ListReaders(Context, Names) = PcscSuccess, 'Discovery tolerates changing required length');
  Check((NativeCount(1) = 2) and (Length(Names) = 2), 'Only discovery is retried');
  Configure(3);
  Check(Api.Transmit(Card, 2, HexToBytes('00A4000000'), 258, Bytes) = PcscInternalError, 'Overreported receive size rejected');
  Check((Length(Bytes) = 0) and (NativeCount(0) = 1), 'Bad receive size has no partial output/resend');
  Configure(4);
  Check(Api.Transmit(Card, 2, HexToBytes('00A4000000'), 258, Bytes) = PcscInsufficientBuffer, 'Native receive capacity error preserved');
  Check((Length(Bytes) = 0) and (NativeCount(0) = 1), 'Capacity error never resends');
  Configure(5);
  Check(Api.ReadAtr(Card, Bytes) = PcscInternalError, 'Overreported ATR size rejected');
  Check(Length(Bytes) = 0, 'Bad ATR clears output');
  Check(Api.WaitStatus(Context, Name, 0, 250, Snapshot) = PcscInternalError, 'Status ATR bounded by SDK buffer');
  Check((Snapshot.State = 0) and (Length(Snapshot.Atr) = 0) and (Snapshot.ReaderName = ''), 'Bad status clears snapshot');
  Configure(6);
  Check(Api.WaitStatus(Context, Name, 0, 0, Snapshot) = PcscTimeout, 'Native wait timeout preserved');
  Check(Length(Snapshot.Atr) = 0, 'Timeout clears output');
  Configure(7);
  Check(Api.Connect(Context, Name, psmShared, 3, Card, Protocol) = $8010000C, 'Native connection failure preserved');
  Check((Card = 0) and (Protocol = 0), 'Failed connect clears native outputs');
  Configure(8);
  Check(Api.ListReaders(Context, Names) = PcscNoReaders, 'Native no-readers status preserved');
  Check(Length(Names) = 0, 'No readers clears discovery');
end;

begin
  try
    TestNativeBoundary;
    Writeln('PASS: ', Checks, ' assertions against the Linux native PC/SC ABI shim.');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
