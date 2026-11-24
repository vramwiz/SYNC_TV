unit TV_Artwork;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 架空の人物、風景、小道具と番組テロップの共通描画。

interface

uses
  TV_Canvas;

procedure DrawPresenter(Canvas: TTVCanvas; X, Y, Scale: Single; Style: Integer;
  Time: Double; Speech, Gesture: Single; FacingLeft: Boolean = False);
procedure DrawWeatherPresenter(Canvas: TTVCanvas; X,Y,Scale: Single; Time: Double;
  TargetX,TargetY: Single);
procedure DrawSkyline(Canvas: TTVCanvas; Variant: Integer; Time: Double);
procedure DrawCloud(Canvas: TTVCanvas; X, Y, Scale: Single; Color: TTVColor);
procedure DrawWeatherIcon(Canvas: TTVCanvas; X, Y, Scale: Single; Weather: Integer);
procedure DrawProduct(Canvas: TTVCanvas; X, Y, Scale: Single; Product: Integer; Time: Double);
procedure DrawLive(Canvas: TTVCanvas; const Caption: string; Brand: TTVColor);
procedure DrawLowerThird(Canvas: TTVCanvas; const Category, Headline: string;
  Accent, Background: TTVColor);
procedure DrawCrawl(Canvas: TTVCanvas; const Copy: string; Time: Double; Accent: TTVColor);

implementation

uses
  System.Math, System.SysUtils, System.Types, TV_Timeline;

const
  Jackets: array[0..7] of TTVColor = ($315576,$A26372,$427D79,$B8594A,
    $B0803A,$503B73,$54875A,$4A658E);
  SkinTones: array[0..7] of TTVColor = ($E5A47F,$F4B39A,$EAC097,$BF815E,
    $DB9D74,$B67958,$EAB187,$C98A6C);
  HairTones: array[0..7] of TTVColor = ($232531,$412B33,$30353D,$2D2226,
    $5A372F,$222A36,$323327,$35262A);

procedure DrawPresenterEye(Canvas: TTVCanvas; X,Y,Opening,Look: Single);
var
  Top, Bottom: Single;
begin
  if Opening < 0.24 then
  begin
    Canvas.Stroke([M,X-9,Y,L,X-4,Y+1.2,C,X,Y+2.5,X+5,Y+2.5,X+9,Y-0.8],
      $423039,1.8);
    Exit;
  end;
  Top := 7.2*Opening;
  Bottom := 6.4*Opening;
  Canvas.Path([M,X-10,Y,C,X-6,Y-Top*1.18,X+5,Y-Top*1.29,X+10,Y-1,
    C,X+7,Y+Bottom*1.3,X-5,Y+Bottom*1.25,X-10,Y,Z],$FFF5EB);
  Canvas.Ellipse(X+Look,Y-0.25,5.7,6.2*Opening,$59434A);
  Canvas.Ellipse(X+Look,Y-0.85,4.1,5.1*Opening,$28222F);
  if Opening > 0.55 then
  begin
    Canvas.Ellipse(X+Look-1.65,Y-2.4*Opening,1.5,1.65*Opening,$FFF9F1);
    Canvas.Ellipse(X+Look+2.45,Y+2.35*Opening,0.86,0.92*Opening,$D6AC97);
  end;
  Canvas.Stroke([M,X-10.4,Y+0.15,C,X-6,Y-Top*1.21,X+5,Y-Top*1.3,X+10.5,Y-1.1],
    $402D39,1.65);
end;

procedure DrawPresenterHead(Canvas: TTVCanvas; X,Y,Scale: Single; Style: Integer;
  Time: Double; Speech: Single; FacingLeft: Boolean);
var
  Skin, Hair, SkinLight, SkinShade: TTVColor;
  Nod, MouthOpen, Blink, Look: Single;
