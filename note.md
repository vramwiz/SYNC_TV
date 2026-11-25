# SYNC_TV 作業ノート

- フォルダーは `D:\DelphiProg\MyApp\SYNC_TV`。Delphi プロジェクト名は `SYNC_TV`、グループは `SYNC`、日本語プラグイン名は「テレビ演出」。
- `D:\DelphiProg\MyApp\SYNC_WeatherFX` から Delphi プロジェクトと共通基盤の構成を引き継ぐ。本番は `SYNC_TV.dproj` / `SYNC_TV.auf2` の1つ。
- 仕様は `docs/SPECIFICATION.md`、利用方法は `README.md` を参照する。

## ビルド

- Delphi 37.0 / Win64。IDE では `SYNC_TV.dproj` を直接開く。
- プロジェクトルートで `rsvars.bat` を呼び、MSBuild で Debug / Release の両方を実行する。警告0・エラー0と AUF2 の更新を確認し、最後に Release を配置する。

```powershell
cmd /c 'call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && msbuild SYNC_TV.dproj /t:Build /p:Config=Debug /p:Platform=Win64'
cmd /c 'call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && msbuild SYNC_TV.dproj /t:Build /p:Config=Release /p:Platform=Win64'
```

全体を再ビルドし、ログを残す場合:

```powershell
New-Item -ItemType Directory -Path Win64\BuildLogs -Force | Out-Null
cmd /c 'call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && msbuild SYNC_TV.dproj /t:Rebuild /p:Config=Debug /p:Platform=Win64 /fl /flp:"logfile=Win64\BuildLogs\Debug.log;verbosity=normal;encoding=UTF-8"'
cmd /c 'call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && msbuild SYNC_TV.dproj /t:Rebuild /p:Config=Release /p:Platform=Win64 /fl /flp:"logfile=Win64\BuildLogs\Release.log;verbosity=normal;encoding=UTF-8"'
```

## ビルド後イベントとプロジェクト登録

