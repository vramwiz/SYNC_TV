unit TV_Sports;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 野球とサッカーの競技場、選手とボール、得点表示を時刻から描画する。

interface

uses TV_Canvas;

procedure DrawBaseball(Canvas: TTVCanvas; Time: Double);
procedure DrawFootball(Canvas: TTVCanvas; Time: Double);

implementation

uses
  System.Math, System.SysUtils, System.Types, TV_Timeline, TV_Artwork;

type
  TFieldCamera = record
    X, Y, Zoom: Single;
    function Point(XPos, YPos: Single): TPointF;
  end;

function TFieldCamera.Point(XPos, YPos: Single): TPointF;
begin
  Result := PointF(X + XPos*Zoom,Y + YPos*Zoom);
end;

procedure DrawFootballStadium(Canvas: TTVCanvas; Time: Double);
var
  I, Row: Integer;
  X, Y, D: Single;
  Paint: TTVColor;
begin
  Canvas.Shade(0,0,960,540,$304D6F,$131C2F);
  Canvas.Path([M,0,13,L,960,13,L,882,90,L,58,85,Z],$718C9D,'stadium roof');
  Canvas.Line(0,20,960,20,6,$B2CFD5,0.77);
  for I := 0 to 21 do Canvas.Line(I*47,21,I*44+15,83,2,$CEE7E8,0.4);
  for Row := 0 to 5 do
  begin
    Y := 65+Row*20;
    Canvas.Shade(0,Y,960,19,$52667D,$273B52);
    for I := 0 to 81 do
    begin
      D := (TVHash(Cardinal(Row*97+I)) and $FF)/255;
      Paint := TVColorMix($477BA4,$DCD4C2,D);
      X := 12*I+5*(Row mod 2);
      Canvas.Ellipse(X,Y+8+D*5,1.4+D*1.6,2.3,Paint);
      if I mod 6 = 0 then
        Canvas.Fill(X-4,Y+9,8,5,TVColorMix($BD4161,$72ADA5,D),0.77);
    end;
    Canvas.Line(0,Y+18,960,Y+18,1.5,$A3B2BA,0.47);
  end;
  Canvas.Shade(0,185,960,47,$254A57,$123741);
  Canvas.Line(0,186,960,186,3,$A7D6CD,0.48);
  for I := 0 to 11 do
  begin
    Canvas.Fill(I*80+2,197,76,20,$153548);
    Canvas.Line(I*80+9,206,I*80+67,206,2,$8ACDE0,0.58+0.18*Sin(Time+I));
  end;
end;

procedure Athlete(Canvas: TTVCanvas; const P: TPointF; Scale: Single; Paint: TTVColor;
  Time, Run, Reach: Double; Baseball, Flip: Boolean);
var
  F, Alt, Lean: Single;
  Shade, Light: TTVColor;

  procedure DrawArm(Side: Integer; UpperAngle, ForeAngle: Single);
  var
    Shoulder,Elbow,Hand: TPointF;
  begin
    Shoulder := PointF(Lean+Side*9,-48);
    Elbow := PointF(Shoulder.X+Side*12*Sin(UpperAngle),Shoulder.Y+12*Cos(UpperAngle));
    Hand := PointF(Elbow.X+Side*12*Sin(ForeAngle),Elbow.Y+12*Cos(ForeAngle));
    Canvas.Line(Shoulder.X,Shoulder.Y,Elbow.X,Elbow.Y,6,$C68F73);
    Canvas.Line(Shoulder.X,Shoulder.Y,TVLerp(Shoulder.X,Elbow.X,0.55),
      TVLerp(Shoulder.Y,Elbow.Y,0.55),7.4,Paint);
    Canvas.Ellipse(Elbow.X,Elbow.Y,2.35,2.35,$C68F73);
    Canvas.Line(Elbow.X,Elbow.Y,Hand.X,Hand.Y,4.5,$D39C7F);
    Canvas.Ellipse(Hand.X,Hand.Y,2.55,2.5,$D69B7D);
  end;