begin
  Skin := SkinTones[Style];
  Hair := HairTones[Style];
  SkinLight := TVColorMix(Skin,$FFF5D0,0.25);
  SkinShade := TVColorMix(Skin,$AD654A,0.36);
  Nod := 2.5*Sin(Time*1.7+Style)+1.4*Sin(Time*3.1);

  Canvas.Transform(X, Y + Scale * Nod, Scale, FacingLeft);
  Canvas.Ellipse(-43,-74,10,16,TVColorMix(Skin,$9A514B,0.20));
  Canvas.Ellipse(43,-72,9,14,Skin);
  case Style of
    3:
      begin
        Canvas.ShadePath([M,-45,-106,C,-35,-138,37,-139,48,-102,
          L,48,-55,C,48,-40,44,-26,30,-18,L,13,-8,C,3,-2,-10,-4,-20,-9,
          L,-35,-19,C,-49,-28,-51,-50,-48,-72,Z],SkinLight,SkinShade,-123,-9,'square face');
        Canvas.Path([M,-47,-69,L,-49,-99,C,-60,-127,-38,-142,-25,-139,
          L,-19,-152,L,-4,-144,L,6,-151,L,17,-141,C,43,-144,55,-123,48,-88,
          L,42,-103,L,40,-117,C,10,-116,-17,-124,-41,-110,Z],Hair,'cropped hair');
        Canvas.Stroke([M,-30,-84,L,-12,-85,M,12,-85,L,31,-82],
          TVColorMix(Hair,Skin,0.15),3.4,'straight eyebrows');
      end;
    4:
      begin
        Canvas.ShadePath([M,-43,-104,C,-33,-132,32,-135,45,-102,
          C,58,-87,53,-40,43,-24,C,30,-3,12,2,-6,1,C,-29,0,-47,-16,-53,-35,
          C,-58,-54,-53,-87,-43,-104,Z],SkinLight,SkinShade,-123,-9,'round face');
        Canvas.Path([M,-48,-60,C,-60,-78,-60,-111,-44,-132,
          C,-23,-150,25,-146,46,-126,C,60,-111,55,-90,49,-80,
          L,44,-94,C,21,-97,4,-100,-10,-118,C,-21,-103,-41,-97,-46,-81,Z],
          Hair,'swept hair');
        Canvas.Stroke([M,-17,-125,C,0,-114,23,-108,43,-102],
          TVColorMix(Hair,$DCAA7E,0.48),2.8,'swept hair highlight');
      end;
    5:
      begin
        Canvas.ShadePath([M,-40,-106,C,-30,-138,26,-144,43,-102,
          C,49,-83,42,-43,31,-22,C,20,-6,8,4,-2,4,C,-16,1,-29,-17,-37,-37,
          C,-46,-57,-46,-85,-40,-106,Z],SkinLight,SkinShade,-125,-3,'long face');
        Canvas.Path([M,-51,-49,C,-61,-67,-60,-114,-44,-133,
          C,-24,-157,24,-155,44,-132,C,58,-110,53,-75,51,-53,L,42,-54,
          C,43,-79,44,-96,33,-105,C,15,-101,-9,-108,-25,-118,
          C,-39,-103,-42,-83,-42,-53,Z],Hair,'bob fringe');
        Canvas.Stroke([M,-34,-132,C,-15,-148,14,-149,33,-132],
          TVColorMix(Hair,$B29AAC,0.42),2.8,'bob highlight');
      end;
  else
    Canvas.ShadePath([M,-44,-102,C,-39,-138,33,-150,47,-101,
      C,54,-85,47,-51,37,-26,C,28,-10,10,2,-3,1,C,-24,-2,-43,-26,-46,-52,
      C,-48,-67,-48,-89,-44,-102,Z],SkinLight,SkinShade,-124,-9,'face');
    Canvas.Path([M,-46,-66,C,-55,-75,-57,-107,-46,-123,C,-33,-151,10,-151,36,-135,
      C,52,-125,56,-109,46,-78,L,42,-91,C,42,-111,25,-109,14,-126,
      C,-4,-106,-21,-103,-42,-96,L,-43,-76,Z],Hair,'hair');
    Canvas.Stroke([M,-45,-110,C,-22,-134,7,-144,32,-128],
      TVColorMix(Hair,$C99976,0.27),3,'hair highlight');
  end;
  if Style in [1,5,7] then
  begin
    if Style<>5 then
      Canvas.Stroke([M,-41,-95,C,-48,-76,-36,-48,-45,-31],Hair,7,'side hair');
    Canvas.Ellipse(-47,-55,3.5,4,$FFEAB9);
    Canvas.Ellipse(44,-55,3.5,4,$FFEAB9);
  end;
  if Style<>3 then
    Canvas.Stroke([M,-31,-83,C,-25,-87,-15,-86,-11,-82,M,11,-82,C,18,-87,27,-87,32,-83],
      TVColorMix(Hair,Skin,0.25),2.7,'brows');
  Blink := 1 - 0.92 * TVSmooth((Abs(TVCycle(Time + Style * 0.37, 4.73) - 0.72) - 0.035)/-0.035);
  Look := 1.6*Sin(Time*0.7+Style);
  DrawPresenterEye(Canvas,-21,-71.5,Blink,Look);
  DrawPresenterEye(Canvas,22,-71.5,Blink,Look);
  if Style=4 then
    Canvas.Stroke([M,-34,-72,C,-34,-85,-8,-85,-8,-72,C,-8,-58,-34,-58,-34,-72,Z,
      M,9,-72,C,9,-85,35,-85,35,-72,C,35,-58,9,-58,9,-72,Z,
      M,-8,-74,C,-4,-77,5,-77,9,-74,M,-35,-75,L,-47,-80,M,35,-75,L,46,-80],
      $693D40,2.15,'round glasses');
  Canvas.Stroke([M,1,-73,C,-3,-63,-3,-59,-6,-53,C,-3,-49,2,-50,5,-52],
    TVColorMix(Skin,$924E43,0.42),1.7,'nose');
  Canvas.Ellipse(-28,-57,9,5,$D36B6C,0.15);
  Canvas.Ellipse(27,-57,9,5,$D36B6C,0.18);
  MouthOpen := 1.5 + Speech * (2 + 5 * Sqr(Sin(Time*12.8 + 0.6*Sin(Time*3.7))));
  Canvas.Path([M,-14,-37,C,-6,-39,6,-39,15,-38,
    C,8,-35+MouthOpen,-7,-35+MouthOpen,-14,-37,Z],$743D48);
  if MouthOpen > 4 then Canvas.Line(-8,-37,9,-37,1.4,$FAE3D7);
  if Style=3 then
  begin
    Canvas.Line(-18,-37,-16,-40,1.8,SkinShade);
    Canvas.Line(17,-37,19,-40,1.8,SkinShade);
  end;
  if Style=5 then
    Canvas.Stroke([M,-12,-36,C,-6,-32,7,-32,12,-36],$A65867,1.6,'lip gloss');
  Canvas.Stroke([M,-8,-26,C,-3,-24,3,-24,8,-27],
    TVColorMix(Skin,$A15453,0.29),1.7,'chin');
  Canvas.Transform(0,0);
