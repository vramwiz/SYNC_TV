unit TV_GameBattle;

// Copyright (c) 2026 VRAMの魔術師
// SPDX-License-Identifier: GPL-3.0-only
// 対戦格闘の試合と、コマンド選択式RPGの戦闘を時刻から再構成する。

interface

uses TV_Canvas;

// 提供された960×540の番組面に時刻 Time（秒）の対戦や戦闘を描く。
procedure DrawFightingGame(Canvas: TTVCanvas; Time: Double);
procedure DrawRolePlayingGame(Canvas: TTVCanvas; Time: Double);

implementation

uses System.Math, System.SysUtils, TV_Timeline, TV_GameArt;

procedure FighterArm(Canvas: TTVCanvas; ElbowX, ElbowY, HandX, HandY: Single;
  Sleeve, Glove: TTVColor);
begin
  Canvas.Line(6,-118,ElbowX,ElbowY,23,$252439);
  Canvas.Line(6,-120,ElbowX,ElbowY-2,15,Sleeve);
  Canvas.Line(ElbowX,ElbowY,HandX,HandY,16,$E9AE88);
  Canvas.Ellipse(HandX,HandY,16,13,$252439);
  Canvas.Ellipse(HandX+2,HandY-2,13,10,Glove);
end;

procedure Fighter(Canvas: TTVCanvas; X, Ground, Breath, Punch, Kick, Guard, Recoil: Single;
  Primary, Secondary: TTVColor; Opponent: Boolean);
var
  Hip, HeadX, Reach, FootX, FootY: Single;
begin
  Canvas.Ellipse(X,Ground,67,13,$211B2F,0.65);
  Canvas.Transform(X,Ground+Breath,1,Opponent);
  try
    Hip := -7*Recoil;
    HeadX := 11*Punch-18*Recoil-6*Guard;
    FootX := 40+71*Kick;
    FootY := -8-91*Kick;
    Canvas.Line(Hip,-70,-32,-39,28,$282641);
    Canvas.Line(-32,-39,-44,-9,23,$282641);
    Canvas.Line(Hip+9,-72,30+32*Kick,-39-41*Kick,28,Secondary);
    Canvas.Line(30+32*Kick,-39-41*Kick,FootX,FootY,23,Secondary);
    Canvas.RoundRect(-64,-16,37,15,4,$1C1D30);
    Canvas.RoundRect(FootX-11,FootY-7,38,15,4,$1C1D30);
    FighterArm(Canvas,-22,-107,15+23*Guard,-112-32*Guard,Secondary,Primary);
    Canvas.Path([M,-27,-135,L,HeadX+28,-132,L,27,-98,L,18,-67,L,-28,-71,L,-36,-110,Z],Primary);
    Canvas.Path([M,-25,-124,L,20,-118,L,15,-102,L,-22,-103,Z],$FFFFFF,'',0.22);
    Canvas.Line(-26,-80,19,-78,10,$262238);
    Canvas.Fill(-10,-85,13,12,$E7CC83);
    Canvas.RoundRect(HeadX-22,-180,45,48,13,$E9AE88);
    if Opponent then
    begin
      Canvas.RoundRect(HeadX-25,-186,43,20,8,$F7D08F);
      Canvas.Fill(HeadX-27,-173,10,26,$F7D08F);
    end
    else
      Canvas.Path([M,HeadX-24,-145,L,HeadX-29,-177,L,HeadX-12,-190,
        L,HeadX+23,-181,L,HeadX+26,-171,L,HeadX+1,-166,L,HeadX-11,-146,Z],$302942);
    Canvas.Line(HeadX+9,-162,HeadX+20,-163,4,$362A42);
    Reach := 49+93*Punch-9*Guard;
    FighterArm(Canvas,23+49*Punch,-94-31*Punch,Reach,-111-14*Punch-34*Guard,Primary,Secondary);
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure DrawFightingGame(Canvas: TTVCanvas; Time: Double);
var
  RoundInfo, Beat: TTVScene;
  I, Combo, Exchanges: Integer;
  X, LeftX, RightX, Advance, Strike, LH, RH, P, Impact: Single;
  LeftAttacks, Blocked, Kick: Boolean;
