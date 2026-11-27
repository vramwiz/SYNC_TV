unit TV_GamePuzzle;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 落ち物パズルの連鎖とリズムゲームのノーツ・判定を番組時刻から描く。

interface

uses TV_Canvas;

// 提供された960×540の番組面に時刻 Time（秒）のゲーム映像を描く。
procedure DrawFallingGame(Canvas: TTVCanvas; Time: Double);
procedure DrawRhythmGame(Canvas: TTVCanvas; Time: Double);

implementation

uses System.Math, System.SysUtils, TV_Timeline, TV_GameArt;

const
  WellX = 326;
  WellY = 76;
  Cell = 33;
  Columns = 10;
  Rows = 13;
  BlockColors: array[0..4] of TTVColor = ($60ABF0,$F5AC5F,$9A81E0,$63CBA0,$F17591);

procedure PuzzleBlock(Canvas: TTVCanvas; X, Y: Single; Color: TTVColor; Opacity: Single = 1);
begin
  Canvas.RoundRect(X+1,Y+1,Cell-2,Cell-2,5,Color,Opacity);
  Canvas.Line(X+6,Y+7,X+Cell-7,Y+7,3,$FFFFFF,Opacity*0.53);
  Canvas.Line(X+7,Y+Cell-6,X+Cell-6,Y+Cell-6,3,$272344,Opacity*0.36);
  Canvas.Fill(X+13,Y+13,7,7,$FFFFFF,Opacity*0.43);
end;

procedure DrawFallingGame(Canvas: TTVCanvas; Time: Double);
var
  Sequence: TTVScene;
  Column, Row, Blue, Amber, Height, Score, Chain, Sign: Integer;
  P, FallingX, FallingY, Rotation, X, Y, Drop, Flash: Single;
  Base: TTVColor;

  function BlockX(Index: Single): Single;
  begin
    if Sign<0 then Index := Columns-1-Index;
    Result := WellX+Cell*Index;
  end;

begin
  Sequence := TVSceneAt(Time,6.5);
  P := Sequence.Age;
  Blue := Sequence.Choice(24,5);
  Amber := (Blue+1+Sequence.Choice(52,4)) mod 5;
  Sign := 1-2*Sequence.Choice(13,2);
  Canvas.Shade(0,0,960,540,$342956,$1B203E);
  for Row := 0 to 11 do
    for Column := 0 to 23 do
      if (Column+Row) mod 2=0 then Canvas.Fill(40*Column,65+40*Row,40,40,$786AB3,0.10);
  Canvas.RoundRect(WellX-10,WellY-10,Columns*Cell+20,Rows*Cell+20,10,$786CB0);
  Canvas.Fill(WellX,WellY,Columns*Cell,Rows*Cell,$12182C);
  for Column := 1 to Columns-1 do
    Canvas.Line(WellX+Column*Cell,WellY,WellX+Column*Cell,WellY+Rows*Cell,1,$546083,0.42);
  for Row := 1 to Rows-1 do
    Canvas.Line(WellX,WellY+Row*Cell,WellX+Columns*Cell,WellY+Row*Cell,1,$546083,0.42);
  Canvas.Clip(WellX,WellY,Columns*Cell,Rows*Cell);
  try
    for Column := 6 to Columns-1 do
    begin
      Height := 1+Sequence.Choice(Cardinal(100+Column),4);
      for Row := 1 to Height do
        PuzzleBlock(Canvas,BlockX(Column),WellY+(Rows-Row)*Cell,
          BlockColors[(Column+2*Row+Blue) mod 5]);
    end;
    Y := WellY+(Rows-1)*Cell;
    if P<3.35 then
    begin
      Flash := 1-0.72*TVClamp((P-3)*3)*(0.6+0.4*Sin(P*96));
      PuzzleBlock(Canvas,BlockX(2),Y,BlockColors[Blue],Flash);
      PuzzleBlock(Canvas,BlockX(3),Y,BlockColors[Blue],Flash);
    end;
    if P<4.55 then
    begin
      Flash := 1-0.73*TVClamp((P-4.17)*3)*(0.6+0.4*Sin(P*96));
      PuzzleBlock(Canvas,BlockX(4),Y,BlockColors[Amber],Flash);
      PuzzleBlock(Canvas,BlockX(5),Y,BlockColors[Amber],Flash);
      Drop := TVSmooth((P-3.35)/0.58);
      PuzzleBlock(Canvas,BlockX(2),Y-Cell*(1-Drop),BlockColors[Amber],Flash);
      PuzzleBlock(Canvas,BlockX(3),Y-Cell*(1-Drop),BlockColors[Amber],Flash);
    end;
    if P<3.35 then
    begin
      FallingX := 4-TVSmooth((P-0.52)/0.44)*2-TVSmooth((P-1.44)/0.44)*2;
      FallingY := TVLerp(WellY-Cell,Y,TVClamp(P/2.97));
      Rotation := Pi/2*TVSmooth((P-1.21)/0.30);
      Flash := 1-0.72*TVClamp((P-3)*3)*(0.6+0.4*Sin(P*96));
      PuzzleBlock(Canvas,BlockX(FallingX),FallingY,BlockColors[Blue],Flash);
      PuzzleBlock(Canvas,BlockX(FallingX+Sin(Rotation)),FallingY-Cell*Cos(Rotation),
        BlockColors[Blue],Flash);
    end;
    GameBurst(Canvas,BlockX(1.5)+Cell/2,Y+Cell/2,105,(P-3.25)/0.53,BlockColors[Blue]);
    GameBurst(Canvas,BlockX(3.5)+Cell/2,Y+Cell/2,108,(P-4.45)/0.66,BlockColors[Amber]);
  finally
    Canvas.Unclip;
  end;
  Canvas.LabelText('CHROMA DROP',25,12,319,28,$F4D4FF,True);
  Canvas.RoundRect(37,114,251,141,14,$201D39);
  Canvas.LabelText('SCORE',59,131,211,22,$CBB7E8,True);
  Score := Integer(Sequence.Index mod 1000)*360+120*Ord(P>=3.35)+240*Ord(P>=4.55);
  Canvas.LabelText(Format('%6.6d',[Score]),59,164,213,37,$F5F4FF,True);
  Canvas.LabelText(Format('STAGE %2.2d',[Sequence.Index mod 99+1]),59,216,213,20,$BFA9DA);
  Canvas.RoundRect(699,114,224,167,14,$201D39);
  Canvas.LabelText('NEXT',720,132,184,22,$CBB7E8,True);
  Base := BlockColors[(Amber+2) mod 5];
  PuzzleBlock(Canvas,783,177,Base);
  PuzzleBlock(Canvas,783,210,BlockColors[(Blue+3) mod 5]);
  Chain := Ord(P>=3.35)+Ord(P>=4.55);
  if Chain>0 then
  begin
    X := 699;
    Canvas.LabelText(Format('%dx CHAIN',[Chain]),X,315,224,33,$FFDA9F,True,2);
  end;
