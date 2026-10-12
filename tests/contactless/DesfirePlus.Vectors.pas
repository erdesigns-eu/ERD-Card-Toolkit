unit DesfirePlus.Vectors;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
type
  /// <summary>Independent synthetic native command/response strings, generated with Python cryptography.</summary>
  TExtendedPair = record
    /// <summary>Exact expected command bytes.</summary>
    Command: string;
    /// <summary>Exact synthetic response bytes.</summary>
    Response: string;
  end;
  /// <summary>Owned ordered protocol fixture with no real card data.</summary>
  TExtendedPairs = array of TExtendedPair;
/// <summary>Returns independent synthetic DfInitialize native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfInitialize: TExtendedPairs;
/// <summary>Returns independent synthetic DfChangeInactive native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfChangeInactive: TExtendedPairs;
/// <summary>Returns independent synthetic DfFinalize native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfFinalize: TExtendedPairs;
/// <summary>Returns independent synthetic DfRoll native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRoll: TExtendedPairs;
/// <summary>Returns independent synthetic DfConfigAts native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfConfigAts: TExtendedPairs;
/// <summary>Returns independent synthetic DfConfigValue native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfConfigValue: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmChange native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmChange: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfSetVersions native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSetVersions: TExtendedPairs;
/// <summary>Returns independent synthetic DfCreate native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfCreate: TExtendedPairs;
/// <summary>Returns independent synthetic PlusMacRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusMacRead: TExtendedPairs;
/// <summary>Returns independent synthetic PlusMacWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusMacWrite: TExtendedPairs;
/// <summary>Returns independent synthetic PlusFullRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusFullRead: TExtendedPairs;
/// <summary>Returns independent synthetic PlusFullReadNew native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusFullReadNew: TExtendedPairs;
/// <summary>Returns independent synthetic PlusFullWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusFullWrite: TExtendedPairs;
/// <summary>Returns independent synthetic Plus4KRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function Plus4KRead: TExtendedPairs;
/// <summary>Returns independent synthetic Plus4KWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function Plus4KWrite: TExtendedPairs;
/// <summary>Returns independent synthetic PlusRotate4000 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusRotate4000: TExtendedPairs;
/// <summary>Returns independent synthetic PlusRotate4001 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusRotate4001: TExtendedPairs;
/// <summary>Returns independent synthetic PlusRotate4040 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusRotate4040: TExtendedPairs;
/// <summary>Returns independent synthetic PlusPersonalize native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusPersonalize: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel9004 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel9004: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel9002 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel9002: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel9003 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel9003: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel3Proof native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel3Proof: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevelAcr native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevelAcr: TExtendedPairs;
/// <summary>Returns independent synthetic PlusValueRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusValueRead: TExtendedPairs;
/// <summary>Returns independent synthetic PlusValueWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusValueWrite: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel2To3 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel2To3: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative0Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative0Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative0Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative0Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative1Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative1Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative1Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative1Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative2Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative2Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative2Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative2Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative3Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative3Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative3Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative3Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative4Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative4Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative4Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative4Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative4KIncrement native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative4KIncrement: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative4KDecrement native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative4KDecrement: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNativeBadTarget native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNativeBadTarget: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNativeBadSource native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNativeBadSource: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoDirectory native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoDirectory: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateApplication native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateApplication: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoFileIds native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoFileIds: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateFile0 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateFile0: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateFile1 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateFile1: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateFile3 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateFile3: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateFile4 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateFile4: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiSettings native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiSettings: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiChange native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiChange: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacCreate native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacCreate: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacSettings native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacSettings: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacRecord native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacRecord: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacAbort: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacReaderWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacReaderWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacReaderRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacReaderRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacReaderAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacReaderAbort: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacBadMac native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacBadMac: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacBadCounter native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacBadCounter: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacCrypto native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacCrypto: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacRecordMac native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacRecordMac: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacRecordFull native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacRecordFull: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacLimitChange native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacLimitChange: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacDelete native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacDelete: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiNonMasterRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiNonMasterRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateKeySets native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateKeySets: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateBadGeometry native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateBadGeometry: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateBadFid native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateBadFid: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateBadName native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateBadName: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardOverlap native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardOverlap: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardDisjoint native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardDisjoint: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardNoop native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardNoop: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardAbort: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardRepeat native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardRepeat: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardPreimage native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardPreimage: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardImmediateMismatch native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardImmediateMismatch: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardCommitMismatch native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardCommitMismatch: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardDeniedWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardDeniedWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardDeniedRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardDeniedRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardWrongFile native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardWrongFile: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardBounds native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardBounds: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmAccessRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmAccessRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmAccessEnable native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmAccessEnable: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmAccessDisableSdm native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmAccessDisableSdm: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmAccessRemoveRights native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmAccessRemoveRights: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmAccessRemoveBoth native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmAccessRemoveBoth: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmAccessNoop native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmAccessNoop: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmAccessBadPreimage native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmAccessBadPreimage: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmAccessBadPostimage native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmAccessBadPostimage: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordRepeat native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordRepeat: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordAbort: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordNoop native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordNoop: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordPreimage native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordPreimage: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordAppendConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordAppendConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordClearConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordClearConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordDifferentConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordDifferentConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordWrongCommit native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordWrongCommit: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordAppendFirstConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordAppendFirstConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordClearFirstConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordClearFirstConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacRepeat native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacRepeat: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacAbort: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacNoop native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacNoop: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacPreimage native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacPreimage: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacAppendConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacAppendConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacClearConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacClearConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacDifferentConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacDifferentConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacWrongCommit native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacWrongCommit: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacAppendFirstConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacAppendFirstConflict: TExtendedPairs;
/// <summary>Returns independent synthetic DfRecordTmacClearFirstConflict native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRecordTmacClearFirstConflict: TExtendedPairs;
/// <summary>Returns independent synthetic LrpPublishedEval native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpPublishedEval: TExtendedPairs;
/// <summary>Returns independent synthetic LrpPublishedCrypt native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpPublishedCrypt: TExtendedPairs;
/// <summary>Returns independent synthetic LrpPublishedCmac native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpPublishedCmac: TExtendedPairs;
/// <summary>Returns independent synthetic LrpAuth native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpAuth: TExtendedPairs;
/// <summary>Returns independent synthetic LrpAuthBadCapability native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpAuthBadCapability: TExtendedPairs;
/// <summary>Returns independent synthetic LrpPlainRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpPlainRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpPlainWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpPlainWrite: TExtendedPairs;
/// <summary>Returns independent synthetic LrpMacRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpMacRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpMacWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpMacWrite: TExtendedPairs;
/// <summary>Returns independent synthetic LrpFullRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpFullRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpFullWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpFullWrite: TExtendedPairs;
/// <summary>Returns independent synthetic LrpBadPadding native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpBadPadding: TExtendedPairs;
/// <summary>Returns independent synthetic LrpBadLength native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpBadLength: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativePlainRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativePlainRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativePlainWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativePlainWrite: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativeMacRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativeMacRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativeMacWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativeMacWrite: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativeFullRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativeFullRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativeFullWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativeFullWrite: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativeNonFirstRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativeNonFirstRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativeBadCapability native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativeBadCapability: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativeBadMode native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativeBadMode: TExtendedPairs;
/// <summary>Returns independent synthetic LrpOwnedBackup native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpOwnedBackup: TExtendedPairs;
/// <summary>Returns independent synthetic LrpOwnedValue native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpOwnedValue: TExtendedPairs;
/// <summary>Returns independent synthetic LrpOwnedRecord native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpOwnedRecord: TExtendedPairs;
/// <summary>Returns independent synthetic LrpOwnedAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpOwnedAbort: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTransactionCrypto native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTransactionCrypto: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacWrite: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacAbort: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacStandard native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacStandard: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacRecord native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacRecord: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacWrongReceipt native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacWrongReceipt: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacWrongAct native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacWrongAct: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacWrongSession native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacWrongSession: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacWrongPostimage native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacWrongPostimage: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacLimitReached native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacLimitReached: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderWrite: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderRead: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderAbort: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderStandard native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderStandard: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderRecord native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderRecord: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderWrongReceipt native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderWrongReceipt: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderWrongAct native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderWrongAct: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderWrongSession native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderWrongSession: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderWrongPostimage native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderWrongPostimage: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacReaderLimitReached native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacReaderLimitReached: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacAcquired1 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacAcquired1: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacAcquired7 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacAcquired7: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacAcquired65535 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacAcquired65535: TExtendedPairs;
/// <summary>Returns independent synthetic LrpTmacZeroSession native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpTmacZeroSession: TExtendedPairs;
/// <summary>Returns independent synthetic LrpNativeUid native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpNativeUid: TExtendedPairs;
/// <summary>Returns independent synthetic DfNativeUid native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfNativeUid: TExtendedPairs;
/// <summary>Returns independent synthetic LrpStoredTmacPlain native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpStoredTmacPlain: TExtendedPairs;
/// <summary>Returns independent synthetic LrpStoredTmacMac native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpStoredTmacMac: TExtendedPairs;
/// <summary>Returns independent synthetic LrpStoredTmacFull native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function LrpStoredTmacFull: TExtendedPairs;
implementation
function DfInitialize: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '905600000A01029688731516D1623400';
  Result[4].Response := '2815BB17AD6EAF2F9100';
end;
function DfChangeInactive: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90C600002A010111CC601EC19ABA33BF9FE3B2807CF68667A0306AEC2CF4D6B87E1B5102E3E1A485119FEFF3021DE400';
  Result[4].Response := '2815BB17AD6EAF2F9100';
  Result[5].Command := '906400000A41013A5105B3DFE8D3DB00';
  Result[5].Response := '34C662C9D35CB6771E9100';
end;
function DfFinalize: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '905700000A012153EF72E0D48BB1D400';
  Result[4].Response := '2815BB17AD6EAF2F9100';
end;
function DfRoll: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '905500000901267ACB61A7E6557E00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9071000002000000';
  Result[6].Response := 'D0EA8B2030A9A14763EF94BEFCB4AB8991AF';
  Result[7].Command := '90AF000020FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A85900';
  Result[7].Response := 'AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF086169100';
  Result[8].Command := '9064000009001E3288A2F0EB85E300';
  Result[8].Response := '342E92780A2DD8DC579100';
end;
function DfConfigAts: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '905C00001902CE69F3DF2C9428855C9F52D34E8FF6CF3426E8FA17F99AC500';
  Result[3].Response := 'FA0E3F508A694E089100';
end;
function DfConfigValue: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '905C00001909984B8CD7D715F4E4315F2B571EBD20F88E73F9992890FA6E00';
  Result[3].Response := 'FA0E3F508A694E089100';
end;
function DfSdmChange: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '000000E00001002358DF7643B0182A9100';
  Result[5].Command := '905F00001900FF07F33052793813ED0FD16D2C0E09F129F6960964CFD31400';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '004000E0000100C1F12120000043000043000003C530E29B79BC979100';
end;
function DfSdmRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90F500000900C88DBE6B1DBE53DD00';
  Result[3].Response := '004000E0000100C1F1212000004300004300006CBF9073B793052A9100';
end;
function DfSetVersions: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '906400000A40801BBEA2CE05D9CFD000';
  Result[4].Response := '01212FA2A134083358CB9100';
end;
function DfCreate: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '2815BB17AD6EAF2F9100';
  Result[5].Command := '90CA0000125634120F930101021000DCC96054EE7326A600';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '905A00000356341200';
  Result[6].Response := '9100';
  Result[7].Command := '9045000000';
  Result[7].Response := '0F9301010210009100';
  Result[8].Command := '905A00000300000000';
  Result[8].Response := '9100';
  Result[9].Command := '9071000002000000';
  Result[9].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[10].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[10].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
end;
function PlusMacRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '33020001B962854D170390D8';
  Result[2].Response := '90000102030405060708090A0B0C0D0E0FE5108F0C63C71F1D';
end;
function PlusMacWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '33020001B962854D170390D8';
  Result[2].Response := '90000102030405060708090A0B0C0D0E0FE5108F0C63C71F1D';
  Result[3].Command := 'A30200101112131415161718191A1B1C1D1E1FCA61C76CB9317345';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '330200012EABF89882D898A3';
  Result[4].Response := '90101112131415161718191A1B1C1D1E1FF35A2D89339ADF8A';
end;
function PlusFullRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '9035FD196EBDD0A4D6630D801014BB9AEF16C53C220430BE84';
end;
function PlusFullReadNew: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '906BFA847A3CE7BAE0AF291ABBFA4DCC7536F785C07F279DDC';
end;
function PlusFullWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '9035FD196EBDD0A4D6630D801014BB9AEF16C53C220430BE84';
  Result[3].Command := 'A10200585B9898BC05641C3B98209E55F8EA539704EE50FA73991E';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '31020001CF8B21CA913DC3BB';
  Result[4].Response := '9058A307E7000115EACBFE4F105768A13695FCFD61C7953DB7';
end;
function Plus4KRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '3180000F6F229F6B72FE15A9';
  Result[2].Response := '9035FD196EBDD0A4D6630D801014BB9AEFCEB3A884E9FDA58F2182E69133D2C91D433EB6910809AE453341A9ABE04615EAAC63C31B2AF9D38A1DED093341BF669F44623B950C81FBFBD994D9660D0ECDDEA81C53D0F606BF8D5702E7DE08CBC805475C615CC0C67837F2FD77297BBABDCD4DDDA53E04AB72718FFBD1676B8E9DD1EE0AFAC5A8B53B9919F694129728EE63B55F7522D37EDB924E73577D9B1458C242FBEF99229DDE6CA10D7E27BD30C975E05D3775729A29D2C9BF8452B8618B7C9021A79AB08A6CACB20FFDE68714AC5714537835CEC40D02F1A9E4F756F130E3B2F5D20B3CAC714F4515E4BB95848525A22B49D401C89C87';
end;
function Plus4KWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31800001A9B5529816B9639C';
  Result[2].Response := '9035FD196EBDD0A4D6630D801014BB9AEFD84C74E07E7B7682';
  Result[3].Command := 'A18000585B9898BC05641C3B98209E55F8EA53513648DF64902204';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '318000018DEAD33AF3D04754';
  Result[4].Response := '9058A307E7000115EACBFE4F105768A136F2548BFA7808B382';
end;
function PlusRotate4000: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := 'A100408C0722BCBD7472670951A8348A597F07746B721B16C13813';
  Result[2].Response := '90416B03900FD11506';
  Result[3].Command := '70004000';
  Result[3].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[4].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[4].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
end;
function PlusRotate4001: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := 'A101408C0722BCBD7472670951A8348A597F07F33EB15D4E41458B';
  Result[2].Response := '90416B03900FD11506';
  Result[3].Command := '70014000';
  Result[3].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[4].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[4].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
end;
function PlusRotate4040: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := 'A140408C0722BCBD7472670951A8348A597F079030FAE0C59C1C34';
  Result[2].Response := '90416B03900FD11506';
  Result[3].Command := '70404000';
  Result[3].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[4].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[4].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
end;
function PlusPersonalize: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := 'A8009000000000000000000000000000000000';
  Result[0].Response := '90';
  Result[1].Command := 'A8019000000000000000000000000000000000';
  Result[1].Response := '90';
  Result[2].Command := 'A8039000000000000000000000000000000000';
  Result[2].Response := '90';
  Result[3].Command := 'A80040112233445566778899AABBCCDDEEFF00';
  Result[3].Response := '90';
  Result[4].Command := 'A80200101112131415161718191A1B1C1D1E1F';
  Result[4].Response := '90';
  Result[5].Command := 'AA';
  Result[5].Response := '90';
  Result[6].Command := '70004000';
  Result[6].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[7].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[7].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
  Result[8].Command := '70009000';
  Result[8].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[9].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[9].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[10].Command := '70019000';
  Result[10].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[11].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[11].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[12].Command := '70004000';
  Result[12].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[13].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[13].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
  Result[14].Command := '70004000';
  Result[14].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[15].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[15].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
  Result[16].Command := '310200019179A55A0E015456';
  Result[16].Response := '90435BEFA021830E187FD611C3775C2250197B45A320E5D653';
end;
function PlusLevel9004: TExtendedPairs;
begin
  Result := nil; SetLength(Result,2);
  Result[0].Command := '760490FC00';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9042557CACA75FB489EB682F716D9123D7FF81';
end;
function PlusLevel9002: TExtendedPairs;
begin
  Result := nil; SetLength(Result,2);
  Result[0].Command := '7602902C54';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9042557CACA75FB489EB682F716D9123D7FF81';
end;
function PlusLevel9003: TExtendedPairs;
begin
  Result := nil; SetLength(Result,2);
  Result[0].Command := '760390F44D';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9042557CACA75FB489EB682F716D9123D7FF81';
end;
function PlusLevel3Proof: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '760390F44D';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9042557CACA75FB489EB682F716D9123D7FF81';
  Result[2].Command := '70004000';
  Result[2].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[3].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[3].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[4].Command := '31020001EFD4D960788D6239';
  Result[4].Response := '9035FD196EBDD0A4D6630D801014BB9AEF16C53C220430BE84';
end;
function PlusLevelAcr: TExtendedPairs;
begin
  Result := nil; SetLength(Result,18);
  Result[0].Command := 'FF00000006D43202000B0D';
  Result[0].Response := 'D5339000';
  Result[1].Command := 'FF00000004D4320400';
  Result[1].Response := 'D5339000';
  Result[2].Command := 'FF00000006D43205000000';
  Result[2].Response := 'D5339000';
  Result[3].Command := 'FF00000003D41224';
  Result[3].Response := 'D5139000';
  Result[4].Command := 'FF00000004D4320100';
  Result[4].Response := 'D5339000';
  Result[5].Command := 'FF00000004D4320101';
  Result[5].Response := 'D5339000';
  Result[6].Command := 'FF00000004D44A0100';
  Result[6].Response := 'D54B010104000807041122334455669000';
  Result[7].Command := 'FF00000008D40663026303633D';
  Result[7].Response := 'D5078080009000';
  Result[8].Command := 'FF0000000BD408630200630300633D00';
  Result[8].Response := 'D5099000';
  Result[9].Command := 'FF0000000BD408630200630300633D00';
  Result[9].Response := 'D5099000';
  Result[10].Command := 'FF00000007D442760490FC00';
  Result[10].Response := 'D5430090659F2ABFC5BC0708FB96E7A44AF9D595C3299000';
  Result[11].Command := 'FF00000004D406633C';
  Result[11].Response := 'D507009000';
  Result[12].Command := 'FF0000000BD408630200630300633D00';
  Result[12].Response := 'D5099000';
  Result[13].Command := 'FF00000025D442723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[13].Response := 'D543009042557CACA75FB489EB682F716D9123D7FF819000';
  Result[14].Command := 'FF00000004D406633C';
  Result[14].Response := 'D507009000';
  Result[15].Command := 'FF0000000BD408630280630380633D00';
  Result[15].Response := 'D5099000';
  Result[16].Command := 'FF00000004D4320100';
  Result[16].Response := 'D5339000';
  Result[17].Command := 'FF00000003D41234';
  Result[17].Response := 'D5139000';
