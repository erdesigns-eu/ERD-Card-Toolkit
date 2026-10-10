unit ERD.Card.APDU.Catalog;

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
  /// <summary>Diagnostic status category; caller protocol determines whether a status is acceptable.</summary>
  TApduStatusCategory = (
    /// <summary>Informational response, including success and continuation.</summary>
    ascInfo,
    /// <summary>Warning or recoverable condition, subject to command context.</summary>
    ascWarning,
    /// <summary>Failed command or invalid data.</summary>
    ascError,
    /// <summary>Authentication or security-related historical classification.</summary>
    ascSecurity,
    /// <summary>No authoritative category is available.</summary>
    ascUnknown);

  /// <summary>One source-attributed status interpretation; proprietary meanings can conflict.</summary>
  TApduStatusDescription = record
    /// <summary>Expected status bits; SW1 occupies the high byte.</summary>
    Pattern: Word;

    /// <summary>Significant status bits; only significant bits participate in lookup.</summary>
    Mask: Word;

    /// <summary>Diagnostic category, not an automatic recovery policy.</summary>
    Category: TApduStatusCategory;

    /// <summary>Human-readable status explanation.</summary>
    Description: string;

    /// <summary>Standard reference or explicitly unverified historical provenance.</summary>
    Source: string;
  end;

  /// <summary>Owned status interpretations in precedence order.</summary>
  TApduStatusDescriptions = array of TApduStatusDescription;

  /// <summary>Source-attributed candidate instruction interpretation; CLA and card context still matter.</summary>
  TApduInstructionDescription = record
    /// <summary>Exact instruction byte.</summary>
    Instruction: Byte;

    /// <summary>Historical standard attribution.</summary>
    Standard: string;

    /// <summary>Candidate operation name; no command is executed.</summary>
    Description: string;
  end;

  /// <summary>Owned original instruction dictionary.</summary>
  TApduInstructionDescriptions = array of TApduInstructionDescription;

  /// <summary>Diagnostic APDU dictionaries; interpretations never trigger automatic command retries.</summary>
  TApduCatalog = class
  public
    /// <summary>Returns all 35 original candidate instruction descriptions.</summary>
    /// <returns>Independent dictionary; interpretation remains dependent on CLA/card profile.</returns>
    class function GetInstructions: TApduInstructionDescriptions; static;

    /// <summary>Finds all candidate meanings for an INS byte.</summary>
    /// <param name="AInstruction">Exact INS; proprietary classes can give it a different meaning.</param>
    /// <returns>Independent candidate interpretations, or an empty array.</returns>
    class function FindInstructions(const AInstruction: Byte): TApduInstructionDescriptions; static;

    /// <summary>Returns the 205 valid original status reports.</summary>
    /// <returns>Independent reports; all returned patterns participate in status lookup.</returns>
    class function GetHistoricalStatuses: TApduStatusDescriptions; static;

    /// <summary>Returns standard dynamic interpretations first, followed by all matching historical reports.</summary>
    /// <param name="AStatus">SW1/SW2 with SW1 in the high byte.</param>
    /// <returns>Independent candidate explanations with explicit provenance; empty means unknown.</returns>
    class function FindStatusDescriptions(const AStatus: Word): TApduStatusDescriptions; static;
  end;

implementation

