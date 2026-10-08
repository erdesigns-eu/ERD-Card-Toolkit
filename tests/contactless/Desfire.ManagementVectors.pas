unit Desfire.ManagementVectors;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses Desfire.Vectors;

/// <summary>Independent synthetic Ev1Admin administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1Admin:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1FreeAccess administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1FreeAccess:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1RotateCurrent administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1RotateCurrent:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1RotateProtectedCurrent administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1RotateProtectedCurrent:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1RotateOther administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1RotateOther:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1RotateRoot administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1RotateRoot:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1WrongVersion administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1WrongVersion:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1FreeMemory administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1FreeMemory:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1FixedSettings administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1FixedSettings:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1DeniedRotation administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1DeniedRotation:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1DeniedFileChange administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1DeniedFileChange:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1SettingsMismatch administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1SettingsMismatch:TDesfireWirePairs;
/// <summary>Independent synthetic Ev1GeometryMismatch administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev1GeometryMismatch:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2Admin administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2Admin:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2FreeAccess administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2FreeAccess:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2RotateCurrent administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2RotateCurrent:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2RotateProtectedCurrent administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2RotateProtectedCurrent:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2RotateOther administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2RotateOther:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2RotateRoot administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2RotateRoot:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2WrongVersion administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2WrongVersion:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2FreeMemory administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2FreeMemory:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2FixedSettings administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2FixedSettings:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2DeniedRotation administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2DeniedRotation:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2DeniedFileChange administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2DeniedFileChange:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2SettingsMismatch administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2SettingsMismatch:TDesfireWirePairs;
/// <summary>Independent synthetic Ev2GeometryMismatch administration transcript.</summary>
/// <returns>Owned literal pairs with published test credentials.</returns>
function Ev2GeometryMismatch:TDesfireWirePairs;

implementation

function Ev1Admin:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,12);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90640000010100';
  Result[4].Response:='21126E0AC6BB57D21B9100';
  Result[5].Command:='9045000000';
  Result[5].Response:='0F8236F7BF1A11D768F89100';
  Result[6].Command:='9054000010FD9519D9888184891C8C953D62C34B8A00';
  Result[6].Response:='0036B56485AD4FA39100';
  Result[7].Command:='9045000000';
  Result[7].Response:='EF82864294335278CEE19100';
  Result[8].Command:='9045000000';
  Result[8].Response:='EF82D54FD6DF71C8DD439100';
  Result[9].Command:='90F50000010000';
  Result[9].Response:='00030000200000B94C6184F8D91DE29100';
  Result[10].Command:='905F00001100529D0F3B9874866E10A3D724B384404900';
  Result[10].Response:='094353909B9213049100';
  Result[11].Command:='90F50000010000';
  Result[11].Response:='000110E1200000FF9D885263665F709100';
end;

function Ev1FreeAccess:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,12);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90640000010100';
  Result[4].Response:='21126E0AC6BB57D21B9100';
  Result[5].Command:='9045000000';
  Result[5].Response:='0F8236F7BF1A11D768F89100';
  Result[6].Command:='9054000010FD9519D9888184891C8C953D62C34B8A00';
  Result[6].Response:='0036B56485AD4FA39100';
  Result[7].Command:='9045000000';
  Result[7].Response:='EF82864294335278CEE19100';
  Result[8].Command:='9045000000';
  Result[8].Response:='EF82D54FD6DF71C8DD439100';
  Result[9].Command:='90F50000010000';
  Result[9].Response:='00030E00200000F3C0F972EE5AA5FF9100';
  Result[10].Command:='905F000004000110E100';
  Result[10].Response:='650B7AB8C72737469100';
  Result[11].Command:='90F50000010000';
  Result[11].Response:='000110E12000002488E25CF00245129100';
end;

function Ev1RotateCurrent:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90C400002100796EA7EBC27037037FAE65D2750FBCD69DCD42946A55EAB537A658376E76161400';
  Result[4].Response:='9100';
  Result[5].Command:='90AA0000010000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF000020AD98B455EF7D1409FAF7F7BCE991D80F9D14DA474A13D92D52024047B30E28B400';
  Result[6].Response:='CE7C2AA0C6228AFFD39CFDB6ACC16E2F9100';
  Result[7].Command:='90640000010000';
  Result[7].Response:='429043FBF6A2590C699100';
  Result[8].Command:='9045000000';
  Result[8].Response:='0F82D03B0ABDDE9128349100';