end;
function PlusValueRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '9079095FA26BD6F25E93D1798B5C27C9B4D8B7B44731A38B1D';
end;
function PlusValueWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '9079095FA26BD6F25E93D1798B5C27C9B4D8B7B44731A38B1D';
  Result[3].Command := 'A102003AA22A67FF99CAD402F581058CF743A2206B69FE6D3ADA8F';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '31020001CF8B21CA913DC3BB';
  Result[4].Response := '90B5D09DAE3CA7B0AAEBC5B2076A626F27B3F763A041EE8A03';
end;
function PlusLevel2To3: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '700390007CFA';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A2F35';
  Result[2].Command := '70004000';
  Result[2].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[3].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[3].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[4].Command := '31020001EFD4D960788D6239';
  Result[4].Response := '9035FD196EBDD0A4D6630D801014BB9AEF16C53C220430BE84';
end;
function PlusNative0Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
  Result[3].Command := 'B102004FC00F89220D6158A829FB9ABBD2F96077AC2E83902CF25A';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := 'B50200112B398F0CEF7805';
  Result[4].Response := '903F8C6E54AB4A6196';
  Result[5].Command := '31020001CF8B21CA913DC3BB';
  Result[5].Response := '90AEFF9D6CDED8D03A8EB4DAE4FD62733DF17EA6258D05E1E5';
end;
function PlusNative0Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B10100063F3A9FD5021CC7AA6D4A3D1B59BE8663AE73ECA0D03E8B';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := 'B50200112B398F0CEF7805';
  Result[5].Response := '903F8C6E54AB4A6196';
  Result[6].Command := '31020001CFAD4EC39476ED53';
  Result[6].Response := '9083378EA50274A0B993B1910451B9819E94FF07C5342D1E20';
  Result[7].Command := '31010001EED82CD11D548F19';
  Result[7].Response := '904D2CFE6D0104169B02D828A4E02D8DA31C07FB18E84F474E';
end;
function PlusNative1Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
  Result[3].Command := 'B302004FC00F89220D6158A829FB9ABBD2F960BBD09CD66819E39F';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := 'B50200112B398F0CEF7805';
  Result[4].Response := '903F8C6E54AB4A6196';
  Result[5].Command := '31020001CF8B21CA913DC3BB';
  Result[5].Response := '90955E85CD5B650EBC6BBD4D38DD593AB6A280A3002563B93E';
end;
function PlusNative1Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B30100063F3A9FD5021CC7AA6D4A3D1B59BE86F6C1BF67104DB70B';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := 'B50200112B398F0CEF7805';
  Result[5].Response := '903F8C6E54AB4A6196';
  Result[6].Command := '31020001CFAD4EC39476ED53';
  Result[6].Response := '9053A654A435DE7705E09F137519127ED63F24899933BBAFF1';
  Result[7].Command := '31010001EED82CD11D548F19';
  Result[7].Response := '904D2CFE6D0104169B02D828A4E02D8DA31C07FB18E84F474E';
end;
function PlusNative2Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
  Result[3].Command := 'B7020002004FC00F89220D6158A829FB9ABBD2F9604978A91865B26559';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '31020001CF8B21CA913DC3BB';
  Result[4].Response := '90C682E7657B8E4F29CEFDF10819FEA289A8FF6511A0EE8997';
end;
function PlusNative2Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B701000200063F3A9FD5021CC7AA6D4A3D1B59BE860745B3BC601E0D96';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '31020001CFAD4EC39476ED53';
  Result[5].Response := '9032978C6EFD58A740A4503700504115FBF1FB5639510171B0';
  Result[6].Command := '31010001EED82CD11D548F19';
  Result[6].Response := '90BFCBEE628D9A71F0B4D84A0D0769D229F6CFCF16DAD02DDB';
end;
function PlusNative3Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
  Result[3].Command := 'B9020002004FC00F89220D6158A829FB9ABBD2F960C19FCCBAC657C15B';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '31020001CF8B21CA913DC3BB';
  Result[4].Response := '90D261AC46687BE8D2E7538A827357A3FD8E9E2EE7C711A108';
end;
function PlusNative3Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B901000200063F3A9FD5021CC7AA6D4A3D1B59BE869866A0835EA63126';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '31020001CFAD4EC39476ED53';
  Result[5].Response := '905CB39122DE612C8967F093712271D0366C0BD5D749174226';
  Result[6].Command := '31010001EED82CD11D548F19';
  Result[6].Response := '90BFCBEE628D9A71F0B4D84A0D0769D229F6CFCF16DAD02DDB';
end;
function PlusNative4Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
end;
function PlusNative4Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'C301005469F7B3009E64F2';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := 'B50200112B398F0CEF7805';
  Result[5].Response := '903F8C6E54AB4A6196';
  Result[6].Command := '31020001CFAD4EC39476ED53';
  Result[6].Response := '904632B75ADCDC37FA4E2C4659737A600CE991A6FB93052144';
  Result[7].Command := '31010001EED82CD11D548F19';
  Result[7].Response := '904D2CFE6D0104169B02D828A4E02D8DA31C07FB18E84F474E';
end;
function PlusNative4KIncrement: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31800001A9B5529816B9639C';
  Result[2].Response := '903D5A3DA07BACCC82807A2829339094A083733EEDE5DD7F8A';
  Result[3].Command := '31810001FC6FFA5540A2E090';
  Result[3].Response := '9005F5E56BBE5A2FEE18DE5D9D0E6CA4528CB0988647C79CA7';
  Result[4].Command := 'B78000810036ED82193E74D473DB247091AD153714E0B4B0A12BAB83ED';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '318100012E607DC4A0B52C92';
  Result[5].Response := '907C88A0DACD7BE51117479D7E26078C3BE7B7DE139D5AE275';
  Result[6].Command := '31800001B706F65869502F10';
  Result[6].Response := '90660CB2005C50CD1597897585488F79EA4A2CB736948B1141';
end;
function PlusNative4KDecrement: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31800001A9B5529816B9639C';
  Result[2].Response := '90D0BA914791E4521B1D26864BEF200EF88030024118B158B6';
  Result[3].Command := '31810001FC6FFA5540A2E090';
  Result[3].Response := '9005F5E56BBE5A2FEE18DE5D9D0E6CA4528CB0988647C79CA7';
  Result[4].Command := 'B98000810036ED82193E74D473DB247091AD1537140D084A36CC2A54BE';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '318100012E607DC4A0B52C92';
  Result[5].Response := '90D1A174BCD2CA507CB19FBABA9987FEA90B59077C1D9A30D7';
  Result[6].Command := '31800001B706F65869502F10';
  Result[6].Response := '90FAB9192FE548A003A2FC735CE264611A7AE810C5ADABCAD4';
end;
function PlusNativeBadTarget: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B701000200063F3A9FD5021CC7AA6D4A3D1B59BE860745B3BC601E0D96';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '31020001CFAD4EC39476ED53';
  Result[5].Response := '90C682E7657B8E4F29CEFDF10819FEA289A740C82354AE1B7E';
  Result[6].Command := '31010001EED82CD11D548F19';
  Result[6].Response := '90BFCBEE628D9A71F0B4D84A0D0769D229F6CFCF16DAD02DDB';
end;
function PlusNativeBadSource: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B701000200063F3A9FD5021CC7AA6D4A3D1B59BE860745B3BC601E0D96';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '31020001CFAD4EC39476ED53';
  Result[5].Response := '9032978C6EFD58A740A4503700504115FBF1FB5639510171B0';
  Result[6].Command := '31010001EED82CD11D548F19';
  Result[6].Response := '90AC2FA85C6696172DCEEBE79B4F50D7620B2CAA4D8B010C8D';
end;
function DfIsoDirectory: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906D000008664B64207BDFFE8900';
  Result[4].Response := '02000000E24F4C4491AF';
  Result[5].Command := '90AF000000';
  Result[5].Response := '56341205E1D27600008501010091AF';
  Result[6].Command := '90AF000000';
  Result[6].Response := '03000002E26162636465666768696A6B6C6D6E6F70B52558F18278A6A99100';
end;
function DfIsoCreateApplication: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA0000175634120FA305E1D276000085010100E92D702F899994E100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341205E1D27600008501010059A53775212989EA9100';
end;
function DfIsoFileIds: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '9061000008E1540C530D81F4BE00';
  Result[4].Response := '03E104E1E5FC3D8F5E8EE1179100';
end;
function DfIsoCreateFile0: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0FA34CD9CE33F77CF9D79100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0FA35E414E3F513D2E4D9100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9061000008165FB4AF4A3F91A600';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90CD0000110004E103000004000005538B74CE5657FF00';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '000300000400002F03BE66DED156B69100';
  Result[9].Command := '9061000008A7403968204984B500';
  Result[9].Response := '04E1F906E276FE3F27D69100';
end;
function DfIsoCreateFile1: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0FA34CD9CE33F77CF9D79100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0FA35E414E3F513D2E4D9100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9061000008165FB4AF4A3F91A600';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90CB0000110004E1030000040000D84D78D7FA0A5E8E00';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '01030000040000DAF94F8106BE32629100';
  Result[9].Command := '9061000008A7403968204984B500';
  Result[9].Response := '04E1F906E276FE3F27D69100';
end;
function DfIsoCreateFile3: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0FA34CD9CE33F77CF9D79100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0FA35E414E3F513D2E4D9100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9061000008165FB4AF4A3F91A600';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90C10000140004E10300000400000200005A9CAF1DCD5EFB0900';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '030300000400000200000000009290F963DC6913239100';
  Result[9].Command := '9061000008A7403968204984B500';
  Result[9].Response := '04E1F906E276FE3F27D69100';
end;
function DfIsoCreateFile4: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0FA34CD9CE33F77CF9D79100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0FA35E414E3F513D2E4D9100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9061000008165FB4AF4A3F91A600';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90C00000140004E10300000400000200000EC4F9A0EE54125700';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '0403000004000002000000000025A1E0BEDD3AB05A9100';
  Result[9].Command := '9061000008A7403968204984B500';
  Result[9].Response := '04E1F906E276FE3F27D69100';
end;
function DfMultiSettings: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0083F0FF040000010F00DDE94042D3EE0D079100';
end;
function DfMultiChange: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '0003F0FF040000830DD90CD2E63EBF9100';
  Result[6].Command := '905F00001900E4F92DC9DBE9A01DC76F6B5A334E6B9F7BCA03CF57CAE2C300';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0083F0FF040000010F00A40C259BF35B21AB9100';
end;
function DfMultiRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0083F0FF040000010F00DDE94042D3EE0D079100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90AD00000F0000000004000011602F58CE31EBE800';
  Result[6].Response := 'D75908CD81A37C2ABAF06B548E8F56B606C63163B5690ECF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0083F0FF040000010F00A40C259BF35B21AB9100';
end;
function DfMultiWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0083F0FF040000010F00DDE94042D3EE0D079100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90AD00000F0000000004000011602F58CE31EBE800';
  Result[6].Response := 'D75908CD81A37C2ABAF06B548E8F56B606C63163B5690ECF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0083F0FF040000010F00A40C259BF35B21AB9100';
  Result[8].Command := '908D00001F00000000040000852C874E29DEF102F3768072C74E5125B4FEA9D3F44EF4EC00';
  Result[8].Response := 'E03FB3C38F9C73D19100';
  Result[9].Command := '90AD00000F00000000040000CFF4603C6C93976D00';
  Result[9].Response := '6C0BE84E012C7D96451BE0C0F041E90CD12844ECEBE31CBA9100';
  Result[10].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[10].Response := '0083F0FF040000010F00B20778C44F9A8EB39100';
end;
function DfTmacCreate: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '90CE00002D0100F0EF02EA04D5506B2B2EB33D6000E3E69C603273BD4C5087D081C7BB52D66F782CFBBDD4F65DC67F5408BF00';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90F50000090107A6CE993490A06700';
  Result[7].Response := '0500F0EF02349288E7CCF0F545359100';
end;
function DfTmacSettings: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0500F0EF023420CF7179D98267169100';
end;
function DfTmacRecord: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0500F0EF023420CF7179D98267169100';
  Result[5].Command := '90AD000007010000000C000000';
  Result[5].Response := 'FFFFFFFF11223344556677889100';
  Result[6].Command := '90F50000090156AAD283BC66223200';
  Result[6].Response := '0500F0EF02341D4DD36D81A35A149100';
end;
function DfTmacWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '908D00001F00000000040000FF45F7B48A16322A2176FB5A3196D3293911A4A8CC4484DB00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90F500000901B9543631F9571ADD00';
  Result[11].Response := '0500F0EF0234D77B7DD11D2F3DCA9100';
  Result[12].Command := '90C7000009010A7D06B4709406E400';
  Result[12].Response := '010000007A75C6BA5C12A26BAF0F1CCBC58EB56B9100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0103000004000038C3501A59A21B369100';
  Result[14].Command := '90AD00000F00000000040000A28345832D404ACA00';
  Result[14].Response := '1F564073D7AF62E107760B0306C044C367B8E805C5B9C6FD9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '01030000040000153E4ED0D7BC3B7B9100';
end;
function DfTmacRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '90F500000901BD9E1EE3DAE270A200';
  Result[10].Response := '0500F0EF0234FEA7D038B648C7B99100';
  Result[11].Command := '90C7000009017DBEC65F62F8F97800';
  Result[11].Response := '0100000003A31C0E3D32DD3FBDD300DF526C488A9100';
end;
function DfTmacAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '90A700000869B342C10F4E007000';
  Result[10].Response := 'DCF5C762E10055089100';
end;
function DfTmacReaderWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '050000EF023477FCE7F83BE464F59100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F4AEB360EBDBED01E00';
  Result[7].Response := '214B55834A24B4DC523EC09CE230C9E8A57FB137213D8A189100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '01030000040000DAF94F8106BE32629100';
  Result[9].Command := '90AD00000F00000000040000CFF4603C6C93976D00';
  Result[9].Response := '47C8539101B50B2A4147E45DC7898E9302CACAD84D3844E99100';
  Result[10].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[10].Response := '01030000040000BBD67F7D09FFA0459100';
  Result[11].Command := '908D00001F00000000040000A0A61C830A4BCB5EAB8557573B2A737BBD93F21079A31CCF00';
  Result[11].Response := '0ACE7A1CA867FB5D9100';
  Result[12].Command := '90F500000901D5EB2C680B27291D00';
  Result[12].Response := '050000EF02345419BD6CEB8D16A09100';
  Result[13].Command := '90C7000009012771B5EEAC8707FC00';
  Result[13].Response := '010000008A84BE4B5EF84B691E801FDE8344EB3F9100';
  Result[14].Command := '90F5000009002015F8825CE1C7FB00';
  Result[14].Response := '01030000040000A8C22CB30570BC6D9100';
  Result[15].Command := '90AD00000F0000000004000064008CFA2407E7D900';
  Result[15].Response := '450EDEEE51E6276F1DBD4F95B59A4E65A418B009637ADFD49100';
  Result[16].Command := '90F500000900DA36FB6C287E16A900';
  Result[16].Response := '01030000040000A551C17DEE3C83059100';
end;
function DfTmacReaderRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '050000EF023477FCE7F83BE464F59100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F4AEB360EBDBED01E00';
  Result[7].Response := '214B55834A24B4DC523EC09CE230C9E8A57FB137213D8A189100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '01030000040000DAF94F8106BE32629100';
  Result[9].Command := '90AD00000F00000000040000CFF4603C6C93976D00';
  Result[9].Response := '47C8539101B50B2A4147E45DC7898E9302CACAD84D3844E99100';
  Result[10].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[10].Response := '01030000040000BBD67F7D09FFA0459100';
  Result[11].Command := '90F500000901B9543631F9571ADD00';
  Result[11].Response := '050000EF0234E53D780A6654F4039100';
  Result[12].Command := '90C7000009010A7D06B4709406E400';
  Result[12].Response := '010000001E4BE138CFA127FF3AAB02311881A85A9100';
end;
function DfTmacReaderAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '050000EF023477FCE7F83BE464F59100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F4AEB360EBDBED01E00';
  Result[7].Response := '214B55834A24B4DC523EC09CE230C9E8A57FB137213D8A189100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '01030000040000DAF94F8106BE32629100';
  Result[9].Command := '90AD00000F00000000040000CFF4603C6C93976D00';
  Result[9].Response := '47C8539101B50B2A4147E45DC7898E9302CACAD84D3844E99100';
  Result[10].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[10].Response := '01030000040000BBD67F7D09FFA0459100';
  Result[11].Command := '90A7000008B09FF675403D9FBC00';
  Result[11].Response := '0ACE7A1CA867FB5D9100';
end;
function DfTmacBadMac: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '908D00001F00000000040000FF45F7B48A16322A2176FB5A3196D3293911A4A8CC4484DB00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90F500000901B9543631F9571ADD00';
  Result[11].Response := '0500F0EF0234D77B7DD11D2F3DCA9100';
  Result[12].Command := '90C7000009010A7D06B4709406E400';
  Result[12].Response := '010000007B75C6BA5C12A26B5945096FF86551CD9100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0103000004000038C3501A59A21B369100';
  Result[14].Command := '90AD00000F00000000040000A28345832D404ACA00';
  Result[14].Response := '1F564073D7AF62E107760B0306C044C367B8E805C5B9C6FD9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '01030000040000153E4ED0D7BC3B7B9100';
end;
function DfTmacBadCounter: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '908D00001F00000000040000FF45F7B48A16322A2176FB5A3196D3293911A4A8CC4484DB00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90F500000901B9543631F9571ADD00';
  Result[11].Response := '0500F0EF0234D77B7DD11D2F3DCA9100';
  Result[12].Command := '90C7000009010A7D06B4709406E400';
  Result[12].Response := '020000007A75C6BA5C12A26B6F7FCF8E652A4F5E9100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0103000004000038C3501A59A21B369100';
  Result[14].Command := '90AD00000F00000000040000A28345832D404ACA00';
  Result[14].Response := '1F564073D7AF62E107760B0306C044C367B8E805C5B9C6FD9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '01030000040000153E4ED0D7BC3B7B9100';