begin
  F := 15 * Sin(Time*14) * Run;
  Alt := 9 * Cos(Time*14)*Run;
  Lean := 3+7*Run;
  Shade := TVColorMix(Paint,$13263B,0.60);
  Light := TVColorMix(Paint,$F7DECC,0.35);
  Canvas.Ellipse(P.X,P.Y+1,15*Scale,3.5*Scale,$152619,0.36);
  Canvas.Transform(P.X,P.Y-Abs(Alt)*Scale*0.19,Scale,Flip);
  Canvas.Stroke([M,-6,-27,L,-7+F*0.34,-14+Alt*0.24,L,-8+F,-Abs(F)*0.18,
    M,6,-27,L,7-F*0.34,-15-Alt*0.28,L,8-F,-Abs(F)*0.25],$CEDAE1,6.5);
  if not Baseball then
    Canvas.Stroke([M,-6,-27,L,-7+F*0.34,-16+Alt*0.24,M,6,-27,L,7-F*0.34,-16-Alt*0.28],
      Shade,8.5);
  Canvas.Line(-11+F,-Abs(F)*0.18,-5+F,-Abs(F)*0.18,4,$192739);
  Canvas.Line(5-F,-Abs(F)*0.25,12-F,-Abs(F)*0.25,4,$192739);
  DrawArm(-1,DegToRad(37+F*0.55),DegToRad(-22-F*0.78));
  DrawArm(1,DegToRad(36+37*Reach-F*0.55),DegToRad(12+129*Reach+F*0.82));
  Canvas.ShadePath([M,-12+Lean,-51,L,12+Lean,-51,L,14,-31,L,5,-26,L,-11,-29,Z],
    Light,Paint,-53,-25);
  Canvas.Fill(Lean-3,-43,6,8,$F8EEDC,0.8);
  Canvas.Ellipse(Lean,-58,7,9,$D69B7D);
  if Baseball then
    Canvas.Path([M,Lean-8,-57,C,Lean-9,-71,Lean+10,-73,Lean+9,-58,
      L,Lean+16,-57,L,Lean+14,-54,L,Lean-8,-55,Z],Shade)
  else
  begin
    Canvas.Path([M,Lean-7,-57,C,Lean-12,-71,Lean+6,-73,Lean+8,-59,L,Lean+4,-61,
      L,Lean-6,-58,Z],$2C2429);
    Canvas.Line(Lean+2,-56,Lean+5,-56,1.2,$352837);
  end;
  Canvas.Transform(0,0);
end;

const
  PITCH_RELEASE = 3.81;
  SWING_START = 4.03;
  SWING_CONTACT = 4.28;
  SWING_FINISH = 4.44;
  BATTER_RUN = 4.65;
  BAT_CONTACT_FRACTION = 0.73;

type
  TBatterPose = record
    Grip, Bat: TPointF;
    Hips, Chest, ShoulderY, HalfWidth, LeadFoot, FootLift, Pivot: Single;
  end;

// 打者の軸足を原点にして、同じ時刻から手元・バット・体の向きを求める。
function BatterPoseAt(Age: Double; Hit: Boolean): TBatterPose;
var
  Load, Plant, Drive, Wrap, Sweep, Lower, Reset, Rest,
  Heading, Elevation, Reach: Double;
begin
  Load := TVSmooth((Age-3.57)/(SWING_START-3.57));
  Plant := TVSmooth((Age-3.96)/(SWING_CONTACT-3.96));
  Drive := TVSmooth((Age-SWING_START)/(SWING_CONTACT-SWING_START));
  Wrap := TVSmooth((Age-SWING_CONTACT)/(SWING_FINISH-SWING_CONTACT));
  Sweep := TVSmooth((Age-SWING_START)/(SWING_FINISH-SWING_START));
  Lower := TVSmooth((Age-4.50)/(BATTER_RUN-4.50));
  Reset := TVSmooth((Age-4.57)/0.70);
  Rest := 0.8*Sin(Age*4)*(1-Load);
  if Hit then Reset := 0 else Lower := 0;

  Result.Hips := (3.5*Load-8*Plant-2.5*Wrap+3*Lower)*(1-Reset);
  Result.Chest := Result.Hips+(2*Load-5*Drive+2*Wrap)*(1-Reset);
  Result.ShoulderY := -50+(2*Load-4*Drive-1*Wrap)*(1-Reset);
  Result.HalfWidth := 10.5-(5.0*Drive-2.5*Wrap)*(1-Reset);
  Result.LeadFoot := -11-8*Plant*(1-Reset);
  Result.FootLift := 4*Sin(Pi*Plant)*(1-Reset);
  Result.Pivot := TVClamp((Drive*0.55+Wrap*0.45)*(1-Lower)*(1-Reset));
  Result.Grip.X := TVLerp(14+5*Load-15*Drive-15*Wrap+4*Lower,14,Reset)+Rest;
  Result.Grip.Y := TVLerp(-52-2*Load+16*Drive-18*Wrap+18*Lower,-52,Reset);

  // 水平方向に回すバットを斜め上の中継カメラから見た長さに投影する。
  Heading := DegToRad(TVLerp(27+219*Sweep-58*Lower,27,Reset)+3*Rest);
  Elevation := DegToRad(TVLerp(65+4*Load-66*Drive+44*Wrap-32*Lower,65,Reset)
    +25*Sin(Pi*Reset));
  Reach := 40*Cos(Elevation);
  Result.Bat := PointF(Reach*Cos(Heading),0.34*Reach*Sin(Heading)-40*Sin(Elevation));
end;

procedure DrawBat(Canvas: TTVCanvas; const Grip, Barrel: TPointF);
begin
  Canvas.Line(Grip.X-Barrel.X*0.18,Grip.Y-Barrel.Y*0.18,
    Grip.X+Barrel.X*0.34,Grip.Y+Barrel.Y*0.34,3.4,$B99365);
  Canvas.Line(Grip.X+Barrel.X*0.18,Grip.Y+Barrel.Y*0.18,
    Grip.X+Barrel.X*0.70,Grip.Y+Barrel.Y*0.70,4.5,$DCB982);
  Canvas.Line(Grip.X+Barrel.X*0.53,Grip.Y+Barrel.Y*0.53,
    Grip.X+Barrel.X,Grip.Y+Barrel.Y,5.8,$EDCB91);
  Canvas.Ellipse(Grip.X+Barrel.X,Grip.Y+Barrel.Y,2.8,2.8,$EDCB91);
  Canvas.Ellipse(Grip.X-Barrel.X*0.18,Grip.Y-Barrel.Y*0.18,2.4,2.4,$8B6348);
