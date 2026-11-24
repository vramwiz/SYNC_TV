unit TV_Entertainment;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 音楽、アニメ、料理、通販、ドラマ、CM の番組進行と描画。

interface

uses TV_Canvas;

procedure DrawMusic(Canvas: TTVCanvas; Time: Double);
procedure DrawAnimation(Canvas: TTVCanvas; Time: Double);
procedure DrawCooking(Canvas: TTVCanvas; Time: Double);
procedure DrawShopping(Canvas: TTVCanvas; Time: Double);
procedure DrawDrama(Canvas: TTVCanvas; Time: Double);
procedure DrawCommercial(Canvas: TTVCanvas; Time: Double);

implementation

uses
  System.Math, System.SysUtils, TV_Artwork, TV_Timeline;

procedure DrawStageMic(Canvas: TTVCanvas; X,Y,Scale: Single; FacingLeft: Boolean);
begin
  Canvas.Transform(X,Y,Scale,FacingLeft);
  Canvas.Line(19,28,24,166,7,$101421);
  Canvas.Line(20,34,24.5,165,2,$657386,0.72);
  Canvas.Path([M,-3,-10,L,6,-15,L,25,14,C,28,19,21,26,16,23,Z],
    $242A3A,'stage microphone handle');
  Canvas.Line(6,0,19,19,2,$7B8498,0.69);
  Canvas.ShadePath([M,-13,-22,C,-6,-28,4,-25,9,-18,L,14,-9,
    C,18,-2,6,7,-1,2,L,-10,-5,C,-17,-10,-18,-17,-13,-22,Z],
    $C4C7D2,$49536A,-24,3,'stage microphone grille');
  Canvas.Stroke([M,-16,-15,C,-8,-21,0,-22,7,-20,M,-13,-9,C,-5,-16,3,-17,10,-16,
    M,-8,-4,C,-1,-11,7,-13,13,-11,M,-3,0,C,3,-5,10,-8,14,-7],
    $313952,1.2,'stage microphone mesh',0.68);
  Canvas.Line(14,10,19,7,2,$DCE2E4,0.73);
  Canvas.Transform(0,0);
end;

procedure DrawMusic(Canvas: TTVCanvas; Time: Double);
const
  Colors: array[0..3] of TTVColor = ($E78AD2,$77C9FF,$A090ED,$DEAE75);
  Songs: array[0..3] of string = ('夜明けのリズム','水色の回廊','星の帰り道','風を集めて');
var
  Scene: TTVScene;
  I, Song: Integer;
  Top, Bottom, Width, Center, Scale, SingerY, MicX: Single;
  FacesLeft: Boolean;