end;

// 肩からひじ、ひじから手首までを別々に描き、手首の向きを返す。
function DrawSleeve(Canvas: TTVCanvas; const Shoulder,Elbow,Wrist: TPointF;
  Width: Single; Jacket,Shadow,Cuff: TTVColor): TPointF;
var
  D: Single;
begin
  D := Hypot(Wrist.X-Elbow.X,Wrist.Y-Elbow.Y);
  Result := PointF((Wrist.X-Elbow.X)/D,(Wrist.Y-Elbow.Y)/D);
  Canvas.Line(Shoulder.X,Shoulder.Y,Elbow.X,Elbow.Y,Width,Shadow);
  Canvas.Ellipse(Elbow.X,Elbow.Y,Width*0.48,Width*0.48,Shadow);
  Canvas.Line(Elbow.X,Elbow.Y,Wrist.X,Wrist.Y,Width*0.85,Shadow);
  Canvas.Line(Shoulder.X,Shoulder.Y-1,Elbow.X,Elbow.Y-1,Width*0.76,Jacket);
  Canvas.Ellipse(Elbow.X,Elbow.Y-1,Width*0.35,Width*0.35,Jacket);
  Canvas.Line(Elbow.X,Elbow.Y-1,Wrist.X-Result.X*3,Wrist.Y-Result.Y*3,Width*0.63,Jacket);
  Canvas.Line(Wrist.X-Result.X*4,Wrist.Y-Result.Y*4,Wrist.X,Wrist.Y,Width*0.60,Cuff);