end;
function DfTmacCrypto: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '5A000100800100000004112233445566';
  Result[0].Response := '104FEBF2F6929C6A5A02D798D113F8FD';
  Result[1].Command := 'A5000100800100000004112233445566';
  Result[1].Response := '00B477D3F23DA9C3A93EBA9AD07B05C8';
  Result[2].Command := 'AD000000000400000000000000000000010203040000000000000000000000008D000000000400000000000000000000AABBCCDD000000000000000000000000';
  Result[2].Response := '7A75C6BA5C12A26B';
  Result[3].Command := '102132435465768798A9BACBDCEDFE0F';
  Result[3].Response := 'B1C4F20D1FF15A5B4180AC116D2D8957';
end;
function DfTmacRecordMac: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0501F0EF0234B0F60D59C16C79519100';
  Result[5].Command := '90AD00000F010000000C000026256C8EC1719FE300';
  Result[5].Response := '010000001122334455667788E15E3F2C1E76B86D9100';
  Result[6].Command := '90F50000090156AAD283BC66223200';
  Result[6].Response := '0501F0EF0234659598FF75EB3E2A9100';
end;
function DfTmacRecordFull: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0503F0EF02349BC69A6228FB102E9100';
  Result[5].Command := '90AD00000F010000000C000026256C8EC1719FE300';
  Result[5].Response := 'E1F5150FF050C93281F749D7F2188ED47E3AB52ADF8AF1119100';
  Result[6].Command := '90F50000090156AAD283BC66223200';
  Result[6].Response := '0503F0EF0234E9E123BE3118D89A9100';
end;
function DfTmacLimitChange: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '905F0000190180B7A8E7E0C17635835E3C5C0DA7F444CE4346C4DF57324E00';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90F50000090107A6CE993490A06700';
  Result[7].Response := '0533F0EF0234E803000006BDD70FBF1666A59100';
end;
function DfTmacDelete: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0500F0EF023420CF7179D98267169100';
  Result[5].Command := '90DF00000901968AC3F3ECD3858B00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '906F0000089588797C6DB9E6F300';
  Result[6].Response := '00EB0AA364DA638D069100';
end;
function DfMultiNonMasterRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002010000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0B93010102100040D9E2E071BE0DB89100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0083F0FF040000011F11D97F68358B0C03639100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0B930101021000880A9C6A5B51EC0E9100';
  Result[6].Command := '90AD00000F0000000004000011602F58CE31EBE800';
  Result[6].Response := 'D75908CD81A37C2ABAF06B548E8F56B606C63163B5690ECF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0083F0FF040000011F117C4D7ADEED961ACA9100';
end;
function DfIsoCreateKeySets: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA00001C5634120FB3012104100105E1D276000085010100FF73DD831363351100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341205E1D27600008501010059A53775212989EA9100';
  Result[9].Command := '905A00000356341200';
  Result[9].Response := '9100';
  Result[10].Command := '9045000000';
  Result[10].Response := '0FB301210410019100';
  Result[11].Command := '905A00000300000000';
  Result[11].Response := '9100';
  Result[12].Command := '9071000002000000';
  Result[12].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[13].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[13].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[14].Command := '90450000085888703EC1CC8E6D00';
  Result[14].Response := '0F813A00CA07FE8B45CB9100';
  Result[15].Command := '906D000008664B64207BDFFE8900';
  Result[15].Response := '02000000E24F4C4491AF';
  Result[16].Command := '90AF000000';
  Result[16].Response := '56341205E1D2760000850101002DF92EA32F22A5B69100';
end;
function DfIsoCreateBadGeometry: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA00001C5634120FB3012104100105E1D276000085010100FF73DD831363351100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341205E1D27600008501010059A53775212989EA9100';
  Result[9].Command := '905A00000356341200';
  Result[9].Response := '9100';
  Result[10].Command := '9045000000';
  Result[10].Response := '0FB301200410019100';
  Result[11].Command := '905A00000300000000';
  Result[11].Response := '9100';
  Result[12].Command := '9071000002000000';
  Result[12].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[13].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[13].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[14].Command := '90450000085888703EC1CC8E6D00';
  Result[14].Response := '0F813A00CA07FE8B45CB9100';
  Result[15].Command := '906D000008664B64207BDFFE8900';
  Result[15].Response := '02000000E24F4C4491AF';
  Result[16].Command := '90AF000000';
  Result[16].Response := '56341205E1D2760000850101002DF92EA32F22A5B69100';
end;
function DfIsoCreateBadFid: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA00001C5634120FB3012104100105E1D276000085010100FF73DD831363351100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341204E1D2760000850101004703A53523AC26E69100';
  Result[9].Command := '905A00000356341200';
  Result[9].Response := '9100';
  Result[10].Command := '9045000000';
  Result[10].Response := '0FB301210410019100';
  Result[11].Command := '905A00000300000000';
  Result[11].Response := '9100';
  Result[12].Command := '9071000002000000';
  Result[12].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[13].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[13].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[14].Command := '90450000085888703EC1CC8E6D00';
  Result[14].Response := '0F813A00CA07FE8B45CB9100';
  Result[15].Command := '906D000008664B64207BDFFE8900';
  Result[15].Response := '02000000E24F4C4491AF';
  Result[16].Command := '90AF000000';
  Result[16].Response := '56341205E1D2760000850101002DF92EA32F22A5B69100';
end;
function DfIsoCreateBadName: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA00001C5634120FB3012104100105E1D276000085010100FF73DD831363351100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341205E1D376000085010100E9EAC91D560BAE6A9100';
  Result[9].Command := '905A00000356341200';
  Result[9].Response := '9100';
  Result[10].Command := '9045000000';
  Result[10].Response := '0FB301210410019100';
  Result[11].Command := '905A00000300000000';
  Result[11].Response := '9100';
  Result[12].Command := '9071000002000000';
  Result[12].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[13].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[13].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[14].Command := '90450000085888703EC1CC8E6D00';
  Result[14].Response := '0F813A00CA07FE8B45CB9100';
  Result[15].Command := '906D000008664B64207BDFFE8900';
  Result[15].Response := '02000000E24F4C4491AF';
  Result[16].Command := '90AF000000';
  Result[16].Response := '56341205E1D2760000850101002DF92EA32F22A5B69100';
end;
function DfTmacStandardWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,18);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F500000901A709321D9022932200';
  Result[13].Response := '0500F0EF0234A3DBCA3E22B5233C9100';
  Result[14].Command := '90C70000090171635D463985581800';
  Result[14].Response := '01000000CE8C4411FEE732D2D9096F5EEDB8C4189100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '90AD00000F00020000040000C9DEE8F8FD07B69600';
  Result[16].Response := 'FAB3D8354D83280EE86B297CFDCCADFA46DF6CA8F977BF859100';
  Result[17].Command := '90F5000009006BF71ECCD1FEC69100';
  Result[17].Response := '00030000080000B99999740B9C34809100';
end;
function DfTmacStandardOverlap: TExtendedPairs;
begin
  Result := nil; SetLength(Result,27);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0003000008000009799F67A5AB9DDC9100';
  Result[14].Command := '90AD00000F00030000020000DCC4523C6916678A00';
  Result[14].Response := 'BD4DEC5E571DBA1A7A89845B10AB8236E4E7F3894D753DC19100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '908D00001F0003000002000065EE0304668328A539ED0A42B543201AE42E4EEAFF43B05100';
  Result[16].Response := '72256E5ADC44636D9100';
  Result[17].Command := '90AD00000F00030000020000306F06F3A5DCDC0B00';
  Result[17].Response := 'EAAA37773469441C1EC6A3A9E095D27FFC8835CD86F598B49100';
  Result[18].Command := '90F50000090010834270A478EF8500';
  Result[18].Response := '00030000080000602B9405BB3154AA9100';
  Result[19].Command := '90F500000901655F0EBCF1EA180F00';
  Result[19].Response := '0500F0EF02340084EEA36F021E699100';
  Result[20].Command := '90C700000901EB1C5F898013DB1900';
  Result[20].Response := '01000000E9DA5EC82619B00468DB1AB3F97EFE2F9100';
  Result[21].Command := '90F500000900011382CCAE703DCF00';
  Result[21].Response := '00030000080000F0679ABCF03A86429100';
  Result[22].Command := '90AD00000F0002000004000032C8999A513BFC0500';
  Result[22].Response := '2B10D933910777531943F5E2712A74440D92B55ED8340F0D9100';
  Result[23].Command := '90F500000900C248A61FEC03E17600';
  Result[23].Response := '00030000080000E7F12B709606961E9100';
  Result[24].Command := '90F500000900E6EE352662BBC37A00';
  Result[24].Response := '000300000800006EB861AEE02D8E9E9100';
  Result[25].Command := '90AD00000F0003000002000099CD883367F711EF00';
  Result[25].Response := '14C817A55A7FF6751D4D2A9CA439B0952A207B0647A0AF609100';
  Result[26].Command := '90F500000900C7DA9ECA18EA8CEC00';
  Result[26].Response := '00030000080000723359DBCF3CA9D29100';
end;
function DfTmacStandardDisjoint: TExtendedPairs;
begin
  Result := nil; SetLength(Result,27);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F000000000200006E5CC666AFC62D3500';
  Result[8].Response := '66F60A7B98F8128DCB317DDD3C3029B6F7B15C74293945389100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F0000000002000085F65EFB8667F132955DB617C0AE1B59381FAE06FAC0A32D00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F000000000200005022A9C2FEA1C4F200';
  Result[11].Response := 'FDEA37AA0F53D030A618660D1B743EE4AC9BC364F2FA6FDA9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0003000008000009799F67A5AB9DDC9100';
  Result[14].Command := '90AD00000F00060000020000999F35A78F2D771A00';
  Result[14].Response := '1CE929F9A6C95239343D5F2FFE2CAF115A3681A2D8B07E3F9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '908D00001F000600000200005C0EBADDCAF7885F0EB327823F86B804CB3DF5B3C261705500';
  Result[16].Response := '72256E5ADC44636D9100';
  Result[17].Command := '90AD00000F00060000020000D4D15B6D5BD5E2D100';
  Result[17].Response := '3B4DE5D33A80D161337B16CC0EB6C1DBDCAD4E7276CF1F2D9100';
  Result[18].Command := '90F50000090010834270A478EF8500';
  Result[18].Response := '00030000080000602B9405BB3154AA9100';
  Result[19].Command := '90F500000901655F0EBCF1EA180F00';
  Result[19].Response := '0500F0EF02340084EEA36F021E699100';
  Result[20].Command := '90C700000901EB1C5F898013DB1900';
  Result[20].Response := '01000000081FE2E81BC103EF732DC4CBC8F765219100';
  Result[21].Command := '90F500000900011382CCAE703DCF00';
  Result[21].Response := '00030000080000F0679ABCF03A86429100';
  Result[22].Command := '90AD00000F000000000200001DC73049277C208B00';
  Result[22].Response := 'E91A50090C0EC00DD3D29E27CABF5E32CC12F484F4C96D279100';
  Result[23].Command := '90F500000900C248A61FEC03E17600';
  Result[23].Response := '00030000080000E7F12B709606961E9100';
  Result[24].Command := '90F500000900E6EE352662BBC37A00';
  Result[24].Response := '000300000800006EB861AEE02D8E9E9100';
  Result[25].Command := '90AD00000F000600000200008ADF83580BA4F5AB00';
  Result[25].Response := 'CF57C7BBBF3CC6DEF98D748644A4CBC4AF15399B57E8D31B9100';
  Result[26].Command := '90F500000900C7DA9ECA18EA8CEC00';
  Result[26].Response := '00030000080000723359DBCF3CA9D29100';
end;
function DfTmacStandardNoop: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '90F500000901BD9E1EE3DAE270A200';
  Result[10].Response := '0500F0EF0234FEA7D038B648C7B99100';
  Result[11].Command := '90C7000009017DBEC65F62F8F97800';
  Result[11].Response := '010000004B76CE5D0DCD3B0FAF23C8CD2FAF042C9100';
end;
function DfTmacStandardAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,14);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90A7000008A67C6ACD1805183700';
  Result[13].Response := 'F45ECAB117B00EE09100';
end;
function DfTmacStandardRepeat: TExtendedPairs;
begin
  Result := nil; SetLength(Result,27);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0003000008000009799F67A5AB9DDC9100';
  Result[14].Command := '90AD00000F0002000004000098F01F2E3955B56700';
  Result[14].Response := '1F564073D7AF62E107760B0306C044C367B8E805C5B9C6FD9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '908D00001F000200000400004EB9D24CF6819DF3DD0B72F1269D3732FDAD4948ABA9D77500';
  Result[16].Response := '72256E5ADC44636D9100';
  Result[17].Command := '90AD00000F00020000040000DDC9E0F3489A885500';
  Result[17].Response := 'CCDAE2032BC1D2B351CD0DF8C5FAE4DC86696E11BD27F4059100';
  Result[18].Command := '90F50000090010834270A478EF8500';
  Result[18].Response := '00030000080000602B9405BB3154AA9100';
  Result[19].Command := '90F500000901655F0EBCF1EA180F00';
  Result[19].Response := '0500F0EF02340084EEA36F021E699100';
  Result[20].Command := '90C700000901EB1C5F898013DB1900';
  Result[20].Response := '0100000028A4C4706990BA79875AF4D425A116FC9100';
  Result[21].Command := '90F500000900011382CCAE703DCF00';
  Result[21].Response := '00030000080000F0679ABCF03A86429100';
  Result[22].Command := '90AD00000F0002000004000032C8999A513BFC0500';
  Result[22].Response := '644039ABD05137D4B6858618356D8C70226569713E8828119100';
  Result[23].Command := '90F500000900C248A61FEC03E17600';
  Result[23].Response := '00030000080000E7F12B709606961E9100';
  Result[24].Command := '90F500000900E6EE352662BBC37A00';
  Result[24].Response := '000300000800006EB861AEE02D8E9E9100';
  Result[25].Command := '90AD00000F00020000040000E20079BC694DD3C200';
  Result[25].Response := '372D0AE0D54EBF6F2AE670645F97E8C42AE22F6009D8BBDC9100';
  Result[26].Command := '90F500000900C7DA9ECA18EA8CEC00';
  Result[26].Response := '00030000080000723359DBCF3CA9D29100';
end;
function DfTmacStandardPreimage: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
end;
function DfTmacStandardImmediateMismatch: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '060FF812981C8D16CBBD9929177A027687BC0E1C1464A0559100';
end;
function DfTmacStandardCommitMismatch: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F500000901A709321D9022932200';
  Result[13].Response := '0500F0EF0234A3DBCA3E22B5233C9100';
  Result[14].Command := '90C70000090171635D463985581800';
  Result[14].Response := '01000000CE8C4411FEE732D2D9096F5EEDB8C4189100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '90AD00000F00020000040000C9DEE8F8FD07B69600';
  Result[16].Response := '92B839A2D94255534714467D1E5BA18AE0DF206241D1D8369100';
end;
function DfTmacStandardDeniedWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0003F00F080000559E30FA720FBA4D9100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0003F00F0800001A9BD622459E11569100';
end;
function DfTmacStandardDeniedRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0003F0F0080000B787B9185CE391709100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0003F0F008000077945004613DBFF79100';
end;
function DfTmacStandardWrongFile: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '01030000080000C01AC4857CB7DA999100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '01030000080000FE734FDB6FA97D669100';
end;
function DfTmacStandardBounds: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
end;
function DfSdmAccessRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00C000E0000100010101C1F1212000004300004300007ABC852994CFEB699100';
end;
function DfSdmAccessEnable: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '000000E00001003390D847A31DE2F09100';
  Result[7].Command := '905F000029003DA10E5DEA15D04B6FE9D691CF6B5B473F8114300B6221FC0EB0FF1613256C2197AF1093EA22501700';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '00C000E0000100010101C1F121200000430000430000AA2DBBED01DB7B1C9100';
end;
function DfSdmAccessDisableSdm: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '00C000E0000100010101C1F12120000043000043000051F5386BD59458539100';
  Result[7].Command := '905F000019003B3A7A8F90BD3B413A05305C12C75803E0D39778518FF38A00';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '008000E000010001010180B28AD513E9EB8A9100';
end;
function DfSdmAccessRemoveRights: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '00C000E0000100010101C1F12120000043000043000051F5386BD59458539100';
  Result[7].Command := '905F00001900B37EACAA3C416D211BC06D4A54607718460988B3AD515F7D00';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '004000E0000100C1F121200000430000430000DDE9D8590CAEF0289100';
end;
function DfSdmAccessRemoveBoth: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '00C000E0000100010101C1F12120000043000043000051F5386BD59458539100';
  Result[7].Command := '905F00001900418ECEC4D4DC2564F3368EFCB447E17B070EBD1D2429F9BB00';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '000000E000010093AE9C19F84078C69100';
end;
function DfSdmAccessNoop: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '00C000E0000100010101C1F12120000043000043000051F5386BD59458539100';
end;
function DfSdmAccessBadPreimage: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '00C000E0000100010101C1F12120000043000043000051F5386BD59458539100';
end;
function DfSdmAccessBadPostimage: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '000000E00001003390D847A31DE2F09100';
  Result[7].Command := '905F000029003DA10E5DEA15D04B6FE9D691CF6B5B473F8114300B6221FC0EB0FF1613256C2197AF1093EA22501700';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '00C000E0000100010202C1F1212000004300004300000DAE9BB11E402AB99100';
end;
function DfRecordWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,14);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90BA00003000010000000000100000B2A339D7464EF5B3D270D296D7AF1E3C82F60C562829BA5752724B474F2BC4FFF4960C33709300';
  Result[8].Response := '91AF';
  Result[9].Command := '90AF000002738E00';
  Result[9].Response := 'E03FB3C38F9C73D19100';
  Result[10].Command := '90C7000009004613A9713E755A8300';
  Result[10].Response := 'F4D4C94B9F3EB5119100';
  Result[11].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[11].Response := '0403000010000004000002000043EEA78C98274C3C9100';
  Result[12].Command := '90AB00000F00000000020000540C15BA9DFF0A5900';
  Result[12].Response := '5E0190AF11642DD5AC52BDD3C66BDB60FB05F7666CCEB1ECA9930754A19ECD2E3BB9C3DEE09EFABEA6D2EFE3935564586EA82735C2DC9F529100';
  Result[13].Command := '90F50000090008B058DF21788E4A00';
  Result[13].Response := '040300001000000400000200004E9BEDEC9A54F8B99100';
