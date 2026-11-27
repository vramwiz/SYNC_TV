program TV_RenderTests;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// ビルド済み本番AUF2を読み込み、SDKの描画境界とフレームの再現性を検査する。

{$APPTYPE CONSOLE}
{$POINTERMATH ON}

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Hash, System.Math,
  AviUtl2FilterTypes in 'Source\Lib\AviUtl2FilterTypes.pas';

type
  TGetTable = function: PFILTER_PLUGIN_TABLE; cdecl;
  TInitialize = function(Version: Cardinal): Byte; cdecl;
  TRequiredVersion = function: Cardinal; cdecl;
  TItemList = array[0..99] of Pointer;
  PItemList = ^TItemList;
  TFrame = record
    Width, Height: Integer;
    Pixels: TArray<TPIXEL_RGBA>;
    function Center: TPIXEL_RGBA;
    function Digest: string;
  end;

var
  Table: PFILTER_PLUGIN_TABLE;
  Video: TFILTER_PROC_VIDEO;
  Edit: TEDIT_SECTION;
  Obj: TOBJECT_INFO;
  Scene: TSCENE_INFO;
  Output: TFrame;
  Timeline: Integer;
  LastLookup: Integer;

procedure Require(Condition: Boolean; const MessageText: string);
begin
  if not Condition then raise Exception.Create(MessageText);
end;

function TFrame.Center: TPIXEL_RGBA;
begin
  Result := Pixels[(Height div 2)*Width+Width div 2];
end;

function TFrame.Digest: string;
var
  H: THashSHA2;
begin
  H := THashSHA2.Create;
  H.Update(Width, SizeOf(Width));
  H.Update(Height, SizeOf(Height));
  H.Update(Pixels[0], Length(Pixels)*SizeOf(TPIXEL_RGBA));
  Result := H.HashAsString;
end;

procedure StoreImage(Buffer: PPIXEL_RGBA; Width,Height: Integer); cdecl;
begin
  Output.Width := Width;
  Output.Height := Height;
  SetLength(Output.Pixels,Width*Height);
  Move(Buffer^,Output.Pixels[0],Length(Output.Pixels)*SizeOf(TPIXEL_RGBA));
end;

function Track(const Name: string): PFILTER_ITEM_TRACK;
var
  Index: Integer;
  Item: PFILTER_ITEM_TRACK;
begin
  for Index := 0 to 99 do
  begin
    Item := PItemList(Table^.Items)^[Index];
    if Item=nil then Break;
    if (string(Item^.ItemType)='track') and (string(Item^.Name)=Name) then Exit(Item);
  end;
  raise Exception.Create('Missing track '+Name);
end;

function CheckBox(const Name: string): PFILTER_ITEM_CHECK;
var
  Index: Integer;
  Item: PFILTER_ITEM_CHECK;
begin
  for Index := 0 to 99 do
  begin
    Item := PItemList(Table^.Items)^[Index];
    if Item=nil then Break;
    if (string(Item^.ItemType)='check') and (string(Item^.Name)=Name) then Exit(Item);
  end;
  raise Exception.Create('Missing checkbox '+Name);
end;

function ChannelAt(Frame: Integer): Integer;
begin
  // タイムライン上のフレーム120で切替。AviUtl2オブジェクトは100から始まる。
  case Timeline of
    1: if Frame<120 then Result := 0 else Result := 2;
    2: if Frame<120 then Result := 2 else Result := 0;
    3: if Frame<120 then Result := 10 else Result := 2;
    4: if Frame<120 then Result := 10 else Result := 24;
    5: if Frame<120 then Result := 24 else Result := 0;
  else
    Result := 10;
  end;
end;

function LookupTrack(Effect: EFFECT_HANDLE; Item: PWideChar; Frame: Double;
  out Value: Double): Boolean; cdecl;
begin
  Result := (Effect=Pointer(17)) and (string(Item)='チャンネル') and
    (Frame>=100) and (Frame<=Obj.FrameS+Obj.Frame);
  if Result then
  begin
    LastLookup := Min(LastLookup,Trunc(Frame));
    Value := ChannelAt(Trunc(Frame));
  end;
end;

function Render(Channel, Frame: Integer; Subframe: Double = 0): TFrame;
begin
  Track('チャンネル')^.Value := Channel;
  Obj.Frame := Frame;
  Obj.Time := (Frame+Subframe)*Scene.Scale/Scene.Rate;
  Output := Default(TFrame);
  LastLookup := High(Integer);
  Require(Table^.Func_Proc_Video(@Video)=1,
    Format('Render failed ch=%d frame=%d',[Channel,Frame]));
  Require((Output.Width>0) and (Output.Height>0) and
    (Length(Output.Pixels)=Output.Width*Output.Height),'Invalid output size');
  Result := Output;