begin
  RoundInfo := TVSceneAt(Time,32);
  Beat := TVSceneAt(RoundInfo.Age,3.2);
  Combo := Integer(Beat.Index);
  LeftAttacks := (Combo+RoundInfo.Choice(17,2)) mod 2=0;
  Blocked := (Combo+RoundInfo.Choice(73,3)) mod 3=1;
  Kick := (Combo+RoundInfo.Choice(89,3)) mod 3=0;
  P := Beat.Phase;
  Advance := TVSmooth((P-0.12)*4)*(1-TVSmooth((P-0.63)*4));
  Strike := TVSmooth((P-0.36)*12)*(1-TVSmooth((P-0.52)*7));
  Impact := (P-0.445)*8;
  LeftX := 314+91*Advance;
  RightX := 646-91*Advance;
  if (not Blocked) and (Impact>=0) and (Impact<1) then
    if LeftAttacks then RightX := RightX+25*Sin(Pi*Impact)
    else LeftX := LeftX-25*Sin(Pi*Impact);
  Canvas.Shade(0,0,960,540,$301F4D,$F2A071);
  Canvas.Ellipse(481,239,111,111,$FFD8A4,0.75);
  for I := -1 to 13 do
  begin
    X := I*78;
    Canvas.Fill(X,280-(I and 3)*27,63,125+(I and 3)*27,$523659);
    Canvas.Fill(X+7,289-(I and 3)*27,49,4,$C18A8D,0.65);
    Canvas.Fill(X+13,319-(I and 3)*27,8,18,$E5B582,0.7);
    Canvas.Fill(X+37,319-(I and 3)*27,8,18,$E5B582,0.48);
  end;
  Canvas.Shade(0,376,960,164,$996276,$362841);
  for I := -5 to 5 do
    Canvas.Line(480+I*54,377,480+I*190,540,2,$D7888C,0.42);
  for I := 0 to 4 do Canvas.Line(0,380+I*I*10,960,380+I*I*10,2,$E3A09F,0.38);
  if LeftAttacks then
  begin
    Fighter(Canvas,LeftX,429,2*Sin(Time*7),Strike*Ord(not Kick),Strike*Ord(Kick),
      0,0,$E47E58,$A74D69,False);
    Fighter(Canvas,RightX,429,2*Sin(Time*7+1),0,0,Advance*Ord(Blocked),
      Strike*Ord(not Blocked),$527CB9,$495589,True);
  end
  else
  begin
    Fighter(Canvas,LeftX,429,2*Sin(Time*7),0,0,Advance*Ord(Blocked),Strike*Ord(not Blocked),
      $E47E58,$A74D69,False);
    Fighter(Canvas,RightX,429,2*Sin(Time*7+1),Strike*Ord(not Kick),Strike*Ord(Kick),
      0,0,$527CB9,$495589,True);
  end;
  if (Impact>=0) and (Impact<1) then
  begin
    X := TVLerp(LeftX+31,RightX-31,Ord(LeftAttacks));
    if Blocked then
    begin
      Canvas.Ellipse(X,314,29+30*Impact,40+31*Impact,$A8F4F2,(1-Impact)*0.52);
      Canvas.LabelText('GUARD',398,234,164,23,$C8FFFF,True,2);
    end
    else
      GameBurst(Canvas,X,314+17*Ord(Kick),71,Impact,$FFE284);
  end;
  LH := 1;
  RH := 1;
  for Exchanges := 0 to Combo do
    if ((Exchanges<Combo) or (Impact>=0)) and
      ((Exchanges+RoundInfo.Choice(73,3)) mod 3<>1) then
      if (Exchanges+RoundInfo.Choice(17,2)) mod 2=0 then RH := RH-0.17
      else LH := LH-0.17;
  Canvas.LabelText('RUSK',29,11,230,25,$FFE2CC,True);
  Canvas.LabelText('VAIL',701,11,230,25,$DAEEFF,True,1);
  GameMeter(Canvas,25,48,370,27,LH,$FFB06C);
  GameMeter(Canvas,565,48,370,27,RH,$78D9F6,True);
  Canvas.RoundRect(424,13,112,70,10,$211D36);
  Canvas.LabelText(IntToStr(99-Trunc(RoundInfo.Age*2)),424,14,112,46,$FFF2D8,True,2);
  Canvas.LabelText(Format('ROUND %d',[RoundInfo.Index mod 9+1]),394,86,172,19,$FFF2D8,True,2);