end;

function Ev1RotateProtectedCurrent:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90C400002100796EA7EBC27037037FAE65D2750FBCD69DCD42946A55EAB537A658376E76161400';
  Result[4].Response:='242C45E7A1E462439100';
  Result[5].Command:='90AA0000010000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF000020AD98B455EF7D1409FAF7F7BCE991D80F9D14DA474A13D92D52024047B30E28B400';
  Result[6].Response:='CE7C2AA0C6228AFFD39CFDB6ACC16E2F9100';
  Result[7].Command:='90640000010000';
  Result[7].Response:='429043FBF6A2590C699100';
  Result[8].Command:='9045000000';
  Result[8].Response:='0F82D03B0ABDDE9128349100';
end;

function Ev1RotateOther:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90C400002101CB3AC2B6B2CCF5206046F69A063B23E4EF48F50580DEF57C816CE0295B48AF1F00';
  Result[4].Response:='209EDA1F616F4CB99100';
  Result[5].Command:='90AA0000010100';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF000020AD98B455EF7D1409FAF7F7BCE991D80F9D14DA474A13D92D52024047B30E28B400';
  Result[6].Response:='CE7C2AA0C6228AFFD39CFDB6ACC16E2F9100';
  Result[7].Command:='90640000010100';
  Result[7].Response:='42E8D3D14635C572C69100';
  Result[8].Command:='9045000000';
  Result[8].Response:='0F82827DE32645A119159100';
end;

function Ev1RotateRoot:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,9);
  Result[0].Command:='905A00000300000000';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F814039102D2FAB14E09100';
  Result[4].Command:='90C400002180E48800004239D99FFBBB9733283BE932DAED88D0493785654CE48D4160E30D1000';
  Result[4].Response:='9100';
  Result[5].Command:='90AA0000010000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF000020AD98B455EF7D1409FAF7F7BCE991D80F9D14DA474A13D92D52024047B30E28B400';
  Result[6].Response:='CE7C2AA0C6228AFFD39CFDB6ACC16E2F9100';
  Result[7].Command:='90640000010000';
  Result[7].Response:='429043FBF6A2590C699100';
  Result[8].Command:='9045000000';
  Result[8].Response:='0F812F1B54C1F96A39C49100';
end;

function Ev1WrongVersion:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90C400002100796EA7EBC27037037FAE65D2750FBCD69DCD42946A55EAB537A658376E76161400';
  Result[4].Response:='9100';
  Result[5].Command:='90AA0000010000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF000020AD98B455EF7D1409FAF7F7BCE991D80F9D14DA474A13D92D52024047B30E28B400';
  Result[6].Response:='CE7C2AA0C6228AFFD39CFDB6ACC16E2F9100';
  Result[7].Command:='90640000010000';
  Result[7].Response:='4300AE0E2AA36EFD2C9100';
end;

function Ev1FreeMemory:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,4);
  Result[0].Command:='905A00000300000000';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='906E000000';
  Result[3].Response:='56341244AA1DD5221FE83E9100';
end;

function Ev1FixedSettings:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,4);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0782A5AF4D886AB329169100';
end;

function Ev1DeniedRotation:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,4);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='FE82FDFA5648140DA8829100';
end;

function Ev1DeniedFileChange:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,5);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90F50000010000';
  Result[4].Response:='00030F00200000524B5AE6651715F29100';
end;

function Ev1SettingsMismatch:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90540000108254C04A28F810FC87946A8AB0F2E3E800';
  Result[4].Response:='FBFE08E5A0874F609100';
  Result[5].Command:='9045000000';
  Result[5].Response:='0F82D33B4D5E25F89CD19100';
end;

