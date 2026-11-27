unit TV_GameWorld;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 地形の斜投影、追従カメラ、アイテムとミニマップでフィールド探索を描く。

interface

uses TV_Canvas;

// 提供された960×540の番組面に時刻 Time（秒）の探索映像を描く。
procedure DrawWorldGame(Canvas: TTVCanvas; Time: Double);

implementation

uses System.Math, System.SysUtils, TV_Timeline, TV_GameArt;

const
  TileW = 55;
  TileH = 25;
  CenterX = 455;
  CenterY = 304;
  MapRadius = 71;

function TravelPath(X: Double): Double;
begin
  Result := 1.9*Sin(X*0.37)+1.06*Sin(X*0.177+0.7);
end;

procedure WorldTree(Canvas: TTVCanvas; X, Y, S: Single; Crown: TTVColor);
begin
  Canvas.Ellipse(X+13*S,Y,30*S,11*S,$263C47,0.36);
  Canvas.Line(X,Y,X-2*S,Y-56*S,11*S,$584657);
  Canvas.Transform(X,Y,S);
  try
    Canvas.Path([M,-35,-47,L,-17,-66,L,-26,-65,L,-4,-101,L,21,-72,L,12,-71,
      L,41,-49,L,24,-49,L,40,-36,L,-12,-27,Z],Crown,'game.world.pine');
    Canvas.Path([M,-4,-101,L,21,-72,L,12,-71,L,41,-49,L,24,-49,L,40,-36,
      L,5,-30,L,14,-47,L,3,-51,Z],$234956,'game.world.pine.shade',0.63);
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure WorldHouse(Canvas: TTVCanvas; X, Y: Single; Roof, Walls: TTVColor);
begin
  Canvas.Transform(X,Y);
  try
    Canvas.Ellipse(7,-5,70,25,$253E45,0.38);
    Canvas.Path([M,-52,-27,L,2,-3,L,2,-61,L,-52,-84,Z],Walls,'game.world.house.front');
    Canvas.Path([M,2,-3,L,54,-28,L,54,-84,L,2,-61,Z],$76647D,'game.world.house.side');
    Canvas.Path([M,-64,-82,L,-38,-119,L,19,-94,L,2,-50,Z],Roof,'game.world.roof');
    Canvas.Path([M,-38,-119,L,16,-144,L,72,-83,L,2,-50,L,19,-94,Z],$6D526E,
      'game.world.roof.shade');
    Canvas.Line(-38,-119,19,-94,5,$EAAD91);
    Canvas.Path([M,-30,-17,L,-12,-9,L,-12,-42,L,-30,-50,Z],$54475E,'game.world.door');
    Canvas.Path([M,20,-38,L,37,-47,L,37,-61,L,20,-53,Z],$FFE4A1,'game.world.window');
    Canvas.Line(44,-104,44,-134,13,$6B5570);
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure WorldPlayer(Canvas: TTVCanvas; Time: Double);
var
  Stride, Bob: Single;
begin
  Stride := Sin(Time*14);
  Bob := 3*Abs(Stride);
  Canvas.Ellipse(CenterX,CenterY+4,32,11,$1A3944,0.62);
  Canvas.Transform(CenterX,CenterY-Bob);
  try
    Canvas.Line(-11,-29,-12-13*Stride,-1,12,$272846);
    Canvas.Line(12,-28,15+13*Stride,-1,12,$3B5273);
    Canvas.Path([M,-18,-62,L,-35,-50,L,-30,-9,L,-7,-22,L,3,-53,Z],
      $C17773,'game.world.cape');
    Canvas.Path([M,-21,-61,L,15,-65,L,24,-30,L,-19,-20,Z],$4D84A1,'game.world.coat');
    Canvas.RoundRect(-19,-56,24,24,6,$AC735E);
    Canvas.Line(-14,-50,-2,-48,4,$E1AB87);
    Canvas.Line(12,-53,24+8*Stride,-34,11,$EAC198);
    Canvas.RoundRect(-17,-84,39,31,12,$F5CF9A);
    Canvas.Path([M,-23,-73,L,-20,-83,L,2,-94,L,26,-83,L,22,-72,L,-4,-77,Z],
      $5E3D54,'game.world.hair');
    Canvas.Line(22,-79,35,-69,4,$F3C482);
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure DrawWorldGame(Canvas: TTVCanvas; Time: Double);
const
  Grasses: array[0..3] of TTVColor = ($588D7E,$639686,$689B89,$5B917F);