end;

procedure RPGKnight(Canvas: TTVCanvas; X, Y, Scale, Action: Single; Mage: Boolean);
var
  Primary, Trim: TTVColor;
begin
  Canvas.Ellipse(X,Y,48*Scale,10*Scale,$141A37,0.64);
  Canvas.Transform(X,Y,Scale);
  try
    Primary := $538CBE;
    Trim := $BCE7F6;
    if Mage then
    begin
      Primary := $6456A0;
      Trim := $E9A1D6;
    end;
    Canvas.Path([M,-21,-96,L,21,-96,L,36,-13,L,-33,-13,Z],Primary,'game.rpg.cloak');
    Canvas.Fill(-24,-16,20,14,$333451);
    Canvas.Fill(7,-16,21,14,$333451);
    Canvas.RoundRect(-24,-125,51,44,13,$EAB78C);
    Canvas.Path([M,-29,-96,L,-29,-128,L,-5,-147,L,28,-134,L,30,-113,L,4,-123,
      L,-12,-111,L,-12,-91,Z],Trim,'game.rpg.hood');
    Canvas.Fill(12,-111,7,7,$392747);
    Canvas.Line(15,-74,36+30*Action,-52-31*Action,15,Trim);
    if Mage then
    begin
      Canvas.Line(43,-20,46+22*Action,-119-10*Action,7,$D1AAEB);
      GameDiamond(Canvas,46+22*Action,-121-10*Action,12,16,$FCA9E9);
    end
    else
    begin
      Canvas.Line(40+23*Action,-42-29*Action,66+31*Action,-106+25*Action,10,$E8F7FF);
      Canvas.Line(31+22*Action,-52-24*Action,50+31*Action,-44-21*Action,6,$FFE1A5);
    end;
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure RPGMonster(Canvas: TTVCanvas; X, Y, Lift: Single; Enemy: Integer);
const
  Colors: array[0..2] of TTVColor = ($568F8A,$B15C80,$6B69AA);
var
  Color: TTVColor;
begin
  Color := Colors[Enemy];
  Canvas.Ellipse(X,Y,94,18,$17192F,0.73);
  Canvas.Transform(X,Y-Lift);
  try
    Canvas.Path([M,-83,-28,L,-73,-80,L,-53,-98,L,-53,-135,L,-20,-113,L,25,-113,
      L,55,-139,L,54,-99,L,80,-78,L,89,-27,L,52,-16,L,27,-27,L,-32,-24,L,-56,-15,Z],
      Color,'game.rpg.golem');
    Canvas.Path([M,-68,-70,L,-48,-98,L,45,-98,L,70,-65,L,52,-41,L,-50,-40,Z],
      $242C49,'game.rpg.mask');
    GameDiamond(Canvas,-26,-71,14,10,$FADA80);
    GameDiamond(Canvas,27,-71,14,10,$FADA80);
    Canvas.Fill(-12,-47,24,7,$7F71A3);
    Canvas.Line(-47,-110,-46,-127,6,$D7B4D8);
    Canvas.Line(44,-110,48,-131,6,$D7B4D8);
  finally
    Canvas.Transform(0,0);
  end;
end;

procedure DrawRolePlayingGame(Canvas: TTVCanvas; Time: Double);
const
  Commands: array[0..2] of string = ('ATTACK','SPELL','GUARD');
  EnemyNames: array[0..2] of string = ('MOSS SENTINEL','EMBER SENTINEL','DUSK SENTINEL');
var
  Encounter, Turn: TTVScene;
  I, Enemy, Selected, TurnNumber, Health, Damage: Integer;
  P, Action, Impact, X, Y, OrbX, OrbY: Single;
  Caption: string;
