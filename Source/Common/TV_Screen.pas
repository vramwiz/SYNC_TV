unit TV_Screen;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 番組映像から液晶画面を合成し、必要な場合に四隅を射影変形する。

interface

uses
  AviUtl2FilterTypes, System.Types, TV_Canvas, TV_Timeline;

type
  TTVPixels = TArray<TPIXEL_RGBA>;
  TTVCorners = array[0..3] of TPointF; // 左上、右上、右下、左下。

  TTVSettings = record
    Channel: Integer;
    Body: Boolean;
    Aspect, CornerRadius, Ambient: Double;
    Corners: TTVCorners;
  end;

  TTVScreen = class
  private
    FCanvas: TTVCanvas;
    FLastChannel: Integer;
    FLastTime: Double;
    FPanel: TTVPixels;
    procedure PaintPanel(const Settings: TTVSettings; const Signal: TTVSignal;
      out Width, Height, ScreenW, ScreenH: Integer);
  public
    destructor Destroy; override;
    // Pixels は呼出側の再利用バッファ。補正後も画像中心を同じ座標に保つ。
    procedure Render(const Settings: TTVSettings; const Signal: TTVSignal;
      var Pixels: TTVPixels; out Width, Height: Integer);
  end;

implementation

uses
  System.Math, System.SysUtils, TV_Programs;

{$POINTERMATH ON}

type
  TProjectiveMap = record
    A, B, C, D, E, F, G, H, I: Double;
    function InverseOfQuad(const Quad: TTVCorners; out Forward: TProjectiveMap): Boolean;
  end;

function Cross(const A,B,C: TPointF): Double;
begin
  Result := (B.X-A.X)*(C.Y-B.Y) - (B.Y-A.Y)*(C.X-B.X);
end;

function TProjectiveMap.InverseOfQuad(const Quad: TTVCorners; out Forward: TProjectiveMap): Boolean;
var
  S1, S2, S3: TPointF;
  P, Q, R, U, V, W, L, M, Det: Double;
  Index: Integer;
begin
  Result := False;
  for Index := 0 to 3 do
    if Cross(Quad[Index],Quad[(Index+1) mod 4],Quad[(Index+2) mod 4]) <= 1 then Exit;
  S1 := PointF(Quad[1].X-Quad[2].X,Quad[1].Y-Quad[2].Y);
  S2 := PointF(Quad[3].X-Quad[2].X,Quad[3].Y-Quad[2].Y);
  S3 := PointF(Quad[0].X-Quad[1].X+Quad[2].X-Quad[3].X,
               Quad[0].Y-Quad[1].Y+Quad[2].Y-Quad[3].Y);
  Det := S1.X*S2.Y-S2.X*S1.Y;
  if Abs(Det)<0.0001 then Exit;
  L := (S3.X*S2.Y-S2.X*S3.Y)/Det;
  M := (S1.X*S3.Y-S3.X*S1.Y)/Det;
  if (1+L <= 1E-6) or (1+M <= 1E-6) or (1+L+M <= 1E-6) then Exit;
  P := Quad[1].X*(1+L)-Quad[0].X;
  Q := Quad[3].X*(1+M)-Quad[0].X;
  R := Quad[0].X;
  U := Quad[1].Y*(1+L)-Quad[0].Y;
  V := Quad[3].Y*(1+M)-Quad[0].Y;
  W := Quad[0].Y;
  Forward.A := P;
  Forward.B := Q;
  Forward.C := R;
  Forward.D := U;
  Forward.E := V;
  Forward.F := W;
  Forward.G := L;
  Forward.H := M;
  Forward.I := 1;
  // 逆行列は斉次座標で使うため共通の行列式による除算は不要。
  A := V-W*M;
  B := R*M-Q;
  C := Q*W-R*V;
  D := W*L-U;
  E := P-R*L;
  F := R*U-P*W;
  G := U*M-V*L;
  H := Q*L-P*M;
  I := P*V-Q*U;
  Result := True;
end;

function RoundedDistance(X,Y,HalfWidth,HalfHeight,Radius: Double): Double;
var
  DX, DY: Double;
begin
  DX := Abs(X)-HalfWidth+Radius;
  DY := Abs(Y)-HalfHeight+Radius;
  if (DX>0) and (DY>0) then
    Result := Sqrt(DX*DX+DY*DY)-Radius
  else
    Result := Max(DX,DY)-Radius;