end;
function DfRecordRepeat: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90BA00003000010000000000100000B2A339D7464EF5B3D270D296D7AF1E3C82F60C562829BA5752724B474F2BC4FFF4960C33709300';
  Result[8].Response := '91AF';
  Result[9].Command := '90AF000002738E00';
  Result[9].Response := 'E03FB3C38F9C73D19100';
  Result[10].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[10].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[11].Command := '90BA00003000010000000000100000C3731FEC88D72B10A30D6F0B3A01C77FE785E9A577BABA52D4281D96FA6EB6FB295702339C7600';
  Result[11].Response := '91AF';
  Result[12].Command := '90AF000002542400';
  Result[12].Response := 'DCF5C762E10055089100';
  Result[13].Command := '90C70000090010FB1A72D54B14D700';
  Result[13].Response := '0ACE7A1CA867FB5D9100';
  Result[14].Command := '90F50000090008B058DF21788E4A00';
  Result[14].Response := '040300001000000400000200004E9BEDEC9A54F8B99100';
  Result[15].Command := '90AB00000F00000000020000D87D9493D4F7592C00';
  Result[15].Response := 'B7510CB2FC287C4CDB93869694B9F6343C39E09431CB098BFA9FF972D167587836DC89865E72D1ADCE766C31F1490AA9AD60E30A6BFF2E4A9100';
  Result[16].Command := '90F5000009002015F8825CE1C7FB00';
  Result[16].Response := '04030000100000040000020000D344EE34284AC9E89100';
end;
function DfRecordAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90BA00003000010000000000100000B2A339D7464EF5B3D270D296D7AF1E3C82F60C562829BA5752724B474F2BC4FFF4960C33709300';
  Result[8].Response := '91AF';
  Result[9].Command := '90AF000002738E00';
  Result[9].Response := 'E03FB3C38F9C73D19100';
  Result[10].Command := '90A7000008D08F5ABDB4B8EFE600';
  Result[10].Response := 'F4D4C94B9F3EB5119100';
end;
function DfRecordNoop: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
end;
function DfRecordPreimage: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
end;
function DfRecordAppendConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90BA00003000010000000000100000B2A339D7464EF5B3D270D296D7AF1E3C82F60C562829BA5752724B474F2BC4FFF4960C33709300';
  Result[8].Response := '91AF';
  Result[9].Command := '90AF000002738E00';
  Result[9].Response := 'E03FB3C38F9C73D19100';
  Result[10].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[10].Response := '0403000010000004000002000065E84A1CD23671BC9100';
end;
function DfRecordClearConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90BA00003000010000000000100000B2A339D7464EF5B3D270D296D7AF1E3C82F60C562829BA5752724B474F2BC4FFF4960C33709300';
  Result[8].Response := '91AF';
  Result[9].Command := '90AF000002738E00';
  Result[9].Response := 'E03FB3C38F9C73D19100';
  Result[10].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[10].Response := '0403000010000004000002000065E84A1CD23671BC9100';
end;
function DfRecordDifferentConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90BA00003000010000000000100000B2A339D7464EF5B3D270D296D7AF1E3C82F60C562829BA5752724B474F2BC4FFF4960C33709300';
  Result[8].Response := '91AF';
  Result[9].Command := '90AF000002738E00';
  Result[9].Response := 'E03FB3C38F9C73D19100';
  Result[10].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[10].Response := '0403000010000004000002000065E84A1CD23671BC9100';
end;
function DfRecordWrongCommit: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90BA00003000010000000000100000B2A339D7464EF5B3D270D296D7AF1E3C82F60C562829BA5752724B474F2BC4FFF4960C33709300';
  Result[8].Response := '91AF';
  Result[9].Command := '90AF000002738E00';
  Result[9].Response := 'E03FB3C38F9C73D19100';
  Result[10].Command := '90C7000009004613A9713E755A8300';
  Result[10].Response := 'F4D4C94B9F3EB5119100';
  Result[11].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[11].Response := '0403000010000004000002000043EEA78C98274C3C9100';
  Result[12].Command := '90AB00000F00000000020000540C15BA9DFF0A5900';
  Result[12].Response := '6CFD1BEF2A53CF890149034BD0E8E3A5D8A7591686A41202FF869060C7E560A50397C33337C5C4F7ECD357C2C683F68FA55D7F34C20E79D19100';
end;
function DfRecordAppendFirstConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '908B00002F00000000100000B2A339D7464EF5B3D270D296D7AF1E3C82F60C562829BA5752724B474F2BC4FF809C8F45D15292B000';
  Result[8].Response := 'E03FB3C38F9C73D19100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
end;
function DfRecordClearFirstConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0056AFD8643363A5A19100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '040300001000000400000200003D92A24DE72AED2E9100';
  Result[6].Command := '90AB00000F000000000200008D92777B1CBA2FE400';
  Result[6].Response := 'A4F738A219D4E43AAE2C7329F2F6ABE6BDF1666096E863549FAD4BF13F32B1F5402C29EB846D2A1042CD55D8270ADB50F82D09A5E80EF6CF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90EB000009002748098FC5EC6F1B00';
  Result[8].Response := 'E03FB3C38F9C73D19100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
end;
function DfRecordTmacWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90BA000030000100000000001000006D3639656961EBFE6801B130B0758AED0857991478780FE724ECD757E866E84307A08B17CF7C00';
  Result[10].Response := '91AF';
  Result[11].Command := '90AF000002F3D500';
  Result[11].Response := 'DCF5C762E10055089100';
  Result[12].Command := '90F500000901B9543631F9571ADD00';
  Result[12].Response := '0500F0EF0234D77B7DD11D2F3DCA9100';
  Result[13].Command := '90C7000009010A7D06B4709406E400';
  Result[13].Response := '01000000A7DE10CA4D189AF04EF46662B01C38229100';
  Result[14].Command := '90F5000009002F375AAD1953B61B00';
  Result[14].Response := '0403000010000004000002000037C575CF7525F5DE9100';
  Result[15].Command := '90AB00000F000000000200005C5F6527965D504300';
  Result[15].Response := '4DD63E87EDDDBF9DD7FDC4D908269616580EFBE7069E6FA94617AC58559A5A7604EF5E4DE8721E2C80E5D05590DA5848CFCE3A7C45C20D329100';
  Result[16].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[16].Response := '0403000010000004000002000029F88EAF6473AB469100';
end;
function DfRecordTmacRepeat: TExtendedPairs;
begin
  Result := nil; SetLength(Result,20);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90BA000030000100000000001000006D3639656961EBFE6801B130B0758AED0857991478780FE724ECD757E866E84307A08B17CF7C00';
  Result[10].Response := '91AF';
  Result[11].Command := '90AF000002F3D500';
  Result[11].Response := 'DCF5C762E10055089100';
  Result[12].Command := '90F5000009007C50E2206F5996C200';
  Result[12].Response := '04030000100000040000020000E780C72A5A9BBFA89100';
  Result[13].Command := '90BA00003000010000000000100000F7A2B26E198AD70FD792E684FDB35FD6D09C47EF89C0F4FF2643DAC7579CE49FC09BA506661300';
  Result[13].Response := '91AF';
  Result[14].Command := '90AF000002199F00';
  Result[14].Response := '90D066756C2BAE6C9100';
  Result[15].Command := '90F500000901A709321D9022932200';
  Result[15].Response := '0500F0EF0234A3DBCA3E22B5233C9100';
  Result[16].Command := '90C70000090171635D463985581800';
  Result[16].Response := '01000000F93D2AB36D39E56FE43D7C5A48B06A8B9100';
  Result[17].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[17].Response := '0403000010000004000002000029F88EAF6473AB469100';
  Result[18].Command := '90AB00000F00000000020000A6BB30110F5BD01100';
  Result[18].Response := 'D09D52DAC62E7B28E67DAEB7C83326B15F6AE05206DD3C8B55107DF8DAC24689013077EAE70D9CBB16C88AA5CB9C7CA5C4DA97590A8264869100';
  Result[19].Command := '90F5000009006BF71ECCD1FEC69100';
  Result[19].Response := '04030000100000040000020000050003D3AA86779F9100';
end;
function DfRecordTmacAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90BA000030000100000000001000006D3639656961EBFE6801B130B0758AED0857991478780FE724ECD757E866E84307A08B17CF7C00';
  Result[10].Response := '91AF';
  Result[11].Command := '90AF000002F3D500';
  Result[11].Response := 'DCF5C762E10055089100';
  Result[12].Command := '90A7000008B09FF675403D9FBC00';
  Result[12].Response := '0ACE7A1CA867FB5D9100';
end;
function DfRecordTmacNoop: TExtendedPairs;
begin
  Result := nil; SetLength(Result,15);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90F500000901BD9E1EE3DAE270A200';
  Result[10].Response := '0500F0EF0234FEA7D038B648C7B99100';
  Result[11].Command := '90C7000009017DBEC65F62F8F97800';
  Result[11].Response := '0100000096013638351452F065CE98BBB9A1791F9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '040300001000000400000200004E9BEDEC9A54F8B99100';
  Result[13].Command := '90AB00000F00000000020000D87D9493D4F7592C00';
  Result[13].Response := 'B7510CB2FC287C4CDB93869694B9F634EA8AE6D810A0E97F537B4DB5B456F68ED5469484EAAE201667C1C805C37D61723ECDBF0BA7E8E2FE9100';
  Result[14].Command := '90F5000009002015F8825CE1C7FB00';
  Result[14].Response := '04030000100000040000020000D344EE34284AC9E89100';
end;
function DfRecordTmacPreimage: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
end;
function DfRecordTmacAppendConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90BA000030000100000000001000006D3639656961EBFE6801B130B0758AED0857991478780FE724ECD757E866E84307A08B17CF7C00';
  Result[10].Response := '91AF';
  Result[11].Command := '90AF000002F3D500';
  Result[11].Response := 'DCF5C762E10055089100';
  Result[12].Command := '90F5000009007C50E2206F5996C200';
  Result[12].Response := '04030000100000040000020000E780C72A5A9BBFA89100';
end;
function DfRecordTmacClearConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90BA000030000100000000001000006D3639656961EBFE6801B130B0758AED0857991478780FE724ECD757E866E84307A08B17CF7C00';
  Result[10].Response := '91AF';
  Result[11].Command := '90AF000002F3D500';
  Result[11].Response := 'DCF5C762E10055089100';
  Result[12].Command := '90F5000009007C50E2206F5996C200';
  Result[12].Response := '04030000100000040000020000E780C72A5A9BBFA89100';
end;
function DfRecordTmacDifferentConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90BA000030000100000000001000006D3639656961EBFE6801B130B0758AED0857991478780FE724ECD757E866E84307A08B17CF7C00';
  Result[10].Response := '91AF';
  Result[11].Command := '90AF000002F3D500';
  Result[11].Response := 'DCF5C762E10055089100';
  Result[12].Command := '90F5000009007C50E2206F5996C200';
  Result[12].Response := '04030000100000040000020000E780C72A5A9BBFA89100';
end;
function DfRecordTmacWrongCommit: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90BA000030000100000000001000006D3639656961EBFE6801B130B0758AED0857991478780FE724ECD757E866E84307A08B17CF7C00';
  Result[10].Response := '91AF';
  Result[11].Command := '90AF000002F3D500';
  Result[11].Response := 'DCF5C762E10055089100';
  Result[12].Command := '90F500000901B9543631F9571ADD00';
  Result[12].Response := '0500F0EF0234D77B7DD11D2F3DCA9100';
  Result[13].Command := '90C7000009010A7D06B4709406E400';
  Result[13].Response := '01000000A7DE10CA4D189AF04EF46662B01C38229100';
  Result[14].Command := '90F5000009002F375AAD1953B61B00';
  Result[14].Response := '0403000010000004000002000037C575CF7525F5DE9100';
  Result[15].Command := '90AB00000F000000000200005C5F6527965D504300';
  Result[15].Response := 'BDB9FAE5CF936BE12BE74B16C10128E1F579FFA0F6F7A3847DE0340CFBA2B76227F01343B9D9D8777F322643F51C6DCA7524B7D22EA3A9DF9100';
end;
function DfRecordTmacAppendFirstConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '908B00002F000000001000006D3639656961EBFE6801B130B0758AED0857991478780FE724ECD757E866E8438CCEB7600760E6BE00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90F5000009007C50E2206F5996C200';
  Result[11].Response := '04030000100000040000020000E780C72A5A9BBFA89100';
end;
function DfRecordTmacClearFirstConflict: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '04030000100000040000020000AF3D60ED17D963C09100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '04030000100000040000020000AE3C71A486F86E5F9100';
  Result[8].Command := '90AB00000F00000000020000A0060CB4F081B95C00';
  Result[8].Response := '9910BF0DCC7E5B12571A00D2AE236E3E9E2439C8B928A8BDCCCB0B139D40E51D282EFF525389E29D2DE685DB468432A04025E90BDE52DC8A9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '0403000010000004000002000065E84A1CD23671BC9100';
  Result[10].Command := '90EB0000090015E4D019BF3B968800';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90F5000009007C50E2206F5996C200';
  Result[11].Response := '04030000100000040000020000E780C72A5A9BBFA89100';
end;
function LrpPublishedEval: TExtendedPairs;
begin
  Result := nil; SetLength(Result,50);
  Result[0].Command := '567826B8DA8E768432A9548DBE4AA3A0020101030509';
  Result[0].Response := '1BA2C0C578996BC497DD181C6885A9DD';
  Result[1].Command := 'B65557CE0E9B4C5886F232200113562B01000B0B040F0C0F02070C09040007060F0705060A0B0003000D';
  Result[1].Response := '6FDFA8D2A6AA8476BF94E71F25637F96';
  Result[2].Command := '88B95581002057A93E421EFE4076338B020107070209090D';
  Result[2].Response := 'E9C04556A214AC3297B83E4BDF46F142';
  Result[3].Command := 'C48A8E8B16571645A1557825AA66AC910301010F000B070C000D0B01020808090C0A0403060C0A0B0B07080B0E04020F09';
  Result[3].Response := '51296B5E6D3B8DB8A1A7399760A19189';
  Result[4].Command := 'CAF3750AFF93F9A0C8861BCCCCDF1A9D0300090207030B07';
  Result[4].Response := '468C2BFCF993E7F112E150C17298A968';
  Result[5].Command := '65024B14AA99E9CA93F51172E19EE00001010802060C0E080A02060D0F0E0706080D0901';
  Result[5].Response := 'A3830865D52EAEBC6471CDBD3DFC0A89';
  Result[6].Command := '1EDB9D253DF18D72BEEAE960B6FDF32503000F0D070B0B0C060C0E0801090F00040A0F000C030904040C090E';
  Result[6].Response := 'B73B50D4BA439DF9D4AFB79FF10F1446';
  Result[7].Command := '08CFACB758EB34F0106D42358F22B5EB01010403010B080F0105050E0B010F02080303040F0200010C0A0D0D07';
  Result[7].Response := '40C01FC5DF4C142D9C9721F74A373BA5';
  Result[8].Command := 'CC57E7503BCCCF260D6B4E2AB38ACE940300040D00090803080D0F0307010F0A0C050D050B0604010E0E0405';
  Result[8].Response := 'C1A465936A097FF76FCAF18166E8DF60';
  Result[9].Command := 'D0E9C3CACE9A747A74F582AA0F873FF902010F0C0B06090006080C08030E06040706050607060F0701080E04010E0205';
  Result[9].Response := 'A944D5A19C5B86392CC3CFC58F57C321';
  Result[10].Command := '59C9C703C66A9FD2948E0A48617285DC00010F02080E0F0F0607020108040606050704040F0D0803050B010006040804';
  Result[10].Response := 'F078390B345FC6E22EE9A75B3D8BF490';
  Result[11].Command := '2E763263979117BED33A331B15E3F01B0300020B09060B0F0F010A080402090C060E';
  Result[11].Response := '9193DA3870AA345EB4FDFB5EE4A35E61';
  Result[12].Command := 'A14E397DA6C410440FA9EC4C617740940001040B04020600000D';
  Result[12].Response := '21C0B442BF41B7DDD80D4A99CD7B7B81';
  Result[13].Command := '921038ED913CCEEFC6286B756F9ABC8D0001090F0E0107010D0C0B040C0A010F070E05';
  Result[13].Response := '9FF1DBB5E8528E56370EB55919642AC0';
  Result[14].Command := 'F2512BC694E7A66D6ED67E0841BA252303010D000F09020A0C030F03030E0C01020C0F050B06050C060E0C0E01020D0E00';
  Result[14].Response := '6271F38386E7399D7FA1709A72B4F585';
  Result[15].Command := '75FCA5E188F44F1E808597A0B7B690D4010106040906020F050D0E0D000406080F01';
  Result[15].Response := 'EBD6F32ED75566E6756A14EC16715CBD';
  Result[16].Command := '1000076C2934BDB02750204704DAA4720201080C030E00';
  Result[16].Response := '581C3B057F9312FECF4A7B8070C83B8C';
  Result[17].Command := '99B1647A76CD170EA07997043E1E791901010F';
  Result[17].Response := 'BA5F895E8B57F7753EE5C7276E60B37F';
  Result[18].Command := '6983FC665FBB8BEA35DADBB2EF44665601010B0D0F00090801080B000A070A0F0F0F090C08';
  Result[18].Response := 'E0A4144033A1CACD1DBCE30F9883A1DB';
  Result[19].Command := '9FBC2045FA6215B4FD1ABA412DD9C59D01010F090B07020301000B0D0A0E0008060C05010D0305040B06050F010F00050F01';
  Result[19].Response := '3F410411D5ED704572D06EDE6AB45CA2';
  Result[20].Command := '1EBB6DF4E251A10B9503AE6B3EEB0ACA03000C0D0D06080E0F0F0701030C08';
  Result[20].Response := '28740D45D92737D6CF8F05D05B961424';
  Result[21].Command := '415F46BA9A3C3C44A7E178211766810502000509000001020E08040A0E0C07';
  Result[21].Response := '9852EFC35E53F2A4E8DA55770123C99D';
  Result[22].Command := '371A061E4A3065D00F41C4DA68722FFA030005020C07080A0607050408080D';
  Result[22].Response := 'FD2BDCC3EA26AF2069A4C536E3D6B33B';
  Result[23].Command := 'E28DFE591559441D04213D889747BC4602010401040E04020E07';
  Result[23].Response := '5E8BF483C2D6DA906EC58D1B63AC9887';
  Result[24].Command := '18A4209AAEF2CFC67E48834ED7D2B62B0000040B060E000E0B0C0B0B0902000A000B040401010104040708';
  Result[24].Response := 'D054F91224DAC4C9E46EDF7EFAB6D179';
  Result[25].Command := 'FBBCE5B5F4BF962A345BBF3F13F9E47402010D060B080F0707080C0205';
  Result[25].Response := '73C265CD18C9F909784DCFC4CAA5109D';
  Result[26].Command := '8E90A2AEBEB136C000521AEC0037ACFF03000B030F0D070B070F010002060C0F07000F0F07010C0F08';
  Result[26].Response := '7F519F9B9EAB01EF8DED79520C46770E';
  Result[27].Command := 'FA89CC662EF47C75A9887F12A6C9879F00010B09';
  Result[27].Response := '4973ECE66EEE903D4761EF3960210735';
  Result[28].Command := '3F0E5E6D0F7F7BDE4DB2C4F074D020620301070D000A0A040C03000A07050F0C060C060A050D04070D0102020407';
  Result[28].Response := '87F43A64DAF93DF744F54FECE1A480AB';
  Result[29].Command := 'B443EC2B5E56AF789D27F6C38F9DD6A90000000C0A0C0A0E0302070B00040E0807000A030105010E090607';
  Result[29].Response := '795553EBFA89AD541C0ED2E5F3C4611F';
  Result[30].Command := '7DD9BF8D3337D57ACD92069B13B16CCE0001020206060106090A060808020C070E0804';
  Result[30].Response := '49F4FFFEA580EC96D5DCACC9E10AA95E';
  Result[31].Command := 'B39A5A07AB6746B5DE4875ED9492DF1B03000F00030700040D040800060A070301';
  Result[31].Response := '635E39AEF94D050B5424E1D967027594';
  Result[32].Command := 'E2703DC54BF4E7C63337FFF0AB6BB6F0010103050D0108030B0B040C05060E080F07000B';
  Result[32].Response := '3E537D77DE31EA05C33CE70B4ECE65FA';
  Result[33].Command := 'DF19EF9394EE6344A0832AF8ADCBABE4010104040C0B040D0E040305020D030E04050F05';
  Result[33].Response := '80F1A5169142107FF0873BC4222E8173';
  Result[34].Command := '24E6DD53E9FEE719486C5CBD07714FC8000102040B08000F0608020A0F090B0303';
  Result[34].Response := '4FA0477728E34E1408D98643F8124035';
  Result[35].Command := 'FAE4C2544FF93C20BAA6D60FAFE4919B000108070C040D0B';
  Result[35].Response := 'FD2847D87ADC24C27FA042D1DCA1459B';
  Result[36].Command := '6D1902203D17BCBCE3A0A961EC35851703010C0A050109050201030C020C07050D03070D0C0C060A0607';
  Result[36].Response := '2EADE5706A4BCD7CAF844DE01B127CE0';
  Result[37].Command := '7BC16676A8522EBC2564FEC235654DF800010A080805';
  Result[37].Response := '9819FE9556933E1CFC4E99C8BF64ACFA';
  Result[38].Command := 'F989FF4BDDD5AB6999EF517B742EA08500000C040D0E00070A050E';
  Result[38].Response := 'D6FEE60DBC8BA533E320ED1D18076D82';
  Result[39].Command := '5F07C727DA21B6C1E2688237672BCB7D0000080C07040A0C04070C0003070A0D0702090D03080E030A';
  Result[39].Response := '6021FC212F818102027C61FCE28D382C';
  Result[40].Command := '549C67ECD60E848F773990990CAC681E03010407050B0B04010807080E0B01070406080F070A06080804070D0D0D030B0A0C';
  Result[40].Response := 'C3B5EE74A722E784887C4C9FDB497855';
  Result[41].Command := '9AFF3EF56FFEC3153B1CADB48B4454090300040B0007030B0204070C0D04080F070E000A';
  Result[41].Response := '909415E5C8BE77563050F2227E17C0E4';
  Result[42].Command := 'F2BBB25D607ECD1E551CD75CF0033CCE0001000303050103070B050604010E0F0A040F0107060803060A06050F000F0409';
  Result[42].Response := '87832A9AF79C6CE436EA4DB6CAB18203';
  Result[43].Command := '806A50530D7735B40AC4EF1638E8AD6A03000D040103070706040701060D0B0C080C0507090B0E0A0B070E07060705040E';
  Result[43].Response := 'CF991392F0369350A7E21BE52F748821';
  Result[44].Command := '64193EF6BDDDC74C7C008DB98ED5FF67030108090A0B';
  Result[44].Response := '4A828E35DBADF6A465321363717D0D27';
  Result[45].Command := 'F9E29780209AC952DD87C2572C4950BF010103050A0F01080F04060C020F0D030C080C060E0B0500070104070C0A03050A';
  Result[45].Response := '51F3482AB8880850390F4F6D775F5C1F';
  Result[46].Command := '37A6769D43FEFA9F79CA61628BAFA7F100010F0B';
  Result[46].Response := '81C84283D18071F08DE72AD51B5826B6';
  Result[47].Command := '047568AC57D4DE026C40F7228BDD181903000F010B0101';
  Result[47].Response := '9CE6BEC0F80FDF7D78B1C219130102E7';
  Result[48].Command := 'F36472663A3BA87F3E76399C66C23EC90101010F0F07030303080D02030E0D060A0E090608';
  Result[48].Response := '36DA0902796F4682034DB07D0FF58E28';
  Result[49].Command := '906249E5AF810339F199A25AEC0281E8020105060D0A0404030208020901020602020B0B09020303080F080C0A';
  Result[49].Response := '317600A76B5A7984A681D1D8855F86FC';