end;

procedure SavePreview(const Name: string; const Frame: TFrame);
var
  Bitmap: TBitmapFileHeader;
  Info: TBitmapInfoHeader;
  FileOut: TFileStream;
  Image: TBytes;
  P: TPIXEL_RGBA;
  I, X, Y, Back: Integer;
begin
  SetLength(Image,Frame.Width*Frame.Height*4);
  for I := 0 to High(Frame.Pixels) do
  begin
    P := Frame.Pixels[I];
    X := I mod Frame.Width;
    Y := I div Frame.Width;
    Back := 35+12*((X div 32+Y div 32) mod 2);
    Image[I*4] := (P.B*P.A+Back*(255-P.A)+127) div 255;
    Image[I*4+1] := (P.G*P.A+Back*(255-P.A)+127) div 255;
    Image[I*4+2] := (P.R*P.A+Back*(255-P.A)+127) div 255;
    Image[I*4+3] := 0;
  end;
  Bitmap := Default(TBitmapFileHeader);
  Bitmap.bfType := $4D42;
  Bitmap.bfOffBits := SizeOf(Bitmap)+SizeOf(Info);
  Bitmap.bfSize := Bitmap.bfOffBits+Length(Image);
  Info := Default(TBitmapInfoHeader);
  Info.biSize := SizeOf(Info);
  Info.biWidth := Frame.Width;
  Info.biHeight := -Frame.Height;
  Info.biPlanes := 1;
  Info.biBitCount := 32;
  FileOut := TFileStream.Create(Name, fmCreate);
  try
    FileOut.WriteBuffer(Bitmap,SizeOf(Bitmap));
    FileOut.WriteBuffer(Info,SizeOf(Info));
    FileOut.WriteBuffer(Image[0],Length(Image));
  finally
    FileOut.Free;
  end;
end;

procedure CheckTimeline;
var
  First, Near, Middle, EndFrame: TFrame;
  C: TPIXEL_RGBA;
begin
  Timeline := 1;
  First := Render(2,20);
  Require(LastLookup=119,'Power-on history is not read by absolute frame');
  Near := Render(2,24);
  Middle := Render(2,27);
  EndFrame := Render(2,35);
  Require((First.Center.G<Near.Center.G) and (Near.Center.G<Middle.Center.G) and
    (Middle.Center.G<=EndFrame.Center.G),'Power-on ramp');
  Require(Render(2,24).Digest=Near.Digest,'Power-on rewind');
  Require(Render(2,0).Digest=EndFrame.Digest,'Initial channel uses full brightness');
  Timeline := 2;
  First := Render(0,20);
  Near := Render(0,24);
  EndFrame := Render(0,35);
  C := EndFrame.Center;
  Require((First.Center.G>Near.Center.G) and (Near.Center.G>C.G) and (C.A=255),'Power-off ramp');
  Require(Render(0,24).Digest=Near.Digest,'Power-off rewind');
  Timeline := 3;
  First := Render(2,20);
  Near := Render(2,26);
  Require((First.Center.G<Near.Center.G) and (Near.Center.G<Render(2,35).Center.G),'Channel blank');
  Require(Render(2,20).Digest=First.Digest,'Channel rewind');
  Timeline := 4;
  First := Render(24,20);
  Require(LastLookup=119,'Game switch uses channel history');
  EndFrame := Render(24,35);
  Timeline := 0;
  Require(First.Digest=Render(0,20).Digest,'Game channel starts with a black screen');
  Require(EndFrame.Digest=Render(24,35).Digest,'Game channel reaches full brightness');
  Timeline := 5;
  First := Render(0,20);
  EndFrame := Render(0,35);
  Timeline := 0;
  Require(First.Digest=Render(24,20).Digest,'Game image persists at the start of power-off');
  Require(EndFrame.Digest=Render(0,35).Digest,'Game channel powers off');
end;

procedure CheckGeometry(const PreviewDir: string);
var
  Image, Dark, Bright, OffDark, OffBright, Body, Warp, Invalid: TFrame;
  P: TPIXEL_RGBA;
