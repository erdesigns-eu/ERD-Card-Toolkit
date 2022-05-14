{*******************************************************}
{                                                       }
{             untGPErrorCodes (errorcodes.h)            }
{                     Author: ERD                       }
{                                                       }
{       Global Platform errorcodes.h translation        }
{                                                       }
{*******************************************************}

unit untGPErrorCodes;

interface

uses
  WinApi.Windows;

// Self defined errors.
const
  OPGP_ERROR_SUCCESS                                                 = 0;
  OPGP_ERROR_UNRECOGNIZED_APDU_COMMAND                       : DWORD = $80301000;
  OPGP_ERROR_CARD_CRYPTOGRAM_VERIFICATION                    : DWORD = $80302000;
  OPGP_ERROR_COMMAND_SECURE_MESSAGING_TOO_LARGE              : DWORD = $80303000;
  OPGP_ERROR_COMMAND_TOO_LARGE                               : DWORD = $80303001;
  OPGP_ERROR_INSUFFICIENT_BUFFER                             : DWORD = $80304000;
  OPGP_ERROR_WRONG_TRY_LIMIT                                 : DWORD = $80306000;
  OPGP_ERROR_WRONG_PIN_LENGTH                                : DWORD = $80307000;
  OPGP_ERROR_WRONG_KEY_VERSION                               : DWORD = $80308000;
  OPGP_ERROR_WRONG_KEY_INDEX                                 : DWORD = $80309000;
  OPGP_ERROR_WRONG_KEY_TYPE                                  : DWORD = $8030A000;
  OPGP_ERROR_KEY_CHECK_VALUE                                 : DWORD = $8030B000;
  OPGP_ERROR_INVALID_COMBINATION_KEY_SET_VERSION_KEY_INDEX   : DWORD = $8030C000;
  OPGP_ERROR_MORE_KEY_INFORMATION_TEMPLATES                  : DWORD = $8030D000;
  OPGP_ERROR_APPLICATION_TOO_BIG                             : DWORD = $8030E000;
  OPGP_ERROR_VALIDATION_FAILED                               : DWORD = $8030F000;
  OPGP_ERROR_INVALID_FILENAME                                : DWORD = $8030F001;
  OPGP_ERROR_INVALID_PASSWORD                                : DWORD = $8030F002;
  OPGP_ERROR_WRONG_EXPONENT                                  : DWORD = $8030F003;
  OPGP_ERROR_INVALID_LOAD_FILE                               : DWORD = $8030F008;
  OPGP_ERROR_CAP_UNZIP                                       : DWORD = $8030F009;
  OPGP_ERROR_INVALID_RESPONSE_DATA                           : DWORD = $8030F00B;
  OPGP_ERROR_CRYPT                                           : DWORD = $8030F00C;

  // Philip Wendland: added this because security level 3 of SCP03 is not supported yet.
  OPGP_ERROR_SCP03_SECURITY_R_ENCRYPTION_R_MAC_NOT_SUPPORTED : DWORD = $8030F00E;

  // Open Platform 2.0.1' specific errors
  OP201_ERROR_LOAD_FILE_DAP_NULL                             : DWORD = $8030F007;
  OP201_ERROR_MORE_APPLICATION_DATA                          : DWORD = $80305001;

  // GlobalPlatform 2.1.1 specific errors
  GP211_ERROR_MORE_APPLICATION_DATA                          : DWORD = $80305000;
  GP211_ERROR_LOAD_FILE_DATA_BLOCK_HASH_NULL                 : DWORD = $8030F004;
  GP211_ERROR_INVALID_SCP                                    : DWORD = $8030F005;
  GP211_ERROR_INVALID_SCP_IMPL                               : DWORD = $8030F006;
  GP211_ERROR_VALIDATION_R_MAC                               : DWORD = $8030F007;
  GP211_ERROR_INCONSISTENT_SCP                               : DWORD = $8030F00A;
  GP211_ERROR_INCORRECT_CARD_CHALLENGE                       : DWORD = $8030F00D;
  GP211_ERROR_INCONSISTENT_SCP_IMPL                          : DWORD = $8030F00C;

 (* Mapping of ISO7816-4 errors to error codes.
  * 0x8020XXXX is the general meaning error.
  * 0x802YXXXX is a special meaning for a use case.
  *)
  OPGP_ISO7816_ERROR_PREFIX                                  : DWORD = $80200000;


  // Normal processing
  OPGP_ISO7816_ERROR_SUCCESS                                 : DWORD = $9000;
  OPGP_ISO7816_ERROR_RESPONSE_LENGTH                         : DWORD = $6100;

  // State of non-volatile memory unchanged
  OPGP_ISO7816_ERROR_FILE_INVALIDATED                        : DWORD = $6283;
  OPGP_ISO7816_WARNING_CM_LOCKED                             : DWORD = $16283;

  OPGP_ISO7816_ERROR_FILE_TERMINATED                         : DWORD = $6285;

  // State of non-volatile memory changed
  OPGP_ISO7816_ERROR_6300                                    : DWORD = $6300;
  OPGP_ISO7816_ERROR_HOST_CRYPTOGRAM_VERIFICATION            : DWORD = $16300;

  OPGP_ISO7816_ERROR_MORE_DATA_AVAILABLE                     : DWORD = $6310;

  // Execution errors
  OPGP_ISO7816_ERROR_NOTHING_SPECIFIC                        : DWORD = $6400;
  OPGP_ISO7816_ERROR_MEMORY_FAILURE                          : DWORD = $6581;

  OPGP_ISO7816_ERROR_WRONG_LENGTH                            : DWORD = $6700;

  OPGP_ISO7816_ERROR_CHANNEL_NOT_SUPPORTED                   : DWORD = $6881;
  OPGP_ISO7816_ERROR_SECURE_MESSAGING_NOT_SUPPORTED          : DWORD = $6882;

  // Command not allowed class.
  OPGP_ISO7816_ERROR_CONDITIONS_NOT_SATISFIED                : DWORD = $6985;
  OPGP_ISO7816_ERROR_NOT_MULTI_SELECTABLE                    : DWORD = $16985;

  OPGP_ISO7816_ERROR_SECURITY_STATUS_NOT_SATISFIED           : DWORD = $6982;

  OPGP_ISO7816_ERROR_6999                                    : DWORD = $6999;
  OPGP_ISO7816_ERROR_SELECTION_REJECTED                      : DWORD = $6999;

  // Wrong parameter(s) P1-P2 class.
  OPGP_ISO7816_ERROR_WRONG_DATA                              : DWORD = $6A80;
  OPGP_ISO7816_ERROR_WRONG_GLOBAL_PIN_FORMAT                 : DWORD = $16A80;

  OPGP_ISO7816_ERROR_FUNC_NOT_SUPPORTED                      : DWORD = $6A81;
  OPGP_ISO7816_ERROR_APPLET_NOT_SELECTABLE                   : DWORD = $16A81;

  OPGP_ISO7816_ERROR_FILE_NOT_FOUND                          : DWORD = $6A82;
  OPGP_ISO7816_ERROR_APPLET_NOT_FOUND                        : DWORD = $16A82;

  OPGP_ISO7816_ERROR_NOT_ENOUGH_MEMORY                       : DWORD = $6A84;

  OPGP_ISO7816_ERROR_INCORRECT_P1P2                          : DWORD = $6A86;
  OPGP_ISO7816_ERROR_WRONG_PIN_TRY_LIMIT                     : DWORD = $16A86;

  OPGP_ISO7816_ERROR_DATA_NOT_FOUND                          : DWORD = $6A88;

  OPGP_ISO7816_ERROR_WRONG_P1P2                              : DWORD = $6B00;
  OPGP_ISO7816_ERROR_CORRECT_LENGTH                          : DWORD = $6C00;
  OPGP_ISO7816_ERROR_INVALID_INS                             : DWORD = $6D00;
  OPGP_ISO7816_ERROR_WRONG_CLA                               : DWORD = $6E00;

  OPGP_ISO7816_ERROR_ILLEGAL_PARAMETER                       : DWORD = $6F74;

  OPGP_ISO7816_ERROR_ALGORITHM_NOT_SUPPORTED                 : DWORD = $9484;
  OPGP_ISO7816_ERROR_INVALID_KEY_CHECK_VALUE                 : DWORD = $9485;

implementation

end.