begin
  Scene := TVSceneAt(Time,21);
  Song := Scene.Choice(6,4);
  Canvas.Shade(0,0,960,540,$171131,$080C21);
  for I := 0 to 8 do
  begin
    Top := I*126-18;
    Bottom := Top + 263*Sin(Time*0.83+I*1.09);
    Width := 55+23*Sin(Time*1.7+I);
    Canvas.Path([M,Top-8,30,L,Top+8,30,L,Bottom+Width,433,
      L,Bottom-Width,433,Z],Colors[(I+Song) mod 4],'',0.28);
    Canvas.Ellipse(Top,31,12,6,Colors[(I+Song+1) mod 4]);
  end;
  for I := 0 to 13 do
  begin
    Top := 128+I*54;
    Width := 17+30*Sqr(Sin(Time*4.1+I*0.7));
    Canvas.RoundRect(Top,294-Width,11,Width,3,Colors[(I+Song) mod 4],0.41);
  end;
  Canvas.Shade(0,383,960,157,$3C294D,$0A112A);
  Canvas.Ellipse(480,438,337,45,$8B62BF,0.34);
  Canvas.Stroke([M,45,405,L,912,405,M,20,453,L,938,453],$D077AD,2,'stage rails',0.55);
  Center := 479;
  Scale := 1.23;
  if Scene.Age > 7.5 then
  begin
    if Scene.Age < 13.4 then
    begin
      Center := 577;
      Scale := 1.86;
    end
    else
    begin
      Center := 367;
      Scale := 1.34;
    end;
  end;
  if Scene.Age < 7.5 then
  begin
    DrawPresenter(Canvas,265,329,0.79,5,Time+0.19,0.4,0.43);
    Canvas.Ellipse(255,455,51,51,$BC8EA0);
    Canvas.Ellipse(255,455,44,44,$574383);
    Canvas.Ellipse(255,455,29,29,$68509A);
    Canvas.Line(192,384,330,394,4,$F0CC9B);
    Canvas.Ellipse(196,381+3*Sin(Time*12),36,9,$A17E84);
    DrawPresenter(Canvas,723,329,0.81,7,Time+0.31,0.35,0.62,True);
    Canvas.Ellipse(735,413,40,27,$9D637B);
    Canvas.Line(737,411,800,367,12,$CE91A5);
    Canvas.Line(739,410,802,365,1,$F2C5BD);
  end;
  SingerY := 291+6*Sin(Time*2.4);
  FacesLeft := Scene.Age>13.4;
  DrawPresenter(Canvas,Center,SingerY,Scale,Song+3,Time,1,
    0.57+0.26*Sin(Time*2.2),FacesLeft);
  MicX := Center+(1-2*Ord(FacesLeft))*29*Scale;
  DrawStageMic(Canvas,MicX,SingerY-31*Scale,Scale,FacesLeft);
  DrawLive(Canvas,'ステージ LIVE',$FF80CD);
  DrawLowerThird(Canvas,'月灯りライブ',Songs[Song]+'　／　環灯バンド',$FDBAD7,$4F326B);
end;

procedure AnimeCharacter(Canvas: TTVCanvas; X,Y,Scale: Single; Time: Double;
  Variant: Integer; Action, Talking, Left: Boolean);
const
  Coats: array[0..1] of TTVColor = ($307E8C,$D77860);
  Hair: array[0..1] of TTVColor = ($354658,$6D4261);
var
  Step, Jump, Blink, Mouth, ElbowY, HandY: Single;
  Accent: TTVColor;
