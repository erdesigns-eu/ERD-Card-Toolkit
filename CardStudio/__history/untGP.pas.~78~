{*******************************************************}
{                                                       }
{               untGP (globalplatform.h)                }
{                     Author: ERD                       }
{                                                       }
{     Global Platform globalplatform.h translation      }
{                                                       }
{*******************************************************}

unit untGP;

interface

uses
  WinApi.Windows,
  System.SysUtils,
  untGPConnection,
  untGPSecurity,
  untGPErrorCodes;

const
  GlobalPlatform = 'globalplatform.dll';

const
  APDU_COMMAND_LEN  = 261; //!< The APDU command length: 5 bytes header + 255 body + Le
  APDU_RESPONSE_LEN = 258; //!< The APDU response length: 256 data + 2 bytes SW

  // The default key value for new cards defined in a VISA specification.
  OPGP_VISA_DEFAULT_KEY       : array [0..15] of Byte = ($40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F);

  // The default mother key value for new GemXpresso cards.
  OPGP_GEMXPRESSO_DEFAULT_KEY : array [0..15] of Byte = ($47, $45, $4d, $58, $50, $52, $45, $53, $53, $4f, $53, $41, $4d, $50, $4c, $45);

  // The AID of the Issuer Security Domain defined by GlobalPlatform 2.1.1 specification.
  GP211_CARD_MANAGER_AID      : array [0..6] of Byte = ($A0, $00, $00, $01, $51, $00, $00);

  // The AID of the Issuer Security Domain defined by GlobalPlatform 2.3.1 specification
  GP231_ISD_AID               : array [0..7] of Byte = ($A0, $00, $00, $01, $51, $00, $00, $00);

  // This AID is also used for the Issuer Security Domain, e.g. by JCOP 41 cards.
  GP211_CARD_MANAGER_AID_ALT1 : array [0..7] of Byte = ($A0, $00, $00, $00, $03, $00, $00, $00);

  GP211_LIFE_CYCLE_LOAD_FILE_LOADED             = $01; //!< Executable Load File is loaded.
  GP211_LIFE_CYCLE_CARD_OP_READY                = $01; //!< Card is OP ready.
  GP211_LIFE_CYCLE_CARD_INITIALIZED             = $07; //!< Card is initialized.
  GP211_LIFE_CYCLE_CARD_SECURED                 = $0f; //!< Card is in secured state.
  GP211_LIFE_CYCLE_CARD_LOCKED                  = $7f; //!< Card is locked.
  GP211_LIFE_CYCLE_CARD_TERMINATED              = $ff; //!< Card is terminated.
  GP211_LIFE_CYCLE_APPLICATION_INSTALLED        = $03; //!< Application is installed
  GP211_LIFE_CYCLE_APPLICATION_SELECTABLE       = $07; //!< Application is selectable.
  GP211_LIFE_CYCLE_APPLICATION_LOCKED           = $ff; //!< Application is locked.
  GP211_LIFE_CYCLE_SECURITY_DOMAIN_INSTALLED    = $03; //!< Application is installed
  GP211_LIFE_CYCLE_SECURITY_DOMAIN_SELECTABLE   = $07; //!< Application is selectable.
  GP211_LIFE_CYCLE_SECURITY_DOMAIN_PERSONALIZED = $ff; //!< Application is personalized.
  GP211_LIFE_CYCLE_SECURITY_DOMAIN_LOCKED       = $ff; //!< Application is locked.

  // Consts for MANAGE CHANNEL
  GP211_MANAGE_CHANNEL_OPEN   = $00; //!< Open the next available Supplementary Logical Channel.
  GP211_MANAGE_CHANNEL_CLOSE  = $80; //!< Close the Supplementary Logical Channel.

type
  (**
   *  Application privileges.
   *)
  GP211_APPLICATION_PRIVILEGES = (
    GP211_SECURITY_DOMAIN                       = 1 shl (7 + 16), //!< Application is security domain.
    GP211_DAP_VERIFICATION                      = $C0 shl 16,     //!< Application can require DAP verification for loading and installing applications.
    GP211_DELEGATED_MANAGEMENT                  = $A0 shl 16,     //!< Security domain has delegated management right.
    GP211_CARD_MANAGER_LOCK_PRIVILEGE           = 1 shl (4 + 16), //!< Application can lock the Card Manager.
    GP211_CARD_MANAGER_TERMINATE_PRIVILEGE      = 1 shl (3 + 16), //!< Application can terminate the card.
    GP211_DEFAULT_SELECTED_CARD_RESET_PRIVILEGE = 1 shl (2 + 16), //!< Application is default selected. In GlobalPlatform 2.3.1 this was redefined as Card Reset privilege.
    GP211_PIN_CHANGE_PRIVILEGE                  = 1 shl (1 + 16), //!< Application can change global PIN.
    GP211_MANDATED_DAP_VERIFICATION             = $D0 shl 16,     //!< Security domain requires DAP verification for loading and installing applications.

    GP211_TRUSTED_PATH                          = 1 shl (7 + 8),  //!< Application is a Trusted Path for inter-application communication.
    GP211_AUTHORIZED_MANAGEMENT                 = 1 shl (6 + 8),  //!< Application is capable of Card Content Management; Security Domain privilege shall also be set.
    GP211_TOKEN_VERIFICATION                    = 1 shl (5 + 8),  //!< Application is capable of verifying a token for Delegated Card Content Management.
    GP211_GLOBAL_DELETE                         = 1 shl (4 + 8),  //!< Application may delete any Card Content.
    GP211_GLOBAL_LOCK                           = 1 shl (3 + 8),  //!< Application may lock or unlock any Application.
    GP211_GLOBAL_REGISTRY                       = 1 shl (2 + 8),  //!< Application may access any entry in the GlobalPlatform Registry.
    GP211_FINAL_APPLICATION                     = 1 shl (1 + 8),  //!< The only Application selectable in card Life Cycle State CARD_LOCKED and TERMINATED.
    GP211_GLOBAL_SERVICE                        = 1 shl (0 + 8),  //!< Application provides services to other Applications on the card.

    GP211_RECEIPT_GENERATION                    = 1 shl 7,        //!< Application is capable of generating a receipt for Delegated Card Content Management.
    GP211_CIPHERED_LOAD_FILE_DATA_BLOCK         = 1 shl 6,        //!< The Security Domain requires that the Load File being associated to it is to be loaded ciphered.
    GP211_CONTACTLESS_ACTIVATION                = 1 shl 5,        //!< Application is capable of activating and deactivating any Application on the contactless interface.
    GP211_CONTACTLESS_SELF_ACTIVATION           = 1 shl 4         //!< Application is capable of activating itself on the contactless interface without a prior request to the Application with the Contactless Activation privilege.
  );