begin
  Encounter := TVSceneAt(Time,24);
  Turn := TVSceneAt(Encounter.Age,4);
  TurnNumber := Integer(Turn.Index);
  Enemy := Encounter.Choice(41,3);
  Selected := TurnNumber mod 3;
  P := Turn.Phase;
  if P<0.21 then Selected := (Selected+2) mod 3;
  Action := TVSmooth((P-0.38)*9)*(1-TVSmooth((P-0.63)*6));
  Impact := (P-0.60)*4;
  Damage := 34+Selected*17+Encounter.Choice(Cardinal(34+TurnNumber),15);
  Health := 100-(TurnNumber-TurnNumber div 3)*17;
  if (Impact>=0) and (Selected<>2) then Health := Health-17;
  Canvas.Shade(0,0,960,540,$1E385B,$4A3C64);
  Canvas.Ellipse(733,111,51,49,$EDC4D1,0.71);
  for I := -1 to 7 do
  begin
    X := I*168;
    Y := 114+(I and 3)*20;
    Canvas.Path([M,X,308,L,X+81,Y,L,X+158,308,Z],$2A4261);
    Canvas.Path([M,X+56,Y+60,L,X+81,Y,L,X+106,Y+62,L,X+90,Y+55,L,X+76,Y+74,Z],$7892AB);
  end;
  Canvas.Shade(0,285,960,87,$4A6A74,$455266);
  Canvas.Ellipse(463,296,385,41,$667884,0.40);
  for I := 0 to 15 do
    Canvas.Fill((I*193+67) mod 948,306+(I*29) mod 51,9+I mod 11,2,$B6B3BB,0.51);
  RPGKnight(Canvas,222+335*Action*Ord(Selected=0),300,1,Action*Ord(Selected=0),False);
  RPGKnight(Canvas,122,325,0.79,Action*Ord(Selected=1),True);
  RPGMonster(Canvas,700-178*Action*Ord(Selected=2),296,4*Sin(Time*3),Enemy);
  if (Selected=1) and (P>=0.43) and (P<0.61) then
  begin
    OrbX := TVLerp(162,700,(P-0.43)/0.18);
    OrbY := 214-55*Sin(Pi*(P-0.43)/0.18);
    Canvas.Ellipse(OrbX,OrbY,29,26,$D783FB,0.4);
    GameDiamond(Canvas,OrbX,OrbY,17,19,$FCADF0);
  end;
  if (Impact>=0) and (Impact<1) then
  begin
    if Selected=2 then
    begin
      Canvas.Ellipse(241,239,36,49,$93E9E7,(1-Impact)*0.6);
      Canvas.LabelText('GUARD',170,136-37*Impact,142,27,$BCFCF1,True,2);
    end
    else
    begin
      GameBurst(Canvas,681,219,65,Impact,$FCD08D);
      Canvas.LabelText(IntToStr(Damage),613,143-44*Impact,138,39,$FFF0AD,True,2);
    end;
  end;
  Canvas.LabelText(EnemyNames[Enemy],579,17,330,21,$F9DBEC,True,2);
  GameMeter(Canvas,620,48,247,17,Health/100,$E893B1);
  Canvas.RoundRect(16,374,928,150,11,$101B37);
  Canvas.Line(373,387,373,511,2,$6D82B0);
  for I := 0 to 2 do
  begin
    Y := 385+I*42;
    if I=Selected then
    begin
      Canvas.RoundRect(28,Y,328,39,5,$354A72);
      GameDiamond(Canvas,53,Y+19,7,8,$FCE09C);
    end;
    Canvas.LabelText(Commands[I],76,Y+3,262,23,$EEF0FA,True);
  end;
  Caption := 'Choose a command';
  if P>=0.36 then
    case Selected of
      0: Caption := 'Lio strikes!';
      1: Caption := 'Mira casts Moon Spark!';
      2: Caption := 'Lio guards the party!';
    end;
  Canvas.LabelText(Caption,401,389,516,24,$FDF0D3,True);
  Canvas.LabelText(Format('LIO     HP %d / 125',[125-TurnNumber*5]),401,441,247,20,$BFF7EA,True);
  Canvas.LabelText(Format('MIRA   MP %d / 46',[46-(TurnNumber div 3)*8-8*Ord((Selected=1) and
    (P>=0.43))]),656,441,263,20,$EFCEFF,True);
  Canvas.LabelText(Format('TURN %d',[TurnNumber+1]),401,479,183,19,$A6BCD8);
end;

end.