begin
  Step := 6*Sin(Time*7);
  Jump := 0;
  if Action then
  begin
    Step := Step*4;
    Jump := 45*Sqr(Sin(Time*2.6));
  end;
  Accent := Coats[Variant];
  Canvas.Ellipse(X,Y+83*Scale,39*Scale,7*Scale,$304C58,0.27);
  Canvas.Transform(X,Y-Jump,Scale,Left);
  Canvas.Stroke([M,-15,41,L,-15+Step*0.46,65,L,-20+Step,79,M,15,41,
    L,15-Step*0.46,65,L,20-Step,79],$323C58,13);
  Canvas.RoundRect(-31+Step,73,24,9,4,$F4E2BA);
  Canvas.RoundRect(9-Step,73,24,9,4,$F4E2BA);
  Canvas.ShadePath([M,-18,-17,C,-41,-9,-49,20,-41,46,L,40,46,
    C,44,10,35,-8,15,-18,Z],TVColorMix(Accent,$FFFFFF,0.27),Accent,-20,47,'cartoon coat');
  Canvas.Path([M,-21,-15,L,20,-14,L,28,-1,L,4,11,L,-27,1,Z],$FAE2A4,'cartoon scarf');
  Canvas.Path([M,-20,-7,C,-43,-3,-58,-6,-77,-24+Step*0.23,
    C,-60,-11+Step*0.36,-42,0,-25,8,Z],$F8CF8D);
  ElbowY := 24-Step*0.21;
  HandY := 18-Step*0.63;
  Canvas.Line(31,3,43,ElbowY,12,Accent);
  Canvas.Ellipse(43,ElbowY,6,6,Accent);
  Canvas.Line(43,ElbowY,56,HandY,10,Accent);
  Canvas.Line(52,HandY+(ElbowY-HandY)*0.31,56,HandY,8,$F3DEA9);
  Canvas.Ellipse(59,HandY-1,6,5.5,$F7C0A0);
  Canvas.ShadePath([M,-46,-67,C,-46,-107,40,-111,47,-66,
    C,54,-40,38,-24,8,-16,C,-19,-12,-49,-31,-46,-67,Z],$FFE0B2,$ECB190,-100,-16,'cartoon face');
  Canvas.Path([M,-49,-53,L,-58,-68,L,-51,-77,L,-57,-87,L,-40,-92,
    L,-40,-105,L,-17,-103,L,1,-115,L,12,-105,L,35,-105,
    L,33,-98,C,60,-91,57,-72,45,-59,L,38,-76,L,20,-69,L,24,-85,
    L,-4,-73,L,4,-91,L,-25,-68,L,-25,-77,L,-43,-61,Z],Hair[Variant],'cartoon hair');
  Canvas.Stroke([M,-35,-91,C,-21,-97,-6,-104,13,-103],$F1CBBB,2.7,'cartoon hair shine',0.45);
  Blink := 1-0.89*TVSmooth((0.035-Abs(TVCycle(Time+Variant,3.8)-0.73))/0.035);
  Canvas.Ellipse(-18,-56,10,13*Blink,$FFF6DC);
  Canvas.Ellipse(22,-55,10,13*Blink,$FFF6DC);
  Canvas.Ellipse(-15,-55,4.8,9*Blink,$374D61);
  Canvas.Ellipse(24,-54,4.8,9*Blink,$374D61);
  Canvas.Ellipse(-15,-59,2,2*Blink,$FFFFFF);
  Canvas.Ellipse(25,-58,2,2*Blink,$FFFFFF);
  Canvas.Ellipse(-26,-40,8,3,$E58384,0.58);
  Canvas.Ellipse(29,-40,8,3,$E58384,0.58);
  Mouth := 2.2+7*Ord(Talking)*Sqr(Sin(Time*11));
  Canvas.Ellipse(5,-34,8,Mouth,$9F4A5B);
  Canvas.Ellipse(6,-32,4.3,Mouth*0.48,$F6ACA2);
  Canvas.Transform(0,0);
end;

procedure DrawAnimation(Canvas: TTVCanvas; Time: Double);
const
  Lines: array[0..3] of string = ('風の向こうに、灯台が見えるよ。','じゃあ、あの丘まで競争ね。',
    'ぼくらの地図に、小さな印をつけよう。','波の音が、明日の知らせみたい。');
var
  Scene: TTVScene;
  I: Integer;
  IsAction: Boolean;
  X, Y: Single;
