unit TV_GameDungeon;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 迷路の一人称視点を壁レイと奥行き判定付きの敵・宝箱で描画する。

interface

uses TV_Canvas;

// 提供された960×540の番組面に時刻 Time（秒）の探索映像を描く。
procedure DrawDungeonGame(Canvas: TTVCanvas; Time: Double);

implementation

uses System.Math, System.SysUtils, TV_Timeline, TV_GameArt;

const
  MapW = 13;
  MapH = 11;
  DungeonMap: array[0..MapH-1] of string = (
    '#############',
    '##...#..#...#',
    '#...........#',
    '#..##..##.###',
    '##.#..#.....#',
    '#..##.#.#.#.#',
    '#..#....#...#',
    '#..........##',
    '#..#.#...#..#',
    '##...##.....#',
    '#############');
  RouteX: array[0..3] of Double = (2.5,9.5,9.5,2.5);
  RouteY: array[0..3] of Double = (2.5,2.5,7.5,7.5);
  ColumnWidth = 6;
  RayCount = TV_PROGRAM_WIDTH div ColumnWidth;
  Projection = 590;
  Horizon = 252;

type
  TWallDepth = array[0..RayCount-1] of Single;

function DungeonWall(X,Y: Integer): Boolean;
begin
  if (X<0) or (X>=MapW) or (Y<0) or (Y>=MapH) then Exit(True);
  Result := DungeonMap[Y][X+1]='#';
end;

procedure CastDungeonRay(CamX, CamY, DX, DY: Double; out Depth, Stripe: Double;
  out Side: Boolean);
var
  TileX, TileY, StepX, StepY, Count: Integer;
  DeltaX, DeltaY, EdgeX, EdgeY: Double;
begin
  TileX := Floor(CamX);
  TileY := Floor(CamY);
  StepX := 1-2*Ord(DX<0);
  StepY := 1-2*Ord(DY<0);
  DeltaX := 1/Max(1E-9,Abs(DX));
  DeltaY := 1/Max(1E-9,Abs(DY));
  EdgeX := Abs(TileX+Ord(StepX>0)-CamX)*DeltaX;
  EdgeY := Abs(TileY+Ord(StepY>0)-CamY)*DeltaY;
  Depth := 20;
  Side := False;
  for Count := 1 to MapW+MapH do
  begin
    Side := EdgeY<EdgeX;
    if Side then
    begin
      Inc(TileY,StepY);
      Depth := EdgeY;
      EdgeY := EdgeY+DeltaY;
    end
    else
    begin
      Inc(TileX,StepX);
      Depth := EdgeX;
      EdgeX := EdgeX+DeltaX;
    end;
    if DungeonWall(TileX,TileY) then Break;
  end;
  Stripe := TVCycle(TVLerp(CamY+Depth*DY,CamX+Depth*DX,Ord(Side)),1);
end;

procedure DungeonActor(Canvas: TTVCanvas; X, Y, Size, Age: Single; IsChest: Boolean;
  Color: TTVColor);
begin
  Canvas.Transform(X,Y,Size);
  try
    Canvas.Ellipse(0,0,32,8,$110F22,0.72);
    if IsChest then
    begin
      Canvas.RoundRect(-36,-45,72,42,8,$542D35);
      Canvas.RoundRect(-36,-54,72,25,8,$A96947);
      Canvas.Fill(-30,-51,8,44,$E8B76A);
      Canvas.Fill(22,-51,8,44,$E8B76A);
      GameDiamond(Canvas,0,-31,8,11,$FCEA9E);
    end
    else
    begin
      Canvas.Path([M,-42,-10,L,-32,-49,L,-34,-78,L,-12,-67,L,15,-66,L,36,-81,
        L,33,-48,L,43,-10,L,23,-20,L,1,-8,L,-21,-20,Z],Color,'game.dungeon.wisp');
      Canvas.Ellipse(0,-43,23,16,$282447);
      Canvas.Ellipse(-11,-44,6,4+1.4*Sin(Age*7),$FCDA8F);
      Canvas.Ellipse(11,-44,6,4+1.4*Sin(Age*7),$FCDA8F);
    end;
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure DrawDungeonGame(Canvas: TTVCanvas; Time: Double);
var
  Tour, Leg: TTVScene;
  Distances: TWallDepth;
  LegIndex, Next, Column, Row, X, Y: Integer;
  CamX, CamY, Heading, DX, DY, Ray, Depth, Stripe, Travel, Turn, WalkTime: Double;
  Shift, Top, Bottom, Height, Light, MapX, MapY: Single;
  Side: Boolean;
  Base, Shadow, Torch, Brick: TTVColor;

  procedure PlaceActor(WorldX, WorldY: Double; IsChest: Boolean);
  var
    ActorDepth, Across: Double;
    ScreenX, ScreenY, Scale: Single;
    First, Last, RayIndex, RunStart: Integer;
    Visible: Boolean;
  begin
    ActorDepth := (WorldX-CamX)*DX+(WorldY-CamY)*DY;
    if ActorDepth<0.83 then Exit;
    Across := (WorldY-CamY)*DX-(WorldX-CamX)*DY;
    ScreenX := 480+Projection*Across/ActorDepth;
    Scale := 2.54/ActorDepth;
    ScreenY := Horizon+Shift+Projection*0.54/ActorDepth;
    First := Max(0,Floor((ScreenX-45*Scale)/ColumnWidth));
    Last := Min(RayCount-1,Floor((ScreenX+45*Scale)/ColumnWidth));
    RunStart := -1;
    for RayIndex := First to Last+1 do
    begin
      Visible := False;
      if RayIndex<=Last then Visible := ActorDepth<Distances[RayIndex];
      if Visible and (RunStart<0) then RunStart := RayIndex;
      if not Visible and (RunStart>=0) then
      begin
        Canvas.Clip(RunStart*ColumnWidth,0,(RayIndex-RunStart)*ColumnWidth,540);
        try
          DungeonActor(Canvas,ScreenX,ScreenY,Scale,TVCycle(Time,4),IsChest,Torch);
        finally
          Canvas.Unclip;
        end;
        RunStart := -1;
      end;
    end;
  end;

