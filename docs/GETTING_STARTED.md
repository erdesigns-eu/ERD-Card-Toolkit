# Getting started

This guide walks you through building a first Delphi application with the ERD card
components. It covers which non-visual components to use and how to wire them
together, the events and methods you need, and how to keep card I/O off the UI
thread. It ends with short recipes for each card family.

Everything here is based on the public API in `src/`. Each component's XML
documentation (Help Insight) and its family guide (linked at the end) cover
the full details.

## 1. Before you start

You need:

- Delphi 10.4 or later on Windows (Win32 or Win64).
- A reader that matches your card. For contact smart cards and most NFC cards this
  is a **PC/SC reader** with its Windows driver installed. Magnetic-stripe writers,
  ELATEC TWN4 and keyboard-wedge RFID readers use other transports (COM port or
  HID); see [section 8](#8-recipes).
- OpenSSL 3 (`libcrypto-3.dll`, same bitness as your application), **only** if you
  read ICAO passports/ID cards with BAC/PACE.

Card support and reader support are separate. A card component can only work if
the reader supports the commands it needs. For example, MIFARE Classic over PC/SC
needs a reader that implements the PC/SC storage commands, and SLE memory chips
need an ACS reader with the matching dialect.

## 2. Create the project and make the units visible

1. **File > New > VCL Forms Application.**
2. Make the library visible to the compiler. Choose **one** of the following:
   - **Source (simplest):** add the `src` folders you need to
     *Project > Options > Building > Delphi Compiler > Search path*. This is how the
     bundled demos are built.
   - **Runtime packages:** build `packages/ERDCards.groupproj` and add the matching
     `dist/packages/<Platform>/<Config>` folder to your search path. See
     [INSTALLATION.md](INSTALLATION.md).
3. Optional: install the `ERDCardDesign` package (built for your **IDE** bitness) so
   that the components appear on the palette and you can assign events in the
   Object Inspector. Everything also works when you create the components in code.

Which `src` folders do you need?

| You want to use | Add to the search path |
| --- | --- |
| Any PC/SC card | `src/core`, `src/pcsc` |
| Belgian eID, ICAO documents | + `src/eid` (+ `src/crypto` for ICAO) |
| EMV | + `src/emv` |
| MIFARE, NTAG, NDEF, ISO 15693, DESFire, UID programming, Calypso/MOBIB | + `src/contactless` (+ `src/crypto` for DESFire AES) |
| SLE/I²C memory, counter chips, SLE4404 | + `src/memory` |
| SIM/USIM | + `src/sim` |
| Magnetic stripe | `src/magstripe` (no `src/core` needed) |
| USB-HID, RFID keyboard/HID readers | `src/core`, `src/input` |
| ELATEC TWN4 | `src/core`, `src/readers`, `src/contactless`, `src/magstripe` |

## 3. Pick your components

All components are **non-visual** `TComponent` descendants. None of them opens
hardware, starts a thread or connects to a card when it is created, so it is safe
to drop them on a form.

| Goal | Components | Palette page |
| --- | --- | --- |
| Know when readers are plugged in and cards are inserted or removed | `TSmartCardMonitor` | ERD Cards |
| Connect to a PC/SC reader and exchange APDUs | `TSmartCardReader` | ERD Cards |
| Read a Belgian eID | `TBelgianEIDReader` + `TSmartCardReader` | ERD Cards |
| Read a passport or ICAO ID card | `TICAODocumentReader` + `TSmartCardReader` + crypto provider | ERD Cards |
| Read EMV application data | `TEMVCardReader` + `TSmartCardReader` | ERD Cards |
| Read/write SIM/USIM | `TSimCardReaderWriter` + `TSmartCardReader` | ERD Cards |
| Read/write SLE/I²C memory cards | `TMemoryCardReaderWriter`, `TSleCounterCardReaderWriter`, `TSle4404CardReaderWriter` + `TSmartCardReader` | ERD Cards |
| Read a UID, MIFARE Classic blocks, Ultralight/NTAG pages | `TContactlessCardReader` + `TSmartCardReader` | ERD Contactless |
| Read/write NDEF messages | `TType2NdefCardReader`, `TType4NdefCardReader`, `TType5NdefCardReader` | ERD Contactless |
| Password-protected NTAG/Ultralight EV1 | `TType2PasswordCardReader` | ERD Contactless |
| ISO 15693 tags | `TIso15693CardReader` | ERD Contactless |
| MIFARE DESFire | `TDesfireCardReader` + crypto provider | ERD Contactless |
| Program "magic" UID cards | `TRawUidProgrammer` or `TContactlessCardReader` | ERD Contactless |
| Calypso / MOBIB transit cards | `TCalypsoCardReader` | ERD Contactless |
| Magnetic-stripe read/write | `TMagStripeReaderWriter` + device adapter | ERD Cards |
| Keyboard-wedge RFID readers | `TRfidKeyboardReader` | ERD Input |
| HID RFID readers that send reports | `TUsbHidInputMonitor` + `TRfidHidReportReader` | ERD Input |
| Raw USB-HID reports | `TUsbHidReaderWriter`, `THidDeviceMonitor` | ERD Input |
| ELATEC TWN4 (PRS/USB-CDC firmware) | `TTwn4CardReaderWriter` | ERD Input |

## 4. The basic pattern for PC/SC cards

Every PC/SC card family works the same way:

1. Create a `TSmartCardReader`, set `ReaderName` to an exact name and call `Connect`.
2. Create the card component and assign `Card.Transport` to its `Transport`
   property. Some families also need a `Profile`, `Session` or `CryptoProvider`.
3. Call the card component's read/write methods.
4. Call `Disconnect` and free the components.

```pascal
uses
  System.SysUtils, ERD.Card.PCSC.Api, ERD.Card.PCSC.Reader,
  ERD.Card.EID.Data, ERD.Card.EID.Reader;

procedure ReadBelgianEid(const AReaderName: UnicodeString);
var
  Card: TSmartCardReader;
  Eid: TBelgianEIDReader;
  Data: TBelgianEidData;
begin
  Card := TSmartCardReader.Create(nil);
  try
    Card.ReaderName := AReaderName;
    Card.Connect;
    try
      Eid := TBelgianEIDReader.Create(nil);
      try
        Eid.Transport := Card.Transport;
        Data := Eid.ReadCard([esIdentity, esAddress, esPhoto]);
        // Data.Identity.Surname, Data.Address.PostalCode, Data.Photo (JPEG bytes)...
      finally
        Eid.Free;
      end;
    finally
      Card.Disconnect;
    end;
  finally
    Card.Free;
  end;
end;
```

### `TSmartCardReader` at a glance

| Member | Kind | Purpose |
| --- | --- | --- |
| `ListReaders` | method | Returns `TPcscReaderNames`, the exact names of all installed readers. |
| `ReaderName` | property | Exact reader to use. Nothing is selected automatically. |
| `ShareMode` | property | `psmShared` (default) or `psmExclusive`. |
| `Protocols` | property | Allowed protocol mask; default T=0 or T=1. |
| `Connect` / `Disconnect` | methods | Open/close the card connection. `Disconnect` defaults to leaving the card powered (`pcdLeave`). |
| `Transport` | property | The `ICardTransport` you assign to card components. |
| `ReadAtr` | method | The card's ATR bytes. |
| `BeginTransaction` / `EndTransaction` | methods | Explicit exclusive transaction. Card components already take one per operation by default (`UseTransactions = True`). |
| `Connected`, `Protocol` | properties | Current connection state and negotiated protocol. |
| `StartEventMonitoring` / `StopMonitoring` | methods | Event monitoring for this reader only (see below). |

Set `ReaderName`, `ShareMode`, `Protocols` and `MaxResponseBytes` only while the
reader is disconnected and not monitoring.

## 5. React to readers and cards (events)

Drop a **`TSmartCardMonitor`** on your form (or create it in `FormCreate`), assign
its events and call `Start`. You don't need a timer or polling loop.

| Event | Signature | Fired when |
| --- | --- | --- |
| `OnReaderAdded` | `(Sender: TObject; const AReaderName: UnicodeString)` | A reader is plugged in, or already present at `Start` when `EmitInitialState = True` |
| `OnReaderRemoved` | `(Sender: TObject; const AReaderName: UnicodeString)` | A reader is unplugged |
| `OnCardInserted` | `(Sender: TObject; const ASnapshot: TPcscReaderSnapshot)` | A card is presented. `ASnapshot.ReaderName` and `ASnapshot.Atr` identify it. |
| `OnCardRemoved` | `(Sender: TObject; const ASnapshot: TPcscReaderSnapshot)` | The card is removed; the snapshot is the last known state |
| `OnStateChanged` | `(Sender: TObject; const ASnapshot: TPcscReaderSnapshot)` | Any observed state change; `ASnapshot.State` holds `PcscState*` flags |
| `OnError` | `(Sender: TObject; const AStatusCode: Cardinal)` | The monitor stopped because of a PC/SC error |

Facts worth knowing:

- Events are delivered on the **main thread**, so you can update controls directly.
- `EmitInitialState` (default `True`) reports existing readers and cards right after
  `Start`, so you can fill your reader list from `OnReaderAdded` alone.
- `Stop` (also called by the destructor) cancels and joins the background worker.
  After `OnError` the monitor is stopped; call `Start` again if you want to resume.
- Events never connect to or read the card. You start that work yourself, usually
  in `OnCardInserted`.
- Console and service applications must call `CheckSynchronize` regularly so that
  queued events are delivered.

If you only care about one reader, `TSmartCardReader` offers the same events
(`OnReaderAdded`, `OnReaderRemoved`, `OnCardInserted`, `OnCardRemoved`,
`OnCardStateChange`, `OnMonitorError`) through `StartEventMonitoring`. Card events
are then limited to its `ReaderName`.

For USB-HID devices, `THidDeviceMonitor` raises `OnDeviceAdded`/`OnDeviceRemoved`
with the device path, and `TUsbHidInputMonitor` raises `OnInputReport` for each
input report of a selected device. See [READER_EVENTS.md](READER_EVENTS.md).

## 6. Keep card I/O off the UI thread

Card operations block, sometimes for seconds. Two rules keep this safe:

- **A hardware component belongs to one thread.** Create, use and free
  `TSmartCardReader` and the card components on the same thread. Components dropped
  on a form belong to the main thread. For background work, create them inside the
  worker.
- **Monitors stay on the main thread.** Their events are already marshalled there.

A simple pattern is to start an anonymous thread from `OnCardInserted`, do all card
work in it, and post the result back with `TThread.Queue`. The bundled VCL demos use
a more complete worker (`examples/vcl/shared/ERD.Card.Demo.Job.pas`) that also
copies and wipes credentials and refuses concurrent jobs.

## 7. Complete example: show who is on a Belgian eID card

This form lists readers as they appear and reads the identity of any eID card that
is inserted.

1. Create a VCL application and add `src/core`, `src/pcsc` and `src/eid` to the
   search path.
2. Put a `TListBox` (`ReaderList`) and a `TMemo` (`Log`) on the form.
3. Drop a `TSmartCardMonitor` (`CardMonitor`) on the form, or create it in code as
   shown below.
4. Use the following unit.

```pascal
unit MainForm;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  ERD.Card.Bytes, ERD.Card.PCSC.Api, ERD.Card.PCSC.Monitor, ERD.Card.PCSC.Reader,
  ERD.Card.EID.Data, ERD.Card.EID.Reader;

type
  TFormMain = class(TForm)
    ReaderList: TListBox;
    Log: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FMonitor: TSmartCardMonitor;
    FBusy: Boolean;
    procedure ReaderAdded(Sender: TObject; const AReaderName: UnicodeString);
    procedure ReaderRemoved(Sender: TObject; const AReaderName: UnicodeString);
    procedure CardInserted(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
    procedure CardRemoved(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
    procedure MonitorError(Sender: TObject; const AStatusCode: Cardinal);
    procedure ReadCardInBackground(const AReaderName: UnicodeString);
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FMonitor := TSmartCardMonitor.Create(Self);   // freed (and stopped) with the form
  FMonitor.OnReaderAdded := ReaderAdded;
  FMonitor.OnReaderRemoved := ReaderRemoved;
  FMonitor.OnCardInserted := CardInserted;
  FMonitor.OnCardRemoved := CardRemoved;
  FMonitor.OnError := MonitorError;
  FMonitor.Start;
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FBusy;                        // let a running read finish first
end;

procedure TFormMain.ReaderAdded(Sender: TObject; const AReaderName: UnicodeString);
begin
  ReaderList.Items.Add(AReaderName);
end;

procedure TFormMain.ReaderRemoved(Sender: TObject; const AReaderName: UnicodeString);
var
  Index: Integer;
begin
  Index := ReaderList.Items.IndexOf(AReaderName);
  if Index >= 0 then
    ReaderList.Items.Delete(Index);
end;

procedure TFormMain.CardInserted(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
begin
  Log.Lines.Add('Card in ' + ASnapshot.ReaderName + ', ATR ' + BytesToHex(ASnapshot.Atr));
  ReadCardInBackground(ASnapshot.ReaderName);
end;

procedure TFormMain.CardRemoved(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
begin
  Log.Lines.Add('Card removed from ' + ASnapshot.ReaderName);
end;

procedure TFormMain.MonitorError(Sender: TObject; const AStatusCode: Cardinal);
begin
  Log.Lines.Add(Format('Monitor stopped, PC/SC status %.8x', [AStatusCode]));
end;

procedure TFormMain.ReadCardInBackground(const AReaderName: UnicodeString);
var
  ReaderName: UnicodeString;
begin
  if FBusy then
    Exit;
  FBusy := True;
  ReaderName := AReaderName;
  TThread.CreateAnonymousThread(
    procedure
    var
      Card: TSmartCardReader;
      Eid: TBelgianEIDReader;
      Data: TBelgianEidData;
      Msg: string;
    begin
      try
        Card := TSmartCardReader.Create(nil);   // created on the worker thread
        try
          Card.ReaderName := ReaderName;
          Card.Connect;
          try
            Eid := TBelgianEIDReader.Create(nil);
            try
              Eid.Transport := Card.Transport;
              Data := Eid.ReadCard([esIdentity]);
              Msg := Data.Identity.GivenNames + ' ' + Data.Identity.Surname;
            finally
              Eid.Free;
            end;
          finally
            Card.Disconnect;
          end;
        finally
          Card.Free;
        end;
      except
        on E: Exception do
          Msg := E.ClassName + ': ' + E.Message;  // messages never contain card data
      end;
      TThread.Queue(nil,
        procedure
        begin
          Log.Lines.Add(Msg);
          FBusy := False;
        end);
    end).Start;
end;

end.
```

Not every card in a PC/SC reader is a Belgian eID. With any other card, the read
fails with a status exception such as `EBelgianEidStatusError`, and the example
logs it. In a real application you decide which card family to try based on your
own configuration or the ATR. The library never guesses this for you.

## 8. Recipes

Each recipe assumes `Card` is a connected `TSmartCardReader` on the current thread.
Declarations are omitted for brevity. The linked guides list every option.

### UID and MIFARE Classic

```pascal
uses ERD.Card.Contactless;

Reader := TContactlessCardReader.Create(nil);
Reader.Transport := Card.Transport;
Reader.Profile := TPcscStorageProfile.Create;      // PC/SC Part 3 storage commands
Uid := Reader.ReadUid;
Block := Reader.ReadClassicBlock(mcm1K, 4, mckA, KeyA);   // KeyA: 6 bytes you supply
Reader.WriteClassicDataBlock(mcm1K, 4, mckA, KeyA, SixteenBytes);
```

There are no default keys. Writes to block 0 and to sector trailers are refused.
See [CONTACTLESS.md](CONTACTLESS.md).

### NDEF on an NTAG / Ultralight (Type 2)

```pascal
uses ERD.Card.Ndef, ERD.Card.Ndef.Records, ERD.Card.Contactless,
  ERD.Card.Contactless.Type2, ERD.Card.Contactless.Type2.Ndef;

Ndef := TType2NdefCardReader.Create(nil);
Ndef.Transport := Card.Transport;
Ndef.Profile := TPcscStorageProfile.Create;
Snapshot := Ndef.ReadMessage(ttmNtag213);           // Snapshot.Records, Snapshot.MessageBytes
SetLength(NdefMessage, 1);
NdefMessage[0] := TNdefRecords.Uri('https://example.com');
Ndef.WriteMessage(ttmNtag213, NdefMessage);   // replaces the existing NDEF TLV, verified page by page
```

You pass the tag model explicitly. Type 4 (`TType4NdefCardReader`) works on ISO
7816 files and doesn't need a model. Type 5 (`TType5NdefCardReader`) needs an
ISO 15693 session. See [NDEF.md](NDEF.md), [TYPE4_NDEF.md](TYPE4_NDEF.md) and
[ISO15693_TYPE5.md](ISO15693_TYPE5.md).

### MIFARE DESFire (EV2 AES)

```pascal
uses ERD.Card.Crypto.Windows, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.DESFire.EV2;

Desfire := TDesfireCardReader.Create(nil);
Desfire.Transport := Card.Transport;
Desfire.CryptoProvider := TCardWindowsAesProvider.Create;
Desfire.Security := dfsEv2Aes;                      // or dfsPublic / dfsEv1Aes
Desfire.KeyNumber := 1;
Desfire.AuthenticationKey := AesKey;                // 16 bytes, copied
Desfire.MinimumCommunication := dfcFull;
Bytes := Desfire.ReadData(Aid, FileNumber, 0, Count);
```

Applications, file management and transactions use `OpenSession` and
`OpenManagementSession`. See [DESFIRE.md](DESFIRE.md).

### EMV application data

```pascal
uses ERD.Card.EMV.Data, ERD.Card.EMV.Reader;

Emv := TEMVCardReader.Create(nil);
Emv.Transport := Card.Transport;
Directory := Emv.DiscoverApplications(edContactlessPpse);   // or edContactPse
// Pick an AID from Directory.Applications yourself.
Pdol := Emv.ReadProcessingOptionsDol(Aid);                  // which terminal values the card wants
Data := Emv.ReadApplication(Aid, TerminalValues);           // Data.Pan, Data.ExpiryMonth, ...
```

This is a reader, not a payment terminal. See [EMV_READER.md](EMV_READER.md).

### Passport / ICAO ID card

```pascal
uses ERD.Card.Crypto.EAC.OpenSSL, ERD.Card.EID.Access, ERD.Card.EID.DocumentReader;

Icao := TICAODocumentReader.Create(nil);
Icao.Transport := Card.Transport;
Icao.CryptoProvider := TCardEacOpenSslProvider.Create;      // loads libcrypto-3.dll
Icao.AccessPassword := TIcaoAccessCodec.MrzInformation(FullMrz);  // or a CAN with ipkCan
Doc := Icao.ReadDocument([idsIdentity, idsFace]);
// Doc.Identity, Doc.Biometrics.Images[0].Data (JPEG or JPEG 2000)
```

The default is PACE (`iasPaceGmAes128`, brainpoolP256r1, MRZ password). Set
`Security := iasBac` for BAC-only documents. See [EUROPEAN_EID.md](EUROPEAN_EID.md).

### SLE/I²C memory card (ACS reader)

```pascal
uses ERD.Card.Memory;

Memory := TMemoryCardReaderWriter.Create(nil);
Memory.Transport := Card.Transport;
Memory.Model := mcmSle4442;
Memory.Dialect := amdAcr38Ccid;                     // must match your reader
Snapshot := Memory.ReadSnapshot;
Memory.WriteMemory(Address, NewBytes, Pin);         // verified; PIN only when needed
```

See [MEMORY_CARDS.md](MEMORY_CARDS.md) and [SLE4404.md](SLE4404.md).

### SIM / USIM

```pascal
uses ERD.Card.SIM.Data, ERD.Card.SIM.Reader;

Sim := TSimCardReaderWriter.Create(nil);
Sim.Transport := Card.Transport;
Sim.Profile := scpGsmSim;                           // or scpUiccUsim + ApplicationAid
Iccid := Sim.ReadIccid;
```

See [SIM.md](SIM.md).

### Magnetic stripe (MSR206-7HL on a COM port)

```pascal
uses ERD.Card.MagStripe, ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR2067HL,
  ERD.Card.MagStripe.Tracks;

Msr := TMagStripeReaderWriter.Create(nil);
Msr.Device := TMsr2067HLMagStripeAdapter.Create(
  CreateWindowsMagStripeSerialPort('COM3', mssf7O1));
Msr.TimeoutMs := 10000;
Tracks := Msr.ReadTracks([mstTrack1, mstTrack2]);   // waits for a swipe
```

MSR206/MSR605 and MagTek use other adapters. See [MAGSTRIPE.md](MAGSTRIPE.md).

### Keyboard-wedge RFID reader

Readers that "type" the card number are handled by `TRfidKeyboardReader`. Feed it
the characters your form receives, and handle `OnIdentifier`:

```pascal
uses Winapi.Windows, ERD.Card.RFID.Input;

// FormCreate
FRfid := TRfidKeyboardReader.Create(Self);
FRfid.Encoding := rieDecimal;                       // match the reader's output
FRfid.Terminator := ritCr;
FRfid.OnIdentifier := RfidIdentifier;
FRfid.Start;

// OnKeyPress of a focused control (KeyPreview also works)
procedure TFormMain.ScanEditKeyPress(Sender: TObject; var Key: Char);
begin
  FRfid.FeedCharacter(Key, GetTickCount64);
  Key := #0;
end;

procedure TFormMain.RfidIdentifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  Log.Lines.Add('Scanned: ' + AIdentifier.Text);
end;
```

`FeedCharacter` can raise `ERfidInputTimeout` if characters arrive too slowly.
Handle it in a real application. For HID readers that deliver reports, assign
`CreateWindowsHidReportDevice(Path)` to a `TUsbHidInputMonitor` and pass each report
from `OnInputReport` to `TRfidHidReportReader.FeedReport`. See
[RFID_HID.md](RFID_HID.md) and [USB_HID.md](USB_HID.md).

## 9. Errors and uncertain writes

The library raises exceptions; it never retries on its own. Each family has its own
base class (`EBelgianEidError`, `EEmvDataError`, `EContactlessError`,
`EDesfireError`, `EMemoryCardError`, `ESimCardError`, `EMagStripeError`, `EHidError`
and so on). Card status failures have a `...StatusError` class with a `StatusWord`
(SW1/SW2) property. PC/SC failures raise `EPcscError` with `StatusCode`. Exception
messages never contain card data, keys or APDUs, so they are safe to log.

Writes deserve special attention. If a write was sent but its result can't be
proven, you get a **write-uncertain** exception instead of a silent success:

| Exception | Raised by |
| --- | --- |
| `EContactlessWriteUncertain` | Contactless, NDEF and UID components |
| `EMemoryCardWriteUncertain` (`Verified`) | Memory, counter and SLE4404 components |
| `ESimCardWriteUncertain` (`VerifiedReadBack`) | `TSimCardReaderWriter` |
| `EMagStripeWriteUncertain` | `TMagStripeReaderWriter` |
| `ETwn4WriteUncertain` (`VerifiedReadBack`) | `TTwn4CardReaderWriter` |
| `EHidSendUncertain` | `TUsbHidReaderWriter` |

Don't blindly repeat the operation. Read the card again and decide what to do,
especially for PIN attempts and one-time-programmable cards.

## 10. Checklist

- [ ] The search path contains the `src` folders (or package output) you need.
- [ ] Reader names come from `ListReaders` or `OnReaderAdded`. Don't hard-code them.
- [ ] Interface properties (`Transport`, `Profile`, `Session`, `Device`, `Channel`,
      `CryptoProvider`) are assigned **at runtime**. The IDE can't store them in the DFM.
- [ ] Card models, dialects, keys and AIDs are chosen explicitly. Nothing is detected.
- [ ] Card work runs in a worker thread that creates and frees its own components.
- [ ] Monitors are started on the main thread; console/service hosts call
      `CheckSynchronize`.
- [ ] Write-uncertain exceptions are handled without automatic retries.
- [ ] For ICAO reading, `libcrypto-3.dll` matches your application's bitness.

## 11. Next steps

- Run the VCL demos in `examples/vcl/CardDemos.groupproj`. Each has one form per
  card family and shows the complete flow, including safe handling of credentials.
  See [VCL_DEMOS.md](VCL_DEMOS.md).
- Try the console examples in `examples/`. Most have an offline `--help` mode.
- Read the guide for your card family:
  [Belgian eID](BELGIAN_EID.md) · [ICAO / European eID](EUROPEAN_EID.md) ·
  [EMV](EMV_READER.md) · [Contactless](CONTACTLESS.md) · [NDEF](NDEF.md) ·
  [DESFire](DESFIRE.md) · [ISO 15693](ISO15693_TYPE5.md) ·
  [Programmable UIDs](PROGRAMMABLE_UID.md) · [MOBIB / Calypso](MOBIB_CALYPSO.md) ·
  [Memory cards](MEMORY_CARDS.md) · [SIM](SIM.md) · [Magstripe](MAGSTRIPE.md) ·
  [RFID input](RFID_HID.md) · [USB-HID](USB_HID.md) · [TWN4](TWN4.md) ·
  [PC/SC transport](PCSC_TRANSPORT.md) · [Events](READER_EVENTS.md)