begin
  Scene := TVSceneAt(Time,19.3);
  IsAction := (Scene.Age > 8.4) and (Scene.Age < 15.1);
  if (Scene.Index mod 3 = 1) and not IsAction then
  begin
    Canvas.Shade(0,0,960,540,$DDAA8E,$987D8B);
    Canvas.Shade(0,276,960,264,$D6A986,$AE625C);
    Canvas.RoundRect(91,38,778,243,20,$EBCDAD);
    Canvas.Shade(104,51,752,219,$7799B6,$F0D7A6);
    DrawCloud(Canvas,674,137,1.09,$F6DEB9);
    Canvas.Line(491,51,491,270,12,$CA9C87);
    for I := 0 to 8 do Canvas.Line(0,288+I*33,960,288+I*33,2,$FDE2B6,0.24);
  end
  else
  begin
    Canvas.Shade(0,0,960,540,$70A2CF,$E5E7BD);
    for I := 0 to 4 do
      DrawCloud(Canvas,-70+1120*TVCycle(Time*Ord(IsAction)+I*17,83),
        82+29*(I mod 2),0.92+I*0.13,$FCE9CA);
    Canvas.ShadePath([M,0,371,C,167,228,336,177,470,269,C,602,360,718,187,960,214,
      L,960,540,L,0,540,Z],$91B795,$378477,200,540,'anime hills');
    Canvas.ShadePath([M,0,413,C,259,289,320,371,553,349,C,723,329,846,274,960,299,
      L,960,540,L,0,540,Z],$CAE1A1,$63A67F,340,535,'anime meadow');
    Canvas.Path([M,0,520,C,204,403,546,484,806,389,L,862,377,C,654,499,442,471,186,540,
      L,0,540,Z],$E7D4A4,'anime path');
    for I := 0 to 26 do
    begin
      X := (I*213) mod 960;
      Y := 381+(I*37) mod 144;
      Canvas.Line(X,Y,X-5,Y-9,1.4,$4A9777);
      Canvas.Ellipse(X-6,Y-11,3,2,$FFDA9B);
    end;
  end;
  if IsAction then
  begin
    for I := 0 to 10 do
    begin
      X := 1030-1100*TVCycle(Scene.Age*1.4+I*2,19);
      Canvas.Line(X,61+I*43,X+104,55+I*43,2,$FFF0D8,0.66);
    end;
    AnimeCharacter(Canvas,382+70*Sin(Scene.Age),355,1.05,Time,0,True,True,False);
    AnimeCharacter(Canvas,621+92*Sin(Scene.Age+0.72),360,0.92,Time+0.4,1,True,False,False);
  end
  else
  begin
    AnimeCharacter(Canvas,329+13*Sin(Time),369,1.34,Time,0,False,Scene.Age<4.6,False);
    AnimeCharacter(Canvas,645+12*Cos(Time),377,1.17,Time,1,False,Scene.Age>=4.6,True);
  end;
  Canvas.RoundRect(24,24,225,40,10,$F9E8BE,0.83);
  Canvas.LabelText('風待ち坂のふたり',36,29,201,19,$354960,True,2);
  if not IsAction then
  begin
    Canvas.RoundRect(207,460,546,46,10,$243E50,0.82);
    Canvas.LabelText(Lines[Scene.Choice(53,4)],220,466,520,23,$FFF7E7,True,2);
  end;
end;

procedure Plate(Canvas: TTVCanvas; X, Y, Scale: Single; Dish: Integer);
var
  I: Integer;
  Angle, R: Double;
  Colors: array[0..2] of TTVColor;
begin
  Colors[0] := $DD6D47;
  Colors[1] := $B2A059;
  Colors[2] := $E19C57;
  Canvas.Ellipse(X+5*Scale,Y+8*Scale,152*Scale,71*Scale,$552E2B,0.20);
  Canvas.Ellipse(X,Y,151*Scale,68*Scale,$F5E7D8);
  Canvas.Ellipse(X,Y-2*Scale,137*Scale,58*Scale,$BDABAD,0.8);
  Canvas.Ellipse(X,Y-5*Scale,130*Scale,54*Scale,$F8F0DC);
  Canvas.Ellipse(X,Y-5*Scale,87*Scale,40*Scale,Colors[Dish]);
  for I := 0 to 22 do
  begin
    Angle := I*2.39996;
    R := 15 + (I*17) mod 63;
    Canvas.Ellipse(X+Scale*R*Cos(Angle),Y+Scale*(-5+0.41*R*Sin(Angle)),
      8*Scale,4*Scale,TVColorMix(Colors[Dish],$FADC9A,(I mod 7)/8));
    if I mod 3 = 0 then
      Canvas.Line(X+Scale*R*Cos(Angle),Y+Scale*(-5+0.41*R*Sin(Angle)),
        X+Scale*(R*Cos(Angle)+11),Y+Scale*(-8+0.45*R*Sin(Angle)),3*Scale,$5E824F);
  end;
end;

procedure DrawCooking(Canvas: TTVCanvas; Time: Double);
const
  Dishes: array[0..2] of string = ('菜園トマトの温サラダ','香草と豆のポタージュ','かぼちゃの小さなグラタン');
  Actions: array[0..3] of string = ('野菜を切る','全体をよく混ぜる','中火で焼き色をつける','できあがり');