end;

procedure DrawBatter(Canvas: TTVCanvas; const P: TPointF; Scale: Single;
  const Pose: TBatterPose);
const
  Kit = $B14352;
  KitShade = $733044;
var
  FarHand,NearHand: TPointF;
  RearKnee,LeadKnee,Head: Single;

  procedure DrawArm(const Shoulder,Hand: TPointF; Bend: Single; Sleeve: TTVColor);
  var
    D,Height,DX,DY: Single;
    Elbow: TPointF;
  begin
    DX := Hand.X-Shoulder.X;
    DY := Hand.Y-Shoulder.Y;
    D := Max(0.01,Hypot(DX,DY));
    Height := Sqrt(Max(0.0,Sqr(15.0)-Sqr(D*0.5)));
    Elbow := PointF((Shoulder.X+Hand.X)*0.5-Bend*Height*DY/D,
      (Shoulder.Y+Hand.Y)*0.5+Bend*Height*DX/D);
    Canvas.Line(Shoulder.X,Shoulder.Y,Elbow.X,Elbow.Y,6.1,$C68F73);
    Canvas.Line(Shoulder.X,Shoulder.Y,TVLerp(Shoulder.X,Elbow.X,0.62),
      TVLerp(Shoulder.Y,Elbow.Y,0.62),7.7,Sleeve);
    Canvas.Ellipse(Elbow.X,Elbow.Y,2.6,2.6,$C68F73);
    Canvas.Line(Elbow.X,Elbow.Y,Hand.X,Hand.Y,4.8,$D39C7F);
  end;

begin
  FarHand := PointF(Pose.Grip.X+Pose.Bat.X*0.064,Pose.Grip.Y+Pose.Bat.Y*0.064);
  NearHand := PointF(Pose.Grip.X-Pose.Bat.X*0.047,Pose.Grip.Y-Pose.Bat.Y*0.047);
  LeadKnee := TVLerp(Pose.Hips-8,Pose.LeadFoot,0.55)-1.5;
  RearKnee := TVLerp(Pose.Hips+7,11,0.60)+3*Pose.Pivot;
  Head := Pose.Hips*0.66-1;
  Canvas.Ellipse(P.X,P.Y+1.5*Scale,19*Scale,3.8*Scale,$152619,0.36);
  Canvas.Transform(P.X,P.Y,Scale);
  Canvas.Stroke([M,Pose.Hips+6,-27,L,RearKnee,-14,L,12,-2.8*Pose.Pivot],
    $AABBC9,7.1);
  Canvas.Stroke([M,Pose.Hips-6,-27,L,LeadKnee,-14,L,Pose.LeadFoot,-Pose.FootLift],
    $DCE4E8,7.6);
  Canvas.Line(Pose.LeadFoot-5,-Pose.FootLift,Pose.LeadFoot+3,-Pose.FootLift,4,$192739);
  Canvas.Line(7,0,15,-4.1*Pose.Pivot,4,$192739);

  DrawArm(PointF(Pose.Chest+Pose.HalfWidth,Pose.ShoulderY+2),FarHand,-1,KitShade);
  Canvas.ShadePath([M,Pose.Chest-Pose.HalfWidth,Pose.ShoulderY,
    L,Pose.Chest+Pose.HalfWidth,Pose.ShoulderY+2,L,Pose.Hips+10,-34,
    L,Pose.Hips+7,-26,L,Pose.Hips-9,-26,L,Pose.Hips-12,-36,Z],
    $D76A69,KitShade,-52,-25);
  Canvas.Line(Pose.Hips-9,-28,Pose.Hips+8,-28,1.8,$583245);
  Canvas.Fill(Pose.Chest-3,Pose.ShoulderY+8,4,6,$F5E8D9,0.8);
  DrawArm(PointF(Pose.Chest-Pose.HalfWidth,Pose.ShoulderY+1),NearHand,1,Kit);
  Canvas.Ellipse(Head,-59,7,9.1,$D69B7D);
  Canvas.Path([M,Head-8,-58,C,Head-9,-70,Head+10,-74,Head+9,-58,
    L,Head-13,-55,L,Head-15,-57,L,Head-8,-60,Z],KitShade);
  Canvas.Line(Head-7,-57,Head-4,-57,1.2,$47313C);

  DrawBat(Canvas,Pose.Grip,Pose.Bat);
  Canvas.Ellipse(FarHand.X,FarHand.Y,2.8,2.6,$C8CBCA);
  Canvas.Ellipse(NearHand.X,NearHand.Y,3.0,2.85,$F3EFE2);
  Canvas.Transform(0,0);
end;

procedure DrawDroppedBat(Canvas: TTVCanvas; const P: TPointF; Scale: Single;
  const Released: TBatterPose; Age: Double);
var
  Fall: Double;
  Grip,Barrel: TPointF;