const
  GP211_STATUS_APPLICATIONS                      = $40; //!< Indicate Applications or Security Domains in GP211_get_status() (request GP211_APPLICATION_DATA) or GP211_set_status().
  GP211_STATUS_ISSUER_SECURITY_DOMAIN            = $80; //!< Indicate Issuer Security Domain in GP211_get_status() (request GP211_APPLICATION_DATA) or GP211_set_status().
  GP211_STATUS_LOAD_FILES                        = $20; //!< Request GP211_APPLICATION_DATA for Executable Load Files in GP211_get_status().
  GP211_STATUS_LOAD_FILES_AND_EXECUTABLE_MODULES = $10; //!< Request GP211_EXECUTABLE_MODULES_DATA for Executable Load Files and their Executable Modules in GP211_get_status().

  GP211_STATUS_FORMAT_NEW                        = $02; //!< New GP2.1.1 GET STATUS format
  GP211_STATUS_FORMAT_DEPRECATED                 = $00; //!< New GP2.1.1 GET STATUS deprecated format

  // Flags for STORE DATA
  STORE_DATA_ENCRYPTION_NO_INFORMATION           = $00; //!< No general encryption information or non - encrypted data
  STORE_DATA_ENCRYPTION_APPLICATION_DEPENDENT    = $20; //!< Application dependent encryption of the data
  STORE_DATA_ENCRYPTION_RFU                      = $40; //!< RFU(encryption indicator)
  STORE_DATA_ENCRYPTION_ENCRYPTED                = $60; //!< Encrypted data. Must be encrypted with data encryption key.

  STORE_DATA_FORMAT_NO_INFORMATION               = $00; //!< No general data structure information
  STORE_DATA_FORMAT_DGI                          = $08; //!< DGI format of the command data field
  STORE_DATA_FORMAT_BER_TLV                      = $10; //!< BER-TLV format of the command data field
  STORE_DATA_FORMAT_RFU                          = $18; //!< RFU (data structure information)

const
  // Some possible identifiers to retrieve card data with get_data() and put_data().
  GP211_GET_DATA_ISSUER_IDENTIFICATION_NUMBER               : array [0..1] of Byte = ($00, $42); //!< Issuer Identification Number, if Card Manager selected.
  GP211_GET_DATA_APPLICATION_PROVIDER_IDENTIFICATION_NUMBER : array [0..1] of Byte = ($00, $42); //!< Application Provider Identification Number, if Security Domain selected.

  GP211_GET_DATA_CARD_IMAGE_NUMBER                          : array [0..1] of Byte = ($00, $45); //!< Card Image Number, if Card Manager selected.
  GP211_GET_DATA_SECURITY_DOMAIN_IMAGE_NUMBER               : array [0..1] of Byte = ($00, $45); //!< Security Domain Image Number, if Security Domain selected.

  GP211_GET_DATA_ISSUER_SECURITY_DOMAIN_AID                 : array [0..1] of Byte = ($00, $4F); //!< Issuer Security Domain AID, if Issuer Security Domain selected.
  GP211_GET_DATA_SECURITY_DOMAIN_AID                        : array [0..1] of Byte = ($00, $4F); //!< Security Domain AID, if Security Domain selected.
  GP211_GET_DATA_LIST_OF_APPLICATIONS                       : array [0..1] of Byte = ($2F, $00); //!< List of applications present on the card.
  GP211_GET_DATA_EXTENDED_CARD_RESOURCES                    : array [0..1] of Byte = ($FF, $21); //!< Extended card resources according TS 102 226.

  GP211_GET_DATA_CARD_DATA                                  : array [0..1] of Byte = ($00, $66); //!< Card Data.
  GP211_GET_DATA_SECURITY_DOMAIN_MANAGEMENT_DATA            : array [0..1] of Byte = ($00, $66); //!< Security Domain Management Data if Security Domain is selected.
  GP211_GET_DATA_SEQUENCE_COUNTER_DEFAULT_KEY_VERSION       : array [0..1] of Byte = ($00, $C1); //!< Sequence Counter of the default Key Version Number.
  GP211_GET_DATA_CONFIRMATION_COUNTER                       : array [0..1] of Byte = ($00, $C2); //!< Confirmation Counter for generating receipts.
  GP211_GET_DATA_FREE_EEPROM_MEMORY_SPACE                   : array [0..1] of Byte = ($00, $C6); //!< Free EEPROM memory space.
  GP211_GET_DATA_FREE_COR_RAM                               : array [0..1] of Byte = ($00, $C7); //!< Free transient Clear on Reset memory space (COR RAM).
  GP211_GET_DATA_DIVERSIFICATION_DATA                       : array [0..1] of Byte = ($00, $CF); //!< Diversification data.