end;

function Pixel(R,G,B,A: Double): TPIXEL_RGBA;
begin
  Result.R := Round(EnsureRange(R,0.0,255.0));
  Result.G := Round(EnsureRange(G,0.0,255.0));
  Result.B := Round(EnsureRange(B,0.0,255.0));
  Result.A := Round(EnsureRange(A,0.0,255.0));
  if Result.A = 0 then Result := Default(TPIXEL_RGBA);
end;

function Overlay(const Fore, Back: TPIXEL_RGBA): TPIXEL_RGBA;
var
  A, B, Total: Double;
begin
  if (Fore.A=255) or (Back.A=0) then Exit(Fore);
  if Fore.A=0 then Exit(Back);
  A := Fore.A;
  B := Back.A*(255-A)/255;
  Total := A+B;
  Result := Pixel((Fore.R*A+Back.R*B)/Total,(Fore.G*A+Back.G*B)/Total,
    (Fore.B*A+Back.B*B)/Total,Total);
end;

function Sample(const Buffer: TTVPixels; Width, Height: Integer; X,Y: Double): TPIXEL_RGBA;
var
  Xi,Yi, Xj,Yj: Integer;
  P0,P1,P2,P3: TPIXEL_RGBA;
  SX,SY,W0,W1,W2,W3,A: Double;
begin
  X := X*Width-0.5;
  Y := Y*Height-0.5;
  Xi := Floor(X);
  Yi := Floor(Y);
  Xj := Xi+1;
  Yj := Yi+1;
  SX := X-Xi;
  SY := Y-Yi;
  P0 := Default(TPIXEL_RGBA);
  P1 := P0;
  P2 := P0;
  P3 := P0;
  if (Xi>=0) and (Xi<Width) and (Yi>=0) and (Yi<Height) then P0 := Buffer[Yi*Width+Xi];
  if (Xj>=0) and (Xj<Width) and (Yi>=0) and (Yi<Height) then P1 := Buffer[Yi*Width+Xj];
  if (Xi>=0) and (Xi<Width) and (Yj>=0) and (Yj<Height) then P2 := Buffer[Yj*Width+Xi];
  if (Xj>=0) and (Xj<Width) and (Yj>=0) and (Yj<Height) then P3 := Buffer[Yj*Width+Xj];
  W0 := (1-SX)*(1-SY)*P0.A;
  W1 := SX*(1-SY)*P1.A;
  W2 := (1-SX)*SY*P2.A;
  W3 := SX*SY*P3.A;
  A := W0+W1+W2+W3;
  if A<0.5 then Exit(Default(TPIXEL_RGBA));
  Result := Pixel((P0.R*W0+P1.R*W1+P2.R*W2+P3.R*W3)/A,
    (P0.G*W0+P1.G*W1+P2.G*W2+P3.G*W3)/A,(P0.B*W0+P1.B*W1+P2.B*W2+P3.B*W3)/A,A);
end;

procedure Warp(const Source: TTVPixels; SourceWidth,SourceHeight,ScreenW,ScreenH: Integer;
  const Corrections: TTVCorners; var Dest: TTVPixels; out Width,Height: Integer);
var
  Quad: TTVCorners;
  Map, Forward: TProjectiveMap;
  Index,X,Y: Integer;
  EdgeX,EdgeY,U,V,W,Xc,Yc,RowA,RowB,RowC,
  HalfScreenW, HalfScreenH, ScaleX, ScaleY: Double;
  HasOffsets, ValidQuad: Boolean;
  P: PPIXEL_RGBA;