var
  Scene: TTVScene;
  I, Stage, Dish: Integer;
  X, Y, Lift: Single;
begin
  Scene := TVSceneAt(Time,27);
  Dish := Scene.Choice(61,3);
  Stage := Min(3,Trunc(Scene.Age/6.7));
  Canvas.Shade(0,0,960,540,$F3D6AD,$C59280);
  for I := 0 to 13 do Canvas.Line(I*78,71,I*78,410,1,$FDE8CF,0.44);
  for I := 0 to 5 do Canvas.Line(0,82+I*61,960,82+I*61,1,$FDE8CF,0.53);
  Canvas.RoundRect(51,88,233,159,13,$FAECD1);
  Canvas.Shade(65,103,205,129,$86B8BC,$C6DDD0);
  DrawCloud(Canvas,163,136,0.73,$EDF2D7);
  Canvas.Fill(162,103,6,129,$F1D8BC);
  Canvas.Line(356,131,624,131,8,$845255);
  for I := 0 to 2 do
  begin
    Canvas.RoundRect(392+I*73,91,31,39,6,$A16F5E);
    Canvas.Fill(392+I*73,88,31,7,$D2A175);
  end;
  if Stage < 3 then
    DrawPresenter(Canvas,605,274,1.16,6,Time,1,0.5+0.28*Sin(Time*3),True);
  Canvas.Shade(0,347,960,193,$9A5D4B,$653D38);
  Canvas.Fill(0,347,960,16,$DBA780);
  for I := 0 to 7 do Canvas.Line(0,365+I*25,960,365+I*25,2,$E6AD7C,0.28);
  if Stage = 0 then
  begin
    Canvas.RoundRect(265,363,356,92,16,$E3B884);
    for I := 0 to 5 do
    begin
      Canvas.Ellipse(290+I*43,411+8*Sin(I),13,11,$C95C50);
      Canvas.Ellipse(287+I*43,409+8*Sin(I),6,3,$F5A474);
    end;
    Lift := 42*Sqr(Sin(Time*5));
    Canvas.Path([M,460,398-Lift,L,558,426-Lift,L,493,435-Lift,Z],$D2DFDF);
    Canvas.Line(558,426-Lift,601,421-Lift,12,$382E35);
  end
  else if Stage < 3 then
  begin
    Canvas.Ellipse(449,420,144,37,$202635);
    Canvas.Ellipse(445,410,142,34,$434857);
    Canvas.Ellipse(443,410,129,27,$C0875D);
    Canvas.Line(568,415,684,438,16,$353447);
    for I := 0 to 7 do
    begin
      X := 447+108*Sin(I*2.3+Time*0.95*Ord(Stage=1));
      Y := 410+18*Cos(I*2.3+Time*0.95*Ord(Stage=1));
      Canvas.Ellipse(X,Y,10,4.5,$E3B97C);
    end;
    if Stage = 1 then
      Canvas.Line(446+55*Sin(Time*3),410,474+62*Sin(Time*3),354,11,$E4B986)
    else
      for I := 0 to 4 do
      begin
        Lift := TVCycle(Time+I*0.41,2.7)*76;
        Canvas.Stroke([M,371+I*39,411-Lift,C,347+I*39,397-Lift,396+I*39,378-Lift,
          366+I*39,365-Lift],$F4E9DB,4,'',0.52*(1-Lift/76));
      end;
  end
  else
  begin
    Canvas.Ellipse(475,340,307,122,$E6B78D,0.39);
    Plate(Canvas,478,340,1.63,Dish);
  end;
  Canvas.RoundRect(35,22,299,52,9,$79554E,0.95);
  Canvas.LabelText('ひだまり台所',49,27,273,31,$FFF1D5,True);
  Canvas.RoundRect(31,468,898,48,8,$4E383A,0.95);
  Canvas.LabelText(Dishes[Dish],45,476,503,23,$FFF2D6,True);
  Canvas.LabelText(Actions[Stage],553,478,360,21,$FBD69E,True,1);