end;

const
  LaneCount = 5;
  LaneColors: array[0..LaneCount-1] of TTVColor = ($6AF9EB,$68B5FF,$B593FA,$F885CB,$FBC475);
  BeatTime = 0.35;

function BeatLane(Beat: Int64): Integer;
begin
  Result := (TVHash(Cardinal(Max(0,Beat div 4)+53)) mod LaneCount+
    (Beat and 3)*2+LaneCount) mod LaneCount;
end;

function LaneX(Index: Integer): Single;
begin
  Result := 174+Index*103;
end;

procedure DrawRhythmGame(Canvas: TTVCanvas; Time: Double);
const
  HitY = 435;
var
  Music: TTVScene;
  Beat: Int64;
  I, Lane, Offset: Integer;
  Age, Travel: Double;
  X, Y, Glow, P: Single;
  Color: TTVColor;
  Judgment: string;
begin
  Beat := Floor(Time/BeatTime);
  Age := Time-Beat*BeatTime;
  Music := TVSceneAt(Time,16);
  Glow := 1-TVSmooth(Age/BeatTime);
  Canvas.Shade(0,0,960,540,$151F35,$321D47);
  Canvas.Path([M,0,456,L,117,330,L,117,431,L,0,532,Z],$624080);
  Canvas.Path([M,960,142,L,700,364,L,700,404,L,960,238,Z],$624080);
  for I := 0 to 8 do
  begin
    P := TVCycle(Time*2+I/9,1);
    Canvas.Line(0,93+I*47,104+41*P,59+I*47,4,$68D8F1,0.2+0.25*Glow);
    Canvas.Line(718,117+I*45,960,96+I*45,4,$E485D4,0.18+0.33*Glow);
  end;
  for Lane := 0 to LaneCount-1 do
  begin
    X := LaneX(Lane);
    Color := LaneColors[Lane];
    Canvas.Fill(X,69,98,401,$0B1428,0.88);
    Canvas.Line(X+1,69,X+1,473,2,Color,0.36);
    Canvas.RoundRect(X+7,HitY-15,84,39,7,Color,0.26);
    Canvas.Line(X+8,HitY+15,X+90,HitY+15,4,Color,0.85);
    if Lane=BeatLane(Beat) then
    begin
      Canvas.RoundRect(X+4,HitY-20,90,48,9,Color,0.58*Glow);
      Canvas.Ellipse(X+49,HitY,32+35*Age,15+20*Age,Color,0.55*Glow);
    end;
  end;
  Canvas.Clip(LaneX(0),69,LaneCount*103,400);
  try
    for Offset := 1 to 7 do
    begin
      Travel := Offset*BeatTime-Age;
      Y := HitY-Travel*(225+Music.Choice(55,3)*18);
      Lane := BeatLane(Beat+Offset);
      X := LaneX(Lane);
      Color := LaneColors[Lane];
      if (Beat+Offset) mod 7=4 then
        Canvas.Shade(X+36,Y-95,26,95,$222A4E,Color,0.73);
      Canvas.RoundRect(X+8,Y-11,82,22,6,Color);
      Canvas.Fill(X+16,Y-6,66,4,$FFFFFF,0.73);
    end;
  finally
    Canvas.Unclip;
  end;
  Canvas.Fill(0,0,960,58,$10182D,0.96);
  Canvas.LabelText('BEAT CIRCUIT',25,10,299,26,$AFEFFB,True);
  Canvas.LabelText(Format('%6.6d  PTS',[(Beat mod 9000)*110]),691,11,244,25,$FFF0D2,True,1);
  Canvas.LabelText(Format('%d',[Beat mod 32+1]),721,325,213,52,$FFF0FD,True,2);
  Canvas.LabelText('COMBO',721,387,213,22,$E6B6E3,True,2);
  if Age<0.28 then
  begin
    Judgment := 'PERFECT';
    if Beat mod 11=8 then Judgment := 'GREAT';
    Canvas.LabelText(Judgment,305,475,350,32,$C7FBEF,True,2);
  end;
end;

end.
