unit TV_GameArcade;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 横スクロール、縦シューティング、ブロック崩しの映像を番組時刻から生成する。

interface

uses TV_Canvas;

// 提供された960×540の番組面に時刻 Time（秒）のゲーム映像を描く。
procedure DrawPlatformGame(Canvas: TTVCanvas; Time: Double);
procedure DrawShooterGame(Canvas: TTVCanvas; Time: Double);
procedure DrawBreakoutGame(Canvas: TTVCanvas; Time: Double);

implementation

uses System.Math, System.SysUtils, TV_Timeline, TV_GameArt;

procedure DrawRunner(Canvas: TTVCanvas; X, Y, Stride: Single; Jumping: Boolean);
begin
  if Jumping then Stride := 10;
  Canvas.Transform(X,Y);
  try
    Canvas.Fill(-25,-68,40,31,$213452);
    Canvas.Fill(-18,-65,30,34,$FFD49A);
    Canvas.Fill(-22,-73,38,15,$F9B451);
    Canvas.Fill(-14,-48,30,24,$B24F49);
    Canvas.Path([M,-17,-46,L,-43,-39,L,-50,-27,L,-21,-31,L,-10,-38,Z],
      $EA6E65,'game.runner.scarf');
    Canvas.Fill(-13,-37,27,23,$4DABB4);
    Canvas.Fill(12,-35,12,11,$FFD49A);
    Canvas.Line(-8,-16,-10-Stride,-4,10,$213452);
    Canvas.Line(8,-16,9+Stride,-6,10,$356186);
    Canvas.Fill(-16-Stride,-7,16,7,$242A47);
    Canvas.Fill(4+Stride,-8,16,8,$242A47);
    Canvas.Fill(6,-58,6,7,$233251);
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure DrawPlatformGame(Canvas: TTVCanvas; Time: Double);
const
  Sky: array[0..2] of TTVColor = ($354C88,$573C81,$286D80);
  Horizon: array[0..2] of TTVColor = ($F7B977,$FF9A84,$EAD39A);
  Ridge: array[0..2] of TTVColor = ($636A91,$7E568C,$589199);
var
  Zone, Tile: TTVScene;
  I, Layer, Variant, TileIndex, Collected: Integer;
  X, Y, Scroll, Jump, EnemyX, GemX, GemY: Single;
  Detail: Cardinal;
begin
  Zone := TVSceneAt(Time,32);
  Tile := TVSceneAt(Time,1);
  Variant := Zone.Choice(65,3);
  Canvas.Shade(0,0,960,540,Sky[Variant],Horizon[Variant]);
  Canvas.Ellipse(751,156,62,62,$FFDF9D,0.83);
  for Layer := 0 to 1 do
  begin
    Scroll := TVCycle(Time,9-Layer*3)*245;
    for I := -1 to 5 do
    begin
      X := 245*I-Scroll;
      Y := 290+Layer*50+((I+5) mod 2)*32;
      Canvas.Path([M,X-70,435,L,X+90,Y,L,X+214,435,Z],
        TVColorMix(Ridge[Variant],$303D62,Layer*0.55));
    end;
  end;
  Canvas.Shade(0,412,960,128,$625675,$33324F);
  Scroll := Tile.Phase*240;
  for I := 0 to 5 do
  begin
    X := I*240-Scroll;
    TileIndex := Integer(Tile.Index)+I;
    Detail := TVHash(Cardinal(TileIndex));
    Canvas.Fill(X,410,177,130,$493550);
    Canvas.Fill(X,410,177,10,$66D4AD);
    Canvas.Fill(X+4,420,169,11,$3F957E);
    Canvas.Fill(X+17,446,82,15,$64435F);
    Canvas.Fill(X+95,475,72,17,$593D59);
    Canvas.Fill(X+14,511,106,8,$513D60);
    if (Detail and 3)=0 then
      Canvas.Path([M,X+175,517,L,X+190,456,L,X+203,483,L,X+221,432,L,X+239,517,Z],$39354F);
    if (Detail and 3)=1 then
    begin
      EnemyX := X+146+3*Sin(Time*5+TileIndex);
      Y := 397-2*Abs(Sin(Time*8+TileIndex));
      Canvas.RoundRect(EnemyX-19,Y-10,38,22,7,$72364F);
      Canvas.Fill(EnemyX-13,Y-8,26,10,$D67877);
      Canvas.Fill(EnemyX-8,Y-5,5,5,$FFF4C7);
      Canvas.Fill(EnemyX+4,Y-5,5,5,$FFF4C7);
      Canvas.Line(EnemyX-18,Y+4,EnemyX-24,407,6,$372940);
      Canvas.Line(EnemyX+18,Y+4,EnemyX+24,407,6,$372940);
    end;
    GemX := X+157;
    GemY := 315-5*Sin(Time*7+TileIndex);
    if GemX>245 then
      GameDiamond(Canvas,GemX,GemY,11+4*Abs(Sin(Time*6)),17,$FFE274)
    else
      GameBurst(Canvas,GemX,GemY,22,(245-GemX)/72,$FFE274);
  end;
  // 足場の縁から跳び、谷を越えて次の足場へ着地する。
  Jump := Max(0.0,Sin(2*Pi*TVCycle(Tile.Age+0.44,1)))*102;
  DrawRunner(Canvas,237,410-Jump,10*Sin(Time*21),Jump>3);
  Collected := Integer(Tile.Index mod 10000)+Ord(Tile.Age>=0.63);
  Canvas.Fill(0,0,960,58,$211D37,0.91);
  Canvas.LabelText('SKY COURIER',26,9,270,25,$FFF1CD,True);
  Canvas.LabelText(Format('ZONE %2.2d',[Zone.Index mod 99+1]),350,11,260,22,$ADEBDC,True,2);
  GameDiamond(Canvas,755,27,10,15,$FFE274);
  Canvas.LabelText(Format('%4.4d',[Collected mod 10000]),
    781,10,151,24,$FFF1CD,True,1);
