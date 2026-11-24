unit TV_Studio;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// ニュース、天気予報、バラエティの番組進行とスタジオ。

interface

uses TV_Canvas;

procedure DrawNews(Canvas: TTVCanvas; Time: Double);
procedure DrawForecast(Canvas: TTVCanvas; Time: Double);
procedure DrawVariety(Canvas: TTVCanvas; Time: Double);

implementation

uses
  System.Math, System.SysUtils, TV_Timeline, TV_Artwork;

procedure DrawNews(Canvas: TTVCanvas; Time: Double);
const
  Headlines: array[0..5] of string = ('港に新しい遊歩道、きょう開通',
    '風見台で星空の観測会', '朝市に春の味覚が集まる', '水辺の図書室がオープン',
    '並木通りで灯りのフェスティバル', '青波線に新しい展望車両');
  Locations: array[0..5] of string = ('灯浜港','風見台','青野通り','水月公園','並木通り','青波駅');
var
  Segment: TTVScene;
  Topic, I: Integer;
  Pan: Single;
begin
  Segment := TVSceneAt(Time, 23);
  Topic := Segment.Choice(12, Length(Headlines));
  if (Segment.Age >= 8.5) and (Segment.Age < 18.2) then
  begin
    DrawSkyline(Canvas, Topic mod 4, Time);
    if Topic in [0,3,5] then
    begin
      Canvas.Shade(0,385,960,155,$51798C,$1E4664);
      for I := 0 to 15 do
        Canvas.Line(0,389+I*9,960,390+I*9,1.1,$C5E3E3,0.13+0.08*Sin(Time*1.3+I));
      Pan := 26 + 720*TVCycle(Time + Topic * 7, 42);
      Canvas.Path([M,Pan,414,L,Pan+157,414,L,Pan+129,437,L,Pan+32,437,Z],$232C3C);
      Canvas.Shade(Pan+40,386,80,27,$E2EAF1,$838C9C);
      Canvas.Fill(Pan+57,373,48,14,$D1E0E7);
      Canvas.Fill(Pan+54,392,49,9,$3A7895);
    end
    else
    begin
      Canvas.Path([M,0,507,L,439,315,L,543,315,L,960,507,L,960,540,L,0,540,Z],$76717C,'field road');
      for I := 0 to 7 do
      begin
        Canvas.Line(64+I*133,315-22*Sin(I),64+I*133,405,4,$364054);
        Canvas.Ellipse(64+I*133,312-22*Sin(I),19,12,$FFE3AA,0.51);
        Canvas.Ellipse(64+I*133,312-22*Sin(I),7,6,$FFECC4);
      end;
    end;
    Canvas.RoundRect(772,26,159,35,4,$15273E,0.85);
    Canvas.LabelText(Locations[Topic],785,30,133,19,$FFFFFF,True,1);
  end
  else
  begin
    Canvas.Shade(0,0,960,540,$103652,$060C1A);
    Canvas.Path([M,0,0,L,565,0,L,455,340,L,0,424,Z],$28516E,'news left wall');
    Canvas.Clip(34,79,891,280);
    DrawSkyline(Canvas,Topic mod 4,Time*0.23);
    Canvas.Fill(34,79,891,280,$375F87,0.47);
    Canvas.Unclip;
    Canvas.Fill(34,73,891,6,$76CCE1);
    for I := 0 to 5 do Canvas.Fill(34+I*176,80,4,286,$11283D,0.83);
    Canvas.Shade(0,361,960,65,$142944,$080D1E);
    Canvas.Line(0,364,960,364,2,$7CBBD4,0.64);
    if Segment.Age < 18 then
      DrawPresenter(Canvas,466,293,1.31,Topic mod 2,Time,1,
        0.25+0.50*Sqr(Sin(Time*0.79)))
    else
    begin
      DrawPresenter(Canvas,334,301,1.06,0,Time,0.9,0.31);
      DrawPresenter(Canvas,635,301,1.06,1,Time,0.42,0.16,True);
    end;
    Canvas.ShadePath([M,129,380,C,249,360,716,360,826,380,L,872,471,L,93,471,Z],
      $507890,$101E31,370,468,'news desk');
    Canvas.Stroke([M,135,381,C,262,363,706,363,820,381],$A3E6F0,3,'news desk trim');
    Canvas.Path([M,420,385,L,536,385,L,546,406,L,411,406,Z],$CADCE8,'news notes');
    Canvas.Line(440,391,505,391,1.5,$50758A);
  end;
  DrawLive(Canvas,'報道ライブ',$EF5463);
  Canvas.LabelText('蒼波 NEWS',739,25,185,22,$F7F8FF,True,1);
  DrawLowerThird(Canvas,'蒼波ニュース ／ ' + Locations[Topic],Headlines[Topic],$74E7EF,$123853);
  DrawCrawl(Canvas, Headlines[Topic] + '　　◇　　地域からの情報をお伝えしています',Time,$78E2E7);