end;

procedure DrawPresenterHand(Canvas: TTVCanvas; const Wrist,Axis: TPointF; Skin: TTVColor);
  function HX(Forward, Across: Single): Single;
  begin
    Result := Wrist.X+Forward*Axis.X-Across*Axis.Y;
  end;
  function HY(Forward, Across: Single): Single;
  begin
    Result := Wrist.Y+Forward*Axis.Y+Across*Axis.X;
  end;
begin
  Canvas.Path([M,HX(-1,-6),HY(-1,-6),L,HX(6,-7),HY(6,-7),
    L,HX(12,-11),HY(12,-11),C,HX(15,-12),HY(15,-12),HX(17,-10),HY(17,-10),HX(16,-8),HY(16,-8),
    L,HX(13,-4),HY(13,-4),L,HX(23,-3),HY(23,-3),
    C,HX(27,-3),HY(27,-3),HX(28,2),HY(28,2),HX(24,4),HY(24,4),
    L,HX(19,7),HY(19,7),C,HX(13,10),HY(13,10),HX(7,8),HY(7,8),HX(-1,6),HY(-1,6),Z],Skin);
  Canvas.Line(HX(15,0),HY(15,0),HX(23,0),HY(23,0),1.1,$A56958,0.57);
  Canvas.Line(HX(14,4),HY(14,4),HX(21,4),HY(21,4),1.1,$A56958,0.46);
end;

procedure DrawPresenter(Canvas: TTVCanvas; X, Y, Scale: Single; Style: Integer;
  Time: Double; Speech, Gesture: Single; FacingLeft: Boolean);
var
  Jacket, Shadow, Skin, Hair, Rim: TTVColor;
  Lift, UpperAngle, ForeAngle: Single;
  Elbow,Wrist,Axis: TPointF;