const
  (**
   * Key Information Template of first 31 keys.
   * Next templates can be obtained with the tag 0x0x 0xE0, where x > 0.
   *)
  GP211_GET_DATA_KEY_INFORMATION_TEMPLATE                             : array [0..1] of Byte = ($00, $E0);

  GP211_GET_DATA_CPLC_PERSONALIZATION_DATE                            : array [0..1] of Byte = ($9F, $66); //!< CPLC personalization date.
  GP211_GET_DATA_CPLC_PRE_PERSONALIZATION_DATE                        : array [0..1] of Byte = ($9F, $67); //!< CPLC pre-personalization date.
  GP211_GET_DATA_CPLC_ICC_MANUFACTURER_EMBEDDING_DATE                 : array [0..1] of Byte = ($9F, $68); //!< CPLC ICC manufacturer, embedding date.
  GP211_GET_DATA_CPLC_MODULE_FABRICATOR_PACKAGING_DATE                : array [0..1] of Byte = ($9F, $69); //!< CPLC module fabricator, module packaging date.
  GP211_GET_DATA_CPLC_FABRICATION_DATE_SERIAL_NUMBER_BATCH_IDENTIFIER : array [0..1] of Byte = ($9F, $6A); //!< CPLC fabrication date, serial number, batch identifier.

  (**
   * Whole CPLC data from ROM and EEPROM.
   * 9F7F // TAG
   * 2A // Length of data
   * ////////////////Data /////////////
   * 4250 // ic fabricator
   * 3272 // ic type
   * 1291 // os id
   * 6181 // os date
   * 0700 // os level
   * 8039 // fabrication date
   * 0106D0BB // ic serial
   * 1D3C // ic batch
   * 0000 // module fabricator
   * 8148 // packing date
   * 0000// icc manufacturer
   * 8148 // ic embedding date
   * 0000 // pre - personalizer
   * 0000 // IC Pre-Personalization Date
   * 00000000 //IC Pre-Personalization Equipment Identifier
   * 0000// IC Personalizer
   * 0000 // IC Personalization Date
   * 00000000 // IC Personalization Equipment Identifier
   *)
  GP211_GET_DATA_CPLC_WHOLE_CPLC                           : array [0..1] of Byte = ($9F, $7F);

  GP211_GET_DATA_FCI_DATA                                  : array [0..1] of Byte = ($BF, $0C); //!< File Control Information (FCI) discretionary data.

  GP211_GET_DATA_PROTOCOL                                  : array [0..1] of Byte = ($DF, $70); //!< Data for protocol change.
  GP211_GET_DATA_ATR_HISTRORICAL_BYTES                     : array [0..1] of Byte = ($DF, $71); //!< Change ATR historical bytes.

  GP211_GET_DATA_EF_PROD_DATA_INITIALIZATION_FINGERPRINT   : array [0..1] of Byte = ($DF, $76); //!< EF<sub>prod</sub> data initialization fingerprint.
  GP211_GET_DATA_EF_PROD_DATA_INITIALIZATION_DATA          : array [0..1] of Byte = ($DF, $77); //!< EF<sub>prod</sub> data initialization data.
  GP211_GET_DATA_EF_PROD_DATA_PRODUCTION_KEY_INDEX         : array [0..1] of Byte = ($DF, $78); //!< EF<sub>prod</sub> data production key index.
  GP211_GET_DATA_EF_PROD_DATA_PROTOCOL_VERSION             : array [0..1] of Byte = ($DF, $79); //!< EF<sub>prod</sub> data protocol version.
  GP211_GET_DATA_EF_PROD_DATA_CHECKSUM                     : array [0..1] of Byte = ($DF, $7A); //!< EF<sub>prod</sub> data checksum.
  GP211_GET_DATA_EF_PROD_DATA_SOFTWARE_VERSION             : array [0..1] of Byte = ($DF, $7B); //!< EF<sub>prod</sub> data software version.
  GP211_GET_DATA_EF_PROD_DATA_RFU                          : array [0..1] of Byte = ($DF, $7C); //!< EF<sub>prod</sub> data RFU.
  GP211_GET_DATA_EF_PROD_DATA_PROFILE_WITH_PROFILE_VERSION : array [0..1] of Byte = ($DF, $7D); //!< EF<sub>prod</sub> data profile with profile version.
  GP211_GET_DATA_EF_PROD_DATA_LOCATION_MACHINE_DATE_TIME   : array [0..1] of Byte = ($DF, $7E); //!< EF<sub>prod</sub> data location, machine number, date, time.

  GP211_GET_DATA_WHOLE_EF_PROD                             : array [0..1] of Byte = ($DF, $7F); //!< Whole EF<sub>prod</sub> data block (39 Byte).

  GP211_GET_DATA_KEY_DIVERSIFICATION                       : array [0..1] of Byte = ($00, $CF); //!< Key diversification data. KMC_ID (6 bytes) + CSN (4 bytes). KMC_ID is usually the IIN (Issuer identification number). CSN is the card serial number.

  // OP 2.0.1' specifific
  OP201_CARD_MANAGER_AID : array [0..6] of Byte = ($A0, $00, $00, $00, $03, $00, $00); //!< The AID of the Card Manager defined by Open Platform specification.

  OP201_LIFE_CYCLE_LOAD_FILE_LOGICALLY_DELETED   = $00; //!< Executable Load File is logically deleted.
  OP201_LIFE_CYCLE_LOAD_FILE_LOADED              = $01; //!< Executable Load File is loaded.
  OP201_LIFE_CYCLE_CARD_MANAGER_OP_READY         = $01; //!< Card is OP ready.
  OP201_LIFE_CYCLE_CARD_MANAGER_INITIALIZED      = $07; //!< Card is initialized.
  OP201_LIFE_CYCLE_CARD_MANAGER_SECURED          = $0f; //!< Card is in secured state.
  OP201_LIFE_CYCLE_CARD_MANAGER_CM_LOCKED        = $7f; //!< Card is locked.
  OP201_LIFE_CYCLE_CARD_MANAGER_TERMINATED       = $ff; //!< Card is terminated.
  OP201_LIFE_CYCLE_APPLICATION_LOGICALLY_DELETED = $00; //!< Application is logically deleted.
  OP201_LIFE_CYCLE_APPLICATION_INSTALLED         = $03; //!< Application is installed
  OP201_LIFE_CYCLE_APPLICATION_SELECTABLE        = $07; //!< Application is selectable.
  OP201_LIFE_CYCLE_APPLICATION_PERSONALIZED      = $0f; //!< Application is personalized.
  OP201_LIFE_CYCLE_APPLICATION_BLOCKED           = $7f; //!< Application is blocked.
  OP201_LIFE_CYCLE_APPLICATION_LOCKED            = $ff; //!< Application is locked.

  (**
   * Application privileges.
   *)
type
  OP201_APPLICATION_PRIVILEGES = (
    OP201_SECURITY_DOMAIN                  = 1 shl 7, //!< Application is security domain.
    OP201_DAP_VERIFICATION                 = $C0,     //!< Application can require DAP verification for loading and installing applications.
    OP201_DELEGATED_MANAGEMENT             = $A0,     //!< Security domain has delegated management right.
    OP201_CARD_MANAGER_LOCK_PRIVILEGE      = 1 shl 4, //!< Application can lock the Card Manager.
    OP201_CARD_MANAGER_TERMINATE_PRIVILEGE = 1 shl 3, //!< Application can terminate the card.
    OP201_DEFAULT_SELECTED                 = 1 shl 2, //!< Application is default selected.
    OP201_PIN_CHANGE_PRIVILEGE             = 1 shl 1, //!< Application can change global PIN.
    OP201_MANDATED_DAP_VERIFICATION        = $D0      //!< Security domain requires DAP verification for loading and installing applications.
  );

const
  OP201_STATUS_APPLICATIONS = $40; //!< Indicate Applications or Security Domains in OP201_get_status() or OP201_set_status().
  OP201_STATUS_CARD_MANAGER = $80; //!< Indicate Card Manager in OP201_get_status() or OP201_set_status().
  OP201_STATUS_LOAD_FILES   = $20; //!< Request OP201_APPLICATION_DATA for Executable Load Files in OP201_get_status().

  // Some possible identifiers to retrieve card data with get_data() and put_data().
  OP201_GET_DATA_ISSUER_BIN                                 : array [0..1] of Byte = ($00, $42); //!< Issuer BIN, if Card Manager selected.
  OP201_GET_DATA_APPLICATION_PROVIDER_IDENTIFICATION_NUMBER : array [0..1] of Byte = ($00, $42); //!< Application provider identification number, if Security Domain selected.

  OP201_GET_DATA_ISSUER_DATA                                : array [0..1] of Byte = ($00, $45); //!< Card issuer data, if Card Manager selected.
  OP201_GET_DATA_SECURITY_DOMAIN_IMAGE_NUMBER               : array [0..1] of Byte = ($00, $45); //!< Security domain image number, if Security Domain selected.

  OP201_GET_DATA_CARD_MANAGER_AID                           : array [0..1] of Byte = ($00, $4F); //!< Change Card Manager AID, if Card Manager selected.
  OP201_GET_DATA_SECURITY_DOMAIN_AID                        : array [0..1] of Byte = ($00, $4F); //!< Change Security Domain AID, if Security Domain selected.

  OP201_GET_DATA_CARD_RECOGNITION_DATA                      : array [0..1] of Byte = ($00, $66); //!< Card recognition data.
  OP201_GET_DATA_SEQUENCE_COUNTER_DEFAULT_KEY_VERSION       : array [0..1] of Byte = ($00, $C1); //!< Sequence Counter of the default Key Version Number.
  OP201_GET_DATA_CONFIRMATION_COUNTER                       : array [0..1] of Byte = ($00, $C2); //!< Confirmation Counter.
  OP201_GET_DATA_FREE_EEPROM_MEMORY_SPACE                   : array [0..1] of Byte = ($00, $C6); //!< Free EEPROM memory space.
  OP201_GET_DATA_FREE_COR_RAM                               : array [0..1] of Byte = ($00, $C7); //!< Free transient Clear on Reset memory space (COR RAM).
  OP201_GET_DATA_DIVERSIFICATION_DATA                       : array [0..1] of Byte = ($00, $CF); //!< Diversification data.

