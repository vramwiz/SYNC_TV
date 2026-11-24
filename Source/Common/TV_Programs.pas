unit TV_Programs;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// チャンネル番号から番組と特殊表示を選び、透過処理前の番組映像を生成する。

interface

uses TV_Canvas;

// TVの画面形状や電源の明るさに依存しない960×540の映像を描く。
procedure DrawTVProgram(Canvas: TTVCanvas; Channel: Integer; Time: Double);

implementation

uses
  System.Math, System.SysUtils, TV_Timeline, TV_Artwork, TV_Studio, TV_Sports,
  TV_Entertainment;

type
  TDrawProgram = procedure(Canvas: TTVCanvas; Time: Double);

const
  Programs: array[10..20] of TDrawProgram = (DrawNews,DrawForecast,DrawBaseball,
    DrawFootball,DrawVariety,DrawMusic,DrawAnimation,DrawCooking,DrawShopping,
    DrawDrama,DrawCommercial);

procedure DrawStatic(Canvas: TTVCanvas; Time: Double);
var
  NoiseSeed, Pattern: Cardinal;
  X, Y, Offset, Shade: Integer;
  Pixel: PTVBGRAPixel;
  Band: Double;
begin
  NoiseSeed := TVHash(Cardinal(UInt64(Trunc(Time*30)) and $FFFFFFFF));
  Offset := Trunc(TVCycle(Time,0.86)*TV_PROGRAM_HEIGHT);
  Pixel := Canvas.Pixels;
  for Y := 0 to TV_PROGRAM_HEIGHT-1 do
  begin
    Band := Max(0.0,1.0-Abs(Y-Offset)/57);
    for X := 0 to TV_PROGRAM_WIDTH-1 do
    begin
      Pattern := TVHash(NoiseSeed xor Cardinal(Y*TV_PROGRAM_WIDTH+X));
      Shade := 42+(Pattern and 158)+Trunc(Band*34);
      Pixel^.R := Shade;
      Pixel^.G := Shade;
      Pixel^.B := Shade;
      Pixel^.A := 255;
      Inc(Pixel);
    end;
  end;
end;

procedure DrawBars(Canvas: TTVCanvas);
const
  Top: array[0..6] of TTVColor = ($C1C1C1,$C0C13C,$3DC0C1,$46BC43,$BE46BB,$BE4343,$4448BA);
  Strip: array[0..6] of TTVColor = ($4448BA,$171A26,$BE46BB,$171A26,$3DC0C1,$171A26,$C1C1C1);
var
  I: Integer;
begin
  Canvas.Clear($151725);
  for I := 0 to 6 do
  begin
    Canvas.Fill(I*960/7,0,960/7+0.3,347,Top[I]);
    Canvas.Fill(I*960/7,347,960/7+0.3,67,Strip[I]);
  end;
  for I := 0 to 7 do Canvas.Fill(23+I*65,450,65,57,TVColorMix($000000,$DFE2EB,I/7));
  Canvas.LabelText('COLOR TEST',606,452,308,29,$EDF0F6,True,1);
end;

procedure DrawNoSignal(Canvas: TTVCanvas; Time: Double; Reserved: Boolean);
var
  X, Y: Single;
begin
  Canvas.Shade(0,0,960,540,$11243A,$060B15);
  X := 119+640*TVCycle(Time,46);
  Y := 103+296*(0.5-0.5*Cos(Time*0.097));
  Canvas.RoundRect(X-99,Y-35,199,69,10,$182F49);
  Canvas.Fill(X-75,Y-19,19,3,$8DB4D9);
  Canvas.LabelText('信号なし',X-45,Y-21,122,28,$D9E9FA,True,2);
  if Reserved then Canvas.LabelText('放送休止中',0,460,960,19,$7894B3,False,2);
end;

procedure DrawTVProgram(Canvas: TTVCanvas; Channel: Integer; Time: Double);
begin
  if Channel = 1 then
  begin
    DrawStatic(Canvas,Time);
    Exit;
  end;
  Canvas.BeginFrame;
  try
    if (Channel >= Low(Programs)) and (Channel <= High(Programs)) then
      Programs[Channel](Canvas,Time)
    else
      case Channel of
        0: Canvas.Clear($000000);
        2: DrawBars(Canvas);
        3: DrawNoSignal(Canvas,Time,False);
      else
        DrawNoSignal(Canvas,Time,True);
      end;
  finally
    Canvas.EndFrame;
  end;
end;

end.