end;

procedure DrawShip(Canvas: TTVCanvas; X, Y, Scale: Single; Friendly: Boolean);
begin
  Canvas.Transform(X,Y,Scale);
  try
    if Friendly then
    begin
      Canvas.Path([M,0,-31,L,13,-4,L,38,14,L,38,24,L,12,17,L,0,26,L,-12,17,
        L,-38,24,L,-38,14,L,-13,-4,Z],$82DDEF,'game.shooter.player');
      Canvas.Path([M,0,-29,L,10,6,L,0,17,L,-10,6,Z],$E4FEFE,'game.shooter.cockpit');
    end
    else
    begin
      Canvas.Path([M,-34,-19,L,-17,-11,L,0,-17,L,17,-11,L,34,-19,L,26,10,L,0,26,
        L,-26,10,Z],$E85982,'game.shooter.enemy');
      Canvas.Ellipse(0,4,13,9,$FFC591);
    end;
  finally
    Canvas.Transform(0,0);
  end;
end;

function ShooterX(Time: Double): Single;
begin
  Result := 480+155*Sin(Time*0.71)+66*Sin(Time*1.73);
end;

procedure DrawShooterGame(Canvas: TTVCanvas; Time: Double);
const
  VolleySeconds = 1.25;
var
  Wave, Attack: TTVScene;
  X, Y, P, Fired, HitX, WingX, WingY: Single;
  I, Shot, Target, FirstVolley: Integer;
  Star: Cardinal;
  Launched, Now, HitTime: Double;