begin
  Style := Style mod Length(Jackets);
  Jacket := Jackets[Style];
  Skin := SkinTones[Style];
  Hair := HairTones[Style];
  Shadow := TVColorMix(Jacket, $161827, 0.63);
  Rim := TVColorMix(Jacket, $F5DCD7, 0.26);
  Lift := Gesture*(0.77+0.23*Sin(Time*2.25+Style*0.84));
  UpperAngle := DegToRad(12+33*Lift);
  ForeAngle := DegToRad(-20+155*Lift);

  Canvas.Transform(X, Y, Scale, FacingLeft);
  if Style in [1,7] then
    Canvas.ShadePath([M,-57,-118,C,-56,-168,43,-170,53,-103,
      C,65,-77,44,-25,68,37,C,40,49,-53,50,-70,31,C,-49,-10,-71,-77,-57,-118,Z],
      Hair, $1A1826, -130, 42, 'long hair');
  Canvas.ShadePath([M,-15,2,C,-31,15,-71,19,-87,37,C,-106,64,-105,134,-108,203,
    L,105,203,C,100,135,108,72,86,39,C,67,19,35,16,16,2,Z],
    Rim, Shadow, 35, 200, 'jacket');
  Canvas.ShadePath([M,-29,15,C,-8,21,14,23,30,15,L,48,35,L,11,135,L,-47,35,Z],
    $EFF0E8, $A4B5BA, 28, 139, 'shirt');
  Canvas.Path([M,-20,-28,L,19,-28,L,24,15,L,10,35,L,-24,13,Z],
    TVColorMix(Skin,$80483E,0.31), 'neck');
  Canvas.Path([M,-51,25,L,-32,19,L,10,135,L,-31,95,L,-36,75,L,-51,67,Z],
    Jacket, 'left lapel');
  Canvas.Path([M,50,26,L,31,19,L,10,135,L,52,88,L,43,75,L,57,66,Z], Rim, 'right lapel');
  if Style in [0, 3, 7] then
  begin
    Canvas.Path([M,-11,28,L,6,26,L,14,38,L,6,46,L,-12,39,Z], $B24454, 'tie knot');
    Canvas.Path([M,-5,40,L,6,43,L,16,107,L,8,124,L,-8,108,Z], $963847, 'tie');
  end;
  Canvas.Line(-74,118,-47,114,2,Rim,0.7);
  Canvas.Line(50,126,71,128,2,Shadow,0.6);
  Canvas.Ellipse(9,158,3,3,Shadow);
  Wrist := PointF(-36,145);
  Axis := DrawSleeve(Canvas,PointF(-77,52),PointF(-82,117),Wrist,25,Jacket,Shadow,$BAC7CB);
  DrawPresenterHand(Canvas,Wrist,Axis,Skin);
  Elbow := PointF(77+57*Sin(UpperAngle),51+57*Cos(UpperAngle));
  Wrist := PointF(Elbow.X+49*Sin(ForeAngle),Elbow.Y+49*Cos(ForeAngle));
  Axis := DrawSleeve(Canvas,PointF(77,51),Elbow,Wrist,27,Jacket,Shadow,$BAC7CB);
  DrawPresenterHand(Canvas,Wrist,Axis,Skin);

  DrawPresenterHead(Canvas,X,Y,Scale,Style,Time,Speech,FacingLeft);
end;

procedure DrawWeatherPresenter(Canvas: TTVCanvas; X,Y,Scale: Single; Time: Double;
  TargetX,TargetY: Single);
const
  Style = 2;
  ElbowX = 85;
var
  Skin,Jacket,Shadow: TTVColor;
  AimY,ElbowY,WristX,WristY,GripX,GripY,DX,DY,D,Reach: Single;
  Axis: TPointF;
