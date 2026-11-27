unit TV_GameArt;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// ゲーム映像で使うゲージ、宝石、衝突エフェクト。描画資源は呼び出し元の Canvas が所有する。

interface

uses TV_Canvas;

// 座標と半径は番組面上のピクセル。Progress は 0～1。
procedure GameDiamond(Canvas: TTVCanvas; X, Y, RX, RY: Single; Color: TTVColor);
procedure GameBurst(Canvas: TTVCanvas; X, Y, Radius, Progress: Single; Color: TTVColor);
procedure GameMeter(Canvas: TTVCanvas; X, Y, W, H, Fraction: Single;
  Color: TTVColor; FromRight: Boolean = False);

implementation

uses System.Math, TV_Timeline;

procedure GameDiamond(Canvas: TTVCanvas; X, Y, RX, RY: Single; Color: TTVColor);
begin
  Canvas.Path([M,X,Y-RY,L,X+RX,Y,L,X,Y+RY,L,X-RX,Y,Z],Color);
  Canvas.Path([M,X,Y-RY,L,X,Y+RY*0.16,L,X-RX,Y,Z],$FFFFFF,'',0.32);
  Canvas.Path([M,X+RX,Y,L,X,Y+RY,L,X,Y+RY*0.16,Z],$160C2A,'',0.28);
end;

procedure GameBurst(Canvas: TTVCanvas; X, Y, Radius, Progress: Single; Color: TTVColor);
var
  Index: Integer;
  Angle, Distance, Length, Opacity: Single;
begin
  if (Progress<0) or (Progress>=1) then Exit;
  Opacity := 1-Progress;
  Distance := Radius*(0.2+Progress*0.8);
  Canvas.Ellipse(X,Y,Radius*(0.15+Progress*0.72),Radius*(0.13+Progress*0.6),Color,Opacity*0.22);
  Canvas.Ellipse(X,Y,Radius*0.24*Opacity,Radius*0.24*Opacity,$FFFFFF,Opacity);
  for Index := 0 to 6 do
  begin
    Angle := Index*(2*Pi/7)+Progress*0.18;
    Length := Radius*(0.39-Progress*0.24);
    Canvas.Line(X+Cos(Angle)*Distance,Y+Sin(Angle)*Distance,
      X+Cos(Angle)*(Distance+Length),Y+Sin(Angle)*(Distance+Length),2+4*Opacity,Color,Opacity);
  end;
end;

procedure GameMeter(Canvas: TTVCanvas; X, Y, W, H, Fraction: Single;
  Color: TTVColor; FromRight: Boolean);
var
  FillWidth: Single;
begin
  Canvas.RoundRect(X,Y,W,H,5,$080B17,0.88);
  FillWidth := (W-8)*TVClamp(Fraction);
  if FillWidth<=0 then Exit;
  if FromRight then X := X+W-8-FillWidth;
  Canvas.Fill(X+4,Y+4,FillWidth,H-8,Color);
  Canvas.Fill(X+4,Y+4,FillWidth,4,$FFFFFF,0.42);
end;

end.