begin
  Wave := TVSceneAt(Time,40);
  Canvas.Shade(0,0,960,540,$101733,$281348);
  Canvas.Ellipse(690,267,180,149,$734394,0.24);
  Canvas.Ellipse(690,267,157,128,$39336A,0.85);
  Canvas.Ellipse(733,240,120,98,$423A76);
  Canvas.Line(515,332,868,191,5,$8576BF,0.44);
  for I := 0 to 89 do
  begin
    Star := TVHash(Cardinal(I)+718);
    X := Star mod 960;
    Y := TVCycle(Time+((Star shr 10) mod 541)/27,7+(I mod 3)*5)*540;
    Canvas.Fill(X,Y,1+I mod 3,2+2*(I mod 3),$BDDAFF,0.35+(I mod 4)*0.14);
  end;
  Now := Time;
  Attack := TVSceneAt(Now,VolleySeconds);
  FirstVolley := Integer(Attack.Index)-2;
  for Target := FirstVolley to Integer(Attack.Index)+1 do
  begin
    HitTime := Target*VolleySeconds+0.68;
    HitX := ShooterX(Round((HitTime-(428-255)/440)*10)*0.1);
    P := (Now-HitTime)/0.72;
    if (P>=-1.8) and (P<0) then
    begin
      X := HitX+Sin(P*2.6)*94;
      Y := 255+P*166;
      DrawShip(Canvas,X,Y,0.88,False);
      Canvas.Line(X,Y-18,X,Y-35,3,$F481A2,0.72);
      if (Target mod 3<>1) then
      begin
        WingX := X+(1-2*(Target and 1))*(72+25*Sin(P*3));
        WingY := Y+74;
        DrawShip(Canvas,WingX,WingY,0.47,False);
      end;
    end;
    if (P>=0) and (P<1) then
    begin
      GameBurst(Canvas,HitX,255,53,P,$FFB272);
      if Target mod 3<>1 then
        GameBurst(Canvas,HitX+(1-2*(Target and 1))*72,329,28,P,$F98BB1);
    end;
    if (P>=-0.23) and (P<0.6) then
    begin
      X := HitX+83+24*Sin(P*4);
      Y := 268+(P+0.23)*315;
      Canvas.Line(X,Y-18,X,Y,4,$FF81A0);
    end;
  end;
  for Shot := 0 to 9 do
  begin
    Launched := (Floor(Now*10)-Shot)*0.1;
    Fired := Now-Launched;
    X := ShooterX(Launched);
    Y := 428-440*Fired;
    Canvas.Line(X-7,Y,X-7,Y-16,3,$8AFFF4);
    Canvas.Line(X+7,Y,X+7,Y-16,3,$8AFFF4);
  end;
  X := ShooterX(Now);
  Canvas.Path([M,X-12,462,L,X,507+7*Sin(Now*40),L,X+12,462,Z],$3CAFFF,'',0.72);
  DrawShip(Canvas,X,449,1,True);
  Canvas.Fill(0,0,960,55,$0C122B,0.94);
  Canvas.LabelText('ION PATROL',25,10,266,24,$9AF5FC,True);
  Canvas.LabelText(Format('WAVE %2.2d',[Wave.Index mod 99+1]),355,11,250,22,$C9CFF8,True,2);
  Canvas.LabelText(Format('%6.6d  PTS',[((Integer(Attack.Index mod 8000)+Ord(Attack.Age>=0.68)) mod 8000)*125]),
    720,10,215,24,$FFCEAE,True,1);
end;

const
  BreakColumns = 12;
  BreakRows = 5;
  BreakLeft = 122;
  BreakRight = 838;
  BreakTop = 64;
  BrickTop = 94;
  BrickPitchX = 57;
  BrickPitchY = 26;
  BrickWidth = 52;
  BrickHeight = 20;
  BrickLeft = 141;
  PaddleY = 482;
  PaddleHalf = 51;
  BallRadius = 8;
  BreakStep = 1/120;
  BreakDuration = 24.0;

type
  TBreakout = record
    X, Y, VX, VY, Paddle, FlashAge, FlashX, FlashY: Double;
    Bricks: array[0..BreakRows-1,0..BreakColumns-1] of Boolean;
    Hits: Integer;
  end;

procedure StepBreakout(var Game: TBreakout; Age: Double);
var
  NextX, NextY, Target, Offset, BX, BY: Double;
  Row, Column: Integer;
begin
  Game.FlashAge := Game.FlashAge+BreakStep;
  Target := Game.X+24*Sin(Age*3.6);
  Game.Paddle := EnsureRange(Game.Paddle+EnsureRange(Target-Game.Paddle,-5.0,5.0),
    BreakLeft+PaddleHalf,BreakRight-PaddleHalf);
  NextX := Game.X+Game.VX*BreakStep;
  NextY := Game.Y+Game.VY*BreakStep;
  if (NextX<BreakLeft+BallRadius) or (NextX>BreakRight-BallRadius) then
  begin
    NextX := EnsureRange(NextX,BreakLeft+BallRadius,BreakRight-BallRadius);
    Game.VX := -Game.VX;
  end;
  if NextY<BreakTop+BallRadius then
  begin
    NextY := BreakTop+BallRadius;
    Game.VY := Abs(Game.VY);
  end;
  if (Game.VY>0) and (NextY>=PaddleY-BallRadius) then
  begin
    NextY := PaddleY-BallRadius;
    Offset := (NextX-Game.Paddle)/PaddleHalf;
    Game.VX := 285*Offset+125*Sin(Age*3.2);
    Game.VY := -332;
  end;
  if (NextY>=BrickTop-BallRadius) and
    (NextY<=BrickTop+BreakRows*BrickPitchY+BallRadius) then
    for Row := 0 to BreakRows-1 do
    begin
      BY := BrickTop+Row*BrickPitchY;
      if (NextY+BallRadius<BY) or (NextY-BallRadius>BY+BrickHeight) then Continue;
      for Column := 0 to BreakColumns-1 do
      begin
        BX := BrickLeft+Column*BrickPitchX;
        if not Game.Bricks[Row,Column] or (NextX+BallRadius<BX) or
          (NextX-BallRadius>BX+BrickWidth) then Continue;
        Game.Bricks[Row,Column] := False;
        Inc(Game.Hits);
        Game.FlashAge := 0;
        Game.FlashX := BX+BrickWidth/2;
        Game.FlashY := BY+BrickHeight/2;
        if (Game.Y+BallRadius<=BY) or (Game.Y-BallRadius>=BY+BrickHeight) then
        begin
          Game.VY := -Game.VY;
          NextY := Game.Y;
        end
        else
        begin
          Game.VX := -Game.VX;
          NextX := Game.X;
        end;
        Break;
      end;
      if Game.FlashAge=0 then Break;
    end;
  Game.X := NextX;
  Game.Y := NextY;