const
  (**
   * Key Information Template of first 31 keys.
   * Next templates can be obtained with the tag 0x0x 0xE0, where x > 0.
   *)
  OP201_GET_DATA_KEY_INFORMATION_TEMPLATE                             : array [0..1] of Byte = ($00, $E0);

  OP201_GET_DATA_CPLC_PERSONALIZATION_DATE                            : array [0..1] of Byte = ($9F, $66); //!< CPLC personalization date.
  OP201_GET_DATA_CPLC_PRE_PERSONALIZATION_DATE                        : array [0..1] of Byte = ($9F, $67); //!< CPLC pre-personalization date.
  OP201_GET_DATA_CPLC_ICC_MANUFACTURER_EMBEDDING_DATE                 : array [0..1] of Byte = ($9F, $68); //!< CPLC ICC manufacturer, embedding date.
  OP201_GET_DATA_CPLC_MODULE_FABRICATOR_PACKAGING_DATE                : array [0..1] of Byte = ($9F, $69); //!< CPLC module fabricator, module packaging date.
  OP201_GET_DATA_CPLC_FABRICATION_DATE_SERIAL_NUMBER_BATCH_IDENTIFIER : array [0..1] of Byte = ($9F, $6A); //!< CPLC fabrication date, serial number, batch identifier.
  OP201_GET_DATA_CPLC_WHOLE_CPLC                                      : array [0..1] of Byte = ($9F, $7F); //!< Whole CPLC data from ROM and EEPROM.

  OP201_GET_DATA_FCI_DATA                                             : array [0..1] of Byte = ($BF, $0C); //!< File Control Information (FCI) discretionary data.

  OP201_GET_DATA_PROTOCOL                                             : array [0..1] of Byte = ($DF, $70); //!< Data for protocol change.
  OP201_GET_DATA_ATR_HISTRORICAL_BYTES                                : array [0..1] of Byte = ($DF, $71); //!< Change ATR historical bytes.

  OP201_GET_DATA_EF_PROD_DATA_INITIALIZATION_FINGERPRINT              : array [0..1] of Byte = ($DF, $76); //!< EF<sub>prod</sub> data initialization fingerprint.
  OP201_GET_DATA_EF_PROD_DATA_INITIALIZATION_DATA                     : array [0..1] of Byte = ($DF, $77); //!< EF<sub>prod</sub> data initialization data.
  OP201_GET_DATA_EF_PROD_DATA_PRODUCTION_KEY_INDEX                    : array [0..1] of Byte = ($DF, $78); //!< EF<sub>prod</sub> data production key index.
  OP201_GET_DATA_EF_PROD_DATA_PROTOCOL_VERSION                        : array [0..1] of Byte = ($DF, $79); //!< EF<sub>prod</sub> data protocol version.
  OP201_GET_DATA_EF_PROD_DATA_CHECKSUM                                : array [0..1] of Byte = ($DF, $7A); //!< EF<sub>prod</sub> data checksum.
  OP201_GET_DATA_EF_PROD_DATA_SOFTWARE_VERSION                        : array [0..1] of Byte = ($DF, $7B); //!< EF<sub>prod</sub> data software version.
  OP201_GET_DATA_EF_PROD_DATA_RFU                                     : array [0..1] of Byte = ($DF, $7C); //!< EF<sub>prod</sub> data RFU.
  OP201_GET_DATA_EF_PROD_DATA_PROFILE_WITH_PROFILE_VERSION            : array [0..1] of Byte = ($DF, $7D); //!< EF<sub>prod</sub> data profile with profile version.
  OP201_GET_DATA_EF_PROD_DATA_LOCATION_MACHINE_DATE_TIME              : array [0..1] of Byte = ($DF, $7E); //!< EF<sub>prod</sub> data location, machine number, date, time.

  OP201_GET_DATA_WHOLE_EF_PROD                                        : array [0..1] of Byte = ($DF, $7F); //!< Whole EF<sub>prod</sub> data block (39 Byte).

  OPGP_DERIVATION_METHOD_NONE      = 0; //!< No key derivation is used during mutual authentication.
  OPGP_DERIVATION_METHOD_VISA2     = 1; //!< The VISA2 key derivation is used during mutual authentication.
  OPGP_DERIVATION_METHOD_EMV_CPS11 = 2; //!< The EMV CPS 11 derivation is used during mutual authentication.
  OPGP_DERIVATION_METHOD_VISA1     = 3; //!< The VISA1 key derivation is used during mutual authentication.

  OPGP_WORK_UNKNOWN  = -1; //!< The amount of work is not known.
  OPGP_TASK_FINISHED = 1;  //!< The task is finished.

  //#define INIT_PROGRESS_CALLBACK_PARAMETERS(callbackParameters, callback) 	if (callback != NULL) {callbackParameters.parameters = callback->parameters; \
  //	callbackParameters.finished = !OPGP_TASK_FINISHED;}

type
  (**
   * The structure measures the progress of a task. This structure is passed to the callback function.
   *)
  OPGP_PROGRESS_CALLBACK_PARAMETERS = record
    currentWork : DWORD;   //!< The current work which is done. If not known this contains #OPGP_WORK_UNKNOWN
    totalWork   : DWORD;   //!< The total work which needs to be done. If not known this contains #OPGP_WORK_UNKNOWN
    finished    : DWORD;   //!< Task is finished. If finished contains #OPGP_TASK_FINISHED.
    parameters  : Pointer; //!< Proprietary parameters for the function passed in with #OPGP_PROGRESS_CALLBACK.
  end;

type
  (**
   * The structure is used when the progress for a task changes in functions supporting callbacks.
   *)
  OPGP_PROGRESS_CALLBACK = record
    callback   : Pointer; //!< The callback function. The must accept a #OPGP_PROGRESS_CALLBACK_PARAMETERS parameter and return void, so the function signature is: void (*callback)(OPGP_PROGRESS_CALLBACK_PARAMETERS).
	  parameters : Pointer; //!< Proprietary parameters for the callback function. Passed in when the function is called.
  end;
  POPGP_PROGRESS_CALLBACK = ^OPGP_PROGRESS_CALLBACK;

type
  (**
   * A structure describing an AID.
   *)
  OPGP_AID = record
    AIDLength : Byte;                   //!< The length of the AID.
	  AID       : array [0..15] of Byte ; //!< The AID.
  end;
  POPGP_AID = ^OPGP_AID;

type
  (**
   * The structure containing Card Manager, Executable Load File and application life cycle states and privileges returned by get_status().
   *)
  OP201_APPLICATION_DATA = record
    aid            : OPGP_AID;                     //!< The AID.
    lifeCycleState : Byte;                         //!< The Card Manager, Executable Load File or application life cycle state.
    privileges     : OP201_APPLICATION_PRIVILEGES; //!< The Card Manager or application privileges.
  end;
  POP201_APPLICATION_DATA = ^OP201_APPLICATION_DATA;