begin
  Fall := TVClamp(Age/0.33);
  Grip := PointF(Released.Grip.X+5*Fall,TVLerp(Released.Grip.Y,2.8,Sqr(Fall)));
  Barrel := PointF(TVLerp(Released.Bat.X,-36,Fall),TVLerp(Released.Bat.Y,3,Fall));
  Canvas.Transform(P.X,P.Y,Scale);
  DrawBat(Canvas,Grip,Barrel);
  Canvas.Transform(0,0);
end;

function OutfieldWallY(X: Single): Single;
begin
  Result := 148+108*Sqr((X-480)/580);
end;

procedure DrawBallpark(Canvas: TTVCanvas; const Camera: TFieldCamera);
var
  I: Integer;
  X, Y: Single;
begin
  Canvas.Shade(0,0,960,540,$658DAF,$C5D5C8);
  Canvas.Transform(Camera.X,Camera.Y,Camera.Zoom);
  Canvas.Path([M,-100,216,C,27,203,87,163,196,170,
    C,292,171,337,123,410,127,C,524,130,546,158,635,145,
    C,819,117,895,168,1060,193,L,1060,285,L,-100,285,Z],
    $6C9991,'ballpark distant hills');
  Canvas.Path([M,-100,222,C,50,200,154,155,274,166,
    C,438,182,426,145,546,157,C,722,175,794,127,911,173,
    C,963,191,1009,191,1060,197,L,1060,285,L,-100,285,Z],
    $547E70,'ballpark trees');
  Canvas.ShadePath([M,-100,279,C,287,135,673,135,1060,279,L,1060,600,L,-100,600,Z],
    $70A862,$39764C,160,557,'ballpark turf');
  for I := -1 to 11 do
  begin
    X := I*91;
    Canvas.Path([M,X,OutfieldWallY(X)+23,L,X+45,OutfieldWallY(X+45)+23,
      L,I*118+54,568,L,I*118,568,Z],$9CC474,'',0.27);
  end;
  Canvas.Path([M,-100,256,C,287,112,673,112,1060,256,L,1060,279,
    C,673,135,287,135,-100,279,Z],$254F50,'ballpark outfield wall');
  Canvas.Stroke([M,-100,256,C,287,112,673,112,1060,256],$B6C98C,3,'ballpark wall cap');
  Canvas.Stroke([M,-100,282,C,287,138,673,138,1060,282],$A68C60,4,
    'ballpark warning track',0.62);
  for I := 0 to 8 do
  begin
    X := 49+I*108;
    Y := OutfieldWallY(X);
    Canvas.Line(X,Y+3,X,Y+22,1.4,$759994,0.44);
  end;
end;

procedure DrawBaseball(Canvas: TTVCanvas; Time: Double);
const
  HitterX = 503;
  HitterY = 466;
  HitterScale = 0.78;
  RunnerScaleAtSecond = 0.56;
  FieldX: array[0..6] of Single = (242,681,127,811,408,550,478);
  FieldY: array[0..6] of Single = (313,316,267,273,281,279,273);
  Innings: array[0..1] of string = ('表','裏');
  PitchNames: array[0..3] of string = ('ストレート','カーブ','スライダー','チェンジアップ');
var
  Segment, Score: TTVScene;
  Camera: TFieldCamera;
  Pitcher, Hitter, Ball, CrossPlate, Runner, LeftBase, RightBase, SecondBase: TPointF;
  T: Double;
  Reach, Run, Flight, BallRadius, RunnerScale: Single;
  Pose: TBatterPose;
  I, Stage, Outs, Away, Home, Play, StartPlay: Integer;
  Hit, ExtraBases: Boolean;
  Earlier: TTVScene;
