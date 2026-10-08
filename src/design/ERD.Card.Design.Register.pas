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
  ERD.Card.RFID.Input, ERD.Card.RFID.HID, DesignIntf, ERD.Card.Memory, ERD.Card.Memory.Counter, ERD.Card.Memory.Sle4404, ERD.Card.PCSC.Reader, ERD.Card.EID.Reader,
  ERD.Card.EID.DocumentReader, ERD.Card.EMV.Reader, ERD.Card.MagStripe,
  ERD.Card.Contactless, ERD.Card.Contactless.Type2.Ndef,
  ERD.Card.Contactless.Type4.Ndef, ERD.Card.Contactless.Type5.Ndef,
  ERD.Card.Contactless.ISO15693, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.Type2.Password, ERD.Card.Contactless.Raw;

procedure Register;
begin
  RegisterComponents('ERD Cards', [TSmartCardReader, TBelgianEIDReader,
    TICAODocumentReader, TEMVCardReader, TMagStripeReaderWriter, TMemoryCardReaderWriter, TSleCounterCardReaderWriter, TSle4404CardReaderWriter]);
  RegisterComponents('ERD Input', [TRfidKeyboardReader, TRfidHidReportReader]);
  RegisterComponents('ERD Contactless', [TContactlessCardReader,
    TType2NdefCardReader, TType4NdefCardReader, TIso15693CardReader,
    TType5NdefCardReader, TDesfireCardReader, TType2PasswordCardReader,
    TRawUidProgrammer]);
end;

end.
