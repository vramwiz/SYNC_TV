# ライセンスと共通基盤の由来

テレビ演出（SYNC_TV） Copyright (c) 2026 VRAMの魔術師

本プラグインのライセンスは GNU General Public License v3.0 のみ（GPL-3.0-only）です。 [ライセンス全文](LICENSE)

## AviUtl ExEdit2 Plugin SDK

`Source/Lib/AviUtl2FilterTypes.pas` に含まれる SDK 由来の型とコールバックの定義には、次の著作権表示と MIT ライセンスが適用されます。

- Copyright (c) 2025 Kenkun
- [AviUtl ExEdit2 Plugin SDK の MIT ライセンス全文](ThirdParty/LICENSE.AviUtl2-SDK.txt)

## 継承元

- **SYNC_WeatherFX** から Delphi プロジェクト、DLLの公開関数、SDKの型定義、フィルターテーブル登録処理、配布スクリプトを引き継ぎました。
- **SYNC_AquaFX**、**SYNC_ParticleFX**、**SYNC_Mine**、**SYNC_Nicomea** は共通基盤の継承元です。Win64 ビルド設定は **SYNC_PhotoShot**、フィルターテーブル登録処理は **Syncroh2 / SYNC_Lyrics** に由来します。

番組に登場する架空の人物・商品・背景と同梱のサンプル画像は、プラグインの描画処理で生成しています。描画には Windows の Direct2D、DirectWrite、システムフォントを使用します。

配布ZIPの作成には xxHash の `xxhsum.exe` を使用します。配布物のチェックサムを算出する開発用ツールです。 [xxHash のライセンス](https://github.com/Cyan4973/xxHash/blob/v0.8.4/LICENSE)