begin
  Segment := TVSceneAt(Time,11.7);
  Score := TVSceneAt(Time,35.1);
  T := Segment.Age;
  Hit := Segment.Choice(7,4) <> 0;
  ExtraBases := Hit and (Segment.Choice(19,5)=0);
  Stage := 0;
  if T >= 3.5 then Stage := 1;
  if T >= 5.4 then Stage := 2;
  if T >= 9.1 then Stage := 3;
  Camera.X := 0;
  Camera.Y := 0;
  Camera.Zoom := 1;
  if Stage in [0,1] then
  begin
    Camera.X := -178;
    Camera.Y := -135;
    Camera.Zoom := 1.37;
  end
  else if Stage = 3 then
  begin
    Camera.X := -38;
    Camera.Y := -85;
    Camera.Zoom := 1.12;
  end;
  DrawBallpark(Canvas,Camera);
  Canvas.ShadePath([M,-30,453,L,476,242,L,995,453,L,995,540,L,-30,540,Z],
    $C5A46C,$876245,246,521,'infield dirt');
  Canvas.ShadePath([M,252,378,L,476,275,L,712,378,L,479,490,Z],
    $68995E,$457A53,275,490,'infield grass');
  Canvas.Stroke([M,478,479,L,8,304,M,478,479,L,948,304],$EFE2BA,2.5,'foul lines');
  Canvas.Ellipse(474,341,31,10,$B48760);
  Canvas.Ellipse(479,475,67,20,$B68B62);
  Canvas.Line(463,340,485,340,2.5,$EFE4C7);
  Canvas.Path([M,473,473,L,486,473,L,488,477,L,479,482,L,470,477,Z],
    $FAF0D0,'home plate');
  Canvas.Stroke([M,452,454,L,470,455,L,460,474,L,442,473,L,452,454,
    M,490,455,L,508,454,L,519,473,L,500,474,L,490,455],$F7E5BF,1.5,'batter boxes');
  Canvas.Transform(0,0);
  LeftBase := Camera.Point(248,380);
  RightBase := Camera.Point(711,380);
  SecondBase := Camera.Point(477,275);
  Canvas.Fill(LeftBase.X-4,LeftBase.Y,8,3,$FBF3D4);
  Canvas.Fill(RightBase.X-4,RightBase.Y,8,3,$FBF3D4);
  Canvas.Fill(SecondBase.X-4,SecondBase.Y,8,3,$FBF3D4);
  for I := 0 to High(FieldX) do
  begin
    Run := TVSmooth((T-5.0)/1.15) * (1-TVSmooth((T-8.7)/1.2)) * Ord(Hit);
    if I=0 then
      Athlete(Canvas,Camera.Point(FieldX[I],FieldY[I]-17*Run),Camera.Zoom*0.52,
        $315FA6,Time,Run*0.3,TVSmooth((T-6.4)/0.72),True,False)
    else
      Athlete(Canvas,Camera.Point(FieldX[I]+(I mod 3-1)*57*Run,
        FieldY[I]-25*Run),Camera.Zoom*(0.43+0.029*I),$315FA6,
        Time+I,Run,0.30,True,Odd(I));
  end;
  Pitcher := Camera.Point(474-13*TVSmooth((T-3.75)/0.28),347+15*TVSmooth((T-3.8)/0.45));
  Hitter := Camera.Point(HitterX,HitterY);
  Reach := TVSmooth((T-3.35)/0.40) * (1-TVSmooth((T-4.0)/0.32));
  Athlete(Canvas,Pitcher,Camera.Zoom*0.78,$426DB2,Time,0.12,Reach,True,False);
  if not Hit or (T < BATTER_RUN) then
    DrawBatter(Canvas,Hitter,Camera.Zoom*HitterScale,BatterPoseAt(T,Hit))
  else
  begin
    Pose := BatterPoseAt(BATTER_RUN,True);
    DrawDroppedBat(Canvas,Hitter,Camera.Zoom*HitterScale,Pose,T-BATTER_RUN);
    Run := TVSmooth((T-BATTER_RUN)/(7.03-BATTER_RUN));
    Runner := PointF(TVLerp(HitterX+HitterScale*Pose.Hips,711,Run),TVLerp(HitterY,380,Run));
    if ExtraBases and (T>=7.03) then
    begin
      Run := TVSmooth((T-7.03)/1.85);
      Runner := PointF(TVLerp(711,477,Run),TVLerp(380,275,Run));
    end;
    // 走塁中は奥行きで縮める。一塁で走路が変わっても大きさを保つ。
    RunnerScale := TVLerp(HitterScale,RunnerScaleAtSecond,(HitterY-Runner.Y)/(HitterY-275));
    Athlete(Canvas,Camera.Point(Runner.X,Runner.Y),Camera.Zoom*RunnerScale,$B14352,Time,
      Ord((T < 7.05) or (ExtraBases and (T<8.88))),0.14,True,False);
  end;
  Athlete(Canvas,Camera.Point(475,488),0.71*Camera.Zoom,$4F5963,Time,0.04,0.26,True,False);
  BallRadius := 3.1*Camera.Zoom;
  // バットの芯とボールの軌道に同じミート座標を使う。空振りは外角低めを通る。
  Pose := BatterPoseAt(SWING_CONTACT,Hit);
  CrossPlate := PointF(
    HitterX+HitterScale*(Pose.Grip.X+BAT_CONTACT_FRACTION*Pose.Bat.X)-16*Ord(not Hit),
    HitterY+HitterScale*(Pose.Grip.Y+BAT_CONTACT_FRACTION*Pose.Bat.Y)+14*Ord(not Hit));
  if (T >= PITCH_RELEASE) and (T < SWING_CONTACT) then
  begin
    Flight := TVClamp((T-PITCH_RELEASE)/(SWING_CONTACT-PITCH_RELEASE));
    Ball := Camera.Point(TVLerp(489,CrossPlate.X,Flight),TVLerp(297,CrossPlate.Y,Flight));
    Canvas.Ellipse(Ball.X,Ball.Y,BallRadius,BallRadius,$FFF5D8);
  end
  else if Hit and (T >= SWING_CONTACT) and (T < 6.45) then
  begin
    Flight := TVClamp((T-SWING_CONTACT)/(6.45-SWING_CONTACT));
    Ball := Camera.Point(TVLerp(CrossPlate.X,242,Flight),
      TVLerp(CrossPlate.Y,285,Flight)-139*Sin(Pi*Flight));
    Canvas.Ellipse(Ball.X,Ball.Y,BallRadius,BallRadius,$FFF5D8);
  end
  else if not Hit and (T >= SWING_CONTACT) and (T < 4.39) then
  begin
    Flight := TVClamp((T-SWING_CONTACT)/(4.39-SWING_CONTACT));
    Ball := Camera.Point(TVLerp(CrossPlate.X,475,Flight),TVLerp(CrossPlate.Y,463,Flight));
    Canvas.Ellipse(Ball.X,Ball.Y,BallRadius,BallRadius,$FFF5D8);
  end;
  if Hit and (T >= 7.14) and (T < 8.52) then
  begin
    Flight := TVClamp((T-7.14)/1.38);
    Ball := Camera.Point(TVLerp(242,711-234*Ord(ExtraBases),Flight),
      TVLerp(270,335-90*Ord(ExtraBases),Flight)-88*Sin(Pi*Flight));
    Canvas.Ellipse(Ball.X,Ball.Y,BallRadius,BallRadius,$FFF5D8);
  end;
  Away := 0;
  Home := 0;
  StartPlay := Integer(Segment.Index) div 54 * 54;
  for Play := StartPlay to Integer(Segment.Index) do
  begin
    Earlier.Index := Cardinal(Play);
    if (Earlier.Choice(7,4)<>0) and (Earlier.Choice(19,5)=0) and
      ((Play<Integer(Segment.Index)) or (T>=8.88)) then
      if (Play div 3) mod 2=0 then Inc(Away) else Inc(Home);
  end;
  Outs := Segment.Index mod 3;
  Canvas.RoundRect(27,27,277,95,9,$122543,0.96);
  Canvas.Fill(38,36,99,37,$426DB2);
  Canvas.Fill(138,36,99,37,$AA3E55);
  Canvas.LabelText('北岬  '+IntToStr(Away),40,38,94,20,$FFFFFF,True,2);
  Canvas.LabelText('南庭  '+IntToStr(Home),140,38,94,20,$FFFFFF,True,2);
  Canvas.LabelText(IntToStr(1+(Score.Index div 2) mod 9)+'回 '+Innings[Score.Index mod 2],
    41,82,108,17,$D9EEFF,True);
  for I := 0 to 2 do
    Canvas.Ellipse(202+I*22,95,5,5,TVColorMix($4F6177,$FFD779,Ord(I<Outs)));
  Canvas.LabelText('生中継  グラウンド便り',657,26,272,21,$F4F7FB,True,1);
  if Stage = 3 then
  begin
    Canvas.RoundRect(634,462,293,48,8,$162C48,0.90);
    Canvas.LabelText(PitchNames[Segment.Choice(43,4)]+'  '+IntToStr(123+
      Segment.Choice(82,25))+' km/h',647,468,266,22,$FFDEAE,True,2);
  end;