begin
  Tour := TVSceneAt(Time,32);
  Leg := TVSceneAt(Tour.Age,8);
  LegIndex := Min(3,Integer(Leg.Index));
  Next := (LegIndex+1) mod 4;
  WalkTime := 6.30+0.55*Tour.Variation(Cardinal(21+LegIndex));
  Travel := TVSmooth(Leg.Age/WalkTime);
  Turn := TVSmooth((Leg.Age-WalkTime)/(8-WalkTime));
  CamX := TVLerp(RouteX[LegIndex],RouteX[Next],Travel);
  CamY := TVLerp(RouteY[LegIndex],RouteY[Next],Travel);
  Heading := (LegIndex+Turn)*Pi/2;
  DX := Cos(Heading);
  DY := Sin(Heading);
  Shift := 5*Sin(Leg.Age*13)*Sin(Pi*Travel);
  Torch := TVColorMix($BB7FAA,$78BBAC,Tour.Variation(42));
  Base := TVColorMix($664961,$41616B,Tour.Variation(19));
  Shadow := $1F2038;
  Canvas.Shade(0,0,960,Horizon+Shift,$13172D,$41344C);
  Canvas.Shade(0,Horizon+Shift,960,540-Horizon-Shift,$242338,$594054);
  for Column := 0 to RayCount-1 do
  begin
    Ray := ((Column+0.5)*ColumnWidth-480)/Projection;
    CastDungeonRay(CamX,CamY,DX-DY*Ray,DY+DX*Ray,Depth,Stripe,Side);
    Distances[Column] := Depth;
    Depth := Max(0.14,Depth);
    Height := Projection*1.01/Depth;
    Top := Horizon+Shift-Height*0.47;
    Bottom := Top+Height;
    Light := TVClamp(1.26-Depth*0.11-0.15*Ord(Side));
    if (Stripe<0.036) or (Stripe>0.97) then Light := Light*0.58;
    Brick := TVColorMix(Shadow,Base,Light);
    Canvas.Fill(Column*ColumnWidth,Top,ColumnWidth,Height,Brick);
    for Row := 1 to 3 do
    begin
      Canvas.Fill(Column*ColumnWidth,Top+Row*Height/4,ColumnWidth,1+Light*2,Shadow,0.57);
      if (Abs(Stripe-0.5+0.08*(Row mod 2))<0.04) then
        Canvas.Fill(Column*ColumnWidth,Top+(Row-1)*Height/4,ColumnWidth,Height/4,Shadow,0.46);
    end;
    Canvas.Fill(Column*ColumnWidth,Bottom-3,ColumnWidth,3,Shadow,0.7);
  end;
  PlaceActor(6.7+Tour.Variation(14),2.5,False);
  PlaceActor(9.5,5.6+Tour.Variation(20),True);
  PlaceActor(5.5+Tour.Variation(31),7.5,False);
  PlaceActor(2.5,4.2+Tour.Variation(37),True);
  Canvas.Fill(0,0,960,56,$111426,0.91);
  Canvas.LabelText('HOLLOW KEEP',25,11,267,25,$E1C1D7,True);
  Canvas.LabelText(Format('DEPTH %2.2d',[Tour.Index mod 99+1]),373,13,215,22,$E8D2D6,True,2);
  Canvas.LabelText('HP',25,489,48,23,$FFE2DE,True);
  GameMeter(Canvas,66,489,211,26,0.9-0.07*LegIndex,$E68D97);
  MapX := 796;
  MapY := 76;
  Canvas.RoundRect(MapX-9,MapY-9,149,129,9,$181B31,0.94);
  for Y := 0 to MapH-1 do
    for X := 0 to MapW-1 do
      if DungeonWall(X,Y) then Canvas.Fill(MapX+X*10,MapY+Y*10,9,9,$A282A4,0.58);
  Canvas.Ellipse(MapX+CamX*10,MapY+CamY*10,4,4,$F9DB9C);
  Canvas.Line(MapX+CamX*10,MapY+CamY*10,MapX+(CamX+DX)*10,MapY+(CamY+DY)*10,3,$F9DB9C);
end;

end.