begin
  Width := SourceWidth;
  Height := SourceHeight;
  HalfScreenW := ScreenW*0.5;
  HalfScreenH := ScreenH*0.5;
  Quad[0] := PointF(-HalfScreenW,-HalfScreenH);
  Quad[1] := PointF(HalfScreenW,-HalfScreenH);
  Quad[2] := PointF(HalfScreenW,HalfScreenH);
  Quad[3] := PointF(-HalfScreenW,HalfScreenH);
  HasOffsets := False;
  for Index := 0 to High(Quad) do
  begin
    HasOffsets := HasOffsets or (Corrections[Index].X<>0) or (Corrections[Index].Y<>0);
    Quad[Index].X := Quad[Index].X+Corrections[Index].X;
    Quad[Index].Y := Quad[Index].Y+Corrections[Index].Y;
  end;
  ValidQuad := HasOffsets and Map.InverseOfQuad(Quad,Forward);
  EdgeX := 0;
  EdgeY := 0;
  ScaleX := ScreenW/SourceWidth;
  ScaleY := ScreenH/SourceHeight;
  if ValidQuad then
    for Index := 0 to 3 do
    begin
      // 四隅は液晶面の座標。ベゼルやスタンドは同じ射影の範囲を外へ延長する。
      U := 0.5 + (Ord(Index in [1,2])-0.5)/ScaleX;
      V := 0.5 + (Ord(Index in [2,3])-0.5)/ScaleY;
      W := Forward.G*U+Forward.H*V+1;
      if W<=1E-6 then
      begin
        ValidQuad := False;
        Break;
      end;
      EdgeX := Max(EdgeX,Abs((Forward.A*U+Forward.B*V+Forward.C)/W));
      EdgeY := Max(EdgeY,Abs((Forward.D*U+Forward.E*V+Forward.F)/W));
    end;
  if not ValidQuad or (EdgeX>1600) or (EdgeY>1600) then
  begin
    SetLength(Dest,Length(Source));
    Move(Source[0],Dest[0],Length(Source)*SizeOf(TPIXEL_RGBA));
    Exit;
  end;
  Width := 2*Ceil(EdgeX+1);
  Height := 2*Ceil(EdgeY+1);
  SetLength(Dest,Width*Height);
  P := @Dest[0];
  for Y := 0 to Height-1 do
  begin
    Yc := Y-Height*0.5+0.5;
    RowA := Map.B*Yc+Map.C;
    RowB := Map.E*Yc+Map.F;
    RowC := Map.H*Yc+Map.I;
    for X := 0 to Width-1 do
    begin
      Xc := X-Width*0.5+0.5;
      W := Map.G*Xc+RowC;
      P^ := Default(TPIXEL_RGBA);
      if Abs(W)>1E-7 then
      begin
        U := 0.5 + ((Map.A*Xc+RowA)/W-0.5)*ScaleX;
        V := 0.5 + ((Map.D*Xc+RowB)/W-0.5)*ScaleY;
        if (U>=-0.5/SourceWidth) and (U<=1+0.5/SourceWidth) and
           (V>=-0.5/SourceHeight) and (V<=1+0.5/SourceHeight) then
          P^ := Sample(Source,SourceWidth,SourceHeight,U,V);
      end;
      Inc(P);
    end;
  end;
end;

procedure ReadProgramColor(Source: PTVBGRAPixel; X,Y: Double; Exact: Boolean;
  out R,G,B: Double);
var
  X0,Y0,X1,Y1: Integer;
  FX,FY: Double;
  P0,P1,P2,P3: PTVBGRAPixel;
begin
  if Exact then
  begin
    P0 := Source+Trunc(Y)*TV_PROGRAM_WIDTH+Trunc(X);
    R := P0^.R;
    G := P0^.G;
    B := P0^.B;
    Exit;
  end;
  X := EnsureRange(X-0.5,0.0,TV_PROGRAM_WIDTH-1.0);
  Y := EnsureRange(Y-0.5,0.0,TV_PROGRAM_HEIGHT-1.0);
  X0 := Trunc(X);
  Y0 := Trunc(Y);
  X1 := Min(X0+1,TV_PROGRAM_WIDTH-1);
  Y1 := Min(Y0+1,TV_PROGRAM_HEIGHT-1);
  FX := X-X0;
  FY := Y-Y0;
  P0 := Source+Y0*TV_PROGRAM_WIDTH+X0;
  P1 := Source+Y0*TV_PROGRAM_WIDTH+X1;
  P2 := Source+Y1*TV_PROGRAM_WIDTH+X0;
  P3 := Source+Y1*TV_PROGRAM_WIDTH+X1;
  R := TVLerp(TVLerp(P0^.R,P1^.R,FX),TVLerp(P2^.R,P3^.R,FX),FY);
  G := TVLerp(TVLerp(P0^.G,P1^.G,FX),TVLerp(P2^.G,P3^.G,FX),FY);
  B := TVLerp(TVLerp(P0^.B,P1^.B,FX),TVLerp(P2^.B,P3^.B,FX),FY);