end;

procedure DrawShopping(Canvas: TTVCanvas; Time: Double);
const
  Names: array[0..2] of string = ('ミオリ 保温ボトル','ノクタ 卓上スピーカー','穂の庭 焼き菓子箱');
  Prices: array[0..2] of string = ('3,480','6,800','2,480');
  Captions: array[0..2] of string = ('朝の温度を、そのまま持ち歩く。','小さな机に、広がる音。','ひと息のおともに、焼きたての香り。');
var
  Scene: TTVScene;
  Product, I: Integer;
  X, Scale: Single;
begin
  Scene := TVSceneAt(Time,19);
  Product := Integer(Scene.Index mod 3);
  Canvas.Shade(0,0,960,540,$E9E4D4,$ADCFD0);
  Canvas.Shade(0,361,960,179,$AAC1C3,$567E87);
  Canvas.Path([M,0,112,L,960,80,L,960,114,L,0,145,Z],$FFFFFF,'shopping light',0.55);
  for I := 0 to 4 do Canvas.Fill(18+I*190,122,5,229,$FAF3DE,0.42);
  if Scene.Age < 7.6 then
  begin
    X := 299;
    Scale := 1.46;
    DrawPresenter(Canvas,728,290,1.16,1,Time,1,0.72,True);
  end
  else
  begin
    X := 279;
    Scale := 1.86+0.16*TVSmooth((Scene.Age-7.6)/3);
    Canvas.RoundRect(559,149,322,167,12,$F8F4E7,0.91);
    Canvas.Fill(585,174,57,4,$EB806F);
    Canvas.LabelText('商品クローズアップ',585,186,270,25,$315462,True);
    Canvas.LabelText(Captions[Product],585,239,270,16,$355461);
  end;
  Canvas.Ellipse(X,400,207,47,$76999D);
  Canvas.Ellipse(X,391,199,35,$E6ECE2);
  DrawProduct(Canvas,X,286,Scale,Product,Time);
  Canvas.RoundRect(26,20,350,49,9,$265363,0.97);
  Canvas.LabelText('くらしの市　TVショッピング',41,28,318,23,$F8F2DC,True);
  Canvas.RoundRect(56,456,476,65,10,$1E4758);
  Canvas.LabelText(Names[Product],76,467,436,32,$FFFFFF,True);
  Canvas.RoundRect(569,379,358,143,13,$DA614F);
  Canvas.LabelText('番組でご紹介',584,390,320,18,$FFF2D5,True,2);
  Canvas.LabelText(Prices[Product]+' 円',581,410,334,57,$FFFFFF,True,2);
  Canvas.LabelText('税込・数量限定',584,491,320,16,$FFEBD4,False,2);
end;

procedure DrawDrama(Canvas: TTVCanvas; Time: Double);
const
  Lines: array[0..5] of string = ('あの窓に、まだ灯りがともってる。','返事は、急がなくていいよ。',
    '駅までなら、一緒に歩こうか。','この街にも、春が来るんだね。','もう一度、聞かせてほしい。','きっと明日は、晴れるよ。');
var
  Scene: TTVScene;
  I, Shot: Integer;
  X, Walk: Single;
