unit ERD.Card.Design.Register;

interface

/// <summary>Registers inactive card components on the ERD Cards component palette.</summary>
/// <remarks>Requires RAD Studio designide; no hardware or cryptographic library is opened.</remarks>
procedure Register;

implementation

uses
{$IFDEF FPC}
  Classes,
{$ELSE}
  System.Classes,
{$ENDIF}
  ERD.Card.GlobalPlatform, ERD.Card.EMV.Calculator, ERD.Card.PCSC.Monitor, ERD.Card.HID.Monitor, ERD.Card.SIM.Reader,
  ERD.Card.Reader.TWN4, ERD.Card.RFID.Input, ERD.Card.RFID.HID, ERD.Card.HID,
  DesignIntf, ERD.Card.Memory, ERD.Card.Memory.Counter, ERD.Card.Memory.Sle4404,
  ERD.Card.PCSC.Reader, ERD.Card.EID.Reader,
  ERD.Card.EID.DocumentReader, ERD.Card.EMV.Reader, ERD.Card.MagStripe,
  ERD.Card.Contactless.Topaz, ERD.Card.Contactless.Type1.Ndef,
  ERD.Card.Contactless.Felica, ERD.Card.Contactless.Type3.Ndef,
  ERD.Card.Contactless.Calypso, ERD.Card.Contactless,
  ERD.Card.Contactless.Type2.Ndef,
  ERD.Card.Contactless.Type4.Ndef, ERD.Card.Contactless.Type5.Ndef,
  ERD.Card.Contactless.ISO15693, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.UltralightC, ERD.Card.Contactless.Type2.Password,
  ERD.Card.Contactless.Raw, ERD.Card.Workflow, ERD.Card.Contactless.Workflow,
  ERD.Card.Contactless.Workflow.UID, ERD.Card.Contactless.Workflow.Credentials,
  ERD.Card.Contactless.Workflow.Ndef, ERD.Card.MagStripe.Workflow;

procedure Register;
begin
  RegisterComponents('ERD Cards', [TGlobalPlatformCardManager, TSmartCardMonitor, TSmartCardReader,
    TBelgianEIDReader, TICAODocumentReader, TSimCardReaderWriter,
    TEmvCalculator, TEMVCardReader, TMagStripeReaderWriter, TMemoryCardReaderWriter,
    TSleCounterCardReaderWriter, TSle4404CardReaderWriter]);
  RegisterComponents('ERD Workflows', [TCardMemoryCopyWorkflow, TMifareClassicCopyWorkflow,
    TType2MemoryWorkflow, TUidProgrammingWorkflow, TClassicCredentialWorkflow,
    TNdefTransferWorkflow, TMagStripeCopyWorkflow]);
  RegisterComponents('ERD Input', [THidDeviceMonitor, TUsbHidInputMonitor,
    TRfidKeyboardReader, TRfidHidReportReader, TUsbHidReaderWriter,
    TTwn4CardReaderWriter]);
  RegisterComponents('ERD Contactless', [TTopazCardReader, TType1NdefCardReader,
    TFelicaCardReader, TType3NdefCardReader, TUltralightCCardReaderWriter,
    TCalypsoCardReader, TContactlessCardReader, TType2NdefCardReader,
    TType4NdefCardReader, TIso15693CardReader, TIso15693SecurityManager,
    TType5NdefCardReader, TDesfireCardReader, TType2PasswordCardReader,
    TRawUidProgrammer]);
end;

end.