end;

function PitchPoint(U,V: Single): TPointF;
begin
  // Uは左右のゴールライン間、Vは奥から手前へのタッチライン間。
  Result := PointF(105-72*V+(750+144*V)*U,219+292*V);
end;

procedure PitchLine(Canvas: TTVCanvas; U1,V1,U2,V2: Single; Weight: Single = 2.1);
var
  A,B: TPointF;
begin
  A := PitchPoint(U1,V1);
  B := PitchPoint(U2,V2);
  Canvas.Line(A.X,A.Y,B.X,B.Y,Weight,$E3EED3);
end;

procedure DrawFootballNet(Canvas: TTVCanvas; Side: Integer);
const
  FarPost = 0.345;
  NearPost = 0.655;
  PostHeight = 49;
var
  FrontFar, FrontNear, BackFar, BackNear, A,B: TPointF;
  I: Integer;
  RoofU, V: Single;
begin
  RoofU := Side+0.033*(2*Side-1);
  FrontFar := PitchPoint(Side,FarPost);
  FrontNear := PitchPoint(Side,NearPost);
  BackFar := PitchPoint(RoofU,FarPost);
  BackNear := PitchPoint(RoofU,NearPost);
  Canvas.Path([M,FrontFar.X,FrontFar.Y-PostHeight,L,FrontNear.X,FrontNear.Y-PostHeight,
    L,BackNear.X,BackNear.Y-PostHeight*0.74,L,BackFar.X,BackFar.Y-PostHeight*0.74,Z],
    $E7F2EB,'',0.22);
  Canvas.Path([M,BackFar.X,BackFar.Y-PostHeight*0.74,L,BackNear.X,BackNear.Y-PostHeight*0.74,
    L,BackNear.X,BackNear.Y,L,BackFar.X,BackFar.Y,Z],$E7F2EB,'',0.15);
  for I := 0 to 8 do
  begin
    V := TVLerp(FarPost,NearPost,I/8);
    A := PitchPoint(Side,V);
    B := PitchPoint(RoofU,V);
    Canvas.Line(A.X,A.Y-PostHeight,B.X,B.Y-PostHeight*0.74,1,$E6EEE7,0.53);
    Canvas.Line(B.X,B.Y-PostHeight*0.74,B.X,B.Y,1,$E6EEE7,0.53);
  end;
  for I := 1 to 5 do
    Canvas.Line(BackFar.X,BackFar.Y-PostHeight*0.74*I/5,
      BackNear.X,BackNear.Y-PostHeight*0.74*I/5,1,$E6EEE7,0.50);
  Canvas.Stroke([M,FrontFar.X,FrontFar.Y,L,FrontFar.X,FrontFar.Y-PostHeight,
    L,FrontNear.X,FrontNear.Y-PostHeight,L,FrontNear.X,FrontNear.Y],
    $F7F6E8,3.5);
  Canvas.Stroke([M,FrontFar.X,FrontFar.Y-PostHeight,L,BackFar.X,BackFar.Y-PostHeight*0.74,
    L,BackNear.X,BackNear.Y-PostHeight*0.74,L,FrontNear.X,FrontNear.Y-PostHeight,
    M,BackNear.X,BackNear.Y-PostHeight*0.74,L,BackNear.X,BackNear.Y,
    M,BackFar.X,BackFar.Y-PostHeight*0.74,L,BackFar.X,BackFar.Y],$DCE8DF,1.5);