var
  Region: TTVScene;
  CamX, CamZ, ItemIndex: Double;
  AnchorX, AnchorZ, Back, Across, WX, WZ, Index, RegionStyle: Integer;
  X, Y, P, PathZ, Collect, MX, MY, PriorX, PriorY: Single;
  Detail: Cardinal;
  Color, Trail, Crown, Roof: TTVColor;
  DrawnPlayer: Boolean;

  procedure Project(WorldX, WorldZ: Double; out ScreenX, ScreenY: Single);
  begin
    ScreenX := CenterX+TileW*((WorldX-CamX)-(WorldZ-CamZ));
    ScreenY := CenterY+TileH*((WorldX-CamX)+(WorldZ-CamZ));
  end;

  function TileDetail(WorldX, WorldZ: Integer): Cardinal;
  begin
    Result := TVHash(TVHash(Cardinal(WorldX mod 4096+4096)) xor
      Cardinal(WorldZ mod 4096+4096));
  end;

begin
  Region := TVSceneAt(Time,42);
  RegionStyle := Region.Choice(61,3);
  CamX := Time*1.65;
  CamZ := TravelPath(CamX);
  AnchorX := Floor(CamX);
  AnchorZ := Floor(CamZ);
  Trail := TVColorMix($CDA77E,$E1BD8F,RegionStyle/2);
  Crown := TVColorMix($3C766C,$477C87,RegionStyle/2);
  Roof := TVColorMix($C87A72,$B98AA6,RegionStyle/2);
  Canvas.Clear($659584);
  for Back := -14 to 12 do
    for Across := -14 to 13 do
    begin
      WX := AnchorX+Across;
      WZ := AnchorZ+Back-Across;
      Project(WX,WZ,X,Y);
      if (X<-TileW-2) or (X>960+TileW+2) or (Y<-TileH-2) or (Y>540+TileH+2) then Continue;
      Detail := TileDetail(WX,WZ);
      PathZ := TravelPath(WX);
      Color := Grasses[Detail and 3];
      if Abs(WZ-PathZ)>4.5 then Color := TVColorMix(Color,$466E77,0.45);
      Canvas.Path([M,X-TileW-0.5,Y,L,X,Y-TileH-0.5,L,X+TileW+0.5,Y,
        L,X,Y+TileH+0.5,Z],Color);
      if (Detail shr 5) and 3=0 then
      begin
        Canvas.Line(X-14,Y+5,X-20,Y-4,2,$C8BD88,0.62);
        Canvas.Line(X-14,Y+5,X-9,Y-7,2,$C8BD88,0.62);
        Canvas.Fill(X+21,Y-4,5,3,$D5B992,0.61);
      end;
    end;
  // 道を地形の上につなげ、その後に奥から手前へ物体を重ねる。
  WX := AnchorX-18;
  Project(WX,TravelPath(WX),PriorX,PriorY);
  for Across := -17 to 18 do
  begin
    WX := AnchorX+Across;
    Project(WX,TravelPath(WX),X,Y);
    Canvas.Line(PriorX,PriorY,X,Y,32,$496E65,0.37);
    Canvas.Line(PriorX,PriorY,X,Y,25,Trail);
    Canvas.Line(PriorX,PriorY,X,Y,3,$F7D8A0,0.34);
    PriorX := X;
    PriorY := Y;
  end;
  ItemIndex := Floor((CamX+2)/6)*6+2;
  if ItemIndex<CamX-0.74 then ItemIndex := ItemIndex+6;
  Collect := (CamX-ItemIndex)/0.74;
  DrawnPlayer := False;
  for Back := -12 to 13 do
    for Across := -13 to 13 do
    begin
      WX := AnchorX+Across;
      WZ := AnchorZ+Back-Across;
      Project(WX,WZ,X,Y);
      if (X<-80) or (X>1040) or (Y<-30) or (Y>690) then Continue;
      if (not DrawnPlayer) and (Y>CenterY) then
      begin
        WorldPlayer(Canvas,Time);
        DrawnPlayer := True;
      end;
      PathZ := TravelPath(WX);
      if Abs(WZ-PathZ)<1.5 then
      begin
        if (WX=Trunc(ItemIndex)) and (WZ=Round(PathZ)) then
        begin
          Project(WX,PathZ,X,Y);
          if Collect<0 then
          begin
            P := 6*Sin(Time*6);
            Canvas.Ellipse(X,Y,22,9,$384849,0.48);
            GameDiamond(Canvas,X,Y-37+P,16,23,$FFE797);
          end
          else
            GameBurst(Canvas,X,Y-35,39,Collect,$FFE797);
        end;
        Continue;
      end;
      if (WX mod 7=4) and (WZ=Round(PathZ)+3) then
      begin
        WorldHouse(Canvas,X,Y,Roof,$DCA88E);
        Continue;
      end;
      Detail := TileDetail(WX,WZ);
      if Detail mod 6=0 then
        WorldTree(Canvas,X,Y,0.80+0.08*((Detail shr 4) and 7),Crown)
      else if Detail mod 13=0 then
      begin
        Canvas.Ellipse(X,Y,25,8,$374F59,0.56);
        Canvas.Path([M,X-24,Y-4,L,X-12,Y-22,L,X+14,Y-25,L,X+25,Y-9,L,X+13,Y+1,Z],
          $798998);
        Canvas.Line(X-12,Y-21,X+13,Y-24,4,$B4AEAA,0.68);
      end;
    end;
  Canvas.Fill(0,0,960,58,$1A3447,0.9);
  Canvas.LabelText('WINDWARD TRAIL',25,10,328,26,$F2ECCD,True);
  GameMeter(Canvas,714,15,218,25,0.82+0.10*Sin(Time*0.12),$A5D1A0);
  MX := 839;
  MY := 151;
  Canvas.Ellipse(MX,MY,MapRadius+5,MapRadius+5,$132A3D,0.9);
  Canvas.Ellipse(MX,MY,MapRadius,MapRadius,$47686B);
  Canvas.Line(MX-69,MY,MX+69,MY,1,$AFD0C7,0.46);
  Canvas.Line(MX,MY-69,MX,MY+69,1,$AFD0C7,0.46);
  PriorX := MX-59;
  PriorY := MY+(TravelPath(CamX-59/9)-CamZ)*9;
  for Index := -5 to 6 do
  begin
    X := MX+Index*9;
    Y := MY+(TravelPath(CamX+Index)-CamZ)*9;
    Canvas.Line(PriorX,PriorY,X,Y,3,$DFBF92);
    PriorX := X;
    PriorY := Y;
  end;
  Canvas.Path([M,MX+9,MY,L,MX-7,MY-7,L,MX-4,MY,L,MX-7,MY+7,Z],$F6F8CB);
  Canvas.LabelText('N',MX-15,MY-68,30,15,$E6E7D2,True,2);
  Canvas.RoundRect(26,465,175,49,9,$19384A,0.88);
  GameDiamond(Canvas,51,488,9,14,$FFE797);
  Canvas.LabelText(Format('%3.3d',[(Floor((CamX+4)/6) mod 1000)]),75,470,104,25,$FFF4D3,True,1);
end;

end.
