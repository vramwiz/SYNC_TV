unit TV_GameRacing;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 道路の遠近投影と車両の位置からレース映像を生成する。

interface

uses TV_Canvas;

// 提供された960×540の番組面に時刻 Time（秒）のレースを描く。
procedure DrawRacingGame(Canvas: TTVCanvas; Time: Double);

implementation

uses System.Math, System.SysUtils, TV_Timeline, TV_GameArt;

procedure RaceCar(Canvas: TTVCanvas; X, Y, Scale: Single; Body, Glass: TTVColor);
begin
  Canvas.Ellipse(X,Y,82*Scale,13*Scale,$16182B,0.69);
  Canvas.Transform(X,Y,Scale);
  try
    Canvas.RoundRect(-72,-29,33,35,6,$151A2B);
    Canvas.RoundRect(39,-29,33,35,6,$151A2B);
    Canvas.Path([M,-75,-38,L,-52,-57,L,-33,-87,L,33,-87,L,55,-55,L,74,-38,
      L,71,-9,L,-70,-9,Z],Body,'game.race.hatchback');
    Canvas.Path([M,-41,-55,L,-27,-77,L,27,-77,L,43,-55,Z],Glass,'game.race.window');
    Canvas.Fill(-67,-35,134,12,$252B41);
    Canvas.Fill(-62,-33,33,6,$FF9177);
    Canvas.Fill(29,-33,33,6,$FF9177);
    Canvas.Fill(-21,-31,42,12,$E6D0A6);
    Canvas.Fill(-10,-29,20,5,$42516F);
    Canvas.Fill(-63,-15,126,5,$F3DAC4,0.65);
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure DrawRacingGame(Canvas: TTVCanvas; Time: Double);
const
  StripCount = 34;
  RivalColors: array[0..3] of TTVColor = ($F59B5F,$75B9DF,$D883AA,$C1D17B);
var
  Race: TTVScene;
  Distance, Curve, Speed, Pos: Double;
  Depth, PreviousDepth, X, PreviousX, Y, PreviousY, W, PreviousW,
  Margin, PreviousMargin, Lane, Scale, CarX, RoadShift: Single;
  I, Column, Segment, Rank: Integer;
  RivalDepth: array[0..3] of Single;
  RivalDrawn: array[0..3] of Boolean;
  Color, Shoulder: TTVColor;
  PlayerDrawn: Boolean;

  function RoadCenter(Z: Double): Double;
  begin
    Result := 480+Curve*246*Sqr(1-Z)+56*Sin(Time*0.66+5*Z)*Z*(1-Z);
  end;

