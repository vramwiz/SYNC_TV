unit TV_Canvas;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// Direct2D / DirectWrite による 960×540 の番組描画。画素と各種資源は描画器が所有する。

interface

uses
  System.Types, System.Generics.Collections, Winapi.Windows, Winapi.D2D1;

const
  TV_PROGRAM_WIDTH = 960;
  TV_PROGRAM_HEIGHT = 540;

type
  TTVColor = Cardinal;
  TTVBGRAPixel = packed record
    B, G, R, A: Byte;
  end;
  PTVBGRAPixel = ^TTVBGRAPixel;

  TTVCanvas = class
  private
    FDC: HDC;
    FDIB: HBITMAP;
    FPreviousBitmap: HGDIOBJ;
    FPixels: PTVBGRAPixel;
    FFactory: ID2D1Factory;
    FTarget: ID2D1DCRenderTarget;
    FWrite: IDWriteFactory;
    FColor: ID2D1SolidColorBrush;
    FGradients: TDictionary<UInt64, ID2D1LinearGradientBrush>;
    FFormats: TDictionary<Integer, IDWriteTextFormat>;
    FPaths: TDictionary<string, ID2D1PathGeometry>;
    procedure SetColor(Color: TTVColor; Opacity: Single);
    function GradientBrush(X1, Y1, X2, Y2: Single; StartColor,
      EndColor: TTVColor; Opacity: Single): ID2D1LinearGradientBrush;
    function Geometry(const Commands: array of Single; const Key: string): ID2D1PathGeometry;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginFrame;
    procedure EndFrame;
    procedure Clear(Color: TTVColor);
    procedure Fill(X, Y, W, H: Single; Color: TTVColor; Opacity: Single = 1);
    procedure Shade(X, Y, W, H: Single; Top, Bottom: TTVColor; Opacity: Single = 1);
    procedure RoundRect(X, Y, W, H, Radius: Single; Color: TTVColor; Opacity: Single = 1);
    procedure Ellipse(X, Y, RX, RY: Single; Color: TTVColor; Opacity: Single = 1);
    procedure Line(X1, Y1, X2, Y2, Width: Single; Color: TTVColor; Opacity: Single = 1);
    procedure Path(const Commands: array of Single; Color: TTVColor;
      const Key: string = ''; Opacity: Single = 1);
    procedure Stroke(const Commands: array of Single; Color: TTVColor; Width: Single;
      const Key: string = ''; Opacity: Single = 1);
    procedure ShadePath(const Commands: array of Single; Top, Bottom: TTVColor;
      Y1, Y2: Single; const Key: string = ''; Opacity: Single = 1);
    procedure LabelText(const Value: string; X, Y, W: Single; Size: Integer;
      Color: TTVColor = $FFFFFF; Bold: Boolean = False; Align: Integer = 0);
    procedure Clip(X, Y, W, H: Single);
    procedure Unclip;
    procedure Transform(X, Y: Single; Scale: Single = 1; Flip: Boolean = False);
    property Pixels: PTVBGRAPixel read FPixels;
  end;

const
  // パスは M,x,y に続けて L,x,y / C,x1,y1,x2,y2,x,y / Z を並べる。
  M = 0;
  L = 1;
  C = 2;
  Z = 3;

function TVColorMix(First, Second: TTVColor; Amount: Single): TTVColor;

implementation

uses
  System.SysUtils, System.Win.ComObj, Winapi.DXGIFormat;

function CreateD2DFactory(FactoryType: D2D1_FACTORY_TYPE; const IID: TGUID;
  Options: PD2D1FactoryOptions; out Factory: ID2D1Factory): HRESULT; stdcall;
  external 'd2d1.dll' name 'D2D1CreateFactory';

function CreateWriteFactory(FactoryType: DWRITE_FACTORY_TYPE; const IID: TGUID;
  out Factory: IUnknown): HRESULT; stdcall;
  external 'dwrite.dll' name 'DWriteCreateFactory';

function TVColorMix(First, Second: TTVColor; Amount: Single): TTVColor;
var
  Shift, A, B: Integer;
