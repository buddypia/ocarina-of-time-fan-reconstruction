# 時のオカリナ — native port

**準備中。全編の動作は未検証です。** ユーザーの依頼は『ゼルダの伝説 時のオカリナ』のフル実装です。ゲーム本体には [HarbourMasters / Shipwright 9.2.3](https://github.com/HarbourMasters/Shipwright/releases/tag/9.2.3) を使用します。これは既存の移植コードを使う構成であり、このworkspaceでゲーム全体を新規開発したという意味ではありません。

対象はこのMac（Apple Silicon、macOS）のnative実行です。原作のキャラクター、世界、ストーリー、全ダンジョン、ボス、道具、楽曲、時間移動、セーブ、エンディングまでが対象です。進捗と未検証項目は [docs/PROGRESS.md](../docs/PROGRESS.md) に記録します。

2026-09-29時点でsource buildと署名検証が完了し、同じローカルbuildでデータ選択画面を3回、各30秒以上確認しました。ゲームデータの抽出、本編の操作、セーブと再開、全編の進行は未検証です。

## 起動

`Play Ocarina of Time.command` を開きます。初回の `No O2R Files` 画面で `Yes` を選び、自分のゲームデータを指定します。現在、ゲームデータは同梱されていません。起動用の基盤だけではゲームをプレイできません。

以下のコマンドはすべて `ocarina-of-time/` で実行します。

```sh
python3 tools/oot.py status
python3 tools/oot.py verify-rom '/path/to/game.z64'
python3 tools/oot.py play '/path/to/game.z64'
```

`.z64`、`.n64`、`.v64` はヘッダーからbyte orderを判定し、正規化したSHA-1をこのreleaseの [対応表](../vendor/Shipwright/docs/supportedHashes.json) と比較します。確認処理は入力ファイルを変更しません。実際のアセット抽出は上流アプリの処理を使用します。9.2.3のゲームアーカイブ名は `oot.o2r` / `oot-mq.o2r` です。古い `oot.otr` を名前だけ変更して使用しないでください。

設定、セーブ、抽出データは `runtime/` に保存します。起動用commandは同じセーブフォルダーでの二重起動を防ぎます。直接 `soh.app` を開く場合は上流既定のApplication Supportを使用するため、このフォルダーの起動用commandを使ってください。既存のセーブを置換する処理は追加していません。

## 既定のキーボード操作

固定版の [ボタン定義](../vendor/Shipwright/libultraship/src/libultraship/controller/controldevice/controller/mapping/ControllerDefaultMappings.cpp) と [スティック定義](../vendor/Shipwright/libultraship/src/ship/controller/controldevice/controller/mapping/ControllerDefaultMappings.cpp) に基づく案内です。本編での入力確認は未実施です。

| キー | N64の入力 |
|---|---|
| W / A / S / D | 移動スティック |
| X | A（決定・状況に応じたアクション） |
| C | B（剣など） |
| Z | Z注目 |
| R | R（盾など） |
| Space | Start |
| 方向キー | Cボタン |
| E | L |

## ソース

- `vendor/Shipwright/`: upstream tag `9.2.3`、commit `cb71e22a79bc5d1f688fa881795bbd93094895fc` と指定submodule。libultrashipに後述のローカル修正を適用。
- `builds/official/soh.app`: 公式配布物。ダウンロードのSHA-256をGitHub releaseのdigestと照合済み。
- `builds/source/`: このMacのsource build用。
- `builds/local/soh.app`: このMacでbuild・起動確認済みのローカル実行用bundle。
- `tools/oot.py`: このworkspaceで追加したROM確認・起動ツール。

上流の [build手順](../vendor/Shipwright/docs/BUILDING.md)、ライセンスとクレジットはvendor内に保持します。

ローカル修正は [Metalテクスチャの参照管理](../production/patches/metal-drawable-ownership.patch) です。drawableから借りたテクスチャを次のフレームで解放する前に、保持する処理を追加しました。未修正版で観測した起動時クラッシュと整合する欠陥を修正していますが、長時間の安定性やゲーム中の全描画経路を保証する検証は未実施です。修正・失敗・再検証の記録は進捗文書に保存しています。

## 再build

Xcode、CMake、Ninja、HomebrewのSDL2、SDL2_net、libpng、glew、tinyxml2、nlohmann-json、libzip、spdlog、opusfile、libvorbisを使用します。

```sh
python3 tools/build.py
python3 -m unittest discover -s tools -p 'test_*.py' -v
python3 tools/smoke_native.py
python3 tools/smoke_native.py --seconds 30
```

buildは上流のCMakeのinstall処理でMac bundleを組み立て、SDL2互換ライブラリを使う場合はSDL3も同梱し、ローカルでad-hoc署名します。起動画面を検証してから `builds/local/soh.app` に配置します。`play` はこのbundleがある場合に優先します。`play --official` で公式版を選べます。buildログは日時付きで `production/logs/`、署名検証とbinaryのhashは `evidence/` に保存します。`smoke_native.py` は証拠フォルダー内の専用設定で起動し、自分が起動したプロセスのウィンドウだけを撮影して終了します。ROM未提供時の画面確認はゲームプレイ検証を意味しません。

`--exercise-window` は専用ウィンドウのresize・最小化・復帰を追加確認します。現在の環境ではAccessibility権限がなく未検証で、このオプションは非zero終了します。権限設定を変更する処理はありません。ほかのMacでの起動、notarization、Metal validation layer、長時間のプレイ性能も未検証です。
