# 時のオカリナ — 自作データによる再制作
# Ocarina of Time — Authored Fan Reconstruction

> [!CAUTION]
> **LEGAL DISCLAIMER & LIMITATION OF LIABILITY / 法的免責事項・責任の免責**
> - **English**: This is an **unofficial, non-commercial fan reconstruction** adapting and referencing intellectual property owned by Nintendo Co., Ltd. without official authorization. The creators and contributors assume **ABSOLUTELY NO LIABILITY OR RESPONSIBILITY** for any claims, damages, takedowns, or legal consequences arising from using, running, or forking this code. **USE ENTIRELY AT YOUR OWN RISK.** All trademarks and copyrights belong to Nintendo Co., Ltd. **NO copyrighted ROMs, rips, or official Nintendo assets are included.** See [LEGAL_DISCLAIMER.md](LEGAL_DISCLAIMER.md) and [LICENSE](LICENSE).
> - **日本語**: 本リポジトリは、任天堂株式会社の知的財産（『ゼルダの伝説』）を元に、公式の許諾なく個人的・非公式に模倣・再構成した**ファンメイド作品**です。**任天堂株式会社とは一切関係がありません**。本コードの利用・実行・フォーク・再配布等により生じたいかなる損害・法的トラブル・不利益についても、**作者および開発者は一切の責任を負いません（完全自己責任）**。本リポジトリには任天堂の著作権保護対象であるゲームROMや抽出アセットは一切含まれていません。詳細は [LEGAL_DISCLAIMER.md](LEGAL_DISCLAIMER.md) および [LICENSE](LICENSE) をご確認ください。

---

## 📚 Repository Governance & Documentation / 各種ドキュメント

