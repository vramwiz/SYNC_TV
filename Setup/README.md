# SYNC_TV の配布ZIP作成

`make_release_zip.bat` はビルド済みの Win64 Release 版を梱包し、カタログの `XXH3_128` をZIPに入れたAUF2の値で更新します。

## 準備と実行

1. Delphi で `SYNC_TV.dproj` の Win64 Release をビルドします。AUF2の標準出力先は `C:\ProgramData\aviutl2\Plugin\SYNC_TV` です。
2. Windows x64 版の `xxhsum.exe` を `Win64\Dependencies\xxHash-0.8.4` か PATH 上に置きます。 [xxHash公式のWindows版](https://github.com/Cyan4973/xxHash/releases/download/v0.8.4/xxhsum_win64_v0_8_4.zip)
3. プロジェクトのルートで次を実行します。

```bat
Setup\make_release_zip.bat
```

別の出力先や `xxhsum.exe` を使う場合は、次のように指定できます。

```bat
Setup\make_release_zip.bat -ReleaseDirectory "D:\Release\SYNC_TV" -XxhsumPath "D:\Tools\xxhsum.exe"
```

## 配布物

- `SYNC_TV.zip` の `SYNC_TV` フォルダーにAUF2、README、サンプル画像、GPL・MITのライセンス情報を収録します。
- 同じZIPの `SYNC_TV-source` フォルダーに対応ソースと Delphi プロジェクトを収録します。AviUtl2へ配置するのは `SYNC_TV` フォルダーです。
- `SYNC_TV.catalog.json` の最新版は `v1.0.1` です。展開後の `{tmp}/SYNC_TV` を `{pluginsDir}/SYNC_TV` へ1回でコピーし、アンインストールも同じインストール先フォルダーを1件の `delete` で削除します。
- カタログの配布元には `vramwiz/SYNC_TV` の GitHub Releases を指定しています。公開するときはリリースのタグとカタログのバージョンを合わせ、実際の公開日に `release_date` を設定してください。