end;

procedure DrawFootballPitch(Canvas: TTVCanvas);
var
  I, Side: Integer;
  A,B,Cp,D: TPointF;
  U,V,Angle: Single;
begin
  Canvas.Shade(-110,219,1180,365,$559F63,$257B50);
  for I := -1 to 10 do
  begin
    A := PitchPoint(I*0.108,-0.02);
    B := PitchPoint(I*0.108+0.054,-0.02);
    Cp := PitchPoint(I*0.108+0.054,1.24);
    D := PitchPoint(I*0.108,1.24);
    Canvas.Path([M,A.X,A.Y,L,B.X,B.Y,L,Cp.X,Cp.Y,L,D.X,D.Y,Z],$9DCA79,'',0.30);
  end;
  PitchLine(Canvas,0,0,1,0,2.5);
  PitchLine(Canvas,0,1,1,1,2.5);
  PitchLine(Canvas,0,0,0,1,2.5);
  PitchLine(Canvas,1,0,1,1,2.5);
  PitchLine(Canvas,0.5,0,0.5,1);
  for Side := 0 to 1 do
  begin
    U := Side+(1-2*Side)*0.168;
    PitchLine(Canvas,Side,0.218,U,0.218);
    PitchLine(Canvas,U,0.218,U,0.782);
    PitchLine(Canvas,U,0.782,Side,0.782);
    U := Side+(1-2*Side)*0.06;
    PitchLine(Canvas,Side,0.345,U,0.345);
    PitchLine(Canvas,U,0.345,U,0.655);
    PitchLine(Canvas,U,0.655,Side,0.655);
    A := PitchPoint(Side+(1-2*Side)*0.118,0.5);
    Canvas.Ellipse(A.X,A.Y,2.5,1.7,$E3EED3);
    DrawFootballNet(Canvas,Side);
  end;
  A := PitchPoint(0.574,0.50);
  for I := 1 to 32 do
  begin
    Angle := I*Pi/16;
    U := 0.50+0.074*Cos(Angle);
    V := 0.50+0.122*Sin(Angle);
    B := PitchPoint(U,V);
    Canvas.Line(A.X,A.Y,B.X,B.Y,2.1,$E3EED3);
    A := B;
  end;
  A := PitchPoint(0.5,0.5);
  Canvas.Ellipse(A.X,A.Y,2.6,1.8,$E3EED3);
end;

procedure DrawFootball(Canvas: TTVCanvas; Time: Double);
const
  StartU: array[0..14] of Single =
    (0.061,0.19,0.28,0.30,0.41,0.52,0.57,0.70,0.77,0.84,0.939,0.60,0.40,0.68,0.50);
  StartV: array[0..14] of Single =
    (0.50,0.26,0.70,0.41,0.58,0.30,0.80,0.48,0.23,0.71,0.50,0.62,0.84,0.33,0.72);
type
  TPlayerPosition = record
    U,V,Speed: Single;
    Kit: TTVColor;
    FacesLeft: Boolean;
  end;
var
  Segment: TTVScene;
  Camera: TFieldCamera;
  T, Progress, X, Y, BallU, BallV, BallHeight, Angle, Direction, Size: Single;
  Spot: TPointF;
  I, J, Carrier, Min, Sec, Home, Away, Play, FirstPlay, PlayMinute: Integer;
  Scored, AttackingHome: Boolean;
  Earlier: TTVScene;
  Players: array[0..High(StartU)] of TPlayerPosition;
  Player: TPlayerPosition;