end;

procedure DrawJapan(Canvas: TTVCanvas);
begin
  Canvas.ShadePath([M,534,115,C,554,113,575,83,591,66,L,610,85,L,620,108,
    L,646,113,L,627,144,L,591,154,L,564,151,L,543,143,Z,
    M,561,160,C,578,156,588,172,584,196,C,582,216,589,224,573,248,
    C,559,269,562,280,541,294,L,524,327,L,494,340,L,478,371,
    L,459,364,L,440,383,L,410,379,L,384,402,L,360,396,L,340,410,
    L,320,399,L,330,379,L,363,372,L,384,351,L,423,347,L,442,321,L,472,317,
    L,492,281,C,503,266,507,238,522,225,C,537,207,543,174,561,160,Z,
    M,385,400,L,427,385,L,451,404,L,433,422,L,401,426,L,377,422,Z,
    M,306,399,L,338,412,L,351,425,L,325,442,L,329,464,L,303,473,
    L,281,448,L,289,432,L,273,422,L,286,404,Z],
    $AFE1B2,$5B9A82,78,476,'japan islands');
  Canvas.Path([M,258,470,L,266,473,L,260,480,L,252,479,Z,
    M,236,486,L,243,490,L,236,495,L,229,492,Z],$8BB7A2,'japan smaller islands');
  Canvas.Stroke([M,541,211,L,576,220,M,505,267,L,553,281,M,472,317,L,516,328,
    M,355,374,L,387,395,M,422,348,L,450,373],$3D836F,1.5,'forecast boundaries',0.67);
end;

procedure DrawForecast(Canvas: TTVCanvas; Time: Double);
const
  Cities: array[0..5] of string = ('札幌','仙台','東京','名古屋','大阪','福岡');
  SpotX: array[0..5] of Single = (606,552,502,435,369,291);
  SpotY: array[0..5] of Single = (135,224,297,333,373,427);
  Days: array[0..2] of string = ('きょう','あす','週末');
var
  Segment: TTVScene;
  I, Kind, Temp, Rain, Day, Region, NextRegion: Integer;
  X, Y: Single;
  Cue, Blend: Double;
begin
  Segment := TVSceneAt(Time,15);
  Day := Segment.Index mod 3;
  Canvas.Shade(0,0,960,540,$184468,$102941);
  for I := 0 to 13 do
    Canvas.Line(I*72,66,I*72,484,1,$84BFDB,0.14);
  for I := 0 to 8 do
    Canvas.Line(0,86+I*49,960,86+I*49,1,$84BFDB,0.14);
  if Segment.Age < 10 then
  begin
    DrawJapan(Canvas);
    for I := 0 to High(Cities) do
    begin
      Kind := Segment.Choice(89+Cardinal(I),4);
      Temp := 9+I*2+Segment.Choice(355+Cardinal(I),11)-5*Ord(Kind=3);
      X := SpotX[I];
      Y := SpotY[I];
      Canvas.RoundRect(X-35,Y-29,119,61,7,$10273C,0.92);
      Canvas.LabelText(Cities[I],X+15,Y-23,62,16,$D3EEF3,True);
      Canvas.LabelText(IntToStr(Temp)+'℃',X+14,Y,69,21,$FECE94,True);
      DrawWeatherIcon(Canvas,X-9,Y,0.73,Kind);
    end;
    Cue := Segment.Age/3.32;
    Region := Min(3,1+Trunc(Cue));
    NextRegion := Min(3,Region+1);
    Blend := TVSmooth((Frac(Cue)-0.58)/0.42);
    DrawWeatherPresenter(Canvas,838,283,1.01,Time,
      TVLerp(SpotX[Region],SpotX[NextRegion],Blend)+90,
      TVLerp(SpotY[Region],SpotY[NextRegion],Blend)+4);
  end
  else
  begin
    for I := 0 to 3 do
    begin
      Kind := Segment.Choice(61+Cardinal(I),4);
      Temp := 15+I+Segment.Choice(201+Cardinal(I),11);
      Rain := 10 + 20 * Kind + 10 * Segment.Choice(671+Cardinal(I),3);
      X := 27+I*174;
      Canvas.RoundRect(X,119,163,320,10,$1D4A67,0.96);
      Canvas.LabelText(Cities[I],X+5,133,153,24,$FFFFFF,True,2);
      DrawWeatherIcon(Canvas,X+81,238,1.58,Kind);
      Canvas.LabelText(IntToStr(Temp)+'℃',X+5,295,153,35,$FCD396,True,2);
      Canvas.LabelText(IntToStr(Rain)+'%',X+5,353,153,25,$8DD8F6,True,2);
    end;
    DrawWeatherPresenter(Canvas,850,283,0.99,Time,700,
      TVLerp(216,365,TVSmooth((Segment.Age-10)/4.6)));
  end;
  Canvas.Shade(0,0,960,72,$11324B,$10263D);
  Canvas.Fill(0,69,960,3,$67D8E2);
  Canvas.LabelText('空もよう予報',29,11,350,33,$F3FCFF,True);
  Canvas.RoundRect(757,16,172,39,8,$33718A);
  Canvas.LabelText(Days[Day] + 'の予報',762,20,162,20,$F5FCFF,True,2);
  Canvas.Shade(0,483,960,57,$112E48,$091C30);
  Canvas.LabelText('気温・降水確率',31,493,256,23,$8BDDEB,True);
  Canvas.LabelText('東から西へ、地域ごとの空もようをチェック',291,495,634,20,$E0F0F5,False,1);