begin
  Result := 0;
  for Shift in [0, 8, 16] do
  begin
    A := (First shr Shift) and $FF;
    B := (Second shr Shift) and $FF;
    Result := Result or (Cardinal(Round(A + (B - A) * Amount)) shl Shift);
  end;
end;

function DColor(Color: TTVColor; Opacity: Single): TD2D1ColorF;
begin
  Result := D2D1ColorF(((Color shr 16) and $FF) / 255, ((Color shr 8) and $FF) / 255,
    (Color and $FF) / 255, Opacity);
end;

constructor TTVCanvas.Create;
var
  Info: TBitmapInfo;
  RawWrite: IUnknown;
  Bounds: TRect;
  ScreenDC: HDC;
begin
  inherited Create;
  FGradients := TDictionary<UInt64, ID2D1LinearGradientBrush>.Create;
  FFormats := TDictionary<Integer, IDWriteTextFormat>.Create;
  FPaths := TDictionary<string, ID2D1PathGeometry>.Create;
  FillChar(Info, SizeOf(Info), 0);
  Info.bmiHeader.biSize := SizeOf(Info.bmiHeader);
  Info.bmiHeader.biWidth := TV_PROGRAM_WIDTH;
  Info.bmiHeader.biHeight := -TV_PROGRAM_HEIGHT;
  Info.bmiHeader.biPlanes := 1;
  Info.bmiHeader.biBitCount := 32;
  ScreenDC := GetDC(0);
  if ScreenDC = 0 then RaiseLastOSError;
  try
    // 生成元の描画スレッドが終了してもメモリDCを次の描画に再利用する。
    FDC := CreateCompatibleDC(ScreenDC);
    if FDC = 0 then RaiseLastOSError;
  finally
    ReleaseDC(0, ScreenDC);
  end;
  FDIB := CreateDIBSection(FDC, Info, DIB_RGB_COLORS, Pointer(FPixels), 0, 0);
  if FDIB = 0 then RaiseLastOSError;
  FPreviousBitmap := SelectObject(FDC, FDIB);
  if FPreviousBitmap = 0 then RaiseLastOSError;
  OleCheck(CreateD2DFactory(D2D1_FACTORY_TYPE_MULTI_THREADED,
    IID_ID2D1Factory, nil, FFactory));
  OleCheck(CreateWriteFactory(DWRITE_FACTORY_TYPE_SHARED, IID_IDWriteFactory, RawWrite));
  FWrite := RawWrite as IDWriteFactory;
  OleCheck(FFactory.CreateDCRenderTarget(D2D1RenderTargetProperties(
    D2D1_RENDER_TARGET_TYPE_SOFTWARE, D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM,
    D2D1_ALPHA_MODE_IGNORE), 96, 96), FTarget));
  Bounds := Rect(0, 0, TV_PROGRAM_WIDTH, TV_PROGRAM_HEIGHT);
  OleCheck(FTarget.BindDC(FDC, Bounds));
  FTarget.SetTextAntialiasMode(D2D1_TEXT_ANTIALIAS_MODE_GRAYSCALE);
  OleCheck(FTarget.CreateSolidColorBrush(DColor($FFFFFF, 1), nil, FColor));
end;

destructor TTVCanvas.Destroy;
begin
  FPaths.Free;
  FFormats.Free;
  FGradients.Free;
  FColor := nil;
  FTarget := nil;
  if FPreviousBitmap <> 0 then SelectObject(FDC, FPreviousBitmap);
  if FDIB <> 0 then DeleteObject(FDIB);
  if FDC <> 0 then DeleteDC(FDC);
  inherited;
end;

procedure TTVCanvas.BeginFrame;
begin
  FTarget.BeginDraw;
  Transform(0, 0);
end;

procedure TTVCanvas.EndFrame;
begin
  OleCheck(FTarget.EndDraw(nil, nil));
  GdiFlush;
end;

procedure TTVCanvas.SetColor(Color: TTVColor; Opacity: Single);
begin
  FColor.SetColor(DColor(Color, Opacity));