begin
  Skin := SkinTones[Style];
  Jacket := Jackets[Style];
  Shadow := TVColorMix(Jacket,$172E39,0.50);
  AimY := EnsureRange((TargetY-Y)/Scale,-90.0,125.0);
  ElbowY := 89+0.14*AimY;
  WristX := 121+3.2*Sin(Time*1.35);
  WristY := 65+0.34*AimY+2*Sin(Time*1.12);
  Canvas.Transform(X,Y,Scale,True);
  Canvas.ShadePath([M,-41,32,C,-65,34,-71,66,-70,95,L,-64,159,L,-43,158,
    L,-45,95,L,-31,49,Z],Jacket,Shadow,39,160,'forecast resting sleeve');
  Canvas.RoundRect(-62,154,15,24,6,Skin);
  Canvas.ShadePath([M,-16,3,C,-27,13,-48,15,-55,34,
    C,-63,56,-53,102,-45,132,C,-42,151,-47,171,-47,189,L,48,189,
    C,48,168,44,150,46,132,C,51,105,61,54,56,35,
    C,51,16,27,13,16,3,Z],TVColorMix(Jacket,$D7E7D8,0.22),Shadow,
    31,187,'forecast fitted jacket');
  Canvas.ShadePath([M,-22,14,C,-9,22,9,22,22,14,L,33,31,L,0,105,L,-30,32,Z],
    $F1F0E4,$A9C6BD,21,107,'forecast blouse');
  Canvas.Path([M,-16,-25,L,17,-25,L,18,9,C,10,21,-7,23,-18,9,Z],
    TVColorMix(Skin,$895447,0.28),'forecast neck');
  Canvas.Path([M,-37,21,L,-24,15,L,0,105,L,-28,75,L,-23,60,L,-36,46,Z],
    $599089,'forecast lapel left');
  Canvas.Path([M,37,21,L,23,15,L,0,105,L,29,76,L,24,60,L,38,46,Z],
    $3A7169,'forecast lapel right');
  Canvas.Stroke([M,0,107,C,-3,134,1,160,0,186],$224B48,1.5,'forecast jacket seam');
  Canvas.Ellipse(-2,116,2.1,2.1,$BAC6B8);
  Canvas.Ellipse(-2,148,2.1,2.1,$97ADA3);

  Axis := DrawSleeve(Canvas,PointF(49,43),PointF(ElbowX,ElbowY),
    PointF(WristX,WristY),24,Jacket,Shadow,$B9D3CA);
  GripX := WristX+Axis.X*7;
  GripY := WristY+Axis.Y*7;
  DX := (X-TargetX)/Scale-GripX;
  DY := (TargetY-Y)/Scale-GripY;
  D := Max(1.0,Hypot(DX,DY));
  DX := DX/D;
  DY := DY/D;
  Reach := Min(122.0,Max(51.0,D-4));
  Canvas.Line(GripX-DX*11,GripY-DY*11,GripX+DX*Reach,GripY+DY*Reach,4.5,$30404D);
  Canvas.Line(GripX,GripY-0.8,GripX+DX*Reach,GripY+DY*Reach-0.8,2.3,$DBE8E1);
  Canvas.Line(GripX+DX*(Reach-7),GripY+DY*(Reach-7),GripX+DX*Reach,GripY+DY*Reach,4,$F5CE7B);
  Canvas.Line(WristX,WristY,GripX,GripY,12,Skin);
  Canvas.Ellipse(GripX,GripY,7.3,6.5,Skin);
  Canvas.Line(GripX+1,GripY-3.2,GripX+5.5,GripY-0.7,1.3,$976250,0.72);
  Canvas.Line(GripX+0.8,GripY+0.3,GripX+5.0,GripY+2.8,1.3,$976250,0.62);

  DrawPresenterHead(Canvas,X,Y,Scale,Style,Time,1,True);
end;

procedure DrawCloud(Canvas: TTVCanvas; X, Y, Scale: Single; Color: TTVColor);
begin
  Canvas.Transform(X,Y,Scale);
  Canvas.Path([M,-53,19,C,-66,9,-59,-12,-42,-13,C,-34,-40,1,-49,16,-23,
    C,37,-25,50,-9,49,1,C,68,9,56,29,41,29,L,-39,29,C,-45,29,-50,25,-53,19,Z],
    Color,'cloud');
  Canvas.Transform(0,0);
end;

procedure DrawSkyline(Canvas: TTVCanvas; Variant: Integer; Time: Double);
const
  SkyTop: array[0..3] of TTVColor = ($3C678F,$258B9D,$3B365C,$2D4B40);
  SkyBottom: array[0..3] of TTVColor = ($C4B4C3,$CAE8D1,$E89976,$B9CF8D);
var
  I, J, Level, H, W: Integer;
  X, Y: Single;
  Paint: TTVColor;