end;

procedure DrawVariety(Canvas: TTVCanvas; Time: Double);
const
  Reactions: array[0..4] of string = ('まさかの大逆転！','その発想はなかった！',
    '正解はどっちだ！？','思わず拍手！','ここからが本番！');
  Palette: array[0..4] of TTVColor = ($E66AAD,$5AD9CB,$FFA05F,$7D71D8,$F2D466);
var
  Segment: TTVScene;
  I, Hero, Reaction: Integer;
  X, Y, W: Single;
begin
  Segment := TVSceneAt(Time,11.4);
  Hero := Segment.Choice(44,3);
  Reaction := Segment.Choice(111,Length(Reactions));
  Canvas.Shade(0,0,960,540,$753A86,$261752);
  for I := 0 to 9 do
  begin
    X := I * 118 - 80;
    Canvas.Path([M,X,0,L,X+58,0,L,X+229,390,L,X+151,390,Z],Palette[I mod 5],'',0.32);
    Y := 68+25*Sin(I*1.9+Time*1.2);
    Canvas.Ellipse(X+117,Y,19,19,Palette[(I+2) mod 5],0.65);
    Canvas.Ellipse(X+117,Y,9,9,$FFFFFF,0.52);
  end;
  Canvas.Shade(0,367,960,173,$CB689B,$3C254E);
  Canvas.Line(0,365,960,365,3,$F3B3D6,0.64);
  if Segment.Age < 7.4 then
  begin
    for I := 0 to 2 do
    begin
      X := 212+I*266;
      DrawPresenter(Canvas,X,279,0.91,3+I,Time+I*0.34,0.4+0.6*Ord(I=Hero),
        0.28+0.60*Ord(I=Hero),I=2);
      Canvas.RoundRect(X-105,337,210,84,16,Palette[(I+1) mod 5]);
      Canvas.Shade(X-93,353,186,68,$543264,$2A1A4E);
      Canvas.LabelText(IntToStr(I+1),X-42,353,84,36,$F0E2FA,True,2);
    end;
  end
  else
  begin
    DrawPresenter(Canvas,502,320,1.56,3+Hero,Time,1,
      0.78+0.18*Sin(Time*5));
    Canvas.RoundRect(718,78,203,166,11,$FFE380);
    Canvas.Clip(726,86,187,150);
    Canvas.Shade(726,86,187,150,$6F78BF,$C15F99);
    DrawPresenter(Canvas,822,180,0.60,3+(Hero+1) mod 3,Time+0.31,0.48,0.57,True);
    Canvas.Unclip;
    Canvas.RoundRect(735,216,86,23,5,$382452);
    Canvas.LabelText('リアクション',740,217,76,11,$FFFFFF,True,2);
  end;
  Canvas.RoundRect(28,25,309,49,13,$442553,0.96);
  Canvas.LabelText('ひらめき！スタジオ',42,30,280,26,$FFE590,True);
  W := 649+17*Sin(Time*3.2);
  Canvas.RoundRect(480-W/2,427,W,80,19,$31214F,0.94);
  Canvas.RoundRect(485-W/2,422,W,73,17,Palette[Reaction]);
  Canvas.LabelText(Reactions[Reaction],485-W/2,427,W,44,$291845,True,2);
end;

end.