const
  InstructionEntries: array [0 .. 34] of TApduInstructionDescription = (
    (Instruction: $04; Standard: 'ISO 7816-9'; Description: 'Deactivate File'),
    (Instruction: $0E; Standard: 'ISO 7816-4'; Description: 'Erase Binary'),
    (Instruction: $20; Standard: 'ISO 7816-4'; Description: 'Verify'),
    (Instruction: $22; Standard: 'ISO 7816-4'; Description: 'Manage Security Environment'),
    (Instruction: $24; Standard: 'ISO 7816-4'; Description: 'Change Reference Data'),
    (Instruction: $26; Standard: 'ISO 7816-4'; Description: 'Disable Verification Requirement'),
    (Instruction: $28; Standard: 'ISO 7816-4'; Description: 'Enable Verification Requirement'),
    (Instruction: $2A; Standard: 'ISO 7816-8'; Description: 'Perform Security Operation'),
    (Instruction: $2C; Standard: 'ISO 7816-4'; Description: 'Reset Retry Counter'),
    (Instruction: $44; Standard: 'ISO 7816-9'; Description: 'Activate File'),
    (Instruction: $46; Standard: 'ISO 7816-8'; Description: 'Generate Asymmetric Key Pair'),
    (Instruction: $70; Standard: 'ISO 7816-4'; Description: 'Manage Channel'),
    (Instruction: $82; Standard: 'ISO 7816-4'; Description: 'External/Mutual Authenticate'),
    (Instruction: $84; Standard: 'ISO 7816-4'; Description: 'Get Challenge'),
    (Instruction: $86; Standard: 'ISO 7816-4'; Description: 'General Authenticate'),
    (Instruction: $88; Standard: 'ISO 7816-4'; Description: 'Internal Authenticate'),
    (Instruction: $A0; Standard: 'ISO 7816-4'; Description: 'Search Binary'),
    (Instruction: $A2; Standard: 'ISO 7816-4'; Description: 'Search Record'),
    (Instruction: $A4; Standard: 'ISO 7816-4'; Description: 'Select'),
    (Instruction: $B0; Standard: 'ISO 7816-4'; Description: 'Read Binary'),
    (Instruction: $B2; Standard: 'ISO 7816-4'; Description: 'Read Record(s)'),
    (Instruction: $C0; Standard: 'ISO 7816-4'; Description: 'Get Response'),
    (Instruction: $C2; Standard: 'ISO 7816-4'; Description: 'Envelope'),
    (Instruction: $CA; Standard: 'ISO 7816-4'; Description: 'Get Data'),
    (Instruction: $D0; Standard: 'ISO 7816-4'; Description: 'Write Binary'),
    (Instruction: $D2; Standard: 'ISO 7816-4'; Description: 'Write Record'),
    (Instruction: $D6; Standard: 'ISO 7816-4'; Description: 'Update Binary'),
    (Instruction: $DA; Standard: 'ISO 7816-4'; Description: 'Put Data'),
    (Instruction: $DC; Standard: 'ISO 7816-4'; Description: 'Update Record'),
    (Instruction: $E0; Standard: 'ISO 7816-9'; Description: 'Create File'),
    (Instruction: $E2; Standard: 'ISO 7816-4'; Description: 'Append Record'),
    (Instruction: $E4; Standard: 'ISO 7816-9'; Description: 'Delete File'),
    (Instruction: $E6; Standard: 'ISO 7816-9'; Description: 'Terminate DF'),
    (Instruction: $E8; Standard: 'ISO 7816-9'; Description: 'Terminate EF'),
    (Instruction: $FE; Standard: 'ISO 7816-9'; Description: 'Terminate Card Usage')
  );

  StatusEntries: array [0 .. 204] of TApduStatusDescription = (
    (Pattern: $6200; Mask: $FFFF; Category: ascWarning; Description: 'No information given (NV-Ram not changed)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 3; historical, card-context dependent'),
    (Pattern: $6201; Mask: $FFFF; Category: ascWarning; Description: 'NV-Ram not changed 1.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 4; historical, card-context dependent'),
    (Pattern: $6281; Mask: $FFFF; Category: ascWarning; Description: 'Part of returned data may be corrupted'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 5; historical, card-context dependent'),
    (Pattern: $6282; Mask: $FFFF; Category: ascWarning; Description: 'End of file/record reached before reading Le bytes'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 6; historical, card-context dependent'),
    (Pattern: $6283; Mask: $FFFF; Category: ascWarning; Description: 'Selected file invalidated'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 7; historical, card-context dependent'),
    (Pattern: $6284; Mask: $FFFF; Category: ascWarning; Description: 'Selected file is not valid. FCI not formated according to ISO'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 8; historical, card-context dependent'),
    (Pattern: $6285; Mask: $FFFF; Category: ascWarning; Description: 'No input data available from a sensor on the card. No Purse Engine enslaved for R3bc'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 9; historical, card-context dependent'),
    (Pattern: $62A2; Mask: $FFFF; Category: ascWarning; Description: 'Wrong R-MAC'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 10; historical, card-context dependent'),
    (Pattern: $62A4; Mask: $FFFF; Category: ascWarning; Description: 'Card locked (during reset( ))'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 11; historical, card-context dependent'),
    (Pattern: $62C0; Mask: $FFF0; Category: ascWarning; Description: 'Counter with value x (command dependent)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 12; historical, card-context dependent'),
    (Pattern: $62F1; Mask: $FFFF; Category: ascWarning; Description: 'Wrong C-MAC'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 13; historical, card-context dependent'),
    (Pattern: $62F3; Mask: $FFFF; Category: ascWarning; Description: 'Internal reset'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 14; historical, card-context dependent'),
    (Pattern: $62F5; Mask: $FFFF; Category: ascWarning; Description: 'Default agent locked'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 15; historical, card-context dependent'),
    (Pattern: $62F7; Mask: $FFFF; Category: ascWarning; Description: 'Cardholder locked'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 16; historical, card-context dependent'),
    (Pattern: $62F8; Mask: $FFFF; Category: ascWarning; Description: 'Basement is current agent'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 17; historical, card-context dependent'),
    (Pattern: $62F9; Mask: $FFFF; Category: ascWarning; Description: 'CALC Key Set not unblocked'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 18; historical, card-context dependent'),
    (Pattern: $6300; Mask: $FFFF; Category: ascWarning; Description: 'No information given (NV-Ram changed)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 20; historical, card-context dependent'),
    (Pattern: $6381; Mask: $FFFF; Category: ascWarning; Description: 'File filled up by the last write. Loading/updating is not allowed.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 21; historical, card-context dependent'),
    (Pattern: $6382; Mask: $FFFF; Category: ascWarning; Description: 'Card key not supported.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 22; historical, card-context dependent'),
    (Pattern: $6383; Mask: $FFFF; Category: ascWarning; Description: 'Reader key not supported.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 23; historical, card-context dependent'),
    (Pattern: $6384; Mask: $FFFF; Category: ascWarning; Description: 'Plaintext transmission not supported.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 24; historical, card-context dependent'),
    (Pattern: $6385; Mask: $FFFF; Category: ascWarning; Description: 'Secured transmission not supported.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 25; historical, card-context dependent'),
    (Pattern: $6386; Mask: $FFFF; Category: ascWarning; Description: 'Volatile memory is not available.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 26; historical, card-context dependent'),
    (Pattern: $6387; Mask: $FFFF; Category: ascWarning; Description: 'Non-volatile memory is not available.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 27; historical, card-context dependent'),
    (Pattern: $6388; Mask: $FFFF; Category: ascWarning; Description: 'Key number not valid.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 28; historical, card-context dependent'),
    (Pattern: $6389; Mask: $FFFF; Category: ascWarning; Description: 'Key length is not correct.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 29; historical, card-context dependent'),
    (Pattern: $63C0; Mask: $FFFF; Category: ascWarning; Description: 'Verify fail, no try left.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 30; historical, card-context dependent'),
    (Pattern: $63C1; Mask: $FFFF; Category: ascWarning; Description: 'Verify fail, 1 try left.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 31; historical, card-context dependent'),
    (Pattern: $63C2; Mask: $FFFF; Category: ascWarning; Description: 'Verify fail, 2 tries left.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 32; historical, card-context dependent'),
    (Pattern: $63C3; Mask: $FFFF; Category: ascWarning; Description: 'Verify fail, 3 tries left.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 33; historical, card-context dependent'),
    (Pattern: $63C0; Mask: $FFF0; Category: ascWarning; Description: 'The counter has reached the value ‘x’ (0 = x = 15) (command dependent).'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 34; historical, card-context dependent'),
    (Pattern: $63F1; Mask: $FFFF; Category: ascWarning; Description: 'More data expected.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 35; historical, card-context dependent'),
    (Pattern: $63F2; Mask: $FFFF; Category: ascWarning; Description: 'More data expected and proactive command pending.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 36; historical, card-context dependent'),
    (Pattern: $6400; Mask: $FFFF; Category: ascError; Description: 'No information given (NV-Ram not changed)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 38; historical, card-context dependent'),
    (Pattern: $6401; Mask: $FFFF; Category: ascError; Description: 'Command timeout. Immediate response required by the card.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 39; historical, card-context dependent'),
    (Pattern: $65FF; Mask: $FFFF; Category: ascError; Description: 'State of non-volatile memory changed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 40; historical, card-context dependent'),
    (Pattern: $6500; Mask: $FFFF; Category: ascError; Description: 'No information given'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 41; historical, card-context dependent'),
    (Pattern: $6501; Mask: $FFFF; Category: ascError; Description: 'Write error. Memory failure. There have been problems in writing or reading the EEPROM. Other hardware problems may also bring this error.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 42; historical, card-context dependent'),
    (Pattern: $6581; Mask: $FFFF; Category: ascError; Description: 'Memory failure'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 43; historical, card-context dependent'),
    (Pattern: $6600; Mask: $FFFF; Category: ascSecurity; Description: 'Error while receiving (timeout)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 44; historical, card-context dependent'),
    (Pattern: $6601; Mask: $FFFF; Category: ascSecurity; Description: 'Error while receiving (character parity error)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 45; historical, card-context dependent'),
    (Pattern: $6602; Mask: $FFFF; Category: ascSecurity; Description: 'Wrong checksum'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 46; historical, card-context dependent'),
    (Pattern: $6603; Mask: $FFFF; Category: ascSecurity; Description: 'The current DF file without FCI'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 47; historical, card-context dependent'),
    (Pattern: $6604; Mask: $FFFF; Category: ascSecurity; Description: 'No SF or KF under the current DF'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 48; historical, card-context dependent'),
    (Pattern: $6669; Mask: $FFFF; Category: ascSecurity; Description: 'Incorrect Encryption/Decryption Padding'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 49; historical, card-context dependent'),
    (Pattern: $6700; Mask: $FFFF; Category: ascError; Description: 'Wrong length'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 50; historical, card-context dependent'),
    (Pattern: $6800; Mask: $FFFF; Category: ascError; Description: 'No information given (The request function is not supported by the card)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 53; historical, card-context dependent'),
    (Pattern: $6881; Mask: $FFFF; Category: ascError; Description: 'Logical channel not supported'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 54; historical, card-context dependent'),
    (Pattern: $6882; Mask: $FFFF; Category: ascError; Description: 'Secure messaging not supported'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 55; historical, card-context dependent'),
    (Pattern: $6883; Mask: $FFFF; Category: ascError; Description: 'Last command of the chain expected'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 56; historical, card-context dependent'),
    (Pattern: $6884; Mask: $FFFF; Category: ascError; Description: 'Command chaining not supported'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 57; historical, card-context dependent'),
    (Pattern: $69FF; Mask: $FFFF; Category: ascError; Description: 'Command not allowed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 58; historical, card-context dependent'),
    (Pattern: $6900; Mask: $FFFF; Category: ascError; Description: 'No information given (Command not allowed)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 59; historical, card-context dependent'),
    (Pattern: $6901; Mask: $FFFF; Category: ascError; Description: 'Command not accepted (inactive state)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 60; historical, card-context dependent'),
    (Pattern: $6981; Mask: $FFFF; Category: ascError; Description: 'Command incompatible with file structure'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 61; historical, card-context dependent'),
    (Pattern: $6982; Mask: $FFFF; Category: ascError; Description: 'Security condition not satisfied.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 62; historical, card-context dependent'),
    (Pattern: $6983; Mask: $FFFF; Category: ascError; Description: 'Authentication method blocked'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 63; historical, card-context dependent'),
    (Pattern: $6984; Mask: $FFFF; Category: ascError; Description: 'Referenced data reversibly blocked (invalidated)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 64; historical, card-context dependent'),
    (Pattern: $6985; Mask: $FFFF; Category: ascError; Description: 'Conditions of use not satisfied.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 65; historical, card-context dependent'),
    (Pattern: $6986; Mask: $FFFF; Category: ascError; Description: 'Command not allowed (no current EF)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 66; historical, card-context dependent'),
    (Pattern: $6987; Mask: $FFFF; Category: ascError; Description: 'Expected secure messaging (SM) object missing'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 67; historical, card-context dependent'),
    (Pattern: $6988; Mask: $FFFF; Category: ascError; Description: 'Incorrect secure messaging (SM) data object'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 68; historical, card-context dependent'),
    (Pattern: $6996; Mask: $FFFF; Category: ascError; Description: 'Data must be updated again'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 69; historical, card-context dependent'),
    (Pattern: $69E1; Mask: $FFFF; Category: ascError; Description: 'POL1 of the currently Enabled Profile prevents this action.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 70; historical, card-context dependent'),
    (Pattern: $69F0; Mask: $FFFF; Category: ascError; Description: 'Permission Denied'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 71; historical, card-context dependent'),
    (Pattern: $69F1; Mask: $FFFF; Category: ascError; Description: 'Permission Denied – Missing Privilege'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 72; historical, card-context dependent'),
    (Pattern: $698D; Mask: $FFFF; Category: ascError; Description: 'Reserved'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 73; historical, card-context dependent'),
    (Pattern: $6AFF; Mask: $FFFF; Category: ascError; Description: 'Wrong parameter(s) P1-P2'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 74; historical, card-context dependent'),
    (Pattern: $6A00; Mask: $FFFF; Category: ascError; Description: 'No information given (Bytes P1 and/or P2 are incorrect)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 75; historical, card-context dependent'),
    (Pattern: $6A80; Mask: $FFFF; Category: ascError; Description: 'The parameters in the data field are incorrect.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 76; historical, card-context dependent'),
    (Pattern: $6A81; Mask: $FFFF; Category: ascError; Description: 'Function not supported'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 77; historical, card-context dependent'),
    (Pattern: $6A82; Mask: $FFFF; Category: ascError; Description: 'File not found'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 78; historical, card-context dependent'),
    (Pattern: $6A83; Mask: $FFFF; Category: ascError; Description: 'Record not found'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 79; historical, card-context dependent'),
    (Pattern: $6A84; Mask: $FFFF; Category: ascError; Description: 'There is insufficient memory space in record or file'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 80; historical, card-context dependent'),
    (Pattern: $6A85; Mask: $FFFF; Category: ascError; Description: 'Lc inconsistent with TLV structure'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 81; historical, card-context dependent'),
    (Pattern: $6A86; Mask: $FFFF; Category: ascError; Description: 'Incorrect P1 or P2 parameter.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 82; historical, card-context dependent'),
    (Pattern: $6A87; Mask: $FFFF; Category: ascError; Description: 'Lc inconsistent with P1-P2'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 83; historical, card-context dependent'),
    (Pattern: $6A88; Mask: $FFFF; Category: ascError; Description: 'Referenced data not found'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 84; historical, card-context dependent'),
    (Pattern: $6A89; Mask: $FFFF; Category: ascError; Description: 'File already exists'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 85; historical, card-context dependent'),
    (Pattern: $6A8A; Mask: $FFFF; Category: ascError; Description: 'DF name already exists.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 86; historical, card-context dependent'),
    (Pattern: $6AF0; Mask: $FFFF; Category: ascError; Description: 'Wrong parameter value'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 87; historical, card-context dependent'),
    (Pattern: $6B00; Mask: $FFFF; Category: ascError; Description: 'Wrong parameter(s) P1-P2'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 88; historical, card-context dependent'),
    (Pattern: $6CFF; Mask: $FFFF; Category: ascError; Description: 'Wrong length Le'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 89; historical, card-context dependent'),
    (Pattern: $6C00; Mask: $FFFF; Category: ascError; Description: 'Incorrect P3 length.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 90; historical, card-context dependent'),
    (Pattern: $6D00; Mask: $FFFF; Category: ascError; Description: 'Instruction code not supported or invalid'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 92; historical, card-context dependent'),
    (Pattern: $6E00; Mask: $FFFF; Category: ascError; Description: 'Class not supported'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 94; historical, card-context dependent'),
    (Pattern: $6F00; Mask: $FFFF; Category: ascError; Description: 'Command aborted – more exact diagnosis not possible (e.g., operating system error).'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 96; historical, card-context dependent'),
    (Pattern: $6FFF; Mask: $FFFF; Category: ascError; Description: 'Card dead (overuse, …)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 97; historical, card-context dependent'),
    (Pattern: $9000; Mask: $FFFF; Category: ascInfo; Description: 'Command successfully executed (OK).'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 99; historical, card-context dependent'),
    (Pattern: $9004; Mask: $FFFF; Category: ascWarning; Description: 'PIN not succesfully verified, 3 or more PIN tries left'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 100; historical, card-context dependent'),
    (Pattern: $9008; Mask: $FFFF; Category: ascInfo; Description: 'Key/file not found'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 101; historical, card-context dependent'),
    (Pattern: $9080; Mask: $FFFF; Category: ascWarning; Description: 'Unblock Try Counter has reached zero'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 102; historical, card-context dependent'),
    (Pattern: $9100; Mask: $FFFF; Category: ascInfo; Description: 'OK'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 103; historical, card-context dependent'),
    (Pattern: $9101; Mask: $FFFF; Category: ascInfo; Description: 'States.activity, States.lock Status or States.lockable has wrong value'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 104; historical, card-context dependent'),
    (Pattern: $9102; Mask: $FFFF; Category: ascWarning; Description: 'Transaction number reached its limit'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 105; historical, card-context dependent'),
    (Pattern: $910C; Mask: $FFFF; Category: ascInfo; Description: 'No changes'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 106; historical, card-context dependent'),
    (Pattern: $910E; Mask: $FFFF; Category: ascError; Description: 'Insufficient NV-Memory to complete command'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 107; historical, card-context dependent'),
    (Pattern: $911C; Mask: $FFFF; Category: ascInfo; Description: 'Command code not supported'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 108; historical, card-context dependent'),
    (Pattern: $911E; Mask: $FFFF; Category: ascWarning; Description: 'CRC or MAC does not match data'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 109; historical, card-context dependent'),
    (Pattern: $9140; Mask: $FFFF; Category: ascError; Description: 'nvalid key number specified'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 110; historical, card-context dependent'),
    (Pattern: $917E; Mask: $FFFF; Category: ascError; Description: 'Length of command string invalid'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 111; historical, card-context dependent'),
    (Pattern: $919D; Mask: $FFFF; Category: ascError; Description: 'Requested command is not allowed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 112; historical, card-context dependent'),
    (Pattern: $919E; Mask: $FFFF; Category: ascError; Description: 'Value of the parameter invalid'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 113; historical, card-context dependent'),
    (Pattern: $91A0; Mask: $FFFF; Category: ascInfo; Description: 'Requested AID not present on PICC'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 114; historical, card-context dependent'),
    (Pattern: $91A1; Mask: $FFFF; Category: ascError; Description: 'Unrecoverable error within application'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 115; historical, card-context dependent'),
    (Pattern: $91AE; Mask: $FFFF; Category: ascWarning; Description: 'Authentication status does not allow the requested command'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 116; historical, card-context dependent'),
    (Pattern: $91AF; Mask: $FFFF; Category: ascWarning; Description: 'Additional data frame is expected to be sent'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 117; historical, card-context dependent'),
    (Pattern: $91BE; Mask: $FFFF; Category: ascError; Description: 'Out of boundary'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 118; historical, card-context dependent'),
    (Pattern: $91C1; Mask: $FFFF; Category: ascError; Description: 'Unrecoverable error within PICC'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 119; historical, card-context dependent'),
    (Pattern: $91CA; Mask: $FFFF; Category: ascInfo; Description: 'Previous Command was not fully completed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 120; historical, card-context dependent'),
    (Pattern: $91CD; Mask: $FFFF; Category: ascError; Description: 'PICC was disabled by an unrecoverable error'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 121; historical, card-context dependent'),
    (Pattern: $91CE; Mask: $FFFF; Category: ascInfo; Description: 'Number of Applications limited to 28'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 122; historical, card-context dependent'),
    (Pattern: $91DE; Mask: $FFFF; Category: ascInfo; Description: 'File or application already exists'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 123; historical, card-context dependent'),
    (Pattern: $91EE; Mask: $FFFF; Category: ascError; Description: 'Could not complete NV-write operation due to loss of power'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 124; historical, card-context dependent'),
    (Pattern: $91F0; Mask: $FFFF; Category: ascInfo; Description: 'Specified file number does not exist'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 125; historical, card-context dependent'),
    (Pattern: $91F1; Mask: $FFFF; Category: ascError; Description: 'Unrecoverable error within file'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 126; historical, card-context dependent'),
    (Pattern: $0920; Mask: $FFFF; Category: ascInfo; Description: 'Writing to EEPROM successful after ‘x’ attempts.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 127; historical, card-context dependent'),
    (Pattern: $9210; Mask: $FFFF; Category: ascError; Description: 'Insufficient memory. No more storage available.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 128; historical, card-context dependent'),
    (Pattern: $9240; Mask: $FFFF; Category: ascError; Description: 'Writing to EEPROM not successful.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 129; historical, card-context dependent'),
    (Pattern: $9301; Mask: $FFFF; Category: ascError; Description: 'Integrity error'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 130; historical, card-context dependent'),
    (Pattern: $9302; Mask: $FFFF; Category: ascWarning; Description: 'Candidate S2 invalid'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 131; historical, card-context dependent'),
    (Pattern: $9303; Mask: $FFFF; Category: ascError; Description: 'Application is permanently locked'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 132; historical, card-context dependent'),
    (Pattern: $9400; Mask: $FFFF; Category: ascError; Description: 'No EF selected.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 133; historical, card-context dependent'),
    (Pattern: $9401; Mask: $FFFF; Category: ascWarning; Description: 'Candidate currency code does not match purse currency'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 134; historical, card-context dependent'),
    (Pattern: $9402; Mask: $FFFF; Category: ascWarning; Description: 'Candidate amount too high'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 135; historical, card-context dependent'),
    (Pattern: $9403; Mask: $FFFF; Category: ascWarning; Description: 'Candidate amount too low'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 136; historical, card-context dependent'),
    (Pattern: $9404; Mask: $FFFF; Category: ascError; Description: 'FID not found, record not found or comparison pattern not found.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 137; historical, card-context dependent'),
    (Pattern: $9405; Mask: $FFFF; Category: ascWarning; Description: 'Problems in the data field'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 138; historical, card-context dependent'),
    (Pattern: $9406; Mask: $FFFF; Category: ascError; Description: 'Required MAC unavailable'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 139; historical, card-context dependent'),
    (Pattern: $9407; Mask: $FFFF; Category: ascError; Description: 'Bad currency : purse engine has no slot with R3bc currency'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 140; historical, card-context dependent'),
    (Pattern: $9408; Mask: $FFFF; Category: ascInfo; Description: 'R3bc currency not supported in purse engine'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 141; historical, card-context dependent'),
    (Pattern: $9580; Mask: $FFFF; Category: ascWarning; Description: 'Bad sequence'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 142; historical, card-context dependent'),
    (Pattern: $9681; Mask: $FFFF; Category: ascInfo; Description: 'Slave not found'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 143; historical, card-context dependent'),
    (Pattern: $9700; Mask: $FFFF; Category: ascWarning; Description: 'PIN blocked and Unblock Try Counter is 1 or 2'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 144; historical, card-context dependent'),
    (Pattern: $9702; Mask: $FFFF; Category: ascWarning; Description: 'Main keys are blocked'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 145; historical, card-context dependent'),
    (Pattern: $9704; Mask: $FFFF; Category: ascWarning; Description: 'PIN not succesfully verified, 3 or more PIN tries left'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 146; historical, card-context dependent'),
    (Pattern: $9784; Mask: $FFFF; Category: ascInfo; Description: 'Base key'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 147; historical, card-context dependent'),
    (Pattern: $9785; Mask: $FFFF; Category: ascError; Description: 'Limit exceeded – C-MAC key'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 148; historical, card-context dependent'),
    (Pattern: $9786; Mask: $FFFF; Category: ascError; Description: 'SM error – Limit exceeded – R-MAC key'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 149; historical, card-context dependent'),
    (Pattern: $9787; Mask: $FFFF; Category: ascError; Description: 'Limit exceeded – sequence counter'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 150; historical, card-context dependent'),
    (Pattern: $9788; Mask: $FFFF; Category: ascError; Description: 'Limit exceeded – R-MAC length'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 151; historical, card-context dependent'),
    (Pattern: $9789; Mask: $FFFF; Category: ascInfo; Description: 'Service not available'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 152; historical, card-context dependent'),
    (Pattern: $9802; Mask: $FFFF; Category: ascError; Description: 'No PIN defined.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 153; historical, card-context dependent'),
    (Pattern: $9804; Mask: $FFFF; Category: ascError; Description: 'Access conditions not satisfied, authentication failed.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 154; historical, card-context dependent'),
    (Pattern: $9835; Mask: $FFFF; Category: ascError; Description: 'ASK RANDOM or GIVE RANDOM not executed.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 155; historical, card-context dependent'),
    (Pattern: $9840; Mask: $FFFF; Category: ascError; Description: 'PIN verification not successful.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 156; historical, card-context dependent'),
    (Pattern: $9850; Mask: $FFFF; Category: ascError; Description: 'INCREASE or DECREASE could not be executed because a limit has been reached.'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 157; historical, card-context dependent'),
    (Pattern: $9862; Mask: $FFFF; Category: ascError; Description: 'Authentication Error, application specific (incorrect MAC)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 158; historical, card-context dependent'),
    (Pattern: $9900; Mask: $FFFF; Category: ascInfo; Description: '1 PIN try left'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 159; historical, card-context dependent'),
    (Pattern: $9904; Mask: $FFFF; Category: ascError; Description: 'PIN not succesfully verified, 1 PIN try left'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 160; historical, card-context dependent'),
    (Pattern: $9985; Mask: $FFFF; Category: ascError; Description: 'Wrong status – Cardholder lock'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 161; historical, card-context dependent'),
    (Pattern: $9986; Mask: $FFFF; Category: ascError; Description: 'Missing privilege'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 162; historical, card-context dependent'),
    (Pattern: $9987; Mask: $FFFF; Category: ascInfo; Description: 'PIN is not installed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 163; historical, card-context dependent'),
    (Pattern: $9988; Mask: $FFFF; Category: ascError; Description: 'Wrong status – R-MAC state'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 164; historical, card-context dependent'),
    (Pattern: $9A00; Mask: $FFFF; Category: ascInfo; Description: '2 PIN try left'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 165; historical, card-context dependent'),
    (Pattern: $9A04; Mask: $FFFF; Category: ascInfo; Description: 'PIN not succesfully verified, 2 PIN try left'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 166; historical, card-context dependent'),
    (Pattern: $9A71; Mask: $FFFF; Category: ascError; Description: 'Wrong parameter value – Double agent AID'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 167; historical, card-context dependent'),
    (Pattern: $9A72; Mask: $FFFF; Category: ascError; Description: 'Wrong parameter value – Double agent Type'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 168; historical, card-context dependent'),
    (Pattern: $9D05; Mask: $FFFF; Category: ascError; Description: 'Incorrect certificate type'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 169; historical, card-context dependent'),
    (Pattern: $9D07; Mask: $FFFF; Category: ascError; Description: 'Incorrect session data size'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 170; historical, card-context dependent'),
    (Pattern: $9D08; Mask: $FFFF; Category: ascError; Description: 'Incorrect DIR file record size'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 171; historical, card-context dependent'),
    (Pattern: $9D09; Mask: $FFFF; Category: ascError; Description: 'Incorrect FCI record size'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 172; historical, card-context dependent'),
    (Pattern: $9D0A; Mask: $FFFF; Category: ascError; Description: 'Incorrect code size'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 173; historical, card-context dependent'),
    (Pattern: $9D10; Mask: $FFFF; Category: ascError; Description: 'Insufficient memory to load application'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 174; historical, card-context dependent'),
    (Pattern: $9D11; Mask: $FFFF; Category: ascError; Description: 'Invalid AID'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 175; historical, card-context dependent'),
    (Pattern: $9D12; Mask: $FFFF; Category: ascError; Description: 'Duplicate AID'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 176; historical, card-context dependent'),
    (Pattern: $9D13; Mask: $FFFF; Category: ascError; Description: 'Application previously loaded'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 177; historical, card-context dependent'),
    (Pattern: $9D14; Mask: $FFFF; Category: ascError; Description: 'Application history list full'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 178; historical, card-context dependent'),
    (Pattern: $9D15; Mask: $FFFF; Category: ascError; Description: 'Application not open'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 179; historical, card-context dependent'),
    (Pattern: $9D17; Mask: $FFFF; Category: ascError; Description: 'Invalid offset'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 180; historical, card-context dependent'),
    (Pattern: $9D18; Mask: $FFFF; Category: ascError; Description: 'Application already loaded'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 181; historical, card-context dependent'),
    (Pattern: $9D19; Mask: $FFFF; Category: ascError; Description: 'Invalid certificate'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 182; historical, card-context dependent'),
    (Pattern: $9D1A; Mask: $FFFF; Category: ascError; Description: 'Invalid signature'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 183; historical, card-context dependent'),
    (Pattern: $9D1B; Mask: $FFFF; Category: ascError; Description: 'Invalid KTU'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 184; historical, card-context dependent'),
    (Pattern: $9D1D; Mask: $FFFF; Category: ascError; Description: 'MSM controls not set'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 185; historical, card-context dependent'),
    (Pattern: $9D1E; Mask: $FFFF; Category: ascError; Description: 'Application signature does not exist'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 186; historical, card-context dependent'),
    (Pattern: $9D1F; Mask: $FFFF; Category: ascError; Description: 'KTU does not exist'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 187; historical, card-context dependent'),
    (Pattern: $9D20; Mask: $FFFF; Category: ascError; Description: 'Application not loaded'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 188; historical, card-context dependent'),
    (Pattern: $9D21; Mask: $FFFF; Category: ascError; Description: 'Invalid Open command data length'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 189; historical, card-context dependent'),
    (Pattern: $9D30; Mask: $FFFF; Category: ascError; Description: 'Check data parameter is incorrect (invalid start address)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 190; historical, card-context dependent'),
    (Pattern: $9D31; Mask: $FFFF; Category: ascError; Description: 'Check data parameter is incorrect (invalid length)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 191; historical, card-context dependent'),
    (Pattern: $9D32; Mask: $FFFF; Category: ascError; Description: 'Check data parameter is incorrect (illegal memory check area)'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 192; historical, card-context dependent'),
    (Pattern: $9D40; Mask: $FFFF; Category: ascError; Description: 'Invalid MSM Controls ciphertext'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 193; historical, card-context dependent'),
    (Pattern: $9D41; Mask: $FFFF; Category: ascError; Description: 'MSM controls already set'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 194; historical, card-context dependent'),
    (Pattern: $9D42; Mask: $FFFF; Category: ascError; Description: 'Set MSM Controls data length less than 2 bytes'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 195; historical, card-context dependent'),
    (Pattern: $9D43; Mask: $FFFF; Category: ascError; Description: 'Invalid MSM Controls data length'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 196; historical, card-context dependent'),
    (Pattern: $9D44; Mask: $FFFF; Category: ascError; Description: 'Excess MSM Controls ciphertext'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 197; historical, card-context dependent'),
    (Pattern: $9D45; Mask: $FFFF; Category: ascError; Description: 'Verification of MSM Controls data failed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 198; historical, card-context dependent'),
    (Pattern: $9D50; Mask: $FFFF; Category: ascError; Description: 'Invalid MCD Issuer production ID'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 199; historical, card-context dependent'),
    (Pattern: $9D51; Mask: $FFFF; Category: ascError; Description: 'Invalid MCD Issuer ID'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 200; historical, card-context dependent'),
    (Pattern: $9D52; Mask: $FFFF; Category: ascError; Description: 'Invalid set MSM controls data date'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 201; historical, card-context dependent'),
    (Pattern: $9D53; Mask: $FFFF; Category: ascError; Description: 'Invalid MCD number'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 202; historical, card-context dependent'),
    (Pattern: $9D54; Mask: $FFFF; Category: ascError; Description: 'Reserved field error'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 203; historical, card-context dependent'),
    (Pattern: $9D55; Mask: $FFFF; Category: ascError; Description: 'Reserved field error'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 204; historical, card-context dependent'),
    (Pattern: $9D56; Mask: $FFFF; Category: ascError; Description: 'Reserved field error'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 205; historical, card-context dependent'),
    (Pattern: $9D57; Mask: $FFFF; Category: ascError; Description: 'Reserved field error'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 206; historical, card-context dependent'),
    (Pattern: $9D60; Mask: $FFFF; Category: ascError; Description: 'MAC verification failed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 207; historical, card-context dependent'),
    (Pattern: $9D61; Mask: $FFFF; Category: ascError; Description: 'Maximum number of unblocks reached'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 208; historical, card-context dependent'),
    (Pattern: $9D62; Mask: $FFFF; Category: ascError; Description: 'Card was not blocked'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 209; historical, card-context dependent'),
    (Pattern: $9D63; Mask: $FFFF; Category: ascError; Description: 'Crypto functions not available'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 210; historical, card-context dependent'),
    (Pattern: $9D64; Mask: $FFFF; Category: ascError; Description: 'No application loaded'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 211; historical, card-context dependent'),
    (Pattern: $9E00; Mask: $FFFF; Category: ascInfo; Description: 'PIN not installed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 212; historical, card-context dependent'),
    (Pattern: $9E04; Mask: $FFFF; Category: ascWarning; Description: 'PIN not succesfully verified, PIN not installed'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 213; historical, card-context dependent'),
    (Pattern: $9F00; Mask: $FFFF; Category: ascWarning; Description: 'PIN blocked and Unblock Try Counter is 3'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 214; historical, card-context dependent'),
    (Pattern: $9F04; Mask: $FFFF; Category: ascWarning; Description: 'PIN not succesfully verified, PIN blocked and Unblock Try Counter is 3'; Source: 'Original CardStudio 01faaef, untAPDUParser.pas, row 215; historical, card-context dependent')
  );

class function TApduCatalog.GetInstructions: TApduInstructionDescriptions;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(InstructionEntries));
  for I := 0 to High(InstructionEntries) do
    Result[I] := InstructionEntries[I];
end;

class function TApduCatalog.FindInstructions(const AInstruction: Byte): TApduInstructionDescriptions;
var
  I, N: Integer;
begin
  Result := nil;
  for I := 0 to High(InstructionEntries) do
    if InstructionEntries[I].Instruction = AInstruction then
    begin
      N := Length(Result);
      SetLength(Result, N + 1);
      Result[N] := InstructionEntries[I];
    end;
end;

class function TApduCatalog.GetHistoricalStatuses: TApduStatusDescriptions;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(StatusEntries));
  for I := 0 to High(StatusEntries) do
    Result[I] := StatusEntries[I];
end;

class function TApduCatalog.FindStatusDescriptions(const AStatus: Word): TApduStatusDescriptions;
var
  I, N, LowByte: Integer;
  procedure Standard(const ACategory: TApduStatusCategory; const AText: string);
  begin
    SetLength(Result, 1);
    Result[0].Pattern := AStatus;
    Result[0].Mask := $FFFF;
    Result[0].Category := ACategory;
    Result[0].Description := AText;
    Result[0].Source := 'ISO/IEC 7816-4 status-word interpretation; command context applies';
  end;
begin
  Result := nil;
  LowByte := AStatus and $FF;
  if AStatus = $9000 then
    Standard(ascInfo, 'Command completed successfully')
  else if AStatus shr 8 = $61 then
  begin
    if LowByte = 0 then
      LowByte := 256;
    Standard(ascInfo, IntToStr(LowByte) + ' response bytes available through GET RESPONSE')
  end
  else if AStatus shr 8 = $6C then
  begin
    if LowByte = 0 then
      LowByte := 256;
    Standard(ascError, 'Wrong Le; expected ' + IntToStr(LowByte) + ' bytes')
  end
  else if AStatus and $FFF0 = $63C0 then
    Standard(ascWarning, 'Counter value (VERIFY: remaining attempts) ' + IntToStr(AStatus and $0F));
  for I := 0 to High(StatusEntries) do
    if (StatusEntries[I].Mask <> 0) and
      ((AStatus and StatusEntries[I].Mask) = StatusEntries[I].Pattern) then
    begin
      N := Length(Result);
      SetLength(Result, N + 1);
      Result[N] := StatusEntries[I];
    end;
end;

end.