begin
  Race := TVSceneAt(Time,38);
  Curve := Sin(Time*0.48)*0.72+Sin(Time*0.21)*0.28;
  Speed := 156+46*Sin(Time*0.48+1.8)+19*Sin(Time*0.91);
  Distance := Time*9-1.4*Cos(Time*0.48+1.8)-0.43*Cos(Time*0.91);
  Canvas.Shade(0,0,960,540,$274780,$FFC18F);
  X := 673+91*Curve;
  Canvas.Ellipse(X,171,75,75,$FFE2A1,0.9);
  for I := -2 to 9 do
  begin
    X := I*154-47*Curve;
    Y := 180+((I+2)*7 mod 5)*13;
    Canvas.Path([M,X-35,264,L,X+77,Y,L,X+178,264,Z],$785C85);
    Canvas.Path([M,X+69,260,L,X+77,Y,L,X+124,260,Z],$98728E);
  end;
  Canvas.Shade(0,250,960,290,$A96E75,$53405E);
  PreviousDepth := 0;
  PreviousX := RoadCenter(0);
  PreviousY := 251;
  PreviousW := 14;
  PreviousMargin := 3;
  for I := 1 to StripCount do
  begin
    Depth := I/StripCount*1.12;
    X := RoadCenter(Depth);
    Y := 251+279*Sqr(Depth);
    W := 14+Depth*403;
    Margin := 3+15*Depth;
    Pos := Distance+12*(1-PreviousDepth)/Max(0.10,PreviousDepth+0.10);
    Segment := Trunc(Pos) mod 2;
    Color := TVColorMix($403A51,$5C5061,0.23*Segment);
    Canvas.Path([M,PreviousX-PreviousW-PreviousMargin,PreviousY,L,PreviousX+PreviousW+
      PreviousMargin,PreviousY,L,X+W+Margin,Y,L,X-W-Margin,Y,Z],
      TVColorMix($55485D,$8E5667,0.27+0.20*Segment));
    Canvas.Path([M,PreviousX-PreviousW,PreviousY,L,PreviousX+PreviousW,PreviousY,
      L,X+W,Y,L,X-W,Y,Z],Color);
    Shoulder := $FFE0A8;
    if Segment=0 then Shoulder := $E57D72;
    Canvas.Path([M,PreviousX-PreviousW,PreviousY,L,PreviousX-PreviousW+PreviousMargin,PreviousY,
      L,X-W+Margin,Y,L,X-W,Y,Z],Shoulder);
    Canvas.Path([M,PreviousX+PreviousW-PreviousMargin,PreviousY,L,PreviousX+PreviousW,PreviousY,
      L,X+W,Y,L,X+W-Margin,Y,Z],Shoulder);
    if Segment=1 then
      for Column := -1 to 1 do
      begin
        Lane := Column*2/3;
        Canvas.Path([M,PreviousX+Lane*PreviousW-2*PreviousDepth,PreviousY,
          L,PreviousX+Lane*PreviousW+2*PreviousDepth,PreviousY,L,X+Lane*W+2*Depth,Y,
          L,X+Lane*W-2*Depth,Y,Z],$ECD8B2);
      end;
    PreviousX := X;
    PreviousY := Y;
    PreviousW := W;
    PreviousMargin := Margin;
    PreviousDepth := Depth;
  end;
  Rank := 1;
  for I := 0 to High(RivalDepth) do
  begin
    RivalDepth[I] := TVCycle(Time*(1+(I mod 3)*0.16)+I*3.3,12+I*0.8)*1.18;
    if RivalDepth[I]<0.92 then Inc(Rank);
    RivalDrawn[I] := False;
  end;
  RoadShift := (Sin(Time*0.79)*0.48+Sin(Time*0.34)*0.12)*345;
  CarX := RoadCenter(0.92)+RoadShift;
  PlayerDrawn := False;
  for Column := 0 to High(RivalDepth) do
  begin
    Segment := -1;
    Depth := 2;
    for I := 0 to High(RivalDepth) do
      if not RivalDrawn[I] and (RivalDepth[I]<Depth) then
      begin
        Depth := RivalDepth[I];
        Segment := I;
      end;
    RivalDrawn[Segment] := True;
    if (Depth>=0.92) and not PlayerDrawn then
    begin
      RaceCar(Canvas,CarX,492,1.03,$66D5C7,$365879);
      PlayerDrawn := True;
    end;
    if (Depth<0.04) or (Depth>=1.18) then Continue;
    Lane := -0.69+(Segment mod 3)*0.66+0.10*Sin(Time*0.92+Segment);
    Scale := Depth*0.81;
    RaceCar(Canvas,RoadCenter(Depth)+Lane*(14+Depth*403),251+279*Sqr(Depth),Scale,
      RivalColors[Segment],$473A61);
  end;
  if not PlayerDrawn then RaceCar(Canvas,CarX,492,1.03,$66D5C7,$365879);
  Canvas.Fill(0,0,960,59,$181C36,0.92);
  Canvas.LabelText('MESA SPRINT',25,12,265,24,$FFE7BF,True);
  Canvas.LabelText(Format('LAP %d / 3',[Race.Index mod 3+1]),354,13,252,23,$FFE7BF,True,2);
  Canvas.LabelText(Format('POS %d / 5',[Rank]),685,12,251,24,$94F4D7,True,1);
  Canvas.RoundRect(720,428,213,88,13,$171C36,0.89);
  Canvas.LabelText(Format('%d',[Round(Speed)]),734,434,103,43,$F4F4E7,True,1);
  Canvas.LabelText('km/h',848,453,70,22,$F2B69C,True);
  GameMeter(Canvas,739,489,175,14,Speed/230,$7FDACF);
end;

end.
