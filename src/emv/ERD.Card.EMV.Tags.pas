unit ERD.Card.EMV.Tags;

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
  /// <summary>Diagnostic EMV value representation, not a decoder or validation policy.</summary>
  TEmvTagEncoding = (
    /// <summary>Opaque binary/bit-field data.</summary>
    eteBinary,
    /// <summary>Packed numeric digits defined by the element; padding rules depend on the tag.</summary>
    eteNumeric,
    /// <summary>Alphanumeric or special-character text; actual character policy depends on the element.</summary>
    eteText,
    /// <summary>Constructed BER-TLV container.</summary>
    eteConstructed,
    /// <summary>Tag/length-only data-object list, not a BER-TLV value stream.</summary>
    eteDol,
    /// <summary>EMV packed Track 2 equivalent; distinct from physical magnetic-track framing.</summary>
    eteTrack2
  );
  /// <summary>Curated source-attributed EMV Book 3 diagnostic tag description.</summary>
  /// <remarks>Lengths are metadata, not validation of context or issuer semantics. Minus one denotes
  /// an unspecified variable maximum; a known name does not imply component or payment support.</remarks>
  TEmvTagDescription = record
    /// <summary>Encoded tag bytes stored as an unsigned big-endian integer, for example 9F26.</summary>
    Tag: Cardinal;
    /// <summary>Standard English data-element or template name.</summary>
    Name: string;
    /// <summary>Diagnostic value representation.</summary>
    Encoding: TEmvTagEncoding;
    /// <summary>Minimum specified length, or zero for variable/context-dependent data.</summary>
    MinLength: Integer;
    /// <summary>Maximum specified length, or minus one when unspecified/context-dependent.</summary>
    MaxLength: Integer;
    /// <summary>True when contents may contain personal, account, issuer or transaction-sensitive data.</summary>
    Sensitive: Boolean;
    /// <summary>Document edition and section used for the description.</summary>
    Source: string;
  end;
  /// <summary>Pure curated EMV tag lookup; no I/O, issuer guessing or payment processing.</summary>
  TEmvTagCatalog = class
  public
    /// <summary>Looks up a curated EMV Book 3 tag using its exact encoded identifier.</summary>
    /// <param name="ATag">Encoded tag integer; unknown/private identifiers are not assigned invented names.</param>
    /// <param name="ADescription">Description on success; a cleared record on an unknown tag.</param>
    /// <returns>True only for a tag explicitly represented by this catalog.</returns>
    /// <remarks>Does not decode values, validate BER tag syntax, enforce lengths or change reader behavior.</remarks>
    class function TryDescribe(const ATag: Cardinal; out ADescription: TEmvTagDescription): Boolean; static;
  end;

implementation

class function TEmvTagCatalog.TryDescribe(const ATag:Cardinal;
  out ADescription:TEmvTagDescription):Boolean;
  procedure Describe(const Name:string; const Encoding:TEmvTagEncoding;
    const MinSize,MaxSize:Integer; const Sensitive:Boolean=False);
  begin
    ADescription.Tag:=ATag; ADescription.Name:=Name; ADescription.Encoding:=Encoding;
    ADescription.MinLength:=MinSize; ADescription.MaxLength:=MaxSize;
    ADescription.Sensitive:=Sensitive; ADescription.Source:='EMV 4.4 Book 3, October 2022, Annex A';
  end;
begin
  ADescription:=Default(TEmvTagDescription); Result:=True;
  case ATag of
    $4F:Describe('Application Identifier (AID) - card',eteBinary,5,16);
    $50:Describe('Application Label',eteText,1,16);
    $57:Describe('Track 2 Equivalent Data',eteTrack2,0,19,True);
    $5A:Describe('Application Primary Account Number (PAN)',eteNumeric,0,10,True);
    $5F20:Describe('Cardholder Name',eteText,2,26,True);
    $5F24:Describe('Application Expiration Date',eteNumeric,3,3,True);
    $5F25:Describe('Application Effective Date',eteNumeric,3,3);
    $5F28:Describe('Issuer Country Code',eteNumeric,2,2);
    $5F2A:Describe('Transaction Currency Code',eteNumeric,2,2);
    $5F2D:Describe('Language Preference',eteText,2,8);
    $5F34:Describe('Application PAN Sequence Number',eteNumeric,1,1,True);
    $61:Describe('Application Template',eteConstructed,0,-1);
    $6F:Describe('File Control Information (FCI) Template',eteConstructed,0,-1);
    $70:Describe('READ RECORD Response Message Template',eteConstructed,0,-1);
    $77:Describe('Response Message Template Format 2',eteConstructed,0,-1);
    $80:Describe('Response Message Template Format 1',eteBinary,0,-1);
    $82:Describe('Application Interchange Profile',eteBinary,2,2);
    $83:Describe('Command Template',eteBinary,0,-1);
    $84:Describe('Dedicated File (DF) Name',eteBinary,5,16);
    $87:Describe('Application Priority Indicator',eteBinary,1,1);
    $8C:Describe('Card Risk Management Data Object List 1 (CDOL1)',eteDol,0,252);
    $8D:Describe('Card Risk Management Data Object List 2 (CDOL2)',eteDol,0,252);
    $8E:Describe('Cardholder Verification Method (CVM) List',eteBinary,0,252,True);
    $94:Describe('Application File Locator',eteBinary,0,252);
    $95:Describe('Terminal Verification Results',eteBinary,5,5,True);
    $9A:Describe('Transaction Date',eteNumeric,3,3,True);
    $9C:Describe('Transaction Type',eteNumeric,1,1,True);
    $9F02:Describe('Amount, Authorised (Numeric)',eteNumeric,6,6,True);
    $9F03:Describe('Amount, Other (Numeric)',eteNumeric,6,6,True);
    $9F07:Describe('Application Usage Control',eteBinary,2,2);
    $9F08:Describe('Application Version Number - card',eteBinary,2,2);
    $9F10:Describe('Issuer Application Data',eteBinary,0,32,True);
    $9F11:Describe('Issuer Code Table Index',eteNumeric,1,1);
    $9F12:Describe('Application Preferred Name',eteText,1,16);
    $9F13:Describe('Last Online Application Transaction Counter (ATC) Register',eteBinary,2,2,True);
    $9F17:Describe('PIN Try Counter',eteBinary,1,1,True);
    $9F26:Describe('Application Cryptogram',eteBinary,8,8,True);
    $9F27:Describe('Cryptogram Information Data',eteBinary,1,1,True);
    $9F33:Describe('Terminal Capabilities',eteBinary,3,3);
    $9F36:Describe('Application Transaction Counter (ATC)',eteBinary,2,2,True);
    $9F37:Describe('Unpredictable Number',eteBinary,4,4,True);
    $9F38:Describe('Processing Options Data Object List (PDOL)',eteDol,0,-1);
    $9F4D:Describe('Log Entry',eteBinary,2,2,True);
    $9F4F:Describe('Log Format',eteDol,0,-1,True);
    $A5:Describe('File Control Information (FCI) Proprietary Template',eteConstructed,0,-1);
    $BF0C:Describe('File Control Information (FCI) Issuer Discretionary Data',eteConstructed,0,-1,True);
  else Result:=False; end;
end;

end.