end;

function TTVCanvas.GradientBrush(X1, Y1, X2, Y2: Single; StartColor,
  EndColor: TTVColor; Opacity: Single): ID2D1LinearGradientBrush;
var
  Key: UInt64;
  Stops: ID2D1GradientStopCollection;
  Points: array[0..1] of TD2D1GradientStop;
  Props: TD2D1LinearGradientBrushProperties;
begin
  Key := (UInt64(StartColor) shl 32) or EndColor;
  if not FGradients.TryGetValue(Key, Result) then
  begin
    Points[0].position := 0;
    Points[0].color := DColor(StartColor, 1);
    Points[1].position := 1;
    Points[1].color := DColor(EndColor, 1);
    OleCheck(FTarget.CreateGradientStopCollection(@Points[0], Length(Points),
      D2D1_GAMMA_2_2, D2D1_EXTEND_MODE_CLAMP, Stops));
    Props.startPoint := D2D1PointF(X1, Y1);
    Props.endPoint := D2D1PointF(X2, Y2);
    OleCheck(FTarget.CreateLinearGradientBrush(Props, nil, Stops, Result));
    if FGradients.Count >= 128 then FGradients.Clear;
    FGradients.Add(Key, Result);
  end
  else
  begin
    Result.SetStartPoint(D2D1PointF(X1, Y1));
    Result.SetEndPoint(D2D1PointF(X2, Y2));
  end;
  Result.SetOpacity(Opacity);
end;

procedure TTVCanvas.Clear(Color: TTVColor);
var
  Value: TD2D1ColorF;
begin
  Value := DColor(Color, 1);
  FTarget.Clear(Value);
end;

procedure TTVCanvas.Fill(X, Y, W, H: Single; Color: TTVColor; Opacity: Single);
begin
  SetColor(Color, Opacity);
  FTarget.FillRectangle(D2D1RectF(X, Y, X + W, Y + H), FColor);
end;

procedure TTVCanvas.Shade(X, Y, W, H: Single; Top, Bottom: TTVColor; Opacity: Single);
begin
  FTarget.FillRectangle(D2D1RectF(X, Y, X + W, Y + H),
    GradientBrush(0, Y, 0, Y + H, Top, Bottom, Opacity));
end;

procedure TTVCanvas.RoundRect(X, Y, W, H, Radius: Single; Color: TTVColor; Opacity: Single);
begin
  SetColor(Color, Opacity);
  FTarget.FillRoundedRectangle(D2D1RoundedRect(D2D1RectF(X, Y, X + W, Y + H),
    Radius, Radius), FColor);
end;

procedure TTVCanvas.Ellipse(X, Y, RX, RY: Single; Color: TTVColor; Opacity: Single);
begin
  SetColor(Color, Opacity);
  FTarget.FillEllipse(D2D1Ellipse(D2D1PointF(X, Y), RX, RY), FColor);
end;

procedure TTVCanvas.Line(X1, Y1, X2, Y2, Width: Single; Color: TTVColor; Opacity: Single);
begin
  SetColor(Color, Opacity);
  FTarget.DrawLine(D2D1PointF(X1, Y1), D2D1PointF(X2, Y2), FColor, Width);
end;

function TTVCanvas.Geometry(const Commands: array of Single; const Key: string): ID2D1PathGeometry;
var
  Sink: ID2D1GeometrySink;
  Curve: TD2D1BezierSegment;
  Index: Integer;
  OpenFigure: Boolean;
