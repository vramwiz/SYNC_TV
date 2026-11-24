unit TV_Timeline;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// フレームに対応する番組時刻、場面の選択と電源の変化を計算する。

interface

type
  TTVSignal = record
    Channel: Integer;
    Light: Single;
    Indicator: Single;
    ProgramTime: Double;
  end;

  TTVScene = record
    Index: Cardinal;
    Age, Phase: Double;
    function Choice(Salt, Count: Cardinal): Integer;
    function Variation(Salt: Cardinal): Double;
  end;

const
  TV_POWER_ON = 0.36;
  TV_POWER_OFF = 0.32;
  TV_CHANNEL_CHANGE = 0.26;

function TVClamp(Value: Double): Double;
function TVSmooth(Value: Double): Double;
function TVLerp(A, B, Fraction: Double): Double;
function TVCycle(Time, Period: Double): Double;
function TVHash(Value: Cardinal): Cardinal;
function TVSceneAt(Time, Duration: Double): TTVScene;
// PreviousChannel = Channel の場合は定常状態。Age は直近の変更からの秒数。
function TVSignalAt(Channel, PreviousChannel: Integer; Time, Age: Double): TTVSignal;

implementation

uses
  System.Math;

function TVClamp(Value: Double): Double;
begin
  Result := EnsureRange(Value, 0.0, 1.0);
end;

function TVSmooth(Value: Double): Double;
begin
  Value := TVClamp(Value);
  Result := Value * Value * (3 - 2 * Value);
end;

function TVLerp(A, B, Fraction: Double): Double;
begin
  Result := A + (B - A) * Fraction;
end;

function TVCycle(Time, Period: Double): Double;
begin
  Result := Time / Period;
  Result := Result - Floor(Result);
end;

function TVHash(Value: Cardinal): Cardinal;
begin
  Value := Value xor (Value shr 16);
  Value := Cardinal((UInt64(Value) * $7FEB352D) and $FFFFFFFF);
  Value := Value xor (Value shr 15);
  Value := Cardinal((UInt64(Value) * $846CA68B) and $FFFFFFFF);
  Result := Value xor (Value shr 16);
end;

function TVSceneAt(Time, Duration: Double): TTVScene;
begin
  Result.Index := Cardinal(Floor(Time / Duration));
  Result.Age := Time - Result.Index * Duration;
  Result.Phase := TVClamp(Result.Age / Duration);
end;

function TTVScene.Choice(Salt, Count: Cardinal): Integer;
begin
  Result := TVHash(Index xor TVHash(Salt)) mod Count;
end;

function TTVScene.Variation(Salt: Cardinal): Double;
begin
  Result := (TVHash(Index xor TVHash(Salt)) shr 8) / $FFFFFF;
end;

function TVSignalAt(Channel, PreviousChannel: Integer; Time, Age: Double): TTVSignal;
begin
  Result.Channel := Channel;
  Result.ProgramTime := Time;
  Result.Light := Ord(Channel > 0);
  Result.Indicator := Result.Light;
  if Channel = PreviousChannel then Exit;
  if Channel = 0 then
  begin
    if Age < TV_POWER_OFF then
    begin
      Result.Channel := PreviousChannel;
      Result.Light := 1 - TVSmooth(Age / TV_POWER_OFF);
      Result.Indicator := Result.Light;
    end;
  end
  else if PreviousChannel = 0 then
  begin
    Result.Light := TVSmooth((Age - 0.045) / (TV_POWER_ON - 0.045));
    Result.Indicator := TVSmooth(Age / 0.16);
  end
  else
    Result.Light := TVSmooth((Age - 0.072) / (TV_CHANNEL_CHANGE - 0.072));
end;

end.