function Ev1GeometryMismatch:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,7);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='9045000000';
  Result[3].Response:='0F82AF81D82393F450C59100';
  Result[4].Command:='90F50000010000';
  Result[4].Response:='00030000200000D84DDE6F3FEDEBC09100';
  Result[5].Command:='905F000011001D4630F564D7E41C35A031A0CC2F5E5100';
  Result[5].Response:='3BE30DE9445DAC139100';
  Result[6].Command:='90F50000010000';
  Result[6].Response:='000110E12100007F345DA332F89C029100';
end;

function Ev2Admin:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,12);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90640000090181B82B5FD414E6E900';
  Result[4].Response:='21544D1EE009F3BE309100';
  Result[5].Command:='904500000868F07460941F8A9600';
  Result[5].Response:='0F821910AF30E5E85FC69100';
  Result[6].Command:='9054000018849A8034819158BD6757D156775E4D5AD22A6227DE2EE4AC00';
  Result[6].Response:='2EE19EB463051C689100';
  Result[7].Command:='9045000008A6CE1238E70C7AE000';
  Result[7].Response:='EF82E134193AFC6BA0269100';
  Result[8].Command:='9045000008F9B4FFAC29C9B41900';
  Result[8].Response:='EF82026E8CB4E881FA6F9100';
  Result[9].Command:='90F500000900B9C805898072292100';
  Result[9].Response:='0003000020000040DCA175D83113939100';
  Result[10].Command:='905F000019006CC0856C38176848B3617587107E9A836F2E2241600DBC0400';
  Result[10].Response:='DA7641FEC546AFD49100';
  Result[11].Command:='90F5000009005C861CA94245010600';
  Result[11].Response:='000110E12000006FE5BD187A0963169100';
end;

function Ev2FreeAccess:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,12);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90640000090181B82B5FD414E6E900';
  Result[4].Response:='21544D1EE009F3BE309100';
  Result[5].Command:='904500000868F07460941F8A9600';
  Result[5].Response:='0F821910AF30E5E85FC69100';
  Result[6].Command:='9054000018849A8034819158BD6757D156775E4D5AD22A6227DE2EE4AC00';
  Result[6].Response:='2EE19EB463051C689100';
  Result[7].Command:='9045000008A6CE1238E70C7AE000';
  Result[7].Response:='EF82E134193AFC6BA0269100';
  Result[8].Command:='9045000008F9B4FFAC29C9B41900';
  Result[8].Response:='EF82026E8CB4E881FA6F9100';
  Result[9].Command:='90F500000900B9C805898072292100';
  Result[9].Response:='00030E00200000CFEDA54668E88E5A9100';
  Result[10].Command:='905F000019006CC0856C38176848B3617587107E9A836F2E2241600DBC0400';
  Result[10].Response:='DA7641FEC546AFD49100';
  Result[11].Command:='90F5000009005C861CA94245010600';
  Result[11].Response:='000110E12000006FE5BD187A0963169100';
end;

function Ev2RotateCurrent:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90C4000029005FEAD85DA2DFAF69D4FBA4E9C07AAB19E30ECE91BE5506006799911E5DC9AB3176028DBF4B72713400';
  Result[4].Response:='9100';
  Result[5].Command:='9071000002000000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E5007342C674C82CFBA82FD682A3AEF7EDB00';
  Result[6].Response:='3042698F810CB3FDF8497B584979DAC41903B39CA00D5AA6480160B90DE42E4E9100';
  Result[7].Command:='9064000009007F58E726C9A857C400';
  Result[7].Response:='424B0DE12C5701B4A09100';
  Result[8].Command:='904500000820B42963BFCF127900';
  Result[8].Response:='0F82CBADFE73A4D1E6EF9100';
end;

function Ev2RotateProtectedCurrent:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90C4000029005FEAD85DA2DFAF69D4FBA4E9C07AAB19E30ECE91BE5506006799911E5DC9AB3176028DBF4B72713400';
  Result[4].Response:='6005DC8CDC54AB609100';
  Result[5].Command:='9071000002000000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E5007342C674C82CFBA82FD682A3AEF7EDB00';
  Result[6].Response:='3042698F810CB3FDF8497B584979DAC41903B39CA00D5AA6480160B90DE42E4E9100';
  Result[7].Command:='9064000009007F58E726C9A857C400';
  Result[7].Response:='424B0DE12C5701B4A09100';
  Result[8].Command:='904500000820B42963BFCF127900';
  Result[8].Response:='0F82CBADFE73A4D1E6EF9100';