- 出力先は Debug / Release 共通で `C:\ProgramData\aviutl2\Plugin\SYNC_TV\`。DLL を `SYNC_TV.auf2` へコピーし、成功後に DLL を削除する。Release では RSM も削除する。
- イベントはコピー元の一行の `copy ... && del ...` を維持する。後続コマンドが `if` の条件内へ取り込まれる `&&if errorlevel ...` の連結へ戻さない。
- DCU は `Win64\Debug\DCU` / `Win64\Release\DCU`。AUF2 の更新時刻・サイズと、DLL / Release RSM が残っていないことを確認する。
- デバッガーホストは参照元の .dproj と同じく両構成とも D:\aviutl2_v2.1.16\aviutl2.exe。
- ユニット追加時は `.dpr` の `in` と `.dproj` の `DCCReference` を両方更新する。現在の検索パスは `Source\Common`、`Source\Lib`、`Source\Lib\FilterTable`、`Source\Plugin\Filter`。
- 開いている `.dpr` / `.dproj` を外部更新した場合は、IDE で開き直して参照を読み込む。古い内容で保存して追加ユニットの参照を失わないようにする。
- MSBuild 成功と IDE の Code Insight・メッセージ表示は区別する。IDE 内のビルドを未確認なら、確認済みと報告しない。

## コメント・分割・文字コード

- ユニット先頭に目的と責務を書く。
- 公開処理には入力、出力、重要な副作用を記載する。必要に応じて値の単位、状態の有効範囲、所有権、保存対象も明記する。
- ホストの画像・テーブル・項目ポインター、描画バッファ、キャッシュは、誰が保持・解放するかを書く。コードをそのまま言い換えるコメントは避ける。
- 日本語を含む `.pas` / `.dpr` / Windows PowerShell 用 `.ps1` は UTF-8 BOM 付きとし、改行は CRLF にする。
- 1ユニットは約1,500行を目安に責務で分割する。UI・描画・データ処理を分け、フォームの `.pas` と `.dfm` は同じフォルダーへ置く。
- SDK 型の順序・サイズ・配置を変更する場合は公式定義と照合する。ホスト所有ポインターをコールバックの外へ保存せず、DLL 境界へ例外を漏らさない。

## 検査とアプリ操作

- 通常のビルド・検査では AviUtl2 と IDE を起動・操作しない。画面操作はユーザーから明示依頼がある場合に行う。
- 本体を検査する場合は同じ本番 AUF2 を読み込む。検査用の別プラグインは追加しない。
- コピー元プロジェクト、ユーザーの AUP2、他のプラグインは変更しない。


## Setup の扱い

- 初期作成時は SYNC_WeatherFX の setup を全ファイルそのままコピーした。v1.0.0 の配布準備で `Setup` のバッチ、手順書、カタログ、ZIPを SYNC_TV 用に整えた。

## 描画とタイムライン

- `TV_Programs` が番組を選択し、`TV_Studio`、`TV_Sports`、`TV_Entertainment` の各番組が共通の描画素材を使う。描画は960×540の Direct2D / DirectWrite。ブラシ、フォント、静的なパスと直近の番組面をエフェクトごとに再利用する。
- `TV_Screen` が液晶の環境光・角丸・ベゼル・スタンドを描く。四隅補正は逆射影とアルファ加重補間で描画し、画像中心を維持する。画素寸法が過大になる射影や頂点が交差する補正は元の形状を表示する。
- AviUtl2の標準描画が座標・中心・軸回転・拡大率・透明度を担当する。遠近付きの3D回転は AviUtl2 のカメラ制御を使用する。プラグインは RGBA のメディア入力を提供する。
- `TV_Parameters` は SDK の `OBJECT_INFO.effect_handle` と `EDIT_SECTION.get_effect_track_value` で、このエフェクトのチャンネル値をシーンのフレーム位置から取得する。演出時間に必要な範囲だけ過去のフレームを読み、値が変わった位置から電源オン0.36秒・オフ0.32秒・切替0.26秒を適用する。オブジェクトの先頭や履歴の取得に失敗した場合は、そのフレームの定常状態を描く。
- SDK の宣言は参照元から必要なフィールドを追加する範囲にとどめた。[公式配布の AviUtl ExEdit2 Plugin SDK](https://spring-fragrance.mints.ne.jp/aviutl/) の `filter2.h` / `plugin2.h` と照合し、Win64 のフィールドオフセットも検査する。

## 描画の検査

プロジェクトルートからビルド済みのAUF2を読み込んで検査する。第2引数にフォルダーを指定すると、番組と四隅補正のフレームをBMPに出力する。

```powershell
New-Item -ItemType Directory -Force Win64\Verification | Out-Null
cmd /c 'call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && dcc64 -B -Q -EWin64\Verification -NUWin64\Verification Tests\TV_RenderTests.dpr'
.\Win64\Verification\TV_RenderTests.exe 'C:\ProgramData\aviutl2\Plugin\SYNC_TV\SYNC_TV.auf2' 'Win64\Verification\Previews'
```

### 初回の確認結果

- Win64 Debug / Release とも警告0・エラー0。ビルド後イベントで Release を `C:\ProgramData\aviutl2\Plugin\SYNC_TV\SYNC_TV.auf2` に配置した。
- 本番AUF2の検査は両構成とも成功。チャンネル0～20と未割り当て番号、逆シーク、電源・切替演出、透過、環境光、四隅補正、複数インスタンス、描画スレッド切替を確認した。両構成の確認画像23枚はハッシュが一致した。
- `Win64/Verification/TV_preview.png` は番組と四隅補正の確認画像。AviUtl2上での操作とエンコードは未検証。
- `Setup` はカタログ・ZIPを含む5ファイルすべてが参照元と SHA-256 一致。

### 2026-11-24 人物と番組の描画調整

- 共通人物の黒目とハイライトを大きくし、肩・ひじ・手首を基準に袖と手を描く。アニメとスポーツ選手にもひじのある腕を描き、野球のバットは手に追従させる。
- CH11の解説者を細身にし、地図と予報ボードの双方を指示棒で案内する。CH12は芝と外野フェンスを中心とした屋外球場に変更した。
- CH13はコートを横向きにし、左右のゴールと交互に攻める場面を描く。選手の位置をコート内に収める。
- CH14の3人の顔を輪郭、髪型、眼鏡などで描き分けた。CH15は口元のマイクを大きくした。
- 描画例は `Win64/Verification/TV_adjustments.png`。Win64 Debug / Release は警告0・エラー0。両構成のAUF2描画検査は成功し、確認画像23枚が一致した。Release版は通常の出力先へ配置した。

### 2026-11-24 野球のスイング

- 打者の構え、踏み込み、両手でのスイング、振り抜き、走塁に入る際のバットの落下をフレーム時刻から描く。安打時はバットの芯と打球軌道が同じ点でつながり、空振り時はボールが外角低めを通る。
- 確認画像は `Win64/Verification/TV_baseball_swing.png`。Win64 Debug / Release は警告0・エラー0。両構成と配置済みReleaseの描画検査が成功し、前版との比較ではCH12以外の検査フレームが一致した。

- 打者を前版の78%に縮小し、バット、ミート位置、走り出しの座標にも同じ倍率を適用した。走者は奥へ進むにつれて縮小する。`Win64/Verification/TV_baseball_size.png` に前後比較と打席の確認画像を保存した。両構成と通常出力先に配置したReleaseの描画検査が通過した。

### 2026-11-24 正式版 v1.0.0

- AUF2の表示とカタログをv1.0.0に揃え、READMEに番組例とインストール・アンインストール手順を記載した。ZIPに実行用フォルダーと対応ソースを収録し、GPLおよびSDK由来部分のMITライセンスを同梱した。
- カタログの配布元は `vramwiz/SYNC_TV` を想定した。インストールは `{tmp}/SYNC_TV` を `{pluginsDir}/SYNC_TV` にコピーし、アンインストールは同じフォルダーへの1件の `delete` とした。隔離環境で隣接プラグインと展開済みソースを残して対象フォルダーだけ削除できた。バッチはプラグイン親フォルダーを削除しようとする設定を拒否した。[カタログ v0.3.3 のフォルダー削除処理](https://github.com/Neosku/aviutl2-catalog/blob/v0.3.3/src/utils/installer/fs-ops.ts)
- Win64 Debug / Release は警告0・エラー0。配置済みReleaseとZIP内のAUF2が一致し、両構成とZIP内の対応ソースから再ビルドした版の描画フレームも一致した。
- ZIP SHA-256 `CBA651C05A47088064E335B34DE147F5A348522F46D0D9FB36209EDBB5AC228D`。AUF2 XXH3-128 `ba17fe77e613f095ef18a7f6b8d627a1`。

## AviUtl2カタログ登録時の共通ルール

1. **概要は35文字以内。** `Setup/*.catalog.json` の `summary` は、JSONのエスケープ表記ではなく実際の表示文字列を数える。機能の詳細や補足は概要に詰め込まず、説明・READMEに記載する。
2. **既存タグを優先する。** [公開カタログの `index.json`](https://github.com/Neosku/aviutl2-catalog-data/blob/main/index.json) で、同じ製品や近い用途に使われているタグの表記を確認し、用途を表すものだけを選ぶ。同義語を重ねたり、製品ごとに新しいタグを量産したりしない。
3. **配布専用フォルダー単位で導入・削除する。** ZIP内を製品専用フォルダーにまとめ、ダウンロード・展開後の配置はフォルダーの `copy` 1件、アンインストールはその専用フォルダーだけを指定する `delete` 1件を基本とする。共有フォルダーや、ユーザー素材・設定を含むフォルダーは一括削除しない。既存パッケージで変更する際は、配布ZIPの配置とセットアップスクリプトの検証条件も確認し、整合しない場合は既存の手順を維持する。