type
  (**
   * A structure describing an Executable Load File.
   * This structure is limited to 32 applets in the Load File.
   *)
  OPGP_LOAD_FILE_PARAMETERS = record
    loadFileSize  : DWORD;                     //!< The size of the Load File.
    loadFileAID   : OPGP_AID;                  //!< The AID of the Load File.
    numAppletAIDs : Byte;                      //!< The number of applets contained in the Load File.
    appletAIDs    : array [0..31] of OPGP_AID; //!< The contained applets in the Load File.
  end;
  POPGP_LOAD_FILE_PARAMETERS = ^OPGP_LOAD_FILE_PARAMETERS;

type
  (**
   * The structure containing Issuer Security Domain, Security Domains, Executable Load Files
   * and Application life cycle states and privileges returned by get_status().
   *)
  GP211_APPLICATION_DATA = record
    aid                         : OPGP_AID;                     //!< The AID.
    lifeCycleState              : Byte;                         //!< The Issuer Security Domain, Security Domains, Executable Load Files and Application life cycle state.
    privileges                  : GP211_APPLICATION_PRIVILEGES; //!< The Issuer Security Domain, Security Domains or Application privileges. Has no meaning for Executable Load Files.
    versionNumber               : array [0..1] of Byte;         //!< On a Java Card based card, this is a 2-byte version number reflecting the major and minor version attributes (in this order) of the Java Card CAP file. Shorted if longer.
    associatedSecurityDomainAID : OPGP_AID;                     //!< The associated Security Domain's AID.
  end;

type
  (**
   * The structure containing Executable Load Files and their Executable Module returned by get_status().
   *)
  GP211_EXECUTABLE_MODULES_DATA = record
    aid                         : OPGP_AID;                  //!< The Executable Load File AID.
    lifeCycleState              : Byte;                      //!< The Executable Load File life cycle state.
    versionNumber               : array [0..1] of Byte;      //!< On a Java Card based card, this is a 2-byte version number reflecting the major and minor version attributes (in this order) of the Java Card CAP file. Shorted if longer.
    numExecutableModules        : Byte;                      //!< Number of associated Executable Modules.
    executableModules           : array [0..63] of OPGP_AID; //!< Array for the maximum possible associated Executable Modules.
    associatedSecurityDomainAID : OPGP_AID;                  //!< The associated Security Domain's AID.
  end;

type
  (**
   * The structure containing the extended card resource information according ETSI TS 102 226, sect. 8.2.1.7.2.
   *)
  OPGP_EXTENDED_CARD_RESOURCE_INFORMATION = record
    numInstalledApplications : DWORD; //!< The number of the installed applications.
    freeVolatileMemory       : DWORD; //!< Free volatile memory.
    freeNonVolatileMemory    : DWORD; //!< Free non volatile memory.
  end;

type
  (**
   * The Card Recognition Data returned for tag 0x66 with GET DATA.
   *)
  GP211_CARD_RECOGNITION_DATA = record
    version                                                     : DWORD;                 //!< The GlobalPlatform version.
    scp                                                         : array [0..15] of Byte; //!< The secure channel protocols.
    scpImpl                                                     : array [0..15] of Byte; //!< The secure channel protocol implementations.
    scpLength                                                   : DWORD;                 //!< The length of the SCP.
    cardConfigurationDetails                                    : array [0..63] of Byte; //!< Card configuration details.
    cardConfigurationDetailsLength                              : DWORD;                 //!< Card configuration details length.
    cardChipDetails                                             : array [0..63] of Byte; //!< Card configuration details.
    cardChipDetailsLength                                       : DWORD;                 //!< Card configuration details length.
    issuerSecurityDomainsTrustPointCertificateInformation       : array [0..63] of Byte; //!< Issuer Security Domain’s Trust Point certificate information.
    issuerSecurityDomainsTrustPointCertificateInformationLength : DWORD;                 //!< Issuer Security Domain’s Trust Point certificate information length.
    issuerSecurityDomainCertificateInformation                  : array [0..63] of Byte; //!< Issuer Security Domain certificate information.
    issuerSecurityDomainCertificateInformationLength            : DWORD;                 //!< Issuer Security Domain certificate information length.
  end;

//! GlobalPlatform2.1.1: Selects an application on a card by AID.
function OPGP_select_application(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; AID: PByte; AIDLength: DWORD): OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Reads the extended card resource information (number of applications + free memory).
function OPGP_get_extended_card_resources_information(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; var secInfo: GP211_SECURITY_INFO; var extendedCardResourceInformation: OPGP_EXTENDED_CARD_RESOURCE_INFORMATION): OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

(** GlobalPlatform2.1.1: Gets the life cycle status of Applications, the Issuer Security
 * Domains, Security Domains and Executable Load Files and their privileges or information about
 * Executable Modules of the Executable Load Files.
 *)