begin
  Track('周囲の明るさ')^.Value := 100;
  Image := Render(10,67);
  Require((Image.Width=960) and (Image.Height=540),'Default 16:9 dimensions');
  Require(Image.Center.A=255,'Default screen must be opaque');
  Track('角丸')^.Value := 75;
  Image := Render(10,67);
  Require(Image.Pixels[0].A=0,'Rounded corner is transparent');
  Track('縦横比')^.Value := 43.75;
  Image := Render(10,67);
  Require((Image.Width=540) and (Image.Height=960),'Portrait 9:16 dimensions');
  Track('縦横比')^.Value := -75;
  Image := Render(10,67);
  Require((Image.Width=960) and (Image.Height=240),'Wide 4:1 dimensions');
  Track('縦横比')^.Value := -43.75;
  Bright := Render(10,67);
  OffBright := Render(0,67);
  Track('周囲の明るさ')^.Value := 0;
  Dark := Render(10,67);
  OffDark := Render(0,67);
  P := Dark.Pixels[(Dark.Height div 2)*Dark.Width+12];
  Require((Dark.Width>Bright.Width) and (P.A>0) and (P.A<128),'Dark-room colored light spill');
  Require((OffBright.Center.B>OffDark.Center.B) and (OffDark.Center.A=255),'Powered-off reflections');
  CheckBox('テレビ本体描画')^.Value := 1;
  Body := Render(10,67);
  Require((Body.Height>Dark.Height) and (Body.Width>Dark.Width),'Body includes bezel and stand');
  Track('左上Y')^.Value := 115;
  Track('左下Y')^.Value := -68;
  Track('右上X')^.Value := 47;
  Warp := Render(10,67);
  Require((Warp.Digest<>Body.Digest) and (Warp.Pixels[0].A=0),'Perspective warp with transparent surround');
  if PreviewDir<>'' then SavePreview(IncludeTrailingPathDelimiter(PreviewDir)+'body-perspective.bmp',Warp);
  Track('左上Y')^.Value := 0;
  Track('左下Y')^.Value := 0;
  Track('右上X')^.Value := 0;
  Track('左上X')^.Value := 480;
  Track('右上X')^.Value := -480;
  Invalid := Render(10,67);
  Require(Invalid.Digest=Body.Digest,'Degenerate corners must leave the image intact');
  Track('左上X')^.Value := 0;
  Track('右上X')^.Value := 0;
  CheckBox('テレビ本体描画')^.Value := 0;
  Track('角丸')^.Value := 0;
  Track('周囲の明るさ')^.Value := 50;
end;

procedure CheckPrograms(const PreviewDir: string);
const
  Frames: array[0..4] of Integer = (65,326,540,13066,1080131);
var
  Channel, Index: Integer;
  Near, Later, Rewind, Other: TFrame;
  Digests: TStringList;
  AdditionalSession, OriginalSession: Pointer;
  Worker: TThread;
begin
  Digests := TStringList.Create;
  try
    for Channel := 0 to 30 do
    begin
      Near := Render(Channel,Frames[0]);
      for Index := 1 to High(Frames) do
      begin
        Later := Render(Channel,Frames[Index]);
        if (Channel in [1,3..30]) then
          Require(Near.Digest<>Later.Digest,'Program has no motion '+IntToStr(Channel));
      end;
      Rewind := Render(Channel,Frames[0]);
      Require(Near.Digest=Rewind.Digest,'Rewind mismatch channel '+IntToStr(Channel));
      Writeln(Format('CH %2d  %s',[Channel,Near.Digest]));
      if Channel>=10 then
      begin
        Require(Digests.IndexOf(Near.Digest)<0,'Different channels rendered the same frame');
        Digests.Add(Near.Digest);
        if PreviewDir<>'' then
        begin
          SavePreview(IncludeTrailingPathDelimiter(PreviewDir)+IntToStr(Channel)+'-a.bmp',Near);
          SavePreview(IncludeTrailingPathDelimiter(PreviewDir)+IntToStr(Channel)+'-b.bmp',
            Render(Channel,Frames[1]));
        end;
      end;
    end;
    Near := Render(999,1080131);
    Require((Near.Center.A=255) and (Render(31,1080131).Digest=Near.Digest) and
      (Render(4,1080131).Digest=Near.Digest),'Unassigned channel falls back safely');
    OriginalSession := Video.UserData;
    AdditionalSession := Table^.Func_Create(37);
    Require(AdditionalSession<>nil,'Cannot create second TV instance');
    try
      Video.UserData := AdditionalSession;
      Worker := TThread.CreateAnonymousThread(
        procedure
        begin
          Other := Render(10,65);
        end);
      Worker.FreeOnTerminate := False;
      try
        Worker.Start;
        Worker.WaitFor;
        Require(Worker.FatalException=nil,'Worker-thread render failed');
      finally
        Worker.Free;
      end;
      Render(16,326);
      Require(Render(10,65).Digest=Other.Digest,'Drawing resources fail after switching workers');
      Video.UserData := OriginalSession;
      Render(16,326);
      Require(Render(10,65).Digest=Other.Digest,'TV instances interfere');
    finally
      Video.UserData := OriginalSession;
      Table^.Func_Destroy(37,AdditionalSession);
    end;
  finally
    Digests.Free;
  end;