end;
function LrpPublishedCrypt: TExtendedPairs;
begin
  Result := nil; SetLength(Result,50);
  Result[0].Command := 'E0C4935FF0C254CD2CEF8FDDC32460CF01C3315DBF012D7F1653CAF6503C6AB0C1010E8CB0';
  Result[0].Response := 'FCBBACAA4F29182464F99DE41085266F480E863E487BAAF687B43ED1ECE0D623';
  Result[1].Command := 'EFA5B7429CD153BF0086DEF900C0F235009036FFFFE7F61E012F4F3255312BA68B1D2FDABF';
  Result[1].Response := 'EA6E09AC2FB97E102D8CA64C1CBC0C0C';
  Result[2].Command := '15CDECFC507C777B31CA4D6562D809F2005B29FFFFAA8EC68E0519914D8F00CFD8EA226B7E';
  Result[2].Response := 'C8FBD3842E69C8E2EBCA96CE28AB02F0';
  Result[3].Command := 'A2D06401CDF35822B430F4457D1D1775015C35A6EDD2D83A1971077EDDFE2DF28DF9B736A4D9D4244BCF72E9597CB47B7DCDB5A4B245B52080E79BBFEDC69F1EE983CE';
  Result[3].Response := '73B1BED57B59090BC496799FA9BFE9F5252A88350A8F48A4FF252B8E813F6D96CA8BA7C8162E4CB2DFE0D53800FF01DA';
  Result[4].Command := '3CEEB70C13578D714860EEE19DBC8B0100104988FF3E1537842F53FFD5AD788DC6C0A14D25';
  Result[4].Response := '0EFEEAE6249011EF6CD2D28980B93766';
  Result[5].Command := 'D36CC09105FD0261C58FD5604486F7570001FFFFFFEF44FE3B50A73B1974D7D624B74012D5BEA07D9F91278035C470CD0BD0E753B2A2F90DBE638A3F2E252A112081DC98942F802D788F4F7AC8C3C876DFDA30498D842382BD32537134614F7A671660B4E8D738DB50B9DA23527F45FA9B145F54F4E0839C5D5ADA61DC0EF91740D513B263148E08A155F9D4A9002F3EED58D62002FA858692C3578DFDD7FE41BFC2E27D6C';
  Result[5].Response := 'F72471266DE22E2C66A6B89F20CA00859B63A41E396A592EF6673E3A5220DF70B9E0D3EFF3503F81F203573871CD5006679A10071B861C3A71B02B86C766576F35DE0790913E7A429C28DB6C398FEA5F9E140F92F5C6729F7FFAD38DE456F1D6222569B461568091B305AB69F19930BC489D18B8C3D6FA7B3D37467E4F3A6C9577E8C285C375A0B73970016BDB288AE4';
  Result[6].Command := '9397878556B29FE7AFF25C2A9C74833801D9154550CA56B814E61EB2D25AC14E9AAB48E59FE3D0FB6360637B09E6';
  Result[6].Response := 'E1D03C38C92DDF5A7C5A3FC1AA52E74627192A01143D26E8F592EE5D3C335168';
  Result[7].Command := 'AD9C2DDF73F7CA844BE8492F9A0C3D7700C9FFFFFFCEC19DAA67DAAE2E398185F2E6CA84155F5F9C7048C4BDEB9649B920A7429FC3F2372809E7A1816E806BD2BCF2D732F764290B9ECE7CF30A04B1131D218E87F6E2C2FFAFA17A2DBDDD2DF0DCF101F8BF';
  Result[7].Response := 'AA8D27EFC3D3ABF80A487C6C3577B2AB6B2FAA4317C0B3EFBB8C9A301F21C5FD2FE0E2E27B6516B8678121091A411D8A08B7E1111E9DB13DB169B2D3052007679E84BE742D4AEABD11FAE5624D49EDE0';
  Result[8].Command := '16C1BB7D3701F476431E05368D634DF200E4DCDA304DC0A08C161803B9540760D209BFE1CD896C8375F72F79E0FEF81527C8E8936BD182E94054EA2D05027D395CED1FDA1CF8634D16D274031E46C08E1D03DCF06C74F40187D6A0789F3F7D737AF51DF3DE1EF92E649A7C985D7ECAFA945C0F02268CCDE8F81D524558EAAED75500892829CCAFFF09AD8CD1F75CA4090CA5E4422F7B4DEE2835FAC0CBB3D579EBA4435CF5A1D1C7AC0FF878FFFCF09B794939B2066BA7D9B39A00F3D1EE3356D812E5521947146AD41D961F83D5EE2B445F47827A227380FD69A85AA1DDF5BEDBA29FED16';
  Result[8].Response := 'B1CF729E877227D606F104827ED07334FBF1AA7782341C77BBEB31EFAB36B96344431098AB2658A5D7F7ADA4B60680C5727F418037DEF71DA1A12AD4C621C74CCD0C3923769798BF7B401C91AA23B060358B7BB3FA831B1D06A85ED5EA8B0A8B1747BCC6D64D3639F8D1B8EBB633C4A02279B59C7E250113080B0240C2947E73BC774B8A1A981F85FE9C18D1C9BA025954E803C08756FC1FD9B83E0CF56C41EC6D32C0EE1946CD6E80E541CC9A0A407C6D171855D0793080A0FE423A0D1B63C45C03F7789552F28E72849DCC42F31F91';
  Result[9].Command := '9D813134CFDEE9D58755DEACD4AF72A701FFFFFFFF27';
  Result[9].Response := 'F5833FC397356EA3D9ECADBB9F6FE440';
  Result[10].Command := 'D744E1350115A7DD154DAA448AAA751300CAAECC2DE94EB047D1927A06E6C1FE4374A8AABE';
  Result[10].Response := '5A00BAA47E1753668D605A1998843DC8';
  Result[11].Command := '08949164317113BBE09CD40CFCC9A4C001191B4BB25EC9AC319F21030D25EE85C595783BF56635BE6E0A1C1D3E2A585CF859A8880E918C134A0EAFFCB208EEA3B53A5386D3';
  Result[11].Response := 'AE617C37C4F55FD711DFD2E3025524C7CA08571CC556A3C85C3BFC9652916070D1CEF452A089F65BE4A981EA9694CCF1133087AB70D7FCC7EC9496F4F83ADEA5';
  Result[12].Command := '7770F8D6C4639941AB6E0746C40AB47C00657734080B651B786704D6D28981E9B0B24A2EF2D19EA0A7B5EDFE3A274FC31F7E6D8689409DB8FD7EC8446A31743B89CBCCB32C';
  Result[12].Response := '55BEB785703EDE175B4EA69054023EB3CF3996C55D3D0FD5D8ED757C397E066C1453ADC6879FF2F501765524CAE5AA27';
  Result[13].Command := '061593514510831E67E1511741B6541C01FA5F6F157641B2746F5A9C961968DA3544301999969C762C297A1F1E8F6C5D9E9AD5A089F60F99416BF372F77BAA9DEB42C51B3EFBF899D7932E0DFB2193E502FCFEFB43C7503E3497D82EA32A7EB17EDD34DCC9511EA2A23CC9F6C8029D20D80D6FFA7CAE5923F187E6A723C9F6AC14';
  Result[13].Response := 'B3CB99514F0AFE7151C3743FAF7DB17E622529CE16F3BB9203BA7DBE45DC89CB3AFDEF19F47CA9BEB54B46F0AB3347FC80BCE7BDF21A2DDB4EB6A425923977FD201A8163865E9BD73B4384702BAF33E7D693DE4D8F6DA00097133E3AA77E25BD5277A24DF1361B5F4725C9FE4CF89145';
  Result[14].Command := '7C8E1EEDB71BB1DE5B5907FE5A7532F901B85695BB426A777FD8451CE14C737F3221F1BD1C';
  Result[14].Response := '9B5C42B96086FB2A9A9AC0B280F020B4B4734EBAD2D6A73BE758B9C8CC7226E5';
  Result[15].Command := '215551249711B3AE6B7361F19048BF9A00DCCCFFFF7929BF798535A3FE67127A32EC5330B7';
  Result[15].Response := '6C4D5A30B3102D627721D19EDDCEC534';
  Result[16].Command := 'C91464E42B5004B4E556541876B546D4018F421EFF354467EF78A8909DC61CDEB628250A94';
  Result[16].Response := '0ADA577B841FC5CB112230336B33CDA72E17D303D05EC66CAECF892B0C282DF5';
  Result[17].Command := '2EE08B87B1CCA5A2A93548C2952E2526013827CF6FB8B18B';
  Result[17].Response := '29E99882A0DCED4E55FB3E61303DE275';
  Result[18].Command := 'F5C3E99FB75E316B76689FC5464260CD010797F6B7';
  Result[18].Response := '93DC3EE14B612BE6A3E9E2E8040CDFCB';
  Result[19].Command := 'C7031CA1994DECF01D4084D8F577C6F501CDB066D0';
  Result[19].Response := '3B1DAAC45010793FD592FB76827796A5';
  Result[20].Command := '10E7C2FA0DF36D4E89F05B15C9DD1BB200D42802DBB150EFCB5EA66A0D8888652AF6104C17';
  Result[20].Response := 'ACA71BCE7E9057EA8B834B37BF028D1C';
  Result[21].Command := '896B876BDF03D34B1DE3F8973323FDC700FFFFFFFF4054B588DE18B6C46BA699C3E2AD7DA3AD7AADD3DA658A9D97BDB3A99805403D7BD7C27E959405E0E16EB7572ECF55AE25DBD5B09C1D2EDACA18F120640C2C66665C480BEAFF0D1975CDF26BAD336FC7';
  Result[21].Response := '60801EEFA4D5506A73753F826F82EFE6B02E6579BB654256BAC5C7ED81E16A190BF8953A056FB869A9C5C10C87AE3FDE28CE32730B290F4EB0062E96AB29B40F764AD5D8ACE61997EC515BB69B24E6C0';
  Result[22].Command := '680583BD2F90A05DA9E8B37DA2E47CD4014151F0D23BCE2BC22D96A92AB85E896F36D6BBEA6102';
  Result[22].Response := '82A7917C5D9B16C8B01277F3E4FF6BD14BF404176F344188F7F8AB2D072C0F99';
  Result[23].Command := '4B8F7691511E2A5C429C401D415CEE730155D131FFD2';
  Result[23].Response := '83FF5F0382BC7EA5C795122C83D3B0C2';
  Result[24].Command := '1B1A179CE9C0DB3E45A97D0D98D0530C00E9FFFFFF472DBAFE6434D357402785A3348081B02EAB54244EE9C9C88E91001C5158992DE36E79AD844645493940902C8746669B';
  Result[24].Response := '397C9EFFD28C560411B934895C8DF60F082B9560778F8571B5C31A057B34C2352F11B5634788623499C6BDD5C490F5CB';
  Result[25].Command := 'ABD094D694942C5E64F26FD333B705E7018E57BFC6';
  Result[25].Response := 'C96E153DDBEC9B8CE23A142A34230CD1';
  Result[26].Command := 'EA0D599D41482A647081C4C3994F411A0048FFFFFF86A093D7A4AC7089A91E04C7B127A8CE468423CABE6F84ED8B9A10F4F568D3B1FF11C18AD099DC18530FA6231681E0AFC8473CB585D371161CA64C0A9C7B94414B53C79F661EFDADA80B76AEC960D609B9602CAE2B1D2B2CA0AA6E2A4CD27BD87A65D8C3BA4149A9498F0D7A5CC24DBB';
  Result[26].Response := '557D92979767DF003FAC2D865C5650FB00936AE565D4413A506E82DA0BADED4CCA98E0F82A602893AE2C8122F2757E3F20AB6AB5D66EED94F2C7908E3AB0F03F1B6FD87DF5FB347C0A8A8F8C8334B4A89D66D4ACA4D5E1AC398F9198723A54EAE62E52A331D18E2F252C2737DDA6A950';
  Result[27].Command := 'D042503B4FE6152D279BFFBBB0D360D5018F9E3364649C0FB1CFDD5CB2590A814089944FAA';
  Result[27].Response := '7BB7E3DA21CBCCEAAEDB71798114656C331C7D2DCD661C43F679FC50FA0239E5';
  Result[28].Command := '9B1E418DF9752F37EBBD8EE833BDF2D70124FFFFFF55534E159F14DD7731368988EE6DD7C6114E747F9C17A91BBC12D68C26531F2FFCFC';
  Result[28].Response := '158B3B9C6136FB715CCF435CA4CADE808D1F98431327061A9A64D52A5FE7B2746D7F5A633FC0CFE7855656AD3C6B94CF';
  Result[29].Command := 'D9E39CA8EFD45645C1A19B44920B46AE01B9D3EA7D3D5050DD16598BF294F32A695F9F2956560880787FCB4677994C447F1F9B39694F629605F5E38A41B8A077528450734A5486E7A1B2E00D7209D943CA150CD3F9BAC119FD092361727E3FBFDF53F4F249';
  Result[29].Response := '0241258DBBC6395735FE6F8B81BB958A3758FD7C772F801EA689A1B3DB83D711CC0E16CF08AEFB39E3DF50551AAB8293E16085B0B7805C2CCFB9A0D2E8FC73542C844A35A9B352F750F8E9344591E2BEC55C87E4AFDE1FA5FAB6AF09357EF28C';
  Result[30].Command := 'D9F92A98B398B76E5523FC1B9FC02CAB00CC7E98C3752273212D1F14E6FAF01BE13A452109ABA7E52646D2BE121313D55C2F1262B8F9743D76434D2704E735A5CF10CA913876B98BCE5B0ADEA263600D1A49B7B6E78D63E7C607AAC65D7FE13E112DEF0249819CE57687945CEF959B13E33F0DBA307EBD41ADE2CA30CCF32D4E7ACBCD75745EC498ADD14060F906F8316C97E21E72260E936FAD5466B66B19825A45E224C8259E847B740D5E3D5D48A7EA99C334100EDC54BC3A06C60A5DE141B8BE06B323D36847F85DA3FD18B0551265AC7C1DA7E4714B698E678E1ED87A1E92CCA67E57';
  Result[30].Response := '6CF4254823B6A182B155A4280F5DD9B86F83968BCA07ABB552077647446C5AE41584B964CB69C03B84BBA9CD181AF60848488B355B058FBEC74FFF11F5A4F05AD15138FA2C4C71BA0AB15C35EDEA9958F6C1904CEC673936554611A47BEDEC467387B99E4D3415C716AECA75039F4FBDB19BE15E042E81522CD819122D3B9D007B9D5DF4A11AFC4FEB58DE24821CE507B2B2B720355E3B23275B05AC543C61EC3905B01B1B3704A86577FE7B4204FC848AF94E612C2A168568D4F44326113AEB7F767E5B43A4B3B2987EDDBD279A8E37';
  Result[31].Command := '948316307C3CB26BDE3B0CE4F4605DE000C4FFFFFF20E3846A4C09D7BAD12965EC2BA8BFDF';
  Result[31].Response := 'BB1942D3E6F866ADD796B7EA85755D57';
  Result[32].Command := '8A525AA92A771D3DCE32D2329C49EEAA015653FFFF33';
  Result[32].Response := '352BBE318443FB9A095621256F9FB523';
  Result[33].Command := '7BD86E2B8DDBBF431130FDA8C5479C190137A41E871762579CF1E8E9C1F6C4A7A5C089AB992555740A9FD7D5CB681A07F9C042969F9EE3A8E0B9940CC0DB85A5558FFF5EFE8F21708117E459408C8B33D7E0F001B42D0807DDE0CADF9149B32E1931803C69BC09699ED11587B98968532D6035DFEB84F12787F8801DC442DE3864B63F0F0C4FCA1AD78763E218814D537877B13114D443953F58B5703BEBA45BF2DD2303495946DE951A0763200E0F06AA2DA44D90AD238F72';
  Result[33].Response := 'C1A48806D8F8A135B7A68636A21203D4A414AEEC663557BA029DB5665EB7BEB69A93E7812277279B501A8EB96EEC64E66874AE7EE33A80CD5D2C3C65B02BF125B989E6BB72BFBC6266A915EDFE05D12B967E8B5C29D37A8B5A4DEB0DB7CC32064EA95C802377C4C22AE5AECAE61EADB9062B8E88382A194ECEB7F08B211FA9E3B1A69D9B37C243D47C9AA56C969C3BA8E2ED668E83BC369CB5C423EBF9A226E7AF00721AFFEB7AE544C9BABD84E4EE3E';
  Result[34].Command := 'AACFB49A5ADFECE208EF3B5D4A091F3001D3FFFFFF4657CA45B993909F8992433B3B1B81181ED4A85F23851CBD112AC292369E6BEB93D0A58A3DAA82C9BA6A959E8F60BDB15E5C12740667EAC13B0C338ED1FE69EB2758A76A75F7DA7452DEA5B9EF7D2EB16C1034D98BF7E42CE6E44E3076F3F7BB01A97636B8533B67819E2127C130D1BDDE8222C1CA8F6030737B8391A8AAFD5FE6E9B84606F7F819D4CD58EDD5BD6AB6129051F4D136F1714946C33DCFAABED7A0C240D7778AB7E78A09EDFD37725AB610CD7E1758088DB0F846FCBF33BA492A0E';
  Result[34].Response := 'E55B18F8DF0546749E5637BDFB11460BAF0BAB9F8CF2D2344335BE43E4F624D434EA724407C9CCA1CB0719C0D508B2A79D9B2AD6552AF40412E1D835707542AFA91C764C32DBC18272C9E88BB2763974FF9C6AF1888459589FC4CF86157F311C3E96C252396FD0CA5E43F8746ABF6501A7141806A82B57BEB506EB9B6D0D6977C0F5859B4A5BB15484F350B6DB8ED144E3D9368B39E2295A180536D4AAC5D18002E277E9EF4D9E0D408CB0FE7D08F61292C2554E9AC18B1F94538E8904F66D2B7002231D3FB984365D4013061D963F63';
  Result[35].Command := '814C137C933E88D96A69C849F43AD6EC000DFFFFFF308EF7B3CFBFC2EEB62647397D8FF63D';
  Result[35].Response := 'B5D3F8560A4577820D2E839D8EF122A5';
  Result[36].Command := 'EE9FC566040C26D3268D47FE6602B4DF01FFFFFFFFB0A5D3AF72356A90F86E29';
  Result[36].Response := '38D1239AF8949B43101EF67CB1C6F211';
  Result[37].Command := 'DB2467238C4278C488B371684DC981FC005A3705BD53DED4C9FB71BB70C2D8E992BF2A5790';
  Result[37].Response := '77813088C92EE813F90A7F7FCC42F88C';
  Result[38].Command := 'C17CD03E3D85E5F0380F59F3B149DC9C01F2F539648BF1986A9B0CAD2C1E81B736F1CEF8E3';
  Result[38].Response := '5AD8ACC4AF8AFD1F5A5E269D53B592DF3E9965397F2CE7005BF6AECE35D1D39D';
  Result[39].Command := '90EC18C8BF78FB4C9FC9F1F3EDC6F08F018845F9F42A5AE4BB036B6BBF6AA029ED3812F64BCAD11BB93F589127AEABD4048BC278CB813A4EA067E4C586872E5B4F669A0DE6';
  Result[39].Response := '0EBF6D014252EA52C077B67AA2BEFAD20847A449B450B8CB1FDC3649E2C20FAD168A0F40D8982FEB2FB1A8CDE5504A1BFD4BE3A732272E049ECD5B78BEE385F9';
  Result[40].Command := 'FD0C03A1318C45D2C8BD0D58966733A801275D6CFE31';
  Result[40].Response := 'A126BB809FBA89EA9F656104F449BED6';
  Result[41].Command := '10FC41C1139DED067FBED69AF5F47CD701AAD66DEF0F22A828';
  Result[41].Response := 'D47A868705A125678D9B1B8FF67978B7';
  Result[42].Command := '1D959B5A35D586FBFABAA961B4EA50C200760948FF4A19B8E48ECB5E56A040FF9ABFA650AFDCB246BE46C8D746B705DA2AEF0EF7F5481F8B6D42152CDE035E490FC3DC4AA12D8932EB6052CF8241722C88F0336692490951A01BE36DC68667BBE77EC883DB';
  Result[42].Response := 'D9339BB44320E9A58113E928753A441C499E17B4289C7FA1ECF6F640C42618BE599A3C70E475325C3123FEA5E2C2B2C2E17046EA3610EBF3DD50FEC8EC131B9E52021A8A4B5826CD599C05C38E190358';
  Result[43].Command := 'BB38FD66DB0B95F54F092BD0E9A3EDCF00F7B7C5B96B65F897E80379EF50CDB836FFB63E74';
  Result[43].Response := '800B79783988A4B9C38B580DBD43B29F';
  Result[44].Command := '5C5112B79CDDE37AECEFC602C95110B201B24A6FA698D5';
  Result[44].Response := '98B5D3CAE67A2AE3C05455E5EC5FBFEB';
  Result[45].Command := '3498F80187442E5974927F8E827DABF8013D7725FFD7';
  Result[45].Response := 'CE6ECAEC9FBEAAF74C2AD5AFBE66B697';
  Result[46].Command := 'FDEA0C05BB450D4553F7C47A8423B73D0120CBE12498192E1443BBEF6D306F678DC3487437';
  Result[46].Response := 'B473762E32201AD37E60A64945A7D3123912F4280283876BD1672F62062A9254';
  Result[47].Command := '570079FCA0DC05C863E96473B8497B4501CAFFADF3';
  Result[47].Response := 'B23F34E57538504915DDA4479CFCA3FE';
  Result[48].Command := '17F248D6920799AFE75B6E4E3E1BBC1401FFFFFFFF9B8020184B707288E9BCF1D1E2CBC4D0ED0DF78CE4F1DFB18D5BB20E630B54B5CF43FE2EC74222DECB93D25774E0768B';
  Result[48].Response := '8C8F3AB5C6863E45D1DE3DBEB1CFF992510ABB95B44188B71EEBAA3E86655BA9A3F59795337F7E2299AE771D3428EC7C01AAB4432B046526A9641FB580613CBD';
  Result[49].Command := 'B7E4F9E62A37DFAAA16F8BF0BD6325DE01683C01FF511E883CADE426577E126D8A9864548D58B73220686DF3EF37DED8BF20DC4EFB11768E8B1932DE0B970BA7CCFAB2693A7809B0F3B8F857E32B9904CE0C6736A2';
  Result[49].Response := 'AE43CEB7586F6BB2848C623E01E26CE2575CE57EC97AB064E498A5D0D8831399E7D40471B5F7E984F679E0D8183D831D4230679D24A21FA47F8D9E6775B16C08B5367247F68ABDD4E6CF6196213BFA1F';