end;

destructor TTVScreen.Destroy;
begin
  FCanvas.Free;
  inherited;
end;

procedure TTVScreen.PaintPanel(const Settings: TTVSettings; const Signal: TTVSignal;
  out Width,Height,ScreenW,ScreenH: Integer);
const
  LedX = 18;
var
  PaddingX,PaddingY,Bezel,GlowSize,X,Y,Row,Column,Count: Integer;
  HalfWidth,HalfHeight,Radius,Ambient,Glow,GlowR,GlowG,GlowB,Emit,Wash,Black: Double;
  XP,YP,Dist,PanelDist,Stand,Shine,Reflection,Alpha,Scale,SampleX,SampleY,
  Red,Green,Blue,SourceR,SourceG,SourceB,LedY,Darkness: Double;
  Source,Video: PTVBGRAPixel;
  Target: PPIXEL_RGBA;
  Back, Fore: TPIXEL_RGBA;
  DrawVideo, NativeSize: Boolean;
begin
  if Settings.Aspect<=0 then
  begin
    ScreenW := TV_PROGRAM_WIDTH;
    ScreenH := Round(ScreenW*(1+Settings.Aspect/100));
  end
  else
  begin
    ScreenH := TV_PROGRAM_WIDTH;
    ScreenW := Round(ScreenH*(1-Settings.Aspect/100));
  end;
  HalfWidth := 0.5*ScreenW;
  HalfHeight := 0.5*ScreenH;
  Radius := Min(Settings.CornerRadius,Min(HalfWidth,HalfHeight));
  Ambient := Settings.Ambient/100;
  Darkness := Sqr(1-Ambient);
  DrawVideo := (Signal.Channel>0) and (Signal.Light>0.0001);
  Source := nil;
  GlowR := 0;
  GlowG := 0;
  GlowB := 0;
  if DrawVideo then
  begin
    if FCanvas=nil then
    begin
      FCanvas := TTVCanvas.Create;
      FLastChannel := -1;
    end;
    if (FLastChannel<>Signal.Channel) or
      ((Signal.Channel<>2) and (FLastTime<>Signal.ProgramTime)) then
    begin
      try
        DrawTVProgram(FCanvas,Signal.Channel,Signal.ProgramTime);
      except
        FreeAndNil(FCanvas);
        raise;
      end;
      FLastChannel := Signal.Channel;
      FLastTime := Signal.ProgramTime;
    end;
    Source := FCanvas.Pixels;
    Count := 0;
    for Row := 0 to 6 do
      for Column := 0 to 31 do
      begin
        Video := Source+(Row*79+17)*TV_PROGRAM_WIDTH+Column*30+14;
        GlowR := GlowR+Video^.R;
        GlowG := GlowG+Video^.G;
        GlowB := GlowB+Video^.B;
        Inc(Count);
      end;
    GlowR := 29+0.86*GlowR/Count;
    GlowG := 29+0.86*GlowG/Count;
    GlowB := 34+0.86*GlowB/Count;
  end;
  Glow := Signal.Light*Darkness*(GlowR*0.2126+GlowG*0.7152+GlowB*0.0722)*0.35;
  GlowSize := 18;
  Bezel := 0;
  if Settings.Body then Bezel := 8;
  PaddingX := Bezel;
  PaddingY := Bezel;
  if Glow>=1 then
  begin
    PaddingX := PaddingX+GlowSize;
    PaddingY := PaddingY+GlowSize;
  end;
  if Settings.Body then PaddingY := Max(PaddingY,45);
  Width := ScreenW+2*PaddingX;
  Height := ScreenH+2*PaddingY;
  SetLength(FPanel,Width*Height);
  Target := @FPanel[0];

  Scale := Min(ScreenW/TV_PROGRAM_WIDTH,ScreenH/TV_PROGRAM_HEIGHT);
  NativeSize := Scale=1;
  Black := 2+17*Ambient;
  Wash := 18*Ambient;
  Emit := Signal.Light*(1-0.115*Ambient);
  LedY := HalfHeight+4.4;
  for Y := 0 to Height-1 do
  begin
    YP := Y-Height*0.5+0.5;
    SampleY := YP/Scale+TV_PROGRAM_HEIGHT*0.5;
    for X := 0 to Width-1 do
    begin
      XP := X-Width*0.5+0.5;
      Dist := RoundedDistance(XP,YP,HalfWidth,HalfHeight,Radius);
      Back := Default(TPIXEL_RGBA);
      if (Dist>=0) and ((Abs(XP)>HalfWidth) or (Abs(YP)>HalfHeight)) and (Glow>=1) then
      begin
        Alpha := Glow*Sqr(TVClamp(1-Max(0.0,Dist-Bezel)/GlowSize));
        Back := Pixel(GlowR,GlowG,GlowB,Alpha);
      end;
      if Settings.Body then
      begin
        Stand := Min(64.0,HalfWidth*0.43);
        if (YP>=HalfHeight+4) and (YP<HalfHeight+35) then
        begin
          Alpha := TVClamp(Stand*0.27+0.5-Abs(XP))*TVClamp(HalfHeight+33.5-YP);
          Back := Overlay(Pixel(10+25*Ambient,12+24*Ambient,16+27*Ambient,255*Alpha),Back);
          Alpha := TVClamp(0.5-RoundedDistance(XP,YP-HalfHeight-33,Stand,4,2.8));
          Back := Overlay(Pixel(12+32*Ambient,15+32*Ambient,19+34*Ambient,255*Alpha),Back);
        end;
        PanelDist := RoundedDistance(XP,YP,HalfWidth+Bezel,HalfHeight+Bezel,Max(4.0,Radius+4));
        if PanelDist<0.5 then
        begin
          Shine := Ambient*(4+10*TVClamp(-YP/HalfHeight)+33*TVClamp(PanelDist+1.0));
          Back := Overlay(Pixel(8+Shine,10+Shine,13+Shine,255*TVClamp(0.5-PanelDist)),Back);
        end;
      end;
      if Dist<0.5 then
      begin
        Reflection := Ambient*(11*Sqr(TVClamp((2.8-2.3*YP/HalfHeight-XP/HalfWidth)/5))+
          9*Sqr(TVClamp((0.17-Abs(XP/HalfWidth+0.64*YP/HalfHeight+0.36))/0.17)));
        Red := Black+Reflection;
        Green := Black+Reflection+1.4*Ambient;
        Blue := Black+Reflection+3.1*Ambient;
        if DrawVideo then
        begin
          SampleX := XP/Scale+TV_PROGRAM_WIDTH*0.5;
          if (SampleX>=0) and (SampleX<TV_PROGRAM_WIDTH) and
             (SampleY>=0) and (SampleY<TV_PROGRAM_HEIGHT) then
          begin
            ReadProgramColor(Source,SampleX,SampleY,NativeSize,SourceR,SourceG,SourceB);
            Red := Red+Emit*(SourceR+Wash*0.25-Black);
            Green := Green+Emit*(SourceG+Wash*0.26-Black);
            Blue := Blue+Emit*(SourceB+Wash*0.32-Black);
          end;
        end;
        Fore := Pixel(Red,Green,Blue,255*TVClamp(0.5-Dist));
        Back := Overlay(Fore,Back);
      end;
      if Settings.Body and (Abs(XP-HalfWidth+LedX)<4) and (Abs(YP-LedY)<3) then
      begin
        Alpha := TVClamp(1-(Sqr((XP-HalfWidth+LedX)/3.8)+Sqr((YP-LedY)/2.7)));
        Back := Overlay(Pixel(TVLerp(196,94,Signal.Indicator),
          TVLerp(57,231,Signal.Indicator),TVLerp(52,204,Signal.Indicator),Alpha*246),Back);
      end;
      Target^ := Back;
      Inc(Target);
    end;
  end;
end;

procedure TTVScreen.Render(const Settings: TTVSettings; const Signal: TTVSignal;
  var Pixels: TTVPixels; out Width, Height: Integer);
var
  PanelWidth, PanelHeight, ScreenW, ScreenH: Integer;
begin
  PaintPanel(Settings,Signal,PanelWidth,PanelHeight,ScreenW,ScreenH);
  Warp(FPanel,PanelWidth,PanelHeight,ScreenW,ScreenH,Settings.Corners,Pixels,Width,Height);
end;

end.