begin
  if (Key <> '') and FPaths.TryGetValue(Key, Result) then Exit;
  OleCheck(FFactory.CreatePathGeometry(Result));
  OleCheck(Result.Open(Sink));
  Index := 0;
  OpenFigure := False;
  while Index < Length(Commands) do
  begin
    case Round(Commands[Index]) of
      M: begin
        if OpenFigure then Sink.EndFigure(D2D1_FIGURE_END_OPEN);
        Sink.BeginFigure(D2D1PointF(Commands[Index + 1], Commands[Index + 2]),
          D2D1_FIGURE_BEGIN_FILLED);
        OpenFigure := True;
        Inc(Index, 3);
      end;
      L: begin
        Sink.AddLine(D2D1PointF(Commands[Index + 1], Commands[Index + 2]));
        Inc(Index, 3);
      end;
      C: begin
        Curve.point1 := D2D1PointF(Commands[Index + 1], Commands[Index + 2]);
        Curve.point2 := D2D1PointF(Commands[Index + 3], Commands[Index + 4]);
        Curve.point3 := D2D1PointF(Commands[Index + 5], Commands[Index + 6]);
        Sink.AddBezier(Curve);
        Inc(Index, 7);
      end;
      Z: begin
        Sink.EndFigure(D2D1_FIGURE_END_CLOSED);
        OpenFigure := False;
        Inc(Index);
      end;
    else
      raise EArgumentException.Create('Invalid artwork path command');
    end;
  end;
  if OpenFigure then Sink.EndFigure(D2D1_FIGURE_END_OPEN);
  OleCheck(Sink.Close);
  if Key <> '' then FPaths.Add(Key, Result);
end;

procedure TTVCanvas.Path(const Commands: array of Single; Color: TTVColor;
  const Key: string; Opacity: Single);
begin
  SetColor(Color, Opacity);
  FTarget.FillGeometry(Geometry(Commands, Key), FColor);
end;

procedure TTVCanvas.Stroke(const Commands: array of Single; Color: TTVColor;
  Width: Single; const Key: string; Opacity: Single);
begin
  SetColor(Color, Opacity);
  FTarget.DrawGeometry(Geometry(Commands, Key), FColor, Width);
end;

procedure TTVCanvas.ShadePath(const Commands: array of Single; Top, Bottom: TTVColor;
  Y1, Y2: Single; const Key: string; Opacity: Single);
begin
  FTarget.FillGeometry(Geometry(Commands, Key), GradientBrush(0, Y1, 0, Y2,
    Top, Bottom, Opacity));
end;

procedure TTVCanvas.LabelText(const Value: string; X, Y, W: Single; Size: Integer;
  Color: TTVColor; Bold: Boolean; Align: Integer);
var
  Key: Integer;
  Weight: TDWriteFontWeight;
  Format: IDWriteTextFormat;
begin
  Key := Size * 8 + Align * 2 + Ord(Bold);
  if not FFormats.TryGetValue(Key, Format) then
  begin
    Weight := DWRITE_FONT_WEIGHT_MEDIUM;
    if Bold then Weight := DWRITE_FONT_WEIGHT_BOLD;
    OleCheck(FWrite.CreateTextFormat('Yu Gothic UI', nil, Weight,
      DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL, Size, 'ja-jp', Format));
    OleCheck(Format.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP));
    OleCheck(Format.SetTextAlignment(TDWriteTextAlignment(Align)));
    FFormats.Add(Key, Format);
  end;
  SetColor(Color, 1);
  FTarget.DrawText(PWideChar(Value), Length(Value), Format,
    D2D1RectF(X, Y, X + W, Y + Size * 1.4), FColor, D2D1_DRAW_TEXT_OPTIONS_CLIP);
end;

procedure TTVCanvas.Clip(X, Y, W, H: Single);
begin
  FTarget.PushAxisAlignedClip(D2D1RectF(X, Y, X + W, Y + H), D2D1_ANTIALIAS_MODE_ALIASED);
end;

procedure TTVCanvas.Unclip;
begin
  FTarget.PopAxisAlignedClip;
end;

procedure TTVCanvas.Transform(X, Y, Scale: Single; Flip: Boolean);
var
  Matrix: TD2D1Matrix3x2F;
begin
  Matrix._11 := Scale;
  if Flip then Matrix._11 := -Scale;
  Matrix._12 := 0;
  Matrix._21 := 0;
  Matrix._22 := Scale;
  Matrix._31 := X;
  Matrix._32 := Y;
  FTarget.SetTransform(Matrix);
end;

end.
