unit SYNC_TV_FilterPlugin;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// テレビ演出の登録と映像出力。インスタンス単位で描画資源を所有する。

interface

uses
  AviUtl2FilterTypes;

const
  TV_REQUIRED_VERSION = 2011600;

// DLL 所有のメディアオブジェクト登録情報を返す。
function GetTVFilterTable: PFILTER_PLUGIN_TABLE;

implementation

uses
  System.SysUtils, System.SyncObjs, Winapi.Windows,
  PluginFilterTable, TV_Parameters, TV_Screen, TV_Timeline;

type
  TTVSession = class
  private
    FLock: TCriticalSection;
    FScreen: TTVScreen;
    FOutput: TTVPixels;
  public
    constructor Create;
    destructor Destroy; override;
    function Render(Video: PFILTER_PROC_VIDEO): Byte;
  end;

var
  TableReady: Boolean;

constructor TTVSession.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FScreen := TTVScreen.Create;
end;

destructor TTVSession.Destroy;
begin
  FScreen.Free;
  FLock.Free;
  inherited;
end;

function TTVSession.Render(Video: PFILTER_PROC_VIDEO): Byte;
var
  Settings: TTVSettings;
  Signal: TTVSignal;
  Width, Height: Integer;
begin
  Result := 0;
  if not Assigned(Video^.SetImageData) then Exit;
  // SDK の設定と履歴は、この描画コールバックの間だけ参照する。
  Settings := ReadTVSettings;
  Signal := ReadTVSignal(Video,Settings.Channel);
  FLock.Acquire;
  try
    FScreen.Render(Settings,Signal,FOutput,Width,Height);
    Video^.SetImageData(@FOutput[0],Width,Height);
    Result := 1;
  finally
    FLock.Release;
  end;
end;

function TVProcVideo(Video: PFILTER_PROC_VIDEO): Byte; cdecl;
begin
  Result := 0;
  if (Video=nil) or (Video^.Object_=nil) or (Video^.UserData=nil) then Exit;
  try
    Result := TTVSession(Video^.UserData).Render(Video);
  except
    on E: Exception do OutputDebugString(PWideChar('SYNC_TV render: '+E.Message));
  end;
end;

function TVCreate(EffectID: Int64): Pointer; cdecl;
begin
  Result := nil;
  try
    Result := TTVSession.Create;
  except
    on E: Exception do OutputDebugString(PWideChar('SYNC_TV create: '+E.Message));
  end;
end;

procedure TVDestroy(EffectID: Int64; UserData: Pointer); cdecl;
begin
  try
    TTVSession(UserData).Free;
  except
    on E: Exception do OutputDebugString(PWideChar('SYNC_TV destroy: '+E.Message));
  end;
end;

function GetTVFilterTable: PFILTER_PLUGIN_TABLE;
begin
  if not TableReady then
  begin
    SetupPluginTable(FILTER_FLAG_VIDEO or FILTER_FLAG_INPUT or FILTER_FLAG_USERDATA,
      'テレビ演出','SYNC','テレビ演出 / SYNC_TV v1.0.0',TVProcVideo,nil);
    RegisterTVParameters;
    GetPluginTable^.Func_Create := TVCreate;
    GetPluginTable^.Func_Destroy := TVDestroy;
    TableReady := True;
  end;
  Result := GetPluginTable;
end;

end.