begin
  Variant := Variant mod Length(SkyTop);
  Canvas.Shade(0,0,960,540,SkyTop[Variant],SkyBottom[Variant]);
  Canvas.Ellipse(716,147,53,53,$FFE5BA,0.36);
  Canvas.Ellipse(716,147,42,42,$FFF4CB,0.67);
  for I := 0 to 3 do
    DrawCloud(Canvas, -80 + 1120 * TVCycle(Time + I * 18, 94), 102 + 39 * (I mod 2),
      0.7 + I * 0.23, TVColorMix(SkyBottom[Variant],$FFFFFF,0.36));
  Canvas.Path([M,0,323,L,167,225,L,247,298,L,393,197,L,582,306,L,687,229,
    L,960,340,L,960,540,L,0,540,Z],$4A6977,'skyline ridge',0.65);
  for Level := 0 to 1 do
    for I := 0 to 19 do
    begin
      W := 38 + Integer(TVHash(Cardinal(I + Variant * 31)) mod 24);
      H := 32 + Integer(TVHash(Cardinal(I + Level * 32 + Variant * 61)) mod Cardinal(101+Level*66));
      X := I * 52 - 20 + Level * 24;
      Y := 432 + Level*47-H;
      Paint := TVColorMix(SkyTop[Variant],$172735,0.37+Level*0.45);
      Canvas.Fill(X,Y,W,H,Paint);
      Canvas.Fill(X+W*0.22,Y-7,W*0.53,8,Paint);
      Canvas.Fill(X,Y,4,H,$E0CDD0,0.10);
      for J := 0 to (H div 18)-1 do
      begin
        Canvas.Fill(X+9,Y+11+J*17,6,5,$FFD4A5,0.30+0.17*(1-Level));
        if (I+J) mod 3 <> 0 then Canvas.Fill(X+23,Y+11+J*17,6,5,$FFE3BC,0.46);
        Canvas.Fill(X+36,Y+11+J*17,5,5,$ACC3D3,0.43);
      end;
    end;
  Canvas.Shade(0,482,960,58,$293946,$101E31);
  Canvas.Line(0,490,960,490,2,$A9B4C0,0.45);
end;

procedure DrawWeatherIcon(Canvas: TTVCanvas; X, Y, Scale: Single; Weather: Integer);
var
  I, J: Integer;
  Angle: Double;
begin
  if Weather = 0 then
  begin
    Canvas.Ellipse(X,Y,18*Scale,18*Scale,$FFBF47);
    Canvas.Ellipse(X-2*Scale,Y-3*Scale,12*Scale,12*Scale,$FFE17D);
    for I := 0 to 7 do
    begin
      Angle := I * Pi / 4;
      Canvas.Line(X+23*Scale*Cos(Angle),Y+23*Scale*Sin(Angle),
        X+30*Scale*Cos(Angle),Y+30*Scale*Sin(Angle),3*Scale,$FFD76E);
    end;
    Exit;
  end;
  DrawCloud(Canvas,X,Y-7*Scale,Scale*0.41,$A2BCD3);
  DrawCloud(Canvas,X-4*Scale,Y-11*Scale,Scale*0.34,$EBF3F7);
  for I := -1 to 1 do
    if Weather = 2 then
      Canvas.Line(X+(I*14+2)*Scale,Y+11*Scale,X+(I*14-3)*Scale,Y+22*Scale,3*Scale,$64D4F9)
    else if Weather = 3 then
      for J := 0 to 2 do
      begin
        Angle := J * Pi / 3;
        Canvas.Line(X+(I*15-5*Cos(Angle))*Scale,Y+(17-5*Sin(Angle))*Scale,
          X+(I*15+5*Cos(Angle))*Scale,Y+(17+5*Sin(Angle))*Scale,1.6*Scale,$E7F7FF);
      end;
end;

procedure DrawProduct(Canvas: TTVCanvas; X, Y, Scale: Single; Product: Integer; Time: Double);
var
  Shine: Single;