end;

function Ev2RotateOther:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90C4000029015C1FD82BC8E7B6A414B1CE5ED3B14330F0DB9E56F0893E5941B9F731033231903938323470851B6A00';
  Result[4].Response:='6005DC8CDC54AB609100';
  Result[5].Command:='9071000002010000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E5007342C674C82CFBA82FD682A3AEF7EDB00';
  Result[6].Response:='3042698F810CB3FDF8497B584979DAC41903B39CA00D5AA6480160B90DE42E4E9100';
  Result[7].Command:='906400000901753FF6B5BA18632E00';
  Result[7].Response:='424B0DE12C5701B4A09100';
  Result[8].Command:='904500000820B42963BFCF127900';
  Result[8].Response:='0F82CBADFE73A4D1E6EF9100';
end;

function Ev2RotateRoot:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,9);
  Result[0].Command:='905A00000300000000';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F81939C3893DDBD1D179100';
  Result[4].Command:='90C4000029805FEAD85DA2DFAF69D4FBA4E9C07AAB19E30ECE91BE5506006799911E5DC9AB311EE0AC4243281BD800';
  Result[4].Response:='9100';
  Result[5].Command:='9071000002000000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E5007342C674C82CFBA82FD682A3AEF7EDB00';
  Result[6].Response:='3042698F810CB3FDF8497B584979DAC41903B39CA00D5AA6480160B90DE42E4E9100';
  Result[7].Command:='9064000009007F58E726C9A857C400';
  Result[7].Response:='424B0DE12C5701B4A09100';
  Result[8].Command:='904500000820B42963BFCF127900';
  Result[8].Response:='0F810CD1F789C366CE2F9100';
end;

function Ev2WrongVersion:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90C4000029005FEAD85DA2DFAF69D4FBA4E9C07AAB19E30ECE91BE5506006799911E5DC9AB3176028DBF4B72713400';
  Result[4].Response:='9100';
  Result[5].Command:='9071000002000000';
  Result[5].Response:='1B872378795F4FFD772855FC87CA964D91AF';
  Result[6].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E5007342C674C82CFBA82FD682A3AEF7EDB00';
  Result[6].Response:='3042698F810CB3FDF8497B584979DAC41903B39CA00D5AA6480160B90DE42E4E9100';
  Result[7].Command:='9064000009007F58E726C9A857C400';
  Result[7].Response:='43E16F3257D7F9C6499100';
end;

function Ev2FreeMemory:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,4);
  Result[0].Command:='905A00000300000000';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='906E0000082FFF9CAAAC92AA9600';
  Result[3].Response:='563412041FA822AE097A709100';
end;

function Ev2FixedSettings:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,4);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='07824803DE964C84EEBE9100';
end;

function Ev2DeniedRotation:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,4);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='FE82ADDEC3D1FA8399A39100';
end;

function Ev2DeniedFileChange:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,5);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90F5000009004F0E8E1DED561C8300';
  Result[4].Response:='00030F00200000AECB483874BFE18C9100';
end;

function Ev2SettingsMismatch:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90540000188A7FA8F6FBF9E75A93FEB5C03620B35D9AC549BCB73AC86E00';
  Result[4].Response:='6005DC8CDC54AB609100';
  Result[5].Command:='904500000868F07460941F8A9600';
  Result[5].Response:='0F821910AF30E5E85FC69100';
end;

function Ev2GeometryMismatch:TDesfireWirePairs;
begin
  Result:=nil;SetLength(Result,7);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90450000087D4BBE2D1190E99C00';
  Result[3].Response:='0F823FB72D9A7EBF276A9100';
  Result[4].Command:='90F5000009004F0E8E1DED561C8300';
  Result[4].Response:='000300002000009EBDCCD586EA6FB09100';
  Result[5].Command:='905F0000190096111F63F848AFCB9871057731824F84BB3925DEF575FA2F00';
  Result[5].Response:='CFB63387839D11299100';
  Result[6].Command:='90F500000900B410C71E49C49A1B00';
  Result[6].Response:='000110E12100002C1B865CAECAACEB9100';
end;

end.