end;

procedure DrawBreakoutGame(Canvas: TTVCanvas; Time: Double);
const
  Colors: array[0..4] of TTVColor = ($EC6D7B,$F79B6E,$F3CF73,$63C9AC,$63ADDF);
var
  RoundInfo: TTVScene;
  Game: TBreakout;
  Row, Column, Step: Integer;
  X, Y, Fraction: Single;
  Color: TTVColor;
begin
  RoundInfo := TVSceneAt(Time,BreakDuration);
  Game := Default(TBreakout);
  Game.X := 385+180*RoundInfo.Variation(81);
  Game.Y := 430;
  Game.VX := 112+130*RoundInfo.Variation(82);
  Game.VY := -315;
  Game.Paddle := Game.X;
  Game.FlashAge := 1;
  for Row := 0 to BreakRows-1 do
    for Column := 0 to BreakColumns-1 do
      Game.Bricks[Row,Column] := (RoundInfo.Index=0) or (Row<2) or
        (((Column+2*Row+Integer(RoundInfo.Index mod 5)) mod 11)<>0);
  // 1 ラウンド分だけを再計算するので逆シークと長時間の再生で挙動が変わらない。
  for Step := 1 to Trunc(RoundInfo.Age/BreakStep) do StepBreakout(Game,Step*BreakStep);
  Fraction := Frac(RoundInfo.Age/BreakStep);
  X := Game.X+Game.VX*BreakStep*Fraction;
  Y := Game.Y+Game.VY*BreakStep*Fraction;
  Canvas.Shade(0,0,960,540,$161A31,$282546);
  Canvas.Fill(BreakLeft,BreakTop,BreakRight-BreakLeft,451,$0E1528);
  for Column := 0 to BreakColumns do
    Canvas.Line(139+Column*57,76,139+Column*57,514,1,$54628A,0.2);
  for Row := 0 to 8 do Canvas.Line(122,94+Row*49,838,94+Row*49,1,$54628A,0.2);
  Canvas.Line(BreakLeft,64,BreakRight,64,4,$768CC0);
  Canvas.Line(BreakLeft,64,BreakLeft,514,4,$768CC0);
  Canvas.Line(BreakRight,64,BreakRight,514,4,$768CC0);
  for Row := 0 to BreakRows-1 do
    for Column := 0 to BreakColumns-1 do
      if Game.Bricks[Row,Column] then
      begin
        Color := Colors[(Row+Integer(RoundInfo.Index mod 5)) mod 5];
        Canvas.RoundRect(BrickLeft+Column*BrickPitchX,BrickTop+Row*BrickPitchY,BrickWidth,BrickHeight,4,Color);
        Canvas.Fill(BrickLeft+Column*BrickPitchX+5,BrickTop+Row*BrickPitchY+3,BrickWidth-10,3,$FFFFFF,0.34);
      end;
  GameBurst(Canvas,Game.FlashX,Game.FlashY,27,Game.FlashAge/0.24,$FFD695);
  Canvas.Ellipse(X,Y,BallRadius+5,BallRadius+5,$8BD8FF,0.24);
  Canvas.Ellipse(X,Y,BallRadius,BallRadius,$F3FCFF);
  Canvas.RoundRect(Game.Paddle-PaddleHalf,PaddleY,PaddleHalf*2,16,7,$5D9BDF);
  Canvas.Fill(Game.Paddle-PaddleHalf+11,PaddleY+3,PaddleHalf*2-22,4,$C5F1FF);
  Canvas.LabelText('PRISM WALL',25,12,255,25,$ACCBFB,True);
  Canvas.LabelText(Format('ROUND %2.2d',[RoundInfo.Index mod 99+1]),350,14,260,22,$FFF0D2,True,2);
  Canvas.LabelText(Format('%6.6d  PTS',[Integer(RoundInfo.Index mod 200)*2400+Game.Hits*100]),
    690,12,244,25,$FFF0D2,True,1);
end;

end.