function GP211_get_status(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; cardElement: Byte; format: Byte; applData: GP211_APPLICATION_DATA; executableData: GP211_EXECUTABLE_MODULES_DATA; dataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Sets the life cycle status of Applications, Security Domains or the Card Manager.
function GP211_set_status(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; cardElement: Byte; AID: PBYTE; AIDLength: DWORD; lifeCycleState: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Mutual authentication.
function GP211_mutual_authentication(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; baseKey: PByte; S_ENC: PByte; S_MAC: PByte; DEK: PByte; keyLength: DWORD; keySetVersion: Byte; keyIndex: Byte; secureChannelProtocol: Byte; secureChannelProtocolImpl: Byte; securityLevel: Byte; derivationMethod: Byte; var secInfo: GP211_SECURITY_INFO): OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Inits a Secure Channel implicitly.
function GP211_init_implicit_secure_channel(AID: PBYTE; AIDLength: DWORD; baseKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte; secureChannelProtocolImpl: Byte; sequenceCounter: array of Byte; secInfo: GP211_SECURITY_INFO) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Closes a Secure Channel implicitly.
function close_implicit_secure_channel(secInfo: GP211_SECURITY_INFO) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Retrieve card data.
function GP211_get_data(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; identifier: array of Byte; recvBuffer: PBYTE; recvBufferLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Retrieve card data according ISO/IEC 7816-4 command not within a secure channel.
function GP211_get_data_iso7816_4(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; identifier: array of Byte; recvBuffer: PBYTE; recvBufferLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Return the card recognition data.
function GP211_get_card_recognition_data(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; cardData: GP211_CARD_RECOGNITION_DATA) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: This returns the Secure Channel Protocol and the Secure Channel Protocol implementation.
function GP211_get_secure_channel_protocol_details(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secureChannelProtocol: Byte; secureChannelProtocolImpl: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: This returns the current Sequence Counter.
function GP211_get_sequence_counter(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; sequenceCounter: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Put card data.
function GP211_put_data(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; identifier: array of Byte; dataObject: PBYTE; dataObjectLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Changes or unblocks the global PIN.
function GP211_pin_change(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; tryLimit: Byte; newPIN: PBYTE; newPINLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: replaces a single symmetric key in a key set or adds a new key.
function GP211_put_symmetric_key(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; keySetVersion: Byte; keyIndex: Byte; newKeySetVersion: Byte; key: array of Byte; keyLength: DWORD; keyType: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: replaces a single AES key in a key set or adds a new AES key.
function GP211_put_aes_key(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; keySetVersion: Byte; keyIndex: Byte; newKeySetVersion: Byte; aesKey: array of Byte; keyLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: replaces a single 3DES key in a key set or adds a new 3DES key.
function GP211_put_3des_key(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; keySetVersion: Byte; keyIndex: Byte; newKeySetVersion: Byte; _3DESKey: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: replaces a single public RSA key in a key set or adds a new public RSA key.
function GP211_put_rsa_key(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; keySetVersion: Byte; keyIndex: Byte; newKeySetVersion: Byte; PEMKeyFileName: LPCTSTR; passPhrase: PChar) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: replaces or adds a secure channel key set consisting of S-ENC, S-MAC and DEK.
function GP211_put_secure_channel_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; keySetVersion: Byte; newKeySetVersion: Byte; baseKey: array of Byte; newS_ENC: array of Byte; newS_MAC: array of Byte; newDEK: array of Byte; keyLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: deletes a key or multiple keys.
function GP211_delete_key(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; keySetVersion: Byte; keyIndex: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Retrieves key information of keys on the card.
function GP211_get_key_information_templates(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; keyInformationTemplate: Byte; keyInformation: GP211_KEY_INFORMATION; keyInformationLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Deletes a Executable Load File or an application.
function GP211_delete_application(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; const secInfo: Pointer; const AIDs: POPGP_AID; AIDsLength: DWORD; const receiptData: PGP211_RECEIPT_DATA; var receiptDataLength: DWORD): OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Prepares the card for loading an application.
function GP211_install_for_load(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; const secInfo: PGP211_SECURITY_INFO; const executableLoadFileAID: PByte; executableLoadFileAIDLength: DWORD; const securityDomainAID: PByte; securityDomainAIDLength: DWORD; loadFileDataBlockHash: PByte; loadToken: PByte; nonVolatileCodeSpaceLimit: DWORD; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD): OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Function to retrieve the data to sign by the Card Issuer in an Extradition Token.
function GP211_get_extradition_token_signature_data(securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; applicationAID: PBYTE; applicationAIDLength: DWORD; extraditionTokenSignatureData: PBYTE; extraditionTokenSignatureDataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Function to retrieve the data to sign by the Card Issuer in a Load Token.
function GP211_get_load_token_signature_data(executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; loadFileDataBlockHash: array of Byte; nonVolatileCodeSpaceLimit: DWORD; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; loadTokenSignatureData: PBYTE; loadTokenSignatureDataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Function to retrieve the data to sign by the Card Issuer in an Install Token.
function GP211_get_install_token_signature_data(P1: BYTE; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; executableModuleAID: PBYTE; executableModuleAIDLength: DWORD; applicationAID: PBYTE; applicationAIDLength: DWORD; applicationPrivileges: BYTE; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; installParameters: PBYTE; installParametersLength: DWORD; installTokenSignatureData: PBYTE; installTokenSignatureDataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Calculates a Load Token using PKCS#1.
function GP211_calculate_load_token(executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; loadFileDataBlockHash: array of Byte; nonVolatileCodeSpaceLimit: DWORD; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; loadToken : array of Byte; PEMKeyFileName: LPCTSTR; passPhrase: PChar) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Calculates an Install Token using PKCS#1.
function GP211_calculate_install_token(P1: Byte; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; executableModuleAID: PBYTE; executableModuleAIDLength: DWORD; applicationAID: PBYTE; applicationAIDLength: DWORD; applicationPrivileges: Byte; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; installParameters: PBYTE; installParametersLength: DWORD; installToken: array of Byte; PEMKeyFileName: LPCTSTR; passPhrase: PChar) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Calculates a Load File Data Block Hash.
function GP211_calculate_load_file_data_block_hash(executableLoadFileName: LPCTSTR; hash: array of Byte; hashLength: DWORD; secureChannelProtocol: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Loads a Executable Load File (containing an application) to the card.
function GP211_load(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; const secInfo: PGP211_SECURITY_INFO; dapBlock: PGP211_DAP_BLOCK; dapBlockLength: DWORD; executableLoadFileName: PChar; receiptData: PGP211_RECEIPT_DATA; var receiptDataAvailable: DWORD; callback: POPGP_PROGRESS_CALLBACK): OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Loads a Executable Load File (containing an application) from a buffer to the card.
function GP211_load_from_buffer(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; dapBlock: GP211_DAP_BLOCK; dapBlockLength: DWORD; loadFileBuffer: PBYTE; loadFileBufSize: DWORD; receiptData: GP211_RECEIPT_DATA; receiptDataAvailable: PDWORD; callback: POPGP_PROGRESS_CALLBACK) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Installs an application on the card.
function GP211_install_for_install(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; executableModuleAID: PBYTE; executableModuleAIDLength: DWORD; applicationAID: PBYTE; applicationAIDLength: DWORD; applicationPrivileges: BYTE; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; installParameters: PBYTE; installParametersLength: DWORD; installToken: array of Byte; receiptData: GP211_RECEIPT_DATA; receiptDataAvailable: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Makes an installed application selectable.
function GP211_install_for_make_selectable(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; applicationAID: PBYTE; applicationAIDLength: DWORD; applicationPrivileges: Byte; installToken: array of Byte; receiptData: GP211_RECEIPT_DATA; receiptDataAvailable: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Installs and makes an installed application selectable.
function GP211_install_for_install_and_make_selectable(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; const secInfo: PGP211_SECURITY_INFO; executableLoadFileAID: PByte; executableLoadFileAIDLength: DWORD; executableModuleAID: PByte; executableModuleAIDLength: DWORD; applicationAID: PByte; applicationAIDLength: DWORD; applicationPrivileges: Byte; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; installParameters: PByte; installParametersLength: DWORD; installToken: PByte; var receiptData: GP211_RECEIPT_DATA; var receiptDataAvailable: DWORD): OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;







//! GlobalPlatform2.1.1: Informs a Security Domain that a associated application will retrieve personalization data.
function GP211_install_for_personalization(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; applicationAID: PBYTE; applicationAIDLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Associates an application with another Security Domain.
function GP211_install_for_extradition(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; applicationAID: PBYTE; applicationAIDLength: DWORD; extraditionToken: array of Byte; receiptData: GP211_RECEIPT_DATA; receiptDataAvailable: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Adds a key set for Delegated Management.
function GP211_put_delegated_management_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; keySetVersion: Byte; newKeySetVersion: Byte; PEMKeyFileName: LPCTSTR; passPhrase: PChar; receiptKey: array of Byte; keyLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Sends an application protocol data unit.
function GP211_send_APDU(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; capdu: PBYTE; capduLength: DWORD; rapdu: PBYTE; rapduLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Calculates a Load File Data Block Signature using AES or 3DES.
function GP211_calculate_DAP(loadFileDataBlockHash: array of Byte; hashLength: Byte; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; DAPCalculationKey: array of Byte; keyLength: DWORD; loadFileDataBlockSignature: GP211_DAP_BLOCK; secureChannelProtocol: BYTE) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Calculates a Load File Data Block Signature using SHA-1 and PKCS#1 (RSA).
function GP211_calculate_rsa_DAP(loadFileDataBlockHash: array of Byte; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; PEMKeyFileName: LPCTSTR; passPhrase: PChar; loadFileDataBlockSignature: GP211_DAP_BLOCK) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Validates a Load Receipt.
function GP211_validate_delete_receipt(confirmationCounter: DWORD; cardUniqueData: PBYTE; cardUniqueDataLength: DWORD; receiptKey: array of Byte; keyLength: DWORD; receiptData: GP211_RECEIPT_DATA; AID: PBYTE; AIDLength: DWORD; secureChannelProtocol: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Validates an Install Receipt.
function GP211_validate_install_receipt(confirmationCounter: DWORD; cardUniqueData: PBYTE; cardUniqueDataLength: DWORD; receiptKey: array of Byte; keyLength: DWORD; receiptData: GP211_RECEIPT_DATA; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; applicationAID: PBYTE; applicationAIDLength: DWORD; secureChannelProtocol: BYTE) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Validates a Load Receipt.
function GP211_validate_load_receipt(confirmationCounter: DWORD; cardUniqueData: PBYTE; cardUniqueDataLength: DWORD; receiptKey: array of Byte; keyLength: DWORD; receiptData: GP211_RECEIPT_DATA; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; secureChannelProtocol: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: Validates an Extradition Receipt.
function GP211_validate_extradition_receipt(confirmationCounter: DWORD; cardUniqueData: PBYTE; cardUniqueDataLength: DWORD; receiptKey: array of Byte; keyLength: DWORD; receiptData: GP211_RECEIPT_DATA; oldSecurityDomainAID: PBYTE; oldSecurityDomainAIDLength: DWORD; newSecurityDomainAID: PBYTE; newSecurityDomainAIDLength: DWORD; applicationOrExecutableLoadFileAID: PBYTE; applicationOrExecutableLoadFileAIDLength: DWORD; secureChannelProtocol: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! ISO 7816-4 / GlobalPlatform2.1.1: Opens or closes a Logical Channel.
function OPGP_manage_channel(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; openClose: Byte; channelNumberToClose: Byte; channelNumberOpened: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! ISO 7816-4 / GlobalPlatform2.1.1: If multiple Logical Channels are open or a new Logical Channel is opened with select_application(), selects the Logical Channel.
function OPGP_select_channel(cardInfo: OPGP_CARD_INFO; channelNumber: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Calculates the key check value of a key.
function OPGP_calculate_key_check_value(secInfo: GP211_SECURITY_INFO; keyData: PBYTE; keyDataLength: DWORD; keyCheckValue: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Encrypts sensitive data like keys or other data which is used in STORE DATA.
function OPGP_encrypt_sensitive_data(secInfo: GP211_SECURITY_INFO; data: PBYTE; dataLength: DWORD; encryptedData: PBYTE; encryptedDataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! GlobalPlatform2.1.1: The STORE DATA command is used to transfer data to an Application or the Security Domain processing the command.
function GP211_store_data(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; encryptionFlags: Byte; formatFlags: Byte; responseDataExpected: BOOL; data: PBYTE; dataLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Gets the life cycle status of Applications, the Card Manager and Executable Load Files and their privileges.
function OP201_get_status(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; cardElement: Byte; applData: POP201_APPLICATION_DATA; applDataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Sets the life cycle status of Applications, Security Domains or the Card Manager.
function OP201_set_status(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; cardElement: Byte; AID: PBYTE; AIDLength: DWORD; lifeCycleState: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Mutual authentication.
function OP201_mutual_authentication(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; baseKey: array of Byte; encKey: array of Byte; macKey: array of Byte; kekKey: array of Byte; keySetVersion: Byte; keyIndex: Byte; securityLevel: Byte; derivationMethod: Byte; secInfo: OP201_SECURITY_INFO) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Retrieve card data.
function OP201_get_data(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; identifier: array of Byte; recvBuffer: PBYTE; recvBufferLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Put card data.
function OP201_put_data(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; identifier: array of Byte; dataObject: PBYTE; dataObjectLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Changes or unblocks the global PIN.
function OP201_pin_change(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; tryLimit: Byte; newPIN: PBYTE; newPINLength: DWORD; KEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: replaces a single 3DES key in a key set or adds a new 3DES key.
function OP201_put_3desKey(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; keySetVersion: Byte; keyIndex: Byte; newKeySetVersion: Byte; _3desKey: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: replaces a single public RSA key in a key set or adds a new public RSA key.
function OP201_put_rsa_key(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; keySetVersion: Byte; keyIndex: Byte; newKeySetVersion: Byte; PEMKeyFileName: LPCTSTR; passPhrase: PChar) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: replaces or adds a secure channel key set consisting of encryption key, MAC key and key encryption.
function OP201_put_secure_channel_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; keySetVersion: Byte; newKeySetVersion: Byte; new_encKey: array of Byte; new_macKey: array of Byte; new_KEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: deletes a key or multiple keys.
function OP201_delete_key(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; keySetVersion: Byte; keyIndex: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Retrieves key information of keys on the card.
function OP201_get_key_information_templates(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; keyInformationTemplate: Byte; keyInformation: OP201_KEY_INFORMATION; keyInformationLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Deletes a Executable Load File or an application.
function OP201_delete_application(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; AIDs: POPGP_AID; AIDsLength: DWORD; receiptData: OP201_RECEIPT_DATA; receiptDataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Prepares the card for loading an application.
function OP201_install_for_load(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; loadFileDAP: array of Byte; loadToken: array of Byte; nonVolatileCodeSpaceLimit: DWORD; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Function to retrieve the data to sign by the Card Issuer in a Load Token.
function OP201_get_load_token_signature_data(executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; loadFileDAP: array of Byte; nonVolatileCodeSpaceLimit: DWORD; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; loadTokenSignatureData: PBYTE; loadTokenSignatureDataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Function to retrieve the data to sign by the Card Issuer in an Install Token.
function OP201_get_install_token_signature_data(P1: Byte; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; AIDWithinLoadFileAID: PBYTE; AIDWithinLoadFileAIDLength: DWORD; applicationInstanceAID: PBYTE; applicationInstanceAIDLength: DWORD; applicationPrivileges: Byte; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; applicationInstallParameters: PBYTE; applicationInstallParametersLength: DWORD; installTokenSignatureData: PBYTE; installTokenSignatureDataLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Calculates a Load Token using PKCS#1.
function OP201_calculate_load_token(executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; loadFileDAP: array of Byte; nonVolatileCodeSpaceLimit: DWORD; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; loadToken: array of Byte; PEMKeyFileName: LPCTSTR; passPhrase: PChar) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Calculates an Install Token using PKCS#1.
function OP201_calculate_install_token(P1: Byte; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; AIDWithinLoadFileAID: PBYTE; AIDWithinLoadFileAIDLength: DWORD; applicationInstanceAID: PBYTE; applicationInstanceAIDLength: DWORD; applicationPrivileges: Byte; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; applicationInstallParameters: PBYTE; applicationInstallParametersLength: DWORD; installToken: array of Byte; PEMKeyFileName: LPCTSTR; passPhrase: PChar) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Calculates a Load File DAP.
function OP201_calculate_load_file_DAP(dapBlock: OP201_DAP_BLOCK; dapBlockLength: DWORD; executableLoadFileName: LPCTSTR; hash: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Loads a Executable Load File (containing an application) to the card.
function OP201_load(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; dapBlock: OP201_DAP_BLOCK; dapBlockLength: DWORD; executableLoadFileName: LPCTSTR; receiptData: OP201_RECEIPT_DATA; receiptDataAvailable: PDWORD; callback: POPGP_PROGRESS_CALLBACK) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Loads a Executable Load File (containing an application) from a buffer to the card.
function OP201_load_from_buffer(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; dapBlock: OP201_DAP_BLOCK; dapBlockLength: DWORD; loadFilebuf: PBYTE; loadFileBufSize: DWORD; receiptData: OP201_RECEIPT_DATA; receiptDataAvailable: PDWORD; callback: POPGP_PROGRESS_CALLBACK) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Installs an application on the card.
function OP201_install_for_install(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; AIDWithinLoadFileAID: PBYTE; AIDWithinLoadFileAIDLength: DWORD; applicationInstanceAID: PBYTE; applicationInstanceAIDLength: DWORD; applicationPrivileges: Byte; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; applicationInstallParameters: PBYTE; applicationInstallParametersLength: DWORD; installToken: array of Byte; receiptData: OP201_RECEIPT_DATA; receiptDataAvailable: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Makes an installed application selectable.
function OP201_install_for_make_selectable(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; applicationInstanceAID: PBYTE; applicationInstanceAIDLength: DWORD; applicationPrivileges: Byte; installToken: array of Byte; receiptData: OP201_RECEIPT_DATA; receiptDataAvailable: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Installs and makes an installed application selectable.
function OP201_install_for_install_and_make_selectable(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; AIDWithinLoadFileAID: PBYTE; AIDWithinLoadFileAIDLength: DWORD; applicationInstanceAID: PBYTE; applicationInstanceAIDLength: DWORD; applicationPrivileges: Byte; volatileDataSpaceLimit: DWORD; nonVolatileDataSpaceLimit: DWORD; applicationInstallParameters: PBYTE; applicationInstallParametersLength: DWORD; installToken: array of Byte; receiptData: OP201_RECEIPT_DATA; receiptDataAvailable: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Adds a key set for Delegated Management.
function OP201_put_delegated_management_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; keySetVersion: Byte; newKeySetVersion: Byte; PEMKeyFileName: LPCTSTR; passPhrase: PChar; receiptGenerationKey: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Sends an application protocol data unit.
function OP201_send_APDU(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; capdu: PBYTE; capduLength: DWORD; rapdu: PBYTE; rapduLength: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Calculates a Load File Data Block DAP using 3DES.
function OP201_calculate_3des_DAP(securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; executableLoadFileName: LPCTSTR; DAP_verification_key: array of Byte; dapBlock: OP201_DAP_BLOCK) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Calculates a Load File Data Block DAP using SHA-1 and PKCS#1 (RSA).
function OP201_calculate_rsa_DAP(securityDomainAID: PBYTE; securityDomainAIDLength: DWORD; executableLoadFileName: LPCTSTR; PEMKeyFileName: LPCTSTR; passPhrase: PChar; dapBlock: OP201_DAP_BLOCK) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Validates a Load Receipt.
function OP201_validate_delete_receipt(confirmationCounter: DWORD; cardUniqueData: array of Byte; receiptGenerationKey: array of Byte; receiptData: OP201_RECEIPT_DATA; AID: PBYTE; AIDLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Validates an Install Receipt.
function OP201_validate_install_receipt(confirmationCounter: DWORD; cardUniqueData: array of Byte; receiptGenerationKey: array of Byte; receiptData: OP201_RECEIPT_DATA; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; applicationInstanceAID: PBYTE; applicationInstanceAIDLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Open Platform: Validates a Load Receipt.
function OP201_validate_load_receipt(confirmationCounter: DWORD; cardUniqueData: array of Byte; receiptGenerationKey: array of Byte; receiptData: OP201_RECEIPT_DATA; executableLoadFileAID: PBYTE; executableLoadFileAIDLength: DWORD; securityDomainAID: PBYTE; securityDomainAIDLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Initiates a R-MAC session.
function GP211_begin_R_MAC(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; securityLevel: Byte; data: PBYTE; dataLength: DWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Terminates a R-MAC session.
function GP211_end_R_MAC(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; secureChannelProtocol: Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Reads the parameters of an Executable Load File.
function OPGP_read_executable_load_file_parameters(loadFileName: PChar; const loadFileParams: POPGP_LOAD_FILE_PARAMETERS): OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Converts a CAP file to an IJC file (Executable Load File).
function OPGP_cap_to_ijc(capFileName: LPCTSTR; ijcFileName: LPTSTR) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Extracts a CAP file into a buffer.
function OPGP_extract_cap_file(fileName: LPCTSTR; loadFileBuf: PBYTE; loadFileBufSize: PDWORD) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Receives Executable Load File as a buffer instead of a FILE.
function OPGP_read_executable_load_file_parameters_from_buffer(loadFileBuf: PBYTE; loadFileBufSize: DWORD; loadFileParams: OPGP_LOAD_FILE_PARAMETERS) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the EMV CPS 1.1 key derivation scheme.
function GP211_EMV_CPS11_derive_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the VISA 2 key derivation scheme.
function GP211_VISA2_derive_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; AID: PBYTE; AIDLength: DWORD; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the VISA 1 key derivation scheme.
function GP211_VISA1_derive_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: GP211_SECURITY_INFO; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the EMV CPS 1.1 key derivation scheme.
function OP201_EMV_CPS11_derive_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the VISA 2 key derivation scheme.
function OP201_VISA2_derive_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; AID: PBYTE; AIDLength: DWORD; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the VISA 1 key derivation scheme.
function OP201_VISA1_derive_keys(cardContext: OPGP_CARD_CONTEXT; cardInfo: OPGP_CARD_INFO; secInfo: OP201_SECURITY_INFO; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the VISA 2 key derivation scheme.
function VISA2_derive_keys(baseKeyDiversificationData: array of Byte; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the VISA 1 key derivation scheme.
function VISA1_derive_keys(cardSerialNumber: array of Byte; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

//! Derives the static keys from a master key according the EMV CPS11 derivation scheme.
function EMV_CPS11_derive_keys(baseKeyDiversificationData: array of Byte; masterKey: array of Byte; S_ENC: array of Byte; S_MAC: array of Byte; DEK: array of Byte) : OPGP_ERROR_STATUS; cdecl; external GlobalPlatform;

implementation

end.