end;
function LrpPublishedCmac: TExtendedPairs;
begin
  Result := nil; SetLength(Result,50);
  Result[0].Command := '63A0169B4D9FE42C72B2784C806EAC21';
  Result[0].Response := '0E07C601970814A4176FDA633C6FC3DE';
  Result[1].Command := '8195088CE6C393708EBBE6C7914ECB0BBBD5B85772C7';
  Result[1].Response := 'AD8595E0B49C5C0DB18E77355F5AAFF6';
  Result[2].Command := '59242F9365E79E5F155B1430D8BA2E56';
  Result[2].Response := 'B8306666C22F9FF3B53A074C6004ABB5';
  Result[3].Command := 'E7FEB463C2498E04EFC5BF503473FC3AF3EFB6B0D4A7';
  Result[3].Response := 'C17AA38420EE2AA13087578CFBB0B7F3';
  Result[4].Command := '7860B864632C6C8BC9A4C06D49D7E2AEDC7F';
  Result[4].Response := '59D3D3A4307A3BBD8E8E5F4B8E75510D';
  Result[5].Command := 'E2F84A0B0AF40EFEB3EEA215A436605C8BF1DDA9FE445560A4F4EB9CE0';
  Result[5].Response := 'D04382DF71BC293FEC4BB10BDB13805F';
  Result[6].Command := 'D66C19216297BAA60D7EA7C13E7839F956076C610CAFB99D0EFAB679C360F34202655178EE7E7236E8BFCC1C66BDDA17F2F67F65ADBF55E70009FE84F0477B1845B7E5B48231FBD89436794CE39D36511F9F86CCE08E95430F6977E57FEE45A044B3D7AFD72694C1FAA6D07645080363D2AC6451C1AE37B621A1';
  Result[6].Response := 'EFFA1488A73FDBCE5B91BBF9B8D51775';
  Result[7].Command := 'A418BA1658A6F0D90830C58679F80AC406';
  Result[7].Response := 'FF9561CC6E45FFFD4388003AA5F61233';
  Result[8].Command := '651312D289F4DE957C208D35827C07E4D39E4B336C46FCDCFDF803A49EB3A603851CFCFA72B3A5F843768EBDEDEB939891059275C79F1DADE2B97E288A91E3';
  Result[8].Response := '9B1530F1AD35213EB8903D5610BFD7C4';
  Result[9].Command := 'C960E0C80D89728D1FF952EFF5B83FEE21';
  Result[9].Response := '4EBEE65E5DD0C30F89C8ED49A3D2BF32';
  Result[10].Command := '313CE6FF4F18B9357C6EB292C55C0D227C74AF27F5A2CA6BC4207E4AA82FA3E20D3A59D4E97CE43D62F2E2E1EFDD5AF420AEB5C836D85975EECAB84D33481D2D694078D5C5A388FF9072C402C0E97CE6C6892AF97ADBAC35E0E4E61FC497091AD5B577AF64842F7D26B538C31357B5044ED187AA1D24B38E9343F5E0BC683BF868A92D0B71CC81415AADD2C4A3E821892FE1D1F2105FFDB101E91B21';
  Result[10].Response := '74637ECB978422D4426F8F876A70E721';
  Result[11].Command := '8F4EC0BE7A3F5B6A2AAA92814F454F706CB1DB9648E809AC7B0988B160B20BED144A648DB75E854E50A2CA0F8D5F13FE70FF229CE427315651BD';
  Result[11].Response := 'CFF39D67CB2B1987DDE2841E4C7F6225';
  Result[12].Command := 'AEA00AD0EF9243833DA4861D6A0D2C8C';
  Result[12].Response := '954230A72692BAB4CE1A44473D081376';
  Result[13].Command := 'F91F1CF58941608F6F08ED190D3BF9B0CB09216F785295157058E08B38579E91AB808E8E02D47A508A78E1705D4847C6F3E52E15FA8611EECB7AFEAF0C8ED5E45A1E38C4F02335F68ED1E4FF7024B72810199752298997246EA0C387D6CB43FCA3FD153E0F83D6CFB0378629A1127EA6C3D69EF3F683BAD18714565060AD20C38DE75C720F79188D43C8A1F2026E825B211CC4FF2C50061F4343B7FB2C856E0216C29BB9B60B9749BD11AF2DE1C7CF1991FA2F43E820973DE13C2FCBC11D60BE599FDB3FD2C9A516857A411BA0D93E7B749E6A32552B19F52B5ED879DBCC88A0B0F1D342EC8F46C85418BE6EDF7C9C08FEB45623B22E682E85E61474F02C3AB8F2A16AAF05FC8FE5';
  Result[13].Response := '5D5E7B4182EBD50B31FFE52DE4AB5C11';
  Result[14].Command := '57A2DD3D6DAB16AFC1D07B277664ED82D2D728DE057B3E';
  Result[14].Response := 'DBDEC069CF2B46450CEFB34FFD80D840';
  Result[15].Command := '11ED02022570CB10502BC1DACF64B21FE825603F896A85CAB45E6730D89DD4CE78010599';
  Result[15].Response := '4A1577C366D53080D0DFD1CC47EE3CC7';
  Result[16].Command := 'DD315EE3E236161FB777CAC2EC8A29C7469CCC';
  Result[16].Response := 'E45A7903A8B9B0366309BB11A451E244';
  Result[17].Command := '5AA9F6C6DE5138113DF5D6B6C77D5D52A4434D740C2CB665FE5396959189383F';
  Result[17].Response := '8B43ADF767E46B692E8F24E837CB5EFC';
  Result[18].Command := '4F41663FB985F7B47200246449B3DF3352D12581AC3FA13F2135F325130424AC';
  Result[18].Response := 'D21C5F1F7881C84540373E4AF9C01714';
  Result[19].Command := 'FDDA1F4B99010C07521C4B74633559D3BE';
  Result[19].Response := 'D3C4EE477F4FA5092B1FE726C18C3D01';
  Result[20].Command := '0D46557550CB313F36AFBA87625D961A90';
  Result[20].Response := 'F7C8553DED574829E6EE68112CB3817B';
  Result[21].Command := 'F32DDBECDB1F527C06B46B3FCDD8F6239CB9DCD3FB3DB886ACAB218F7D52289964EF11ECBAA8051B2290BD23EC9F84481CAA5773FF18E0E299F55A094AB05086CD894D51C3252BF4B3C0';
  Result[21].Response := '9E1107B058A7C310F41AFEDB3C0E58CA';
  Result[22].Command := 'B06A7F949A0D26D872D2FAB4994B0E2F7240375662513285F67F63C03E677562';
  Result[22].Response := '4249F423B3137D3C5EF9A315C4BFD1D3';
  Result[23].Command := '055A4CE2713D7D8B18EF014394D266A6';
  Result[23].Response := '8D8FDCF864C745DF8ABAAFADA00F5074';
  Result[24].Command := '2A473E38BBF4537C5397F45AE498CD4DC2AC3D7250EEF02318BC084F294B1AC72291EE1DC02AF424941CAAC685FCA59D9008679B00C56A0562583BDAEC0BBA';
  Result[24].Response := '66DC2BCE269B793B4ACA1A4D04DDD668';
  Result[25].Command := '4DB286486F2B417498B819DD33442A9EE37EC65C26E8BA67EF193889625C13FEB436724E93CFE3E7E836C138BA1EC3814C996A34C0EB4943860CA99EE154D1E7169F67E1F8708D149ADE74EF2782ADD056B63CC8F2DF3EC8EC2EC7872545069365D9221BB7E188DC0C5599E177591C045FD9472A1809F536609FF4CAA806EE55D8E08A4D5F911875';
  Result[25].Response := '39D04705396D2ABD4CA96B693FC20B04';
  Result[26].Command := '2E5FBC9C465D509212C3274CFEDC7B5CBE';
  Result[26].Response := 'BE0A9F7E4F4C9C55A35D0F90DC0FF866';
  Result[27].Command := '340567430897CFCEA4CEC0D2FBB84C58E5DEA257FC642D6A74D60187702BB635';
  Result[27].Response := 'B9A019E7BB4A84929365B6414D84B849';
  Result[28].Command := '0254B8C2431E598C2BE0C20F8AFBB8C7EC';
  Result[28].Response := 'CC6D34A67B2E3F08221F1F23C498F3B8';
  Result[29].Command := '0C32A26430F8BE4A8B8D9523EEAE969F1BA21EDF781D39FC69DC8F6F15488520DFEE60CDE1553579670D0A31EC9288A0AFC1F1908385B7DA854D21B106B3D866107E94D8254849C66CA4776B130810D753EEC05456F59C5936864893338473B334A3206DFDB07B66772A23DF0D4CC67C3D4A5D17F2840F1BE13AA19E00B693E830C4376FE8A2D9A2735ADC2CD2BD4CE9C0CB56E8265BC0AF94058CC20E';
  Result[29].Response := '0C4222286E02A484217881644CD11A7E';
  Result[30].Command := 'DD65C1973AAE481556949A70BBA498A8DE3560AAC2D50387DBE216179395F41B';
  Result[30].Response := 'E19DA6375B7D44AC7EF2DC379E496775';
  Result[31].Command := '94970E03D46936BB786BB72807B1BB67ED78D9458D';
  Result[31].Response := 'E9779A2E7A2F713C3692E71D1704AA00';
  Result[32].Command := '7BB18459270EA38C4EB115EAE374FEA42927AE423C96C4BAA61E34BE46EE8436';
  Result[32].Response := 'B342A9697FC469EC29D554E24742936E';
  Result[33].Command := '1E44A8857A620951EA738A31BBBB21BC17EA78DED1A793E12B9C86796D1312745605C71D5D58C90B92FEEBFC7855389CFA61075930A6A8BA7670BED604B84DA70F4713088A6D78BE20';
  Result[33].Response := 'FF3D98D31F457AE0D957601ED44F3777';
  Result[34].Command := '6D4BD3BC9668D663E97F0C0CB844AF5C06DAB144ED31412F118CE94838C25AD5FEE008E8721B';
  Result[34].Response := '6BE23B4AFE1F608BCA215E94D7AADA51';
  Result[35].Command := '38419B570263AC7EC78B252E66712277F323C37F8255860DC6E4B07FEBA16FA9';
  Result[35].Response := 'C2D8DAC25EDC2FB9E9F2DCD010AFF945';
  Result[36].Command := '952FDE8393C45D230A5BE9B38636D154D7800E257001A774AE7BCFB2CE1307B5B044';
  Result[36].Response := '05F1CE30451A03A6E468B3A59033A554';
  Result[37].Command := '2EC5A074266CD3868F125C40A85C51D2C3B6AE5BE019';
  Result[37].Response := '003EB550D462D3E9A2ED9BD4B798C87F';
  Result[38].Command := '01B823CA9E8EFE175836625AA152E97261';
  Result[38].Response := '32A2D28599066AA0DDCD1DFB6C3373B0';
  Result[39].Command := 'FC5558E552206A0FF2194552D1CE6B489B5B542E0A39512195ED0EA6A0BCCE71';
  Result[39].Response := '2797A78D54BE757328F7A00C4B522B2C';
  Result[40].Command := 'B93BDEAD484349154F801B064C5BBB29B647';
  Result[40].Response := '0C808D5AE0364B41B122EDB487397BB9';
  Result[41].Command := 'E718EE5C2C37AC31129DD60377CB97AF1E4BD43A31';
  Result[41].Response := '7D45F28E5FAA0C2FA7379A3BBA4B2A6E';
  Result[42].Command := 'E477385CD36D02F3F6945AE61DDDA24F5D96B808E8C5D7BDC8CD1922FA5234F9B5C9690184D4035571F3613C3A15E25FE2ED87E17F53EAA82A352EC7';
  Result[42].Response := 'B7F4DB09E5C5A9133D60AAFC283D270D';
  Result[43].Command := '41C4238B6E55539E0B55C089936396F5';
  Result[43].Response := 'AA7032ED436E7B52808E2E703F8781A1';
  Result[44].Command := 'B2EABA3F0CCB537962DEC1D64EA63B13C243538D2DFD4D1CBCF54490B27BDD878416C01ADCF0C0';
  Result[44].Response := '0BC42ECAC57934BC09899693664C2FF5';
  Result[45].Command := '4A7F71E3574FEA248ECC9EF0A667B2DF7D469C2A5E8C28BA15B308D183080DBB1AF6CDD2D1B6C3148B3620D236F2147F4BD7';
  Result[45].Response := '82B9D1AF7643DE20A65117D1FBA48C7C';
  Result[46].Command := 'CD38D5B8F8C3C26A7818951E225EA424C682889F28';
  Result[46].Response := '093C98AFB1CA352477A296D97611BC72';
  Result[47].Command := '6C5683229E8985AC3BD5E661FD0A1066C1';
  Result[47].Response := '9F65E3937D6C9140FF9B02857ADAFB5B';
  Result[48].Command := '2D113F05F079BF06B54D19D0566BE656CF';
  Result[48].Response := '25938AC2F0F78B21416D5BA1D3642B63';
  Result[49].Command := '3E521285C1B089D7083214AA2871E29999472DB3A480E63173D39E9F5D';
  Result[49].Response := '132A1027AD89A5F26C200966D581554B';