begin
  Canvas.Ellipse(X,Y+97*Scale,95*Scale,16*Scale,$102034,0.24);
  Canvas.Transform(X,Y,Scale);
  Shine := Sin(Time*1.4)*14;
  case Product mod 3 of
    0: begin
      Canvas.ShadePath([M,-53,-79,C,-52,-96,51,-96,53,-79,L,46,82,
        C,43,102,-39,102,-45,82,Z],$E4F7EC,$1F8780,-78,92,'bottle');
      Canvas.RoundRect(-32,-115,64,29,6,$175950);
      Canvas.Shade(-49,-45,98,87,$72CF98,$207E72);
      Canvas.Path([M,-42,16,C,-8,-27,25,49,47,1,L,47,28,C,16,54,-8,-4,-42,41,Z],
        $FFFFFF,'bottle splash',0.61);
      Canvas.LabelText('MIORI',-43,-27,86,22,$0F4847,True,2);
      Canvas.Fill(-27+Shine,-74,5,151,$FFFFFF,0.24);
    end;
    1: begin
      Canvas.ShadePath([M,-75,65,L,-65,-48,C,-50,-86,51,-86,65,-48,
        L,75,65,C,71,99,-69,99,-75,65,Z],$73ABC9,$253856,-71,80,'speaker body');
      Canvas.Ellipse(0,-1,48,48,$19283E);
      Canvas.Ellipse(0,-1,42,42,$436386);
      Canvas.Ellipse(0,-1,32,32,$273F58);
      Canvas.Ellipse(0,-1,18,18,$1D293D);
      Canvas.Ellipse(-4,-7,11,7,$678BAC,0.54);
      Canvas.Line(-49,61,49,61,2,$ABDFEE,0.7);
      Canvas.Ellipse(Shine*0.15,72,3,3,$8DF6E9);
    end;
    2: begin
      Canvas.ShadePath([M,-93,-46,L,48,-59,L,90,-29,L,72,76,L,-75,88,Z],
        $F2C497,$B55754,-46,85,'pastry box');
      Canvas.Path([M,48,-59,L,90,-29,L,72,76,L,47,51,Z],$A85254,'box side');
      Canvas.Path([M,-93,-46,L,48,-59,L,47,51,L,-75,66,Z],$FFE4BB,'box face');
      Canvas.Path([M,-15,-53,L,5,-55,L,9,82,L,-11,83,Z],$AB535D,'ribbon');
      Canvas.LabelText('穂の庭',-67,-26,112,23,$7D344A,True,2);
      Canvas.Stroke([M,-4,-51,C,-73,-77,-40,-115,-4,-51,C,35,-115,81,-87,-4,-51],
        $BC5268,7,'ribbon bow');
    end;
  end;
  Canvas.Transform(0,0);
end;

procedure DrawLive(Canvas: TTVCanvas; const Caption: string; Brand: TTVColor);
begin
  Canvas.RoundRect(26,24,140,37,6,$122134,0.91);
  Canvas.Ellipse(45,42,5,5,Brand);
  Canvas.LabelText(Caption,57,30,103,18,$FFFFFF,True);
end;

procedure DrawLowerThird(Canvas: TTVCanvas; const Category, Headline: string;
  Accent, Background: TTVColor);
begin
  Canvas.Fill(31,414,8,70,Accent);
  Canvas.Shade(39,414,890,70,Background,TVColorMix(Background,$050C17,0.37),0.97);
  Canvas.LabelText(Category,55,418,846,16,Accent,True);
  Canvas.LabelText(Headline,55,438,846,29,$FFFFFF,True);
end;

procedure DrawCrawl(Canvas: TTVCanvas; const Copy: string; Time: Double; Accent: TTVColor);
var
  X: Single;
  Text: string;
begin
  Text := Copy + '      ◇      ' + Copy;
  Canvas.Fill(0,500,960,40,$0A1424);
  Canvas.Fill(0,499,960,2,Accent,0.76);
  Canvas.Clip(164,500,796,40);
  X := 165 - TVCycle(Time,16) * 730;
  Canvas.LabelText(Text,X,507,1550,18,$F5F6FA);
  Canvas.Unclip;
  Canvas.Fill(0,501,159,39,Accent);
  Canvas.LabelText('ニュース速報',10,507,139,18,$102235,True,2);
end;

end.
