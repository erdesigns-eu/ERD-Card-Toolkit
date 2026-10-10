unit ERD.Card.Memory.Capabilities;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses ERD.Card.Memory, ERD.Card.Memory.Counter;

type
  /// <summary>Implemented ordinary-memory profiles, not detected physical chip capabilities.</summary>
  TMemoryCardModels = set of TMemoryCardModel;
  /// <summary>Implemented counter-chip profiles, not hardware certification.</summary>
  TSleCounterModels = set of TSleCounterModel;
  /// <summary>Implemented SLE4404 operations; each still requires an explicit known card layout.</summary>
  TSle4404Feature = (
    /// <summary>Read a public accessible byte range without a code attempt.</summary>
    sfPublicRead,
    /// <summary>Read a range after one user-code attempt with counter proof.</summary>
    sfUserCodeRead,
    /// <summary>Program one-to-zero bits with expected-state and read-back checks.</summary>
    sfProgram,
    /// <summary>Verify one supplied user code through the restored counter.</summary>
    sfUserCodeProof,
    /// <summary>Explicitly erase and verify the scratchpad.</summary>
    sfScratchErase,
    /// <summary>Explicitly erase the application area using both supplied codes.</summary>
    sfApplicationErase);
  /// <summary>Offline set of implemented SLE4404 operations, not detected card rights.</summary>
  TSle4404Features = set of TSle4404Feature;

  /// <summary>Operations available in the component set for one explicitly selected ACS dialect.</summary>
  /// <remarks>This is an offline protocol catalog. It does not query firmware or infer the
  /// reader model from its name or ATR. Card configuration, credentials and locks still apply.</remarks>
  TAcsMemoryCapabilities = record
    /// <summary>Explicit reader dialect described by this result.</summary>
    Dialect: TAcsMemoryDialect;
    /// <summary>Ordinary-memory models with public reads in this dialect.</summary>
    ReadModels: TMemoryCardModels;
    /// <summary>Ordinary-memory models with independently verified writes.</summary>
    WriteModels: TMemoryCardModels;
    /// <summary>Models with supplied-PIN verification and retry-budget checks.</summary>
    PinModels: TMemoryCardModels;
    /// <summary>Models with verified PIN replacement; three-wire replacement is absent.</summary>
    PinChangeModels: TMemoryCardModels;
    /// <summary>Models with explicit irreversible protection operations.</summary>
    ProtectionModels: TMemoryCardModels;
    /// <summary>Counter-chip profiles with reads and verified bit/carry programming.</summary>
    CounterModels: TSleCounterModels;
    /// <summary>Counter-chip profiles with raw certificate calculation, without issuer verification.</summary>
    CertificateModels: TSleCounterModels;
    /// <summary>SLE4404 operations implemented for this reader dialect; empty for ACR39.</summary>
    Sle4404Features: TSle4404Features;
  end;

  /// <summary>Offline catalog separating documented implemented protocols from actual hardware support.</summary>
  TAcsMemoryCapabilityCatalog = class
  public
    /// <summary>Returns explicit component capabilities without opening a device or probing a card.</summary>
    /// <param name="ADialect">Known ACR38x CCID or ACR39 profile.</param>
    /// <returns>Value-only capability sets; invalid dialects raise EMemoryCardError.</returns>
    class function ForDialect(const ADialect: TAcsMemoryDialect)
      : TAcsMemoryCapabilities; static;
    /// <summary>Returns an explicit ordinary chip-profile name for diagnostics and selectors.</summary>
    /// <param name="AModel">Implemented ordinary-memory model.</param>
    /// <returns>Stable chip or capacity name; invalid models raise EMemoryCardError.</returns>
    class function ModelName(const AModel: TMemoryCardModel): string; static;
    /// <summary>Returns an explicit counter-chip name for diagnostics and selectors.</summary>
    /// <param name="AModel">Implemented counter profile.</param>
    /// <returns>Stable chip name; invalid models raise EMemoryCardError.</returns>
    class function CounterName(const AModel: TSleCounterModel): string; static;
  end;

implementation

class function TAcsMemoryCapabilityCatalog.ForDialect(const ADialect
  : TAcsMemoryDialect): TAcsMemoryCapabilities;
begin
  if not(ADialect in [amdAcr38Ccid, amdAcr39]) then
    raise EMemoryCardError.Create('Unknown ACS memory dialect.');
  Result := Default (TAcsMemoryCapabilities);
  Result.Dialect := ADialect;
  Result.ReadModels := [Low(TMemoryCardModel) .. High(TMemoryCardModel)];
  Result.WriteModels := Result.ReadModels;
  Result.PinModels := [mcmSle4442, mcmSle5542, mcmSle4428, mcmSle5528];
  Result.PinChangeModels := [mcmSle4442, mcmSle5542];
  Result.ProtectionModels := [mcmSle4432 .. mcmSle5528];
  if ADialect = amdAcr38Ccid then
  begin
    Result.CounterModels := [Low(TSleCounterModel) .. High(TSleCounterModel)];
    Result.CertificateModels := [scmSle4436, scmSle5536, scmSle6636];
    Result.Sle4404Features := [Low(TSle4404Feature) .. High(TSle4404Feature)];
  end;
end;

class function TAcsMemoryCapabilityCatalog.ModelName(const AModel
  : TMemoryCardModel): string;
begin
  case AModel of
    mcmSle4432:
      Result := 'SLE4432';
    mcmSle4442:
      Result := 'SLE4442';
    mcmSle5532:
      Result := 'SLE5532';
    mcmSle5542:
      Result := 'SLE5542';
    mcmSle4418:
      Result := 'SLE4418';
    mcmSle4428:
      Result := 'SLE4428';
    mcmSle5518:
      Result := 'SLE5518';
    mcmSle5528:
      Result := 'SLE5528';
    mcmI2c1Kbit:
      Result := 'I2C 1 kbit';
    mcmI2c2Kbit:
      Result := 'I2C 2 kbit';
    mcmI2c4Kbit:
      Result := 'I2C 4 kbit';
    mcmI2c8Kbit:
      Result := 'I2C 8 kbit';
    mcmI2c16Kbit:
      Result := 'I2C 16 kbit';
    mcmI2c32Kbit:
      Result := 'I2C 32 kbit';
    mcmI2c64Kbit:
      Result := 'I2C 64 kbit';
    mcmI2c128Kbit:
      Result := 'I2C 128 kbit';
    mcmI2c256Kbit:
      Result := 'I2C 256 kbit';
    mcmI2c512Kbit:
      Result := 'I2C 512 kbit';
    mcmI2c1024Kbit:
      Result := 'I2C 1024 kbit';
  else
    raise EMemoryCardError.Create('Unknown memory model.');
  end;
end;

class function TAcsMemoryCapabilityCatalog.CounterName
  (const AModel: TSleCounterModel): string;
begin
  case AModel of
    scmSle4406:
      Result := 'SLE4406';
    scmSle4436:
      Result := 'SLE4436';
    scmSle5536:
      Result := 'SLE5536';
    scmSle6636:
      Result := 'SLE6636';
  else
    raise EMemoryCardError.Create('Unknown counter model.');
  end;
end;

end.