end;
function LrpAuth: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '00000000000000000000000000000000B04D0787C93EE0CC8CACC8E86F16C6FE0102030405060708090A0B0C0D0E0F10';
  Result[0].Response := '75FE26C7FC2CA632C6DB8C39815EE04B';
  Result[1].Command := 'B04D0787C93EE0CC8CACC8E86F16C6FE0102030405060708090A0B0C0D0E0F10';
  Result[1].Response := 'B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB1';
  Result[2].Command := '0102030405060708090A0B0C0D0E0F10B04D0787C93EE0CC8CACC8E86F16C6FE';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A';
  Result[3].Command := '0102030405060708090A0B0C0D0E0F10B04D0787C93EE0CC8CACC8E86F16C6FE';
  Result[3].Response := 'A9C2E7278A785B8EFC8C9A01714C931B';
end;
function LrpAuthBadCapability: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '';
  Result[0].Response := '6077B0621AD4F439A827156E28F69E0DCC0B95B0BECA482DF99E9527C4FC9FB9';
end;
function LrpPlainRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '00000000100000';
  Result[0].Response := '000102030405060708090A0B0C0D0E0F';
end;
function LrpPlainWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '00000000100000101112131415161718191A1B1C1D1E1F';
  Result[0].Response := '';
end;
function LrpMacRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '000000001000003E73B1F4E99A35F0';
  Result[0].Response := '000102030405060708090A0B0C0D0E0F21C7B9D4DCECEA42';
end;
function LrpMacWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '00000000100000101112131415161718191A1B1C1D1E1F7973FB50DA484165';
  Result[0].Response := '6DE82A0D9CFE09B0';
end;
function LrpFullRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '000000001000003E73B1F4E99A35F0';
  Result[0].Response := '909217E119ECDAF47E171BD3AEACDA570161AE1C3CFA230A9B657AEBE7EC69C3F1DB560845E1762E';
end;
function LrpFullWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '000000001000006FBD5F220B77D28324FA1925375AEA8A0161AE1C3CFA230A9B657AEBE7EC69C330AEF93B00FE1B83';
  Result[0].Response := '6DE82A0D9CFE09B0';
end;
function LrpBadPadding: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '';
  Result[0].Response := '56EAB92568910194DDDF369299FA9EE7D5819F9759B6A6D9';
end;
function LrpBadLength: TExtendedPairs;
begin
  Result := nil; SetLength(Result,1);
  Result[0].Command := '';
  Result[0].Response := '909217E119ECDAF47E171BD3AEACDA57A1B233C6453A5E519AE6F3CB849D021612184616E4227781742A0C827BCD2E7DD7A3883FD179A239';
end;
function LrpNativePlainRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009003105E800918BDED800';
  Result[3].Response := '00000000040000948D549AE02259079100';
  Result[4].Command := '90AD0000070000000004000000';
  Result[4].Response := '010203049100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '000000000400005A55CDFA29B7C04C9100';
end;
function LrpNativePlainWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009003105E800918BDED800';
  Result[3].Response := '00000000040000948D549AE02259079100';
  Result[4].Command := '90AD0000070000000004000000';
  Result[4].Response := '010203049100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '000000000400005A55CDFA29B7C04C9100';
  Result[6].Command := '908D00000B00000000040000AABBCCDD00';
  Result[6].Response := '9100';
  Result[7].Command := '90AD0000070000000004000000';
  Result[7].Response := 'AABBCCDD9100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '00000000040000A9A7DABFABC66A349100';
end;
function LrpNativeMacRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009003105E800918BDED800';
  Result[3].Response := '000100000400007EE2420CACAC73029100';
  Result[4].Command := '90AD00000F000000000400008DE127AC8668C4EA00';
  Result[4].Response := '0102030487D19CBD3C730A3C9100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '00010000040000B5E952AE19FA6A809100';
end;
function LrpNativeMacWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009003105E800918BDED800';
  Result[3].Response := '000100000400007EE2420CACAC73029100';
  Result[4].Command := '90AD00000F000000000400008DE127AC8668C4EA00';
  Result[4].Response := '0102030487D19CBD3C730A3C9100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '00010000040000B5E952AE19FA6A809100';
  Result[6].Command := '908D00001300000000040000AABBCCDDCD36A4B002ED9F5700';
  Result[6].Response := 'E77F89E14E0D1B329100';
  Result[7].Command := '90AD00000F00000000040000762074419F2A97C000';
  Result[7].Response := 'AABBCCDD577A7CC96A494C169100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '00010000040000AE72A3E735C910B99100';
end;
function LrpNativeFullRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009003105E800918BDED800';
  Result[3].Response := '00030000040000C17E1E8DFC59C2249100';
  Result[4].Command := '90AD00000F000000000400008DE127AC8668C4EA00';
  Result[4].Response := '6E93DA41ED9025E1FE500D7835A3AB3765114B388EADBE749100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '00030000040000B80D41D7500FA0689100';
end;
function LrpNativeFullWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009003105E800918BDED800';
  Result[3].Response := '00030000040000C17E1E8DFC59C2249100';
  Result[4].Command := '90AD00000F000000000400008DE127AC8668C4EA00';
  Result[4].Response := '6E93DA41ED9025E1FE500D7835A3AB3765114B388EADBE749100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '00030000040000B80D41D7500FA0689100';
  Result[6].Command := '908D00001F00000000040000623154630527F506219C4097936D6B48D11309EC426684C200';
  Result[6].Response := 'E77F89E14E0D1B329100';
  Result[7].Command := '90AD00000F00000000040000762074419F2A97C000';
  Result[7].Response := 'F8736047C5A804E5B9A1DBF9DC2CE8A9E9DFAC546C1F16F39100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '000300000400008A2EF64846322F009100';
end;
function LrpNativeNonFirstRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009003105E800918BDED800';
  Result[3].Response := '000311110400004D37574B082887A79100';
  Result[4].Command := '90770000010100';
  Result[4].Response := '202122232425262728292A2B2C2D2E2F91AF';
  Result[5].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE2FA0C9EC077A685C264CCB7DED19C59B00';
  Result[5].Response := '4275D08C6048E82ED220ADE0EA91B9379100';
  Result[6].Command := '90AD00000F000000000400003CCD30938596473000';
  Result[6].Response := '7035BD33DBC6BEBA92A4F22021517C1845C06558DEAF5BD59100';
  Result[7].Command := '90F500000900DABCC8235B2E296D00';
  Result[7].Response := '000311110400000B24E7D572B47ED29100';
end;
function LrpNativeBadCapability: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := '6077B0621AD4F439A827156E28F69E0DCC0B95B0BECA482DF99E9527C4FC9FB99100';
end;
function LrpNativeBadMode: TExtendedPairs;
begin
  Result := nil; SetLength(Result,2);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '020102030405060708090A0B0C0D0E0F1091AF';
end;
function LrpOwnedBackup: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '00249244E0FDADD0739100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '010300000400007993A09A8F4924769100';
  Result[6].Command := '90AD00000F00000000040000BADD5E69205F0D4100';
  Result[6].Response := '6E93DA41ED9025E1FE500D7835A3AB37B7B11047209769299100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '908D00001F00000000040000623154630527F506219C4097936D6B4873C8012AD194F5B400';
  Result[8].Response := 'A5452D06A4841B789100';
  Result[9].Command := '90C7000009002337A7FE87E89E0500';
  Result[9].Response := '6CBB8D2FF204BC1B9100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '90AD00000F0000000004000026228D4278AAE09900';
  Result[11].Response := 'F8736047C5A804E5B9A1DBF9DC2CE8A9758576ED6FDFA8429100';
  Result[12].Command := '90F50000090044D458AC5650359A00';
  Result[12].Response := '01030000040000FDD444E633F519189100';
end;
function LrpOwnedValue: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '00249244E0FDADD0739100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '0203000000000000E80300000000000000600DF7B62EF760B19100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '0203000000000000E803000000000000005DC1B8A2770670729100';
  Result[6].Command := '906C000009000F4883D025364C5600';
  Result[6].Response := '131097061F99FE950D00200DD9136D41EB6FC7B6D72B5ADD9100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '0203000000000000E80300000000000000B3B6680360B02D0E9100';
  Result[8].Command := '900C000019005CB0AE5865D269956D006FCBC2F6CBA8FA66E8EBC390240D00';
  Result[8].Response := 'A5452D06A4841B789100';
  Result[9].Command := '90C7000009002337A7FE87E89E0500';
  Result[9].Response := '6CBB8D2FF204BC1B9100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0203000000000000E80300000000000000DFF114EB6902B3C89100';
  Result[11].Command := '906C00000900E7B0A930099929CA00';
  Result[11].Response := '7EC1EBE66C0CC4C42165C0AAB2CE6C53CBF4816B7A7381D39100';
  Result[12].Command := '90F50000090044D458AC5650359A00';
  Result[12].Response := '0203000000000000E803000000000000003AD532F8497DFC5C9100';
end;
function LrpOwnedRecord: TExtendedPairs;
begin
  Result := nil; SetLength(Result,14);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '00249244E0FDADD0739100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '04030000100000040000020000AEF2E34564713C5C9100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '04030000100000040000020000F275F48CEFACEAD69100';
  Result[6].Command := '90AB00000F00000000020000DE1872CC9BCACB5300';
  Result[6].Response := '909217E119ECDAF47E171BD3AEACDA57A1B233C6453A5E519AE6F3CB849D021612184616E4227781742A0C827BCD2E7D97F147B3651D43CE9100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '0403000010000004000002000018958C74A0CC3D069100';
  Result[8].Command := '90BA00003000010000000000100000B61655A3DA0D50BFBFE29C7E94846AA098E941F5D09E9BECDC554AFF9BCD5A41F1756A86529700';
  Result[8].Response := '91AF';
  Result[9].Command := '90AF000002880F00';
  Result[9].Response := 'A5452D06A4841B789100';
  Result[10].Command := '90C7000009002337A7FE87E89E0500';
  Result[10].Response := '6CBB8D2FF204BC1B9100';
  Result[11].Command := '90F5000009003FC45FF67821DDC400';
  Result[11].Response := '04030000100000040000020000807D03FB531504BE9100';
  Result[12].Command := '90AB00000F00000000020000E6FE6511181D5EE100';
  Result[12].Response := '366595D4096611C382D3295856FB4C16334725537D7D569CF7C287E53C403E8F8432D43E3412C637CDFC60BF16FC945122D3A6D238358C059100';
  Result[13].Command := '90F50000090044D458AC5650359A00';
  Result[13].Response := '040300001000000400000200005514A16EED31CECF9100';
end;
function LrpOwnedAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '00249244E0FDADD0739100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F500000900B58EA6101C77791C00';
  Result[5].Response := '010300000400007993A09A8F4924769100';
  Result[6].Command := '90AD00000F00000000040000BADD5E69205F0D4100';
  Result[6].Response := '6E93DA41ED9025E1FE500D7835A3AB37B7B11047209769299100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '908D00001F00000000040000623154630527F506219C4097936D6B4873C8012AD194F5B400';
  Result[8].Response := 'A5452D06A4841B789100';
  Result[9].Command := '90A70000086186B0A663A68FCC00';
  Result[9].Response := '6CBB8D2FF204BC1B9100';
end;
function LrpTransactionCrypto: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '0001008018000300041122334455665A';
  Result[0].Response := '9CEA7E3CCA4ED54BE884B83C303346DD';
  Result[1].Command := '000100801800030004112233445566A5';
  Result[1].Response := 'CE7ED77F713FA22464733605F870C1E2';
  Result[2].Command := 'AD00000000040000000000000000000001020304000000000000000000000000';
  Result[2].Response := '1E73120F39A9E4F3';
  Result[3].Command := '102132435465768798A9BACBDCEDFE0F';
  Result[3].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97';
end;
function LrpTmacWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '90AD00000F000000000400002D49ADE51C4FF37400';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0103000004000006F891123048DA959100';
  Result[10].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A98DE976B403474A4500';
  Result[10].Response := '262E31CA0A7FDC3C9100';
  Result[11].Command := '90F5000009019FD8F0B27F06E88400';
  Result[11].Response := '0520F0EF02342000226BDD07B0F9731B9100';
  Result[12].Command := '90C70000090168B7431C3BD7B9AB00';
  Result[12].Response := '18000300A3031F8F47F2635FF83483F2B5025CDB9100';
  Result[13].Command := '90F500000900E2912F4CD31EF0DE00';
  Result[13].Response := '01030000040000F7AF4184CB53BE989100';
  Result[14].Command := '90AD00000F00000000040000D74C5B78DD6A6F6E00';
  Result[14].Response := '6EDAA4A61B2D0371A024D8F92282775E4CE5327779FF96F49100';
  Result[15].Command := '90F50000090066186D842818474400';
  Result[15].Response := '01030000040000C0239866B1B2CEFF9100';
end;
function LrpTmacRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '90AD00000F000000000400002D49ADE51C4FF37400';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0103000004000006F891123048DA959100';
  Result[10].Command := '90F500000901FF2199FF8725778100';
  Result[10].Response := '0520F0EF02342000F475E8864B78EC0E9100';
  Result[11].Command := '90C700000901E20268E71A40E4DD00';
  Result[11].Response := '180003001E73120F39A9E4F3BBFDDFCED70480109100';
end;
function LrpTmacAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '90AD00000F000000000400002D49ADE51C4FF37400';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0103000004000006F891123048DA959100';
  Result[10].Command := '90A7000008DF8513DFB8814D8E00';
  Result[10].Response := '262E31CA0A7FDC3C9100';
end;
function LrpTmacStandard: TExtendedPairs;
begin
  Result := nil; SetLength(Result,18);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '000300000800008C03CAAEE2B838229100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '00030000080000C3C04A3620B009D09100';
  Result[8].Command := '90AD00000F00020000040000B5E8E7FB548B674000';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '00030000080000DE31E3B00FF1320A9100';
  Result[10].Command := '908D00001F00020000040000F8736047C5A804E5B9A1DBF9DC2CE8A963970AF6615B282500';
  Result[10].Response := '262E31CA0A7FDC3C9100';
  Result[11].Command := '90AD00000F000200000400001AEDCF56374B4EB200';
  Result[11].Response := '6EDAA4A61B2D0371A024D8F92282775E8581CC7BAF4E563C9100';
  Result[12].Command := '90F50000090044D458AC5650359A00';
  Result[12].Response := '00030000080000FF4F5B0B45A9D1809100';
  Result[13].Command := '90F5000009019731628E10A3E66100';
  Result[13].Response := '0520F0EF02342000EBCCDF717C81BCF49100';
  Result[14].Command := '90C700000901A69EB811D153E96C00';
  Result[14].Response := '180003007E1ADF7C2756E3E52422B3B0DA9F68419100';
  Result[15].Command := '90F50000090066186D842818474400';
  Result[15].Response := '000300000800004CA609100B018AB79100';
  Result[16].Command := '90AD00000F000200000400009D6F3B3A2904F65500';
  Result[16].Response := 'B813555E057391A8502DFCD019368E5CB7238EB480C5CF189100';
  Result[17].Command := '90F500000900CC501AA0728D07EA00';
  Result[17].Response := '0003000008000057420D7C96E7444F9100';