end;

procedure CheckGameFrames;
var
  Channel: Integer;
  Original, Later, Warped: TFrame;
begin
  for Channel := 21 to 30 do
  begin
    Original := Render(Channel,141);
    Require(Render(Channel,141).Digest=Original.Digest,'Same game frame changed while paused');
    Later := Render(Channel,140987);
    Require(Later.Digest<>Original.Digest,'Game state did not advance');
    Require(Render(Channel,141).Digest=Original.Digest,'Game seek changed the first frame');
  end;
  Scene.Rate := 1;
  for Channel := 21 to 30 do
    Require(Render(Channel,1000000000).Center.A=255,'Game fails at the upper time bound');
  Scene.Rate := 30;
  Track('角丸')^.Value := 75;
  Track('縦横比')^.Value := -75;
  Track('周囲の明るさ')^.Value := 100;
  Original := Render(28,86);
  Require((Original.Width=960) and (Original.Height=240) and (Original.Pixels[0].A=0),
    'Game video follows TV aspect and rounded corners');
  Track('左上Y')^.Value := 75;
  Warped := Render(28,86);
  Require((Warped.Digest<>Original.Digest) and (Warped.Pixels[0].A=0),
    'Game video follows corner correction');
  Track('左上Y')^.Value := 0;
  Track('角丸')^.Value := 0;
  Track('縦横比')^.Value := -43.75;
  Track('周囲の明るさ')^.Value := 50;
end;

procedure Run;
var
  LibraryHandle: HMODULE;
  GetTable: TGetTable;
  Initialize: TInitialize;
  RequiredVersion: TRequiredVersion;
  PreviewDir: string;
begin
  Require(ParamCount>=1,'Usage: TV_RenderTests <AUF2> [preview-directory]');
  PreviewDir := '';
  if ParamCount>1 then
  begin
    PreviewDir := ParamStr(2);
    ForceDirectories(PreviewDir);
  end;
  LibraryHandle := LoadLibrary(PWideChar(ParamStr(1)));
  if LibraryHandle=0 then RaiseLastOSError;
  try
    GetTable := GetProcAddress(LibraryHandle,'GetFilterPluginTable');
    Initialize := GetProcAddress(LibraryHandle,'InitializePlugin');
    RequiredVersion := GetProcAddress(LibraryHandle,'RequiredVersion');
    Require(Assigned(GetTable) and Assigned(Initialize) and Assigned(RequiredVersion),'Missing DLL exports');
    Require((RequiredVersion=2011600) and (Initialize(2011500)=0) and
      (Initialize(2011600)=1),'Incorrect minimum version');
    Table := GetTable;
    Require(Table<>nil,'Missing plugin table');
    Require((string(Table^.Name)='テレビ演出') and (string(Table^.Label_)='SYNC'),'Registration name');
    Require((Table^.Flag=21) and not Assigned(Table^.Func_Proc_Audio),'Media object without audio');
    Require((Track('チャンネル')^.Value=10) and (Track('チャンネル')^.Step=1)
      and (Track('縦横比')^.Value=-43.75) and (Track('周囲の明るさ')^.Value=50)
      and (CheckBox('テレビ本体描画')^.Value=0),'Incorrect initial values');
    Require((NativeUInt(@Obj.EffectHandle)-NativeUInt(@Obj)=112) and
      (NativeUInt(@@Edit.GetEffectTrackValue)-NativeUInt(@Edit)=472),'Win64 SDK offsets');
    Scene.Width := 1920;
    Scene.Height := 1080;
    Scene.Rate := 30;
    Scene.Scale := 1;
    Obj.FrameS := 100;
    Obj.FrameE := 1200000;
    Obj.FrameTotal := Obj.FrameE-Obj.FrameS+1;
    Obj.EffectHandle := Pointer(17);
    Edit.GetEffectTrackValue := LookupTrack;
    Video.Scene := @Scene;
    Video.Object_ := @Obj;
    Video.SetImageData := StoreImage;
    Video.UserData := Table^.Func_Create(19);
    Require(Video.UserData<>nil,'Cannot create TV instance');
    try
      CheckPrograms(PreviewDir);
      CheckGeometry(PreviewDir);
      CheckGameFrames;
      Video.Edit := @Edit;
      CheckTimeline;
    finally
      Table^.Func_Destroy(19,Video.UserData);
    end;
  finally
    FreeLibrary(LibraryHandle);
  end;
  Writeln('PASS');
end;

begin
  try
    Run;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput,E.ClassName,': ',E.Message);
      ExitCode := 1;
    end;
  end;
end.