begin
  Scene := TVSceneAt(Time,24);
  Shot := Trunc(Scene.Age/6.0);
  if Shot in [0,3] then
  begin
    DrawSkyline(Canvas,2+Integer(Scene.Index mod 2),Time);
    Canvas.Fill(0,0,960,540,$323853,0.27);
    Canvas.Line(0,327,960,327,9,$3E4559);
    for I := 0 to 11 do Canvas.Line(I*92,323,I*92+3,490,4,$3E4559);
    Walk := 140*Scene.Phase;
    DrawPresenter(Canvas,284+Walk,322+3*Sin(Time*5),0.99,5,Time,0.68,0.32);
    DrawPresenter(Canvas,562+Walk,331+4*Cos(Time*5),1.08,7,Time,0.32,0.27,True);
  end
  else
  begin
    Canvas.Shade(0,0,960,540,$5B4D65,$2C344A);
    Canvas.Clip(106,51,746,324);
    DrawSkyline(Canvas,2,Time*0.2);
    Canvas.Fill(106,51,746,324,$443855,0.40);
    Canvas.Unclip;
    for I := 0 to 3 do
    begin
      X := 106+I*248;
      Canvas.Shade(X-4,51,12,324,$595B73,$282A42);
    end;
    Canvas.Line(106,375,854,375,9,$90717A);
    if Shot = 1 then
      DrawPresenter(Canvas,462,336,1.91,5,Time,1,0.34)
    else
      DrawPresenter(Canvas,541,347,1.72,7,Time,1,0.31,True);
    for I := 0 to 5 do
      Canvas.Ellipse(36+I*164,183+13*Cos(I),13,16,$E7A380,0.22);
  end;
  Canvas.Fill(0,0,960,47,$0D1020);
  Canvas.Fill(0,493,960,47,$0D1020);
  Canvas.LabelText('灯りの残る街',34,13,294,17,$DED1D5,False);
  Canvas.LabelText(Lines[Scene.Choice(77+Cardinal(Shot),Length(Lines))],83,443,794,27,$FFF2E5,True,2);
end;

procedure DrawCommercial(Canvas: TTVCanvas; Time: Double);
const
  Brand: array[0..2] of string = ('MIORI','NOCTUA','穂の庭');
  Captions: array[0..2] of string = ('きょうを、あたたかく。','机の上に、小さな劇場。','おやつから、季節がはじまる。');
  Subtitles: array[0..2] of string = ('ミオリ 保温ボトル','ノクタ 卓上スピーカー','穂の庭 焼き菓子箱');
  Top: array[0..2] of TTVColor = ($E8EBD1,$3E4163,$F4D3AD);
  Bottom: array[0..2] of TTVColor = ($58AA92,$151928,$C2706B);
  Ink: array[0..2] of TTVColor = ($21484C,$E4D8F3,$673645);
var
  Scene: TTVScene;
  Product, I: Integer;
  X, Y, R: Single;
begin
  Scene := TVSceneAt(Time,12.4);
  Product := Integer(Scene.Index mod 3);
  Canvas.Shade(0,0,960,540,Top[Product],Bottom[Product]);
  for I := 0 to 11 do
  begin
    X := (117+I*267) mod 960 + 25*Sin(Time*0.7+I);
    Y := 16+(I*83) mod 505+12*Cos(Time+I);
    R := 9+(I*29) mod 62;
    Canvas.Ellipse(X,Y,R,R,$FFF0D5,0.13);
    Canvas.Ellipse(X-R*0.27,Y-R*0.22,R*0.20,R*0.18,$FFF8E5,0.25);
  end;
  if Scene.Age < 3.2 then
  begin
    DrawProduct(Canvas,648,270,2.09-0.23*TVSmooth(Scene.Age/3),Product,Time);
    Canvas.LabelText(Brand[Product],63,174,417,56,Ink[Product],True);
    Canvas.LabelText(Subtitles[Product],66,265,410,30,Ink[Product]);
  end
  else if Scene.Age < 7.9 then
  begin
    Canvas.Ellipse(480,303,297,161,$FFF0D4,0.35);
    DrawProduct(Canvas,473,239,1.89+0.24*Scene.Phase,Product,Time);
    Canvas.LabelText(Captions[Product],71,438,818,39,Ink[Product],True,2);
  end
  else
  begin
    Canvas.Fill(0,218,960,150,$FDF0D5,0.43);
    DrawProduct(Canvas,200,298,1.16,Product,Time);
    Canvas.LabelText(Brand[Product],341,226,529,55,Ink[Product],True);
    Canvas.LabelText(Captions[Product],344,304,545,33,Ink[Product],True);
    Canvas.LabelText(Subtitles[Product],345,386,539,21,Ink[Product]);
  end;
end;

end.