| Document | Description |
|---|---|
| ⚖️ [LEGAL_DISCLAIMER.md](LEGAL_DISCLAIMER.md) | Trademark notices, liability waiver, and non-affiliation statements |
| 📄 [LICENSE](LICENSE) | MIT License with IP special disclaimer & limitation of liability |
| 🧩 [ATTRIBUTION.md](ATTRIBUTION.md) | Third-party software (Godot), CC0 scans (Poly Haven, MakeHuman), and credits |
| 🤝 [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines and strict "No ROMs / No Copyrighted Assets" rules |
| 📜 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Contributor Covenant Code of Conduct |
| 📈 [docs/PROGRESS.md](docs/PROGRESS.md) | Detailed verification ledger, frame metrics, and area progress |
| 🚢 [docs/NATIVE_PORT.md](docs/NATIVE_PORT.md) | Reference notes for the upstream native PC port (Ship of Harkinian) |

---

## 概要 / Overview

**制作中。全編のフル実装と、実写に近い3D品質への更新は未完了です。**
場面・配置・音・会話・進行をこのworkspaceで制作し、Godot Engine (v4.7+) で実行しています。環境の一部には出典を記録したCC0のスキャン・材質を使用しています。原作ROMからの抽出物やShipwright用O2Rではありません。全地域・ダンジョン・物語・道具・時間移動・エンディングまでという目標を維持しています。

## 起動 / Quick Start

### 1. ソースコードから実行 (Developer Preview)
Godot 4.7.2+ が必要です。[Play Source Preview.command](<Play Source Preview.command>) または以下のコマンドで起動します：
```sh
# アセットのインポート
python3 tools/authored.py import

# ゲームの起動
python3 tools/authored.py play
```

### 2. ビルド済みアプリの起動 (Prebuilt Releases)
GitHub Releases（または同梱スクリプト）から配布されるパッケージを利用する場合：
- [Play Ocarina of Time.command](<Play Ocarina of Time.command>) を実行し、`Begin journey` を選びます。
- 保存先は `runtime/authored-save.json`。`Continue saved journey` で再開します。
- command経由では同じ保存先の二重起動を防ぎます。旧移植版の保存先とは別です。app単体を別の場所へコピーした場合は、その隣の `Ocarina Saves/authored-save.json` に保存します。

0.5にはジャブジャブ様の体内、時の神殿と大人への目覚め、墓地とHookshot、迷いの森と森の神殿、森のメダルと時間往復、七年後のゴロンシティ、火口、炎の神殿の最初の三つの牢までを収録しました。鉄格子は衝突を保って上昇し、停止・再開に追従します。外部入力の範囲は [アセットの出典](production/authored/THIRD_PARTY_ASSETS.md) を参照してください。

## 現在の冒険

1. **コキリの森** — サリアに話し、剣を取り、8個の青ルピーを集め、店で盾を買います。ミドに装備を見せてデクの樹へ。
2. **デクの樹の5部屋** — 坂を登ってパチンコを入手。Qで目の仕掛けを狙い、Rで撃ちます。ツタを登って高い枝から中央の巣へ落ち、地下では松明の火を巣へ運びます。3兄弟の木の実を盾で反射し、2→3→1の順に話します。
3. **ゴーマ** — 赤い目をパチンコで撃ち、ひるんだ間に剣で攻撃。倒して光に入ると、エメラルドとハートを得て森に帰還します。サリアからオカリナを受け取り、西のトンネルへ。
4. **平原・城下町・城** — 北の道から城下町へ。マロンから卵を預かり、平原の牧場東にある焚き火で朝まで休みます。城の配達口でタロンを起こし、衛兵の視線を避けて庭を進みます。ゼルダに2回話して手紙を受け取り、インパに子守唄を教わります。
5. **ロンロン牧場と帰郷** — 平原中央の牧場でマロンの歌を習い、演奏するとエポナが近づきます。タロンから2回飲めるミルクの瓶を受け取れます。森へ戻るとサリアから新しい歌を習えます。
6. **カカリコ村・デスマウンテン・ゴロンシティ** — 平原の北東へ。衛兵に手紙を見せ、3段の山道を登ります。王家の紋章の前で子守唄、ダルニアの前でサリアの歌を演奏すると腕輪を得ます。山道の爆弾花を持ち上げ、採石場の岩を壊します。村では3羽のコッコを連れ戻す小さな依頼もあります。
7. **ドドンゴの洞窟の7部屋** — 東の通路でリザルフォスを倒し、爆弾花の列の中央を爆破。開いた坂を登り、目のスイッチを撃ってボム袋へ。巨像の頭上で左右のくぼみに爆弾を置くと、下の口が開きます。
8. **キングドドンゴ** — 口を開いて吸い込む間に爆弾を投げ、倒れている間に剣で攻撃。立ち上がったら外周へ退避して転がりを避けます。勝利後の光から山へ戻ると、ゴロンのルビーとハートを得ます。


9. **ゾーラ川と里** — 平原の東の道へ。川岸の岩を爆弾で壊し、橋を渡って上流へ進みます。滝の前の王家の紋章で子守唄を演奏すると、里に入れます。
10. **潜水ゲームとハイリア湖** — 里の西の坂を登って潜水の主催者へ。20ルピーを払い、55秒以内に水中の青ルピーを5個集めます。Spaceを押して潜り、離して浮上。岸の薄い色の坂から戻り、主催者に話すと銀のウロコを得ます。里の南東の水中通路を抜け、湖底の瓶を拾ってルトの手紙を読みます。湖の陸路は平原にもつながります。
11. **王の許可とゾーラの泉** — 手紙を王に見せると道を空け、空き瓶をもらえます。里の東側の浅い池でVを押して魚を捕り、王の後ろの道から泉へ。桟橋を進んでジャブジャブの口の前でVを押すと、魚を捧げて口が開きます。旧0.4 appの範囲はここまでです。0.5 appでは以降の体内から炎の神殿の序盤まで続きます。

12. **ジャブジャブ様の体内（0.5）** — 天井の膜をパチンコで開き、ルトを追って水の部屋へ。会話後にEで抱え、右の圧力板を踏んでから水場の縁を回って上へ戻ります。分岐の東の丸い板にルトを置き、奥のStingerを倒してブーメランを取得。Tで投げます。
13. **三本の根とBig Octo（0.5）** — 西・東・北の順で、根が伸びた間にブーメランを当てます。西の奥では泡を時間内に消す任意課題。ルトを迎えに戻り、穴の部屋の北から祭壇へ連れて行きます。Big Octoをブーメランで止め、背面に回って剣で攻撃します。
14. **Barinadeとサファイア（0.5）** — 震える二つの足場をブーメランで静めて渡り、最後の膜の左から奥のスイッチを狙います。ボスの天井接続を三本切り、周囲のBiriを倒し、本体をひるませて剣で攻撃。勝利後にルトの光へ入るとサファイアとハートを得て泉へ戻ります。

15. **城門の事件と青いオカリナ（0.5）** — 三つの精霊石を持って平原北の城門へ向かい、Eを押します。事件の後、橋の東側の堀へ入り、青い楽器の近くでSpaceを押して潜り、Eで拾います。記憶から時の歌を習得。南側の坂で陸へ戻れます。
16. **時の神殿（0.5）** — 城下町の北東の道へ。祭壇の前でEを押して精霊石を置き、1でオカリナを出して `L J K L J K` を演奏します。祭壇の横を回り、開いた扉の奥へ進みます。
17. **マスターソードと七年後（0.5）** — 台座でEを押して剣を調べ、もう一度Eで抜きます。賢者の間で目覚め、光のメダルを受け取って神殿へ戻ります。シークに話すと次の道筋を聞けます。演出中はEscで停止・再開できます。

18. **七年後の町と墓地（0.5）** — 城下町は廃墟となり、ReDeadが徘徊します。カカリコ村の東から墓地へ進み、西側の花が置かれた墓石でEを押して動かし、もう一度Eで地下へ。村には城下町から移った住民もいます。
19. **墓守の試練とHookshot（0.5）** — ダンペイに話し、ランタンを追います。火を避け、閉まる門を通って最後まで進むとHookshotの宝箱が開きます。遅れたらEで再挑戦。取得後の再走を60秒以内で終え、ダンペイに話すと一度だけハートのかけらを得ます。
20. **風車小屋（0.5）** — ゴール脇の青い石の前で時の歌を演奏し、Eで上段へ抜けます。上の宝箱にはハートのかけら。下にいる管理人から嵐の歌を習得できます。HookshotはQで木の的を狙い、Rで発射。14m以内なら上段へ引き寄せられます。
21. **墓地の任意探索（0.5）** — 兵士の墓の宝箱からハイリアの盾。大人ではShiftで構えます。王家の墓で子守唄を演奏して入り、コウモリを倒して奥の碑文から太陽の歌を習得。別の墓で太陽の歌を演奏するとハートの宝箱が現れます。子供が墓石を動かせるのは夜。ハートのかけらは四つで最大ハートが一つ増えます。

22. **迷いの森と森の聖域（0.5）** — 大人で森の北東へ。分岐ではEで旋律を聞いて進み、ミドの前でサリアの歌を演奏します。聖域の生け垣の切れ目を抜け、シークから森のメヌエットを習得。Hookshotで奥の枝をつかむと神殿の上段へ届きます。
23. **森の神殿の前半（0.5）** — 入口の木と北のスタルフォスの部屋で鍵を入手。中央広間の西奥の青い石を時の歌で消し、中庭のツタからMapの部屋へ。東の中庭上段で井戸を排水し、地下の鍵を回収します。広間の西手前の扉を開け、二つの積み木を押して上段へ。スタルフォスの一体戦と二体戦を終えると妖精の弓を得ます。
24. **赤と青の炎・Boss Key（0.5）** — 弓で絵のポウを追い、姿を現した間に剣で倒します。赤の鍵を入手したら、西のねじれた廊下の目を射て宝物庫へ。下層の敵と分裂するフロアマスターを倒して鍵を取り、廊下を再びねじらせて青のポウへ進みます。Xで弓とHookshotを切替えます。
25. **氷の目・落ちる天井・緑の炎（0.5）** — 東の回転床へ坂から乗り、中央の火と凍った目が一直線になる時に矢を放ちます。天井の落ちる部屋では淡い色の安全な床を使います。緑の絵を射たら、Eで四つの積み木を番号の床へ押し、60秒以内に完成させます。余分な積み木もあります。現れたポウを倒して中央広間へ。
26. **最後の炎と地下室（0.5）** — 四体の分身のうち、最初に回転する一体が本体です。弓で倒すと四つの炎が揃います。中央の床でEを押して地下へ。中央のレバーで壁を回し、三つの小部屋のスイッチを押してボスの通路を開けます。
27. **ファントムガノンと森のメダル（0.5）** — 絵から前へ出てくる実体を三回射ると、剣で魔法弾を打ち返す戦いになります。相手が打ち返す弾にもFを合わせ、ひるんだら近づいて剣で攻撃。光に入りサリアに二回話すと、森のメダルとハートを得ます。
28. **森の回復と時間の往復（0.5）** — デクの樹の芽から四つの話を聞けます。時の神殿のシークは光のプレリュードを教えます。台座でEを押して剣を戻すと子供へ、再び抜くと大人へ。メヌエット `J I U L U L` は聖域へ、プレリュード `I L I L U I` は時の神殿へ戻ります。

29. **七年後のゴロンシティ（0.5）** — 転がる小さなゴロンを、注目した弓か爆弾で止めます。3回話して事情を聞き、ゴロンの服を受け取ります。北のダルニアの部屋に進み、奥の石像をEで引くと火口への道が開きます。部屋の右には救出用の補給があります。
30. **デスマウンテン火口（0.5）** — 橋の切れ目へ進み、対岸の木の的をQで注目してHookshotを撃ちます。Xで弓から切り替えます。渡った先のシークから炎のボレロを習い、北の入口から炎の神殿へ。服は火口と神殿で自動的に着用しますが、溶岩に落ちればダメージを受けます。
31. **炎の神殿・最初の三つの牢（0.5）** — 入口の西でダルニアと話し、溶岩上の通路から西の牢の床スイッチへ。牢内の宝箱の鍵で入口東の扉を開けます。次の大きな溶岩の部屋は両側に牢があり、東側のひび割れた壁は爆弾で壊します。各牢の床スイッチを踏み、住民の話と宝箱を確認してください。
32. **炎のボレロと現在の制作境界（0.5）** — `K J K J L K L K` の8音で火口の石の円へ戻れます。現在の炎の神殿は入口・ダルニアの部屋・溶岩橋・東西の牢の5区画までです。北の昇降筒から先、ハンマー、Volvagia、炎のメダルは未実装で、この先への進行はまだできません。全神殿の制作を継続しています。

配置や攻略は自作の簡略再構成です。原作の全マップ・部屋・イベントを忠実に復元したものではありません。騎乗、大人時代の残る地域・炎の神殿の上層以降と他の大人神殿・終盤・任意要素の多くは未実装です。墓地周辺にも原作の全地形・多層の墓守コース・掘り当て遊び・闇の神殿・井戸の底などが残ります。森の神殿は鍵・弓・四姉妹・ボス・報酬を実装していますが、原作の全地形・敵・演出への一致、MapとCompassの地図表示、全失敗経路の検証は残ります。城下町の廃墟とカカリコの会話・住民を追加しましたが、大人世界の完成版とは扱いません。人物・生物・各場面の完成品質も継続中です。

## 操作

| 操作 | キー |
|---|---|
| 移動 / ツタを登る・下りる | W / A / S / D |
| カメラを回す | ← / → |
| 会話・宝箱・買い物・出入口・休息 | E |
| 注目 / 解除 | Q |
| パチンコ（子供） / Hookshot（大人） | R |
| 妖精の弓を引く / 放つ（大人） | Rを押す / 離す |
| 弓 / Hookshotの切替 | X |
| ブーメラン | T |
| ルトを抱える / 置く / 投げる | E / E / T |
| 爆弾を取り出す / 投げる / 置く | C / C / E |
| 爆弾花を持ち上げる（腕輪が必要） | E |
| 剣 / 盾 / 回転移動 | F / Shift / Space |
| オカリナを出す・しまう | 1 |
| オカリナの音符 | J＝A、K＝↓、L＝→、U＝←、I＝↑ |
| 潜る / 浮上する（水中） | Spaceを押し続ける / 離す |
| 空き瓶で魚を捕る / 魚を捧げる | V |
| ミルクを飲む | B |
| 音の消音・復帰 | M |
| セーブ / 停止・再開 | F5 / Esc |

演奏中は覚えた歌とキー列を表示します。現在習得できるのは子守唄・エポナの歌・サリアの歌・時の歌・太陽の歌・嵐の歌・森のメヌエット・光のプレリュード・炎のボレロ。演奏は曲ごとの長さで認識し、間違えた場合はオカリナをしまわず最初からやり直せます。嵐の歌による井戸の底への進行はまだありません。倒されたらEで部屋の入口から再挑戦し、装備と解いた仕掛けを保持します。

## 自作データと編集元

- [最新版0.5の制作データ](builds/authored-data-20260930T093859Z.zip)：254 source files。炎の神殿序盤・上昇する鉄格子・人物と装備・Blender編集元・生成source・検証sourceを含みます。appは別のZIPです。展開後は `ARCHIVE_README.md` の手順で起動してください。

- [森の神殿追加時点の制作データ](builds/authored-data-20260929T065534Z.zip)：迷いの森・森の神殿・弓・四姉妹・Phantom Ganon・森のメダル・時間往復までを含む231 source files。ゲーム・Blender編集元・生成source・出典・検証sourceを収録。全編と最終3D品質は未完了です。展開後は `ARCHIVE_README.md` を参照してください。

- [墓地追加時点の制作データ](builds/authored-data-20260929T044914Z.zip)：墓地・墓守の試練・Hookshot・盾・歌までを含む204 source files。ゲーム・モデル・Blender編集元・生成script・出典・検証を収録。全編と最終3D品質は未完了です。展開後は `ARCHIVE_README.md` を参照してください。

- [大人の山・火口・炎の神殿のデータ](game/data/fire_mountain.json)、[山と火口の進行](game/scripts/fire_quest.gd)、[最初の牢の進行](game/scripts/fire_temple.gd)、[ゴロンの編集元](production/authored/fire-assets/goron-study.blend)、[モデルと溶岩材質の生成source](production/authored/make_fire_assets.py)、[写真参照と生成物のmanifest](production/authored/fire-reference-manifest.json)。造形・配置・炎の神殿全体は制作中です。

- [森の神殿の部屋・会話・仕掛け](game/data/forest_temple.json)、[神殿の進行](game/scripts/forest_temple.gd)、[迷いの森と聖域](game/scripts/woodland.gd)、[敵とボス](game/scripts/forest_enemy.gd)。
- [弓と矢の編集元](production/authored/forest-equipment/bow-and-arrow.blend)、[骨格兵の形状study](production/authored/forest-equipment/stalfos-study.blend)、[生成source](production/authored/make_forest_equipment.py)、[出典manifest](production/authored/forest-reference-manifest.json)。骨格兵や馬・住民の最終造形は未達です。

- [墓地と住民のデータ](game/data/graveyard.json)、[墓地・追走・任意探索](game/scripts/graveyard.gd)、[Hookshotの物理処理](game/scripts/hookshot.gd)、[ReDead・Keese](game/scripts/grave_enemy.gd)。
- [Hookshot・ハイリアの盾の編集元](production/authored/graveyard-equipment/equipment.blend)、[制作source](production/authored/make_hookshot.py)、[墓石の編集元](production/authored/grave-marker/gravestone.blend)、[刻字・石材の生成source](production/authored/make_gravestone.py)。

- [大人の主人公](game/assets/link_adult.glb)、[Blender編集元](production/authored/adult-link-study/link-adult.blend)、[マスターソードと鞘の編集元](production/authored/master-sword/master-sword.blend)。大人の形状はCC0の成人morphと再調整した衣装で作成し、品質調整を継続しています。
- [時の神殿と物語](game/data/time_quest.json)、[進行と時間の切替](game/scripts/time_quest.gd)、[石造の空間](game/scripts/time_temple_art.gd)、[神殿の石材生成](production/authored/make_temple_materials.py)。
- [現在の主人公](game/assets/link_anatomical.glb)、[Blender編集元](production/authored/link-study/link-anatomical.blend)、[生成source](production/authored/make_link_anatomical.py)。CC0の人体・肌・髪・衣服の入力と、ここで制作した衣装・骨格設定・10動作を組み合わせています。
- [剣・鞘・盾の編集元](production/authored/equipment/equipment.blend)、[生成source](production/authored/make_equipment.py)。形状・木目・装飾をここで制作しています。
- [旧キャラクター編集元](production/authored/characters.blend)、[旧生成source](production/authored/make_characters.py)。既存NPCはこの仮モデルの派生で、品質更新が残っています。
- [森の配置](game/data/kokiri.json)、[地域・住民・会話](game/data/hyrule.json)、[演奏パターン](game/data/songs.json)。
- [山の地域・会話](game/data/mountain.json)、[村・山・ゴロン族](game/scripts/mountain.gd)、[ドドンゴの洞窟](game/scripts/dodongo_dungeon.gd)、[爆弾](game/scripts/bomb.gd)、[リザルフォス・ドドンゴ](game/scripts/reptile.gd)。
- [川・里・湖・泉のデータ](game/data/zora.json)、[ゾーラ族と水辺の進行](game/scripts/zora.gd)、[水面](game/shaders/water.gdshader)。
- [体内の部屋・会話](game/data/jabu.json)、[仕掛けとルト](game/scripts/jabu_dungeon.gd)、[体内の敵・ボス](game/scripts/jabu_enemy.gd)、[ブーメラン](game/scripts/boomerang.gd)、[生体の形状](game/scripts/jabu_art.gd)。
- [環境・材質](game/scripts/art.gd)、[デクの樹](game/scripts/deku_dungeon.gd)、[平原・町・城・牧場](game/scripts/overworld.gd)。
- [戦闘と敵](game/scripts/creature.gd)、[飛び道具](game/scripts/projectile.gd)、[移動・カメラ](game/scripts/player.gd)、[進行・保存](game/scripts/world.gd)。
- [音の制作source](production/authored/make_audio.py)：4効果音、5つの演奏音、6つの地域・戦闘用ループを合成。BGMは自作曲で、原作楽曲・録音音声ではありません。
- [時の神殿追加時点のデータ](builds/authored-data-20260929T040353Z.zip)：城門の事件、時の神殿、マスターソード、大人への目覚めまでを含む180 source files。モデル・Blender編集元・材質生成・会話・進行・検証を含みます。全編・写実品質・性能の安定化は未完了です。
- [体内追加時点のデータ](builds/authored-data-20260929T032019Z.zip)：体内の14区画・ルト・ブーメラン・敵とボス・サファイア取得を含む145 source files。全編と3D品質は未完了です。展開後は `ARCHIVE_README.md` を参照してください。
- [人物・里の更新時点のデータ](builds/authored-data-20260929T022309Z.zip)：人物の10動作・装備・里の更新を含む、体内追加前のsource、Blender編集元、出典とhash。展開後は同梱の `ARCHIVE_README.md` を参照してください。全編と写実品質は未完了です。
- [自作データ一式](builds/authored-data.zip) はversion 0.4段階の配布物です。原作ROMではありません。進行中の材質・人物研究はsourceと `production/authored/` にあり、この旧ZIPの検証結果には含めません。
- [2026-09-29制作中データ](builds/authored-lookdev-data-20260929.zip)：里の更新と、未採用の人物研究を含むsourceのsnapshot。完成版ではありません。
- [里の材質・石組み](game/scripts/natural_art.gd)、[新しい水面](game/shaders/water_realistic.gdshader)、[人物研究の制作source](production/authored/make_link_anatomical.py)、[外部入力と再生成方法](production/authored/THIRD_PARTY_ASSETS.md)。

## build・検証

作業ディレクトリは `ocarina-of-time/`。sourceにはGodot 4.7.2、モデルの再生成にはBlenderを使用します。Mac appにはGodot実行ファイルを同梱しています。

```sh
python3 tools/authored.py import
python3 tools/authored.py play
python3 tools/authored.py verify --time-quest --fixture --metal
python3 tools/authored.py verify --graveyard --fixture --metal
python3 tools/authored.py verify --forest-temple --metal
python3 tools/authored.py verify --fire-mountain --metal
OOT_FIRE_STAGE=contracts python3 tools/authored.py verify --fire-mountain
OOT_FOREST_STAGE=contracts python3 tools/authored.py verify --forest-temple
python3 tools/authored.py verify --time-quest --fixture --dungeon --metal
python3 tools/authored.py verify --character --metal
python3 tools/authored.py verify --jabu --fixture --metal
python3 tools/authored.py verify --jabu --metal
python3 tools/authored.py build
python3 tools/authored.py verify --packaged --fire-mountain --headless
python3 tools/authored.py verify --packaged --zora
python3 tools/authored.py verify --packaged --combat
python3 tools/authored.py verify --packaged --bomb-test
python3 tools/authored.py assets
```

`assets` は完全なgame project・制作source・hashを日時付きの新しいZIPに保存し、CRCとhashを確認します。既存archiveは保持します。`--character` は装備と位置を用意し、人物の操作・持ち上げ・装備・停止を確認して近景を撮影するfixtureです。

`--metal` はnative Metal / Forward+でsourceやpackageを検証する指定です。既定のappはOpenGL Compatibilityです。`--headless` は画面・音声を出さず入力・物理・進行を検証します。描画・音・GPU性能の証拠にはなりません。検証は専用saveと専用ログをevidenceに保存し、完了したpassing reportがなければ成功扱いにしません。

`--time-quest --fixture` は三つの精霊石までを準備した状態で、城門の事件から大人への目覚め・保存まで新しい区間を操作します。`--dungeon` を併用すると開いた神殿の台座からの専用fixtureです。時間を往復する検証では森のメダルを直接準備します。どちらも森からの新規全編通しや森の神殿の攻略を示すものではありません。

`--fire-mountain` は大人・弓・Hookshot・爆弾・腕輪・森のメダル等を明示的に準備したfixtureで、ゴロンシティから三つの牢、保存と火口への帰還までを入力で検証します。照準対象の選択は補助します。`--capture-only` は耐熱服を準備した火口から最初の牢まで。`OOT_FIRE_STAGE=contracts` は鍵不足、熱と停止、落下復帰、演奏のやり直し、幼少期の制限等の境界fixtureです。`OOT_FIRE_STAGE=art` はゴロン三方向と火口の描画確認です。前段の通常獲得や全神殿完了の証拠とは分けます。

`--forest-temple` はHookshot取得後の装備を準備し、迷いの森から神殿の鍵・弓・四姉妹・ボス・報酬・時代往復を操作します。照準対象の選択には補助を使います。`--dungeon` は聖域から開始、`--capture-only` は代表中庭の描画とツタだけ。`OOT_FOREST_STAGE=art` は弓と骨格兵の複数方向の近景撮影です。`OOT_FOREST_STAGE=contracts` は鍵不足・再消費・時間切れ・敵再生等を調べる明示的な状態準備を伴う検証です。到達段階の独立saveは `OOT_FOREST_SAVE=/absolute/path/to/stage-save.json` で再検証できます。前半の獲得を再実行した証拠とは分け、identityに元saveのhashを記録します。

`--graveyard` は大人への目覚めまでの装備を準備したfixtureです。取得前の墓地から追走・Hookshot・風車小屋・任意の墓を操作します。`--dungeon` は取得済みHookshotからの契約fixture、さらに `--capture-only` を付けるとHookshotの物理処理だけを確認します。`--dungeon` なしの `--capture-only` は墓地の描画だけです。いずれも新規開始からの全編通しではありません。

`--jabu --fixture` は水辺の攻略後に相当する装備と開いた口から始め、体内の進行・ボス・報酬・境界条件を検証します。戦闘の注目対象はtestから指定する補助を使い、移動・攻撃・道具・相互作用は入力で行います。`--jabu` 単独は森の新規開始から接続します。`--jabu --fixture --dungeon` はルト・ブーメラン・根を用意した中ボス以降の専用fixtureです。いずれも人による全操作の受け入れとは区別します。

`--zora` は新規開始から森・山・水辺を進み、銀のウロコ、手紙、王の許可、魚の供物、保存と再開までを検証します。その後、時間切れ・息切れ・瓶の中身などの失敗条件を、明示的な状態準備を使って検証します。`--zora --capture-only` は4地域へ直接入る撮影用fixtureです。`--mountain` は新規開始から森・デクの樹・城・牧場・山・ドドンゴの洞窟・ルビー取得を通常の移動と操作入力で検証します。`--world` は城・牧場・森への帰還までを対象にします。`--bomb-test` は装備と位置を準備し、ボス戦と爆弾の残数・爆風・連鎖・停止等を検証します。`--combat` は装備・位置・敵の状態を明示的に準備し、失敗・防御・弾切れ・休息・音符の拒否等を調べる境界テストです。`--fixture` は開発用に前段の進行を付与する指定（`--zora` ではルビー取得後相当の装備と40ルピー）で、新規開始からの完走とは区別します。`--mountain --capture-only` は3地域と7部屋へ直接入り、入口の実画面を保存する撮影用fixtureです。

日時付きの `evidence/authored-*/` に実画面、結果、ログ、source hash、package hashを保存します。確認済みの版・範囲・性能と未確認事項は [進捗記録](docs/PROGRESS.md) を参照してください。人による操作感・楽しさの評価は未実施です。

[Godotライセンス](production/authored/GODOT-LICENSE.txt) を同梱しています。旧Shipwright版のsource・build・証拠は保持しています。旧版の手順は [移植版の記録](docs/NATIVE_PORT.md)、起動は `Play Native Port.command` です。
