unit TV_Parameters;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// AviUtl2の標準項目の登録、現在値の取得、チャンネル履歴の参照。

interface

uses
  AviUtl2FilterTypes, TV_Screen, TV_Timeline;

procedure RegisterTVParameters;
function ReadTVSettings: TTVSettings;
// 描画するフレームとその直前をSDKから評価する。ホストのポインターを保持しない。
function ReadTVSignal(Video: PFILTER_PROC_VIDEO; Channel: Integer): TTVSignal;

implementation

uses
  System.Types, System.Math, PluginFilterTable;

const
  CHANNEL_ITEM = 'チャンネル';
  MAX_CHANNEL = 999;
  CORNER_X: array[0..3] of PWideChar = ('左上X','右上X','右下X','左下X');
  CORNER_Y: array[0..3] of PWideChar = ('左上Y','右上Y','右下Y','左下Y');

var
  Main, Appearance, Shape: TFILTER_ITEM_GROUP;
  ChannelTrack, Aspect, CornerRadius, Ambient: TFILTER_ITEM_TRACK;
  Body: TFILTER_ITEM_CHECK;
  CornerX, CornerY: array[0..3] of TFILTER_ITEM_TRACK;

function Limited(Value, Low, High, DefaultValue: Double): Double;
begin
  if IsNan(Value) or IsInfinite(Value) then Exit(DefaultValue);
  Result := EnsureRange(Value,Low,High);
end;

function ChannelNumber(Value: Double): Integer;
begin
  Result := Floor(Limited(Value,0,MAX_CHANNEL,10)+0.5);
end;

procedure RegisterTVParameters;
var
  Index: Integer;
begin
  AddGroup(Main,'テレビ設定',1);
  AddTrack(ChannelTrack,CHANNEL_ITEM,10,0,MAX_CHANNEL,1);
  AddCheck(Body,'テレビ本体描画',0);
  AddTrack(CornerRadius,'角丸',0,0,480,0.01);
  AddTrack(Ambient,'周囲の明るさ',50,0,100,0.01);

  AddGroup(Appearance,'画面形状',1);
  AddTrack(Aspect,'縦横比',-43.75,-95,95,0.001);

  AddGroup(Shape,'四隅補正',0);
  for Index := 0 to High(CornerX) do
  begin
    AddTrack(CornerX[Index],CORNER_X[Index],0,-480,480,0.01);
    AddTrack(CornerY[Index],CORNER_Y[Index],0,-480,480,0.01);
  end;
end;

function ReadTVSettings: TTVSettings;
var
  Index: Integer;
begin
  Result.Channel := ChannelNumber(ChannelTrack.Value);
  Result.Body := Body.Value<>0;
  Result.Aspect := Limited(Aspect.Value,-95,95,-43.75);
  Result.CornerRadius := Limited(CornerRadius.Value,0,480,0);
  Result.Ambient := Limited(Ambient.Value,0,100,50);
  for Index := 0 to High(Result.Corners) do
    Result.Corners[Index] := PointF(Limited(CornerX[Index].Value,-480,480,0),
      Limited(CornerY[Index].Value,-480,480,0));
end;

function ReadTVSignal(Video: PFILTER_PROC_VIDEO; Channel: Integer): TTVSignal;
var
  Obj: POBJECT_INFO;
  CurrentFrame, PreviousFrame, FirstFrame, Window: Int64;
  Time, FrameSeconds, Age, Value: Double;
  PreviousChannel: Integer;
begin
  Obj := Video^.Object_;
  Time := Limited(Obj^.Time,0,1E9,0);
  Result := TVSignalAt(Channel,Channel,Time,0);
  if (Video^.Edit=nil) or (Obj^.EffectHandle=nil) or (Video^.Scene=nil) or
    not Assigned(Video^.Edit^.GetEffectTrackValue) then Exit;
  if (Video^.Scene^.Rate<=0) or (Video^.Scene^.Scale<=0) or (Obj^.Frame<=0) then Exit;
  FrameSeconds := Video^.Scene^.Scale/Video^.Scene^.Rate;
  CurrentFrame := Int64(Obj^.FrameS)+Obj^.Frame;

  // 参照先はシーン上の絶対フレーム。実際に評価された現在値と一致する場合に履歴を使う。
  if not Video^.Edit^.GetEffectTrackValue(Obj^.EffectHandle,CHANNEL_ITEM,CurrentFrame,Value) or
    (ChannelNumber(Value)<>Channel) then Exit;
  Window := Min(Int64(4096),Ceil(Max(TV_POWER_ON,Max(TV_POWER_OFF,TV_CHANNEL_CHANGE))/FrameSeconds));
  FirstFrame := Max(Int64(Obj^.FrameS),CurrentFrame-Window);
  for PreviousFrame := CurrentFrame-1 downto FirstFrame do
  begin
    if not Video^.Edit^.GetEffectTrackValue(Obj^.EffectHandle,CHANNEL_ITEM,PreviousFrame,Value) then Exit;
    PreviousChannel := ChannelNumber(Value);
    if PreviousChannel=Channel then Continue;
    Age := Max(0.0, Time-(PreviousFrame+1-Obj^.FrameS)*FrameSeconds);
    Result := TVSignalAt(Channel,PreviousChannel,Time,Age);
    Exit;
  end;
end;

end.
