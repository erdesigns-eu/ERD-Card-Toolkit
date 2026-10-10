unit ERD.Card.EMV.Aids;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

type
  /// <summary>Historical known application identifier; no card-selection command is issued.</summary>
  TEmvAidDescription = record
    /// <summary>Exact encoded AID or RID prefix, as uppercase hexadecimal.</summary>
    AidHex: string;

    /// <summary>Historical scheme/application label.</summary>
    Name: string;

    /// <summary>True for a five-byte RID prefix; not an exact instance identifier.</summary>
    PrefixOnly: Boolean;
  end;

  /// <summary>Owned original known-AID suggestions; selection remains an explicit application choice.</summary>
  TEmvAidDescriptions = array of TEmvAidDescription;

  /// <summary>Source-attributed known application suggestions from CardStudio/CardPeek.</summary>
  TEmvAidCatalog = class
  public
    /// <summary>Returns the 61 valid historical suggestions, preserving RID prefixes as prefixes.</summary>
    /// <returns>Independent ordered metadata array; no transport or card side effects.</returns>
    class function GetEntries: TEmvAidDescriptions; static;
  end;

implementation

const
  Entries: array [0 .. 60] of TEmvAidDescription = (
    (AidHex: 'A0000000031010'; Name: 'Visa credit or debit'; PrefixOnly: False),
    (AidHex: 'A000000003101001'; Name: 'VISA Credit'; PrefixOnly: False),
    (AidHex: 'A000000003101002'; Name: 'VISA Debit'; PrefixOnly: False),
    (AidHex: 'A0000000032010'; Name: 'Visa electron'; PrefixOnly: False),
    (AidHex: 'A0000000032020'; Name: 'V pay'; PrefixOnly: False),
    (AidHex: 'A0000000033010'; Name: 'VISA Interlink'; PrefixOnly: False),
    (AidHex: 'A0000000034010'; Name: 'VISA Specific'; PrefixOnly: False),
    (AidHex: 'A0000000035010'; Name: 'VISA Specific'; PrefixOnly: False),
    (AidHex: 'A0000000036010'; Name: 'Domestic Visa Cash Stored Value'; PrefixOnly: False),
    (AidHex: 'A0000000036020'; Name: 'International Visa Cash Stored Value'; PrefixOnly: False),
    (AidHex: 'A0000000038002'; Name: 'Barclays/HBOS'; PrefixOnly: False),
    (AidHex: 'A0000000038010'; Name: 'Visa Plus'; PrefixOnly: False),
    (AidHex: 'A0000000039010'; Name: 'VISA Loyalty'; PrefixOnly: False),
    (AidHex: 'A000000003999910'; Name: 'VISA ATM'; PrefixOnly: False),
    (AidHex: 'A000000004'; Name: 'US Debit (MC)'; PrefixOnly: True),
    (AidHex: 'A0000000041010'; Name: 'Mastercard credit or debit'; PrefixOnly: False),
    (AidHex: 'A00000000410101213'; Name: 'MasterCard'; PrefixOnly: False),
    (AidHex: 'A00000000410101215'; Name: 'MasterCard'; PrefixOnly: False),
    (AidHex: 'A0000000042010'; Name: 'MasterCard Specific'; PrefixOnly: False),
    (AidHex: 'A0000000043010'; Name: 'MasterCard Specific'; PrefixOnly: False),
    (AidHex: 'A0000000043060'; Name: 'Mastercard Maestro'; PrefixOnly: False),
    (AidHex: 'A0000000044010'; Name: 'MasterCard Specific'; PrefixOnly: False),
    (AidHex: 'A0000000045010'; Name: 'MasterCard Specific'; PrefixOnly: False),
    (AidHex: 'A0000000046000'; Name: 'Mastercard Cirrus'; PrefixOnly: False),
    (AidHex: 'A0000000048002'; Name: 'NatWest or SecureCode Auth'; PrefixOnly: False),
    (AidHex: 'A0000000049999'; Name: 'Mastercard'; PrefixOnly: False),
    (AidHex: 'A0000000050001'; Name: 'UK Domestic Maestro - Switch (debit card) Maestro'; PrefixOnly: False),
    (AidHex: 'A0000000050002'; Name: 'UK Domestic Maestro - Switch (debit card) Solo'; PrefixOnly: False),
    (AidHex: 'A0000000250000'; Name: 'American Express (Credit/Debit)'; PrefixOnly: False),
    (AidHex: 'A00000002501'; Name: 'American Express'; PrefixOnly: False),
    (AidHex: 'A000000025010402'; Name: 'American Express'; PrefixOnly: False),
    (AidHex: 'A000000025010701'; Name: 'American Express ExpressPay'; PrefixOnly: False),
    (AidHex: 'A000000025010801'; Name: 'American Express'; PrefixOnly: False),
    (AidHex: 'A0000000291010'; Name: 'ATM card LINK (UK) ATM network'; PrefixOnly: False),
    (AidHex: 'A0000000421010'; Name: 'French CB'; PrefixOnly: False),
    (AidHex: 'A0000000422010'; Name: 'French CB'; PrefixOnly: False),
    (AidHex: 'A00000006510'; Name: 'JCB'; PrefixOnly: False),
    (AidHex: 'A0000000651010'; Name: 'JCB'; PrefixOnly: False),
    (AidHex: 'A00000006900'; Name: 'FR Moneo'; PrefixOnly: False),
    (AidHex: 'A000000098'; Name: 'US Debit (Visa)'; PrefixOnly: True),
    (AidHex: 'A0000000980848'; Name: 'Schwab Bank Debit Card'; PrefixOnly: False),
    (AidHex: 'A0000001211010'; Name: 'Dankort Danish domestic debit card'; PrefixOnly: False),
    (AidHex: 'A0000001410001'; Name: 'Pagobancomat Italian domestic debit card'; PrefixOnly: False),
    (AidHex: 'A000000152'; Name: 'US Debit (Discover)'; PrefixOnly: True),
    (AidHex: 'A0000001523010'; Name: 'Diners club/Discover'; PrefixOnly: False),
    (AidHex: 'A0000001544442'; Name: 'Banricompras Debito (Brazil)'; PrefixOnly: False),
    (AidHex: 'A0000001850002'; Name: 'UK Post Office Card Account card'; PrefixOnly: False),
    (AidHex: 'A0000002281010'; Name: 'SAMA Saudi Arabia domestic credit/debit card'; PrefixOnly: False),
    (AidHex: 'A0000002282010'; Name: 'SAMA Saudi Arabia domestic credit/debit card'; PrefixOnly: False),
    (AidHex: 'A0000002771010'; Name: 'Interac'; PrefixOnly: False),
    (AidHex: 'A0000003156020'; Name: 'Chipknip'; PrefixOnly: False),
    (AidHex: 'A0000003241010'; Name: 'Discover'; PrefixOnly: False),
    (AidHex: 'A0000003591010028001'; Name: 'ZKA Girocard (Germany)'; PrefixOnly: False),
    (AidHex: 'A0000003710001'; Name: 'InterSwitch Verve Card (Nigeria)'; PrefixOnly: False),
    (AidHex: 'A0000004540010'; Name: 'Etranzact Genesis Card (Nigeria)'; PrefixOnly: False),
    (AidHex: 'A0000004540011'; Name: 'Etranzact Genesis Card 2 (Nigeria)'; PrefixOnly: False),
    (AidHex: 'A0000004766C'; Name: 'Google'; PrefixOnly: False),
    (AidHex: 'A0000005241010'; Name: 'RuPay (India)'; PrefixOnly: False),
    (AidHex: 'A000000620'; Name: 'US Debit (DNA)'; PrefixOnly: True),
    (AidHex: 'D27600002545500100'; Name: 'ZKA Girocard (Germany)'; PrefixOnly: False),
    (AidHex: 'D5780000021010'; Name: 'BankAxept Norwegian domestic debit card'; PrefixOnly: False)
  );

class function TEmvAidCatalog.GetEntries: TEmvAidDescriptions;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(Entries));
  for I := 0 to High(Entries) do
    Result[I] := Entries[I];
end;

end.