end;
function LrpTmacRecord: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '04030000100000040000020000AEF2E34564713C5C9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '0403000010000004000002000018958C74A0CC3D069100';
  Result[8].Command := '90AB00000F000000000200003677DEF4492F838A00';
  Result[8].Response := 'F366EC9383C5C6CC076C43D38CF78FAC4F68CA3FC92E74066EC2D4B3A76FAA618CD643AFC5A77752E2D3C40443ACE184AE50128D6C1360FC9100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0403000010000004000002000029FD28D656B958C19100';
  Result[10].Command := '90BA000030000100000000001000000D5329ED157B4F222916E0059F0DDF274C5888EA2CBD19385D191B8806E5D21BA2AA2DBF8C2600';
  Result[10].Response := '91AF';
  Result[11].Command := '90AF000002190D00';
  Result[11].Response := '262E31CA0A7FDC3C9100';
  Result[12].Command := '90F5000009019FD8F0B27F06E88400';
  Result[12].Response := '0520F0EF02342000226BDD07B0F9731B9100';
  Result[13].Command := '90C70000090168B7431C3BD7B9AB00';
  Result[13].Response := '180003006D0C33359470924BFBCEB4FA0E9C47D19100';
  Result[14].Command := '90F500000900E2912F4CD31EF0DE00';
  Result[14].Response := '04030000100000040000020000B72880FCA1EE4F8B9100';
  Result[15].Command := '90AB00000F00000000020000E70325BF2FB35AB700';
  Result[15].Response := '8C54926B3C35F05EA5F07F8909F454127F51481629D3BAA750B5DAA6F17A6B3424885426AF0E7D0CA5905C00F1C0DDDF1C4DD06ABB3FDE679100';
  Result[16].Command := '90F50000090066186D842818474400';
  Result[16].Response := '04030000100000040000020000B29913A842258BAA9100';
end;
function LrpTmacWrongReceipt: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '90AD00000F000000000400002D49ADE51C4FF37400';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0103000004000006F891123048DA959100';
  Result[10].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A98DE976B403474A4500';
  Result[10].Response := '262E31CA0A7FDC3C9100';
  Result[11].Command := '90F5000009019FD8F0B27F06E88400';
  Result[11].Response := '0520F0EF02342000226BDD07B0F9731B9100';
  Result[12].Command := '90C70000090168B7431C3BD7B9AB00';
  Result[12].Response := '18000300A2031F8F47F2635F13C205017CA3A2459100';
end;
function LrpTmacWrongAct: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '90AD00000F000000000400002D49ADE51C4FF37400';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0103000004000006F891123048DA959100';
  Result[10].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A98DE976B403474A4500';
  Result[10].Response := '262E31CA0A7FDC3C9100';
  Result[11].Command := '90F5000009019FD8F0B27F06E88400';
  Result[11].Response := '0520F0EF02342000226BDD07B0F9731B9100';
  Result[12].Command := '90C70000090168B7431C3BD7B9AB00';
  Result[12].Response := '19000300A3031F8F47F2635F84F135859AED27599100';
end;
function LrpTmacWrongSession: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '90AD00000F000000000400002D49ADE51C4FF37400';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0103000004000006F891123048DA959100';
  Result[10].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A98DE976B403474A4500';
  Result[10].Response := '262E31CA0A7FDC3C9100';
  Result[11].Command := '90F5000009019FD8F0B27F06E88400';
  Result[11].Response := '0520F0EF02342000226BDD07B0F9731B9100';
  Result[12].Command := '90C70000090168B7431C3BD7B9AB00';
  Result[12].Response := '18000400A3031F8F47F2635F404BA79E3000E37F9100';
end;
function LrpTmacWrongPostimage: TExtendedPairs;
begin
  Result := nil; SetLength(Result,15);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '90AD00000F000000000400002D49ADE51C4FF37400';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0103000004000006F891123048DA959100';
  Result[10].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A98DE976B403474A4500';
  Result[10].Response := '262E31CA0A7FDC3C9100';
  Result[11].Command := '90F5000009019FD8F0B27F06E88400';
  Result[11].Response := '0520F0EF02342000226BDD07B0F9731B9100';
  Result[12].Command := '90C70000090168B7431C3BD7B9AB00';
  Result[12].Response := '18000300A3031F8F47F2635FF83483F2B5025CDB9100';
  Result[13].Command := '90F500000900E2912F4CD31EF0DE00';
  Result[13].Response := '01030000040000F7AF4184CB53BE989100';
  Result[14].Command := '90AD00000F00000000040000D74C5B78DD6A6F6E00';
  Result[14].Response := '9C1D376E57780ACAE480404A5540F201DA317068A2EE7CA19100';
end;
function LrpTmacLimitReached: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0520F0EF0234200017078C096C0B31539100';
end;
function LrpTmacReaderWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A9DD8F9F49F331D88B00';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[12].Response := '052000EF02342000B3332E640671C3E69100';
  Result[13].Command := '90C7000009014A06D2F6877807FE00';
  Result[13].Response := '18000300B2259AA6E1E7187F39A2E72E614B21019100';
  Result[14].Command := '90F5000009003BF82919A7B25EFA00';
  Result[14].Response := '01030000040000E332CCB8F10E6B149100';
  Result[15].Command := '90AD00000F00000000040000C268FB5DD855730700';
  Result[15].Response := '6EDAA4A61B2D0371A024D8F92282775E60EEDF435B11FC109100';
  Result[16].Command := '90F500000900C8D51EDC9B9D29E000';
  Result[16].Response := '0103000004000046A919358DE71C1A9100';
end;
function LrpTmacReaderRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '90F5000009019FD8F0B27F06E88400';
  Result[11].Response := '052000EF02342000FAEB3B2B07BF187E9100';
  Result[12].Command := '90C70000090168B7431C3BD7B9AB00';
  Result[12].Response := '1800030037CB6DA408A6A7979A40892395EFDB829100';
end;
function LrpTmacReaderAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '90A7000008F14D55E55FDB6E9700';
  Result[11].Response := '648B3D4C01C939039100';
end;
function LrpTmacReaderStandard: TExtendedPairs;
begin
  Result := nil; SetLength(Result,19);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '000300000800008C03CAAEE2B838229100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '000300000800000691395E52F43C3F9100';
  Result[9].Command := '90AD00000F00020000040000E5A1783036F03A0800';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '00030000080000AB5F1F7D39AE67D49100';
  Result[11].Command := '908D00001F00020000040000F8736047C5A804E5B9A1DBF9DC2CE8A901680762A7AD173800';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90AD00000F00020000040000D2301097E270C23D00';
  Result[12].Response := '6EDAA4A61B2D0371A024D8F92282775ED762B606DF59DCEF9100';
  Result[13].Command := '90F500000900E2912F4CD31EF0DE00';
  Result[13].Response := '00030000080000DFC313AF97DA7C8B9100';
  Result[14].Command := '90F500000901C6DDCD8952296C0500';
  Result[14].Response := '052000EF02342000B749DFB8BFF6B3A09100';
  Result[15].Command := '90C700000901FECE4A0F20EE24B300';
  Result[15].Response := '180003004F70A0B73F184DAA32751AF916D27A519100';
  Result[16].Command := '90F500000900C8D51EDC9B9D29E000';
  Result[16].Response := '000300000800002702B0313628367C9100';
  Result[17].Command := '90AD00000F0002000004000094A8B6BB2B97289000';
  Result[17].Response := 'B813555E057391A8502DFCD019368E5CD409436959612DC19100';
  Result[18].Command := '90F500000900C5C1180048F556B300';
  Result[18].Response := '0003000008000074C6009F5E2155C99100';
end;
function LrpTmacReaderRecord: TExtendedPairs;
begin
  Result := nil; SetLength(Result,18);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '04030000100000040000020000AEF2E34564713C5C9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '04030000100000040000020000D0B9A44186FDB3109100';
  Result[9].Command := '90AB00000F000000000200003FE93A6E6618135E00';
  Result[9].Response := 'F366EC9383C5C6CC076C43D38CF78FAC4F68CA3FC92E74066EC2D4B3A76FAA618CD643AFC5A77752E2D3C40443ACE184F25DDBD7D2968A4F9100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '04030000100000040000020000807D03FB531504BE9100';
  Result[11].Command := '90BA000030000100000000001000000D5329ED157B4F222916E0059F0DDF274C5888EA2CBD19385D191B8806E5D21B0E9B7D5CD74100';
  Result[11].Response := '91AF';
  Result[12].Command := '90AF000002553E00';
  Result[12].Response := '648B3D4C01C939039100';
  Result[13].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[13].Response := '052000EF02342000B3332E640671C3E69100';
  Result[14].Command := '90C7000009014A06D2F6877807FE00';
  Result[14].Response := '18000300B0F43B14086CB4D6E3D5647A50C47CCE9100';
  Result[15].Command := '90F5000009003BF82919A7B25EFA00';
  Result[15].Response := '040300001000000400000200000750C6B937DBFD0F9100';
  Result[16].Command := '90AB00000F00000000020000059019818696BE3E00';
  Result[16].Response := '8C54926B3C35F05EA5F07F8909F454127F51481629D3BAA750B5DAA6F17A6B3424885426AF0E7D0CA5905C00F1C0DDDF7976E7F45E182EBF9100';
  Result[17].Command := '90F500000900C8D51EDC9B9D29E000';
  Result[17].Response := '04030000100000040000020000743E9D580EA67A5D9100';
end;
function LrpTmacReaderWrongReceipt: TExtendedPairs;
begin
  Result := nil; SetLength(Result,14);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A9DD8F9F49F331D88B00';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[12].Response := '052000EF02342000B3332E640671C3E69100';
  Result[13].Command := '90C7000009014A06D2F6877807FE00';
  Result[13].Response := '18000300B3259AA6E1E7187F82DBA0AB239134509100';
end;
function LrpTmacReaderWrongAct: TExtendedPairs;
begin
  Result := nil; SetLength(Result,14);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A9DD8F9F49F331D88B00';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[12].Response := '052000EF02342000B3332E640671C3E69100';
  Result[13].Command := '90C7000009014A06D2F6877807FE00';
  Result[13].Response := '19000300B2259AA6E1E7187FF3088D4BD2C614259100';
end;
function LrpTmacReaderWrongSession: TExtendedPairs;
begin
  Result := nil; SetLength(Result,14);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A9DD8F9F49F331D88B00';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[12].Response := '052000EF02342000B3332E640671C3E69100';
  Result[13].Command := '90C7000009014A06D2F6877807FE00';
  Result[13].Response := '18000400B2259AA6E1E7187F4457AF65DDEE76E49100';
end;
function LrpTmacReaderWrongPostimage: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '47B7BF09BC19ACE3BBD9F6BE6C44AF97262F1E6D9595CAB69100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A9DD8F9F49F331D88B00';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[12].Response := '052000EF02342000B3332E640671C3E69100';
  Result[13].Command := '90C7000009014A06D2F6877807FE00';
  Result[13].Response := '18000300B2259AA6E1E7187F39A2E72E614B21019100';
  Result[14].Command := '90F5000009003BF82919A7B25EFA00';
  Result[14].Response := '01030000040000E332CCB8F10E6B149100';
  Result[15].Command := '90AD00000F00000000040000C268FB5DD855730700';
  Result[15].Response := '9C1D376E57780ACAE480404A5540F2017EC32F487B52C8C29100';
end;
function LrpTmacReaderLimitReached: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '052000EF023420003A5E4E3B730676BE9100';
end;
function LrpTmacAcquired1: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '050000EF023494A4A890EFFDA1899100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '5E6072AE7C5B61BBDBC79BB4B1E2EB1D6B257C8D84781FE49100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A9DD8F9F49F331D88B00';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[12].Response := '050000EF023499FD12EB68093C659100';
  Result[13].Command := '90C7000009014A06D2F6877807FE00';
  Result[13].Response := '18000100C9060DA8AB60ABD38149BE76E9105A529100';
  Result[14].Command := '90F5000009003BF82919A7B25EFA00';
  Result[14].Response := '01030000040000E332CCB8F10E6B149100';
  Result[15].Command := '90AD00000F00000000040000C268FB5DD855730700';
  Result[15].Response := '6EDAA4A61B2D0371A024D8F92282775E60EEDF435B11FC109100';
  Result[16].Command := '90F500000900C8D51EDC9B9D29E000';
  Result[16].Response := '0103000004000046A919358DE71C1A9100';
end;
function LrpTmacAcquired7: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '050000EF023494A4A890EFFDA1899100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := 'CF71E1D955E0566357612EEACB5664F25FECE8333BB700E59100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A9DD8F9F49F331D88B00';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[12].Response := '050000EF023499FD12EB68093C659100';
  Result[13].Command := '90C7000009014A06D2F6877807FE00';
  Result[13].Response := '18000700681C13040226B38BEFB39FDA06C5B0459100';
  Result[14].Command := '90F5000009003BF82919A7B25EFA00';
  Result[14].Response := '01030000040000E332CCB8F10E6B149100';
  Result[15].Command := '90AD00000F00000000040000C268FB5DD855730700';
  Result[15].Response := '6EDAA4A61B2D0371A024D8F92282775E60EEDF435B11FC109100';
  Result[16].Command := '90F500000900C8D51EDC9B9D29E000';
  Result[16].Response := '0103000004000046A919358DE71C1A9100';
end;
function LrpTmacAcquired65535: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '050000EF023494A4A890EFFDA1899100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F8F9B594C7331D41B00';
  Result[7].Response := '2591DA65CF70D1B62B7DE2E53B52DE2430E9F65472FAFCF49100';
  Result[8].Command := '90F500000900615B4071502FF60000';
  Result[8].Response := '010300000400007A24486F8EEC6BB29100';
  Result[9].Command := '90AD00000F000000000400001AE61667A508F77900';
  Result[9].Response := '90679F83C73DE2A1B73C9074C7154747E3C36BAB7F418D219100';
  Result[10].Command := '90F5000009003FC45FF67821DDC400';
  Result[10].Response := '0103000004000095740B66B5BAE8C59100';
  Result[11].Command := '908D00001F00000000040000F8736047C5A804E5B9A1DBF9DC2CE8A9DD8F9F49F331D88B00';
  Result[11].Response := '648B3D4C01C939039100';
  Result[12].Command := '90F50000090174EC6D1D2CF7C97E00';
  Result[12].Response := '050000EF023499FD12EB68093C659100';
  Result[13].Command := '90C7000009014A06D2F6877807FE00';
  Result[13].Response := '1800FFFF06760B1A43A085CA4FE9A22CDC426BB79100';
  Result[14].Command := '90F5000009003BF82919A7B25EFA00';
  Result[14].Response := '01030000040000E332CCB8F10E6B149100';
  Result[15].Command := '90AD00000F00000000040000C268FB5DD855730700';
  Result[15].Response := '6EDAA4A61B2D0371A024D8F92282775E60EEDF435B11FC109100';
  Result[16].Command := '90F500000900C8D51EDC9B9D29E000';
  Result[16].Response := '0103000004000046A919358DE71C1A9100';
end;
function LrpTmacZeroSession: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '906F00000805E3A08E954A8C3200';
  Result[3].Response := '0001DB43E4BDA91743859100';
  Result[4].Command := '90F500000900BCEDCB4B9018211C00';
  Result[4].Response := '01030000040000617A62B240B9294D9100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0500F0EF0234ACA0FC8A06C4DADF9100';
  Result[6].Command := '90510000085412C9BC366EB19B00';
  Result[6].Response := '6F46AA25151A10AABD8D71445D44888B17A04D8F072D29729100';
  Result[7].Command := '90F50000090048A7EFD20E2BBF7A00';
  Result[7].Response := '01030000040000AB983AEB8A4159FF9100';
  Result[8].Command := '90AD00000F000000000400002D49ADE51C4FF37400';
  Result[8].Response := '90679F83C73DE2A1B73C9074C715474771BD535EDE7721799100';
  Result[9].Command := '90F50000090097048160AA334A0700';
  Result[9].Response := '0103000004000006F891123048DA959100';
  Result[10].Command := '90F500000901FF2199FF8725778100';
  Result[10].Response := '0500F0EF023421CD2CCB5C165D989100';
  Result[11].Command := '90C700000901E20268E71A40E4DD00';
  Result[11].Response := '1800000000000000000000001B24438FFCC80EC29100';
end;
function LrpNativeUid: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '9051000008F1D8F9065A237F5A00';
  Result[3].Response := '6F46AA25151A10AABD8D71445D44888B5F4B183F8687AB759100';
end;
function DfNativeUid: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90510000088B9663175782C45300';
  Result[3].Response := '98A003281D24738C997028AC7BE1F287590CF4A9375EDAE99100';
end;
function LrpStoredTmacPlain: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009016E8B0539D97BC82F00';
  Result[3].Response := '0500F0EF0234F0962CF4DEFFDC119100';
  Result[4].Command := '90AD000007010000000C000000';
  Result[4].Response := '1700090011223344556677889100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0500F0EF0234ACA0FC8A06C4DADF9100';
end;
function LrpStoredTmacMac: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009016E8B0539D97BC82F00';
  Result[3].Response := '0501F0EF0234E74189F2C68DE8C09100';
  Result[4].Command := '90AD00000F010000000C0000E3289581E7CAF03200';
  Result[4].Response := '17000900112233445566778873B98C15B3C668299100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0501F0EF0234B10599411620B1EC9100';
end;
function LrpStoredTmacFull: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000008000602000000000000';
  Result[1].Response := '010102030405060708090A0B0C0D0E0F1091AF';
  Result[2].Command := '90AF000020B04D0787C93EE0CC8CACC8E86F16C6FE3C29BBAED89DC54169734EE0DB0F7AB100';
  Result[2].Response := 'EB5A4FEC8610C9038BDC14940D0EDB35ED8EE556B4CA938345A98841873FAB7A9100';
  Result[3].Command := '90F5000009016E8B0539D97BC82F00';
  Result[3].Response := '0503F0EF0234A508A170D2F4C5119100';
  Result[4].Command := '90AD00000F010000000C0000E3289581E7CAF03200';
  Result[4].Response := '32D06CD4C5A2E2EAFA896460E55115C20C4C1E1A125D2E719100';
  Result[5].Command := '90F5000009012FA0D5B2D029F26D00';
  Result[5].Response := '0503F0EF023406C5EEB75AAC9D119100';
end;
end.