begin
  Segment := TVSceneAt(Time,16.4);
  T := Segment.Age;
  Scored := Segment.Choice(8,6)=0;
  AttackingHome := not Odd(Segment.Index);
  Direction := 2*Ord(AttackingHome)-1;

  Camera.X := 0;
  Camera.Y := 0;
  Camera.Zoom := 1;
  if T > 10.5 then
  begin
    Camera.X := -65*Ord(AttackingHome);
    Camera.Y := -25;
    Camera.Zoom := 1.07;
  end;
  DrawFootballStadium(Canvas,Time);
  Canvas.Transform(Camera.X,Camera.Y,Camera.Zoom);
  DrawFootballPitch(Canvas);
  Canvas.Transform(0,0);

  Carrier := -1;
  BallHeight := 0;
  if T < 4.1 then
  begin
    Progress := TVClamp(T/4.1);
    BallU := TVLerp(0.18,0.38,Progress);
    BallV := TVLerp(0.67,0.56,Progress);
    Carrier := 3+Ord(AttackingHome);
  end
  else if T < 7.3 then
  begin
    Progress := TVClamp((T-4.1)/3.2);
    BallU := TVLerp(0.38,0.67,Progress);
    BallV := TVLerp(0.56,0.31,Progress);
    BallHeight := 24*Sin(Pi*Progress);
  end
  else if T < 10.6 then
  begin
    Progress := TVClamp((T-7.3)/3.3);
    BallU := TVLerp(0.67,0.84,Progress);
    BallV := TVLerp(0.31,0.47,Progress);
    Carrier := 9-Ord(AttackingHome);
  end
  else
  begin
    Progress := TVClamp((T-10.6)/1.11);
    BallU := TVLerp(0.84,0.965+0.057*Ord(Scored),Progress);
    BallV := TVLerp(0.47,0.69-0.19*Ord(Scored),Progress);
    BallHeight := 24*Sin(Pi*Progress);
  end;
  if not AttackingHome then BallU := 1-BallU;

  for I := 0 to High(Players) do
  begin
    X := StartU[I]+0.038*Sin(T*0.73+I*2);
    Y := StartV[I]+0.049*Cos(T*0.91+I);
    Player.Speed := 0.62+0.29*Sin(T*0.61+I);
    Player.Kit := $335BA8;
    if Odd(I) then Player.Kit := $BC3D59;
    if I in [0,10] then
    begin
      X := StartU[I];
      Y := TVLerp(0.50,BallV,0.45);
      Player.Kit := $D6B951;
      if I=10 then Player.Kit := $56B6AA;
      Player.Speed := 0.30;
    end;
    if I=Carrier then
    begin
      X := BallU-0.024*Direction;
      Y := BallV+0.025;
      Player.Speed := 0.96;
    end;
    if I=High(Players) then Player.Kit := $3C4554;
    Player.U := EnsureRange(X,0.058,0.942);
    Player.V := EnsureRange(Y,0.19,0.88);
    Player.FacesLeft := (Ord(Odd(I))=Ord(AttackingHome));
    // 手前の選手を後から描く。並び順はフィールド上の奥行きで決まる。
    J := I;
    while (J>0) and (Players[J-1].V>Player.V) do
    begin
      Players[J] := Players[J-1];
      Dec(J);
    end;
    Players[J] := Player;
  end;
  for Player in Players do
  begin
    Spot := PitchPoint(Player.U,Player.V);
    Size := (0.47+0.25*Player.V)*Camera.Zoom;
    Athlete(Canvas,Camera.Point(Spot.X,Spot.Y),Size,Player.Kit,
      Time+Player.U*4,Player.Speed,0.14,False,Player.FacesLeft);
  end;

  Spot := PitchPoint(BallU,BallV);
  Spot := Camera.Point(Spot.X,Spot.Y);
  Canvas.Ellipse(Spot.X,Spot.Y+2,5.7*Camera.Zoom,2.7*Camera.Zoom,$152C24,0.46);
  Spot.Y := Spot.Y-BallHeight*Camera.Zoom;
  Canvas.Ellipse(Spot.X,Spot.Y,4.7*Camera.Zoom,4.7*Camera.Zoom,$F9F3DE);
  for I := 0 to 2 do
  begin
    Angle := I*2*Pi/3+Time*6;
    Canvas.Ellipse(Spot.X+2.4*Camera.Zoom*Cos(Angle),Spot.Y+2.4*Camera.Zoom*Sin(Angle),
      0.92*Camera.Zoom,0.92*Camera.Zoom,$203448);
  end;
  Home := 0;
  Away := 0;
  FirstPlay := Integer(Segment.Index) div 32 * 32;
  for Play := FirstPlay to Integer(Segment.Index) do
  begin
    Earlier.Index := Cardinal(Play);
    if (Earlier.Choice(8,6)=0) and ((Play<Integer(Segment.Index)) or (T>=11.71)) then
      if Odd(Play) then Inc(Away) else Inc(Home);
  end;
  PlayMinute := Trunc((Integer(Segment.Index)-FirstPlay)*16.4+T)*10;
  Min := PlayMinute div 60;
  Sec := PlayMinute mod 60;
  Canvas.RoundRect(25,26,307,62,9,$14263E,0.96);
  Canvas.Fill(33,35,71,28,$416FC0);
  Canvas.Fill(173,35,71,28,$B54C66);
  Canvas.LabelText('青波',33,36,71,19,$FFFFFF,True,2);
  Canvas.LabelText('灯浜',173,36,71,19,$FFFFFF,True,2);
  Canvas.LabelText(Format('%d-%d',[Home,Away]),104,35,69,20,$FFFFFF,True,2);
  Canvas.LabelText(Format('%.2d:%.2d',[Min,Sec]),248,39,76,17,$E8F3FF,True,2);
  Canvas.LabelText('海風リーグ  LIVE',687,32,240,21,$FFFFFF,True,1);
  if Scored and (T >= 11.71) and (T < 14.5) then
  begin
    Canvas.RoundRect(292,391,376,95,14,$1B2D53,0.94);
    Canvas.Fill(314,405,332,3,$5EFCCD,0.9);
    Canvas.LabelText('GOAL!',292,403,376,44,$C4FFEC,True,2);
    if AttackingHome then
      Canvas.LabelText('青波',298,458,360,18,$A7DFFF,True,2)
    else
      Canvas.LabelText('灯浜',298,458,360,18,$FFD1D4,True,2);
  end;
end;

end.
