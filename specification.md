Specification 仕様書
====================

本書はRuby製Bizgram DSLライブラリの仕様をまとめたものである。

コンセプト・背景
----------------

### Bizgram（ビズグラム）とは

- [Bizgram公式サイト](https://bizgram.zukai.co/) / [図解の説明書](https://bizgram.zukai.co/howto)

> ビジネスモデル図解とは、**「そのビジネスは誰（何）が関係してるの？ どんな関係なの？ を知るためのツール」** である。よりシンプルでわかりやすく相手に伝えるために、いくつかのルールがある。
> - `ルール1` 主体を３×３で構成する
> - `ルール2` モノ・カネ・情報の流れを矢印で説明する
> - `ルール3` 説明しきれない部分はふきだしの補足で説明する

ビズグラムを使うことで、自社のビジネスを可視化するだけでなく、自社の経営資源や強みを把握したり、投資家や経営陣に対する説明資料としても活用することができる。

### なぜRubyの内部DSLか

[Mermaid](https://mermaid.js.org/)や[PlantUML](https://plantuml.com/)のような独自の言語にはせず、Rubyの内部DSLを採用した。

- 独自の文法や専用パーサーを作る労力が削減できる
- 既存のRubyの構文（演算子オーバーロードやブロック等）を活用し、表現力豊かな記述が可能
- 開発者が慣れ親しんだエディタやツールチェインをそのまま利用可能

外部仕様（ユーザー向けAPI）
--------------------------

### コードサンプルと出力例

```ruby
require "bizgram"

Bizgram.draw "タイトル" do
  # 主体の定義
  entity :user, "太郎", :ct # 利用者
  entity :business, "HOGEビジネス", :cm # 事業
  entity :operator, "社員", :cb # 事業者

  # ショートカットでの主体定義
  jiro = user "次郎", [1, 0]
  fuga = business "FUGAビジネス", [1, 1]
  clerk = operator "販売員", [1, 2]

  # モノ・カネ・情報の流れの定義（従来の記法）
  arrow :object, "商品", business("FUGAビジネス"), user("太郎")

  # モノ・カネ・情報の流れの定義（直感的なDSL記法）
  user("太郎") -money("代金")> business("HOGEビジネス")
  operator("販売員") -info("広告")> user("太郎")
  jiro -money("代金")> fuga

  # その他の補足情報（コメント）の定義
  comment_to user("太郎"), "太郎君"
  comment clerk, "広告" # 3文字だけ短く書けるショートカット
end
```

生成されるSVG画像のイメージ（`example/04_test_dsl.rb` の実行結果）：

![](./example/04_test_dsl.svg)

### 主体の定義（Entity）

主体を定義する基本メソッドとそのショートカット。

#### `entity` メソッド

| 仮引数 | 必須 | 型 | 説明 |
| ------ | ---- | --- | ---- |
| `type` | * | `Symbol` | 主体の種類。`:person`(`:user`), `:company`(`:business`), `:money`, `:object`(`:goods`), `:information`(`:info`), `:smartphone`(`:device`), `:store`(`:shop`), `:other` |
| `name` | * | `String` | 主体の名称 |
| `position` | * | `Integer` \| `Symbol` \| `Array` | 配置位置。数値（`0`-`8`）、シンボル（`:lt`, `:cm`等）、または座標（`[x, y]`） |

**戻り値**: 主体を表す `Entity` オブジェクト

#### ショートカットメソッド

`person`(`user`), `company`(`business`), `money`, `object`(`goods`), `information`(`info`), `smartphone`(`device`), `store`(`shop`), `other` を用いることで、型（`type`）の指定を省略可能。


### 流れの定義（Arrow）

#### 直感的なDSL記法 (`- ... >`)

Rubyのメソッドチェーンを応用し、矢印を直感的な記号を使って定義できる。

```ruby
user("太郎") -info("情報")> company("会社")
```

1. **`-` メソッド** (主体に対するメソッド)
   - 引数: `PendingArrow` オブジェクト (`info("情報")` など)
   - 戻値: 流れの始点が決定された `HalfArrow` オブジェクト
2. **`>` メソッド** (`HalfArrow` に対するメソッド)
   - 引数: 矢印の先の主体 (`Entity` オブジェクト)
   - 戻値: 生成された `Arrow` オブジェクト

※ `info`, `money`, `object`, `goods`, `information` メソッドは、この構文の内部で一時的な `PendingArrow` を生成するために用いる。

#### `arrow` メソッド（従来記法）

| 仮引数 | 必須 | 型 | 説明 |
| ------ | ---- | --- | ---- |
| `type` | * | `Symbol` | 流れの種類 `:object`, `:money`, `:information`, `:other` |
| `name` | * | `String` | 流れの名称 |
| `from` | * | `Entity` \| `Integer` \| `String` | 矢印の元の主体 |
| `to` | * | `Entity` \| `Integer` \| `String` | 矢印の先の主体 |

**戻り値**: 流れを表す `Arrow` オブジェクト


### 補足の定義（Comment）

#### `comment_to`（エイリアス: `comment`）メソッド

| 仮引数 | 必須 | 型 | 説明 |
| ------ | ---- | --- | ---- |
| `to` | * | `Entity` \| `Integer` \| `String` | コメントを付与する対象の主体 |
| `text` | * | `String` | コメント内容の文字列 |

**戻り値**: 補足を表す `Comment` オブジェクト


### 描画実行

#### `Bizgram.draw` メソッド

ブロック内で主体や流れを定義し、最終的なSVG文字列を生成するエントリーポイント。

| 仮引数 | 必須 | 型 | 説明 |
| ------ | ---- | --- | ---- |
| `title` | * | `String` | この図を端的に表す名称 |

**戻り値**: Bizgramを描画するための SVG ドキュメント文字列


内部アーキテクチャと設計
------------------------

### システム構造（Builderパターン）

```
Bizgram
  ├── Builder（DSLコンテキスト）
  │   ├── 主体定義 (entity, user, company...)
  │   ├── 流れ定義 (arrow)
  │   ├── 補足定義 (comment_to)
  │   └── SVG生成トリガー (to_svg)
  ├── PositionResolver（位置指定のパース）
  ├── SvgGenerator（SVGコード生成・ルーティング）
  └── 内部モデル
      ├── Entity（主体）
      ├── Arrow / PendingArrow / HalfArrow（流れ・DSL状態管理）
      └── Comment（補足）
```

### 主要クラスと責務

- **`Builder`** : DSLのブロック内での操作を受け取り、内部状態（エンティティ、矢印、コメント）を各マップ（ID/名前参照）で統合管理する。
- **`PositionResolver`** : ユーザーからの多様な位置指定（`0`-`8` の数値、`:cm` などのシンボル、`[x,y]` の配列）をパースし、単一の座標インデックスに正規化する。
- **`SvgGenerator`** : 収集されたオブジェクト群をもとに、キャンバスの準備、画像の埋め込み、テキスト配置、矢印のルーティングなどを行い、最終的なSVGを出力する。
- **`Entity` / `Arrow` / `Comment`** : それぞれのドメイン知識と属性（ID、種類、接続元・先など）を保持する。`Entity` はDSL構文のために `-` メソッドを持ち、`HalfArrow` オブジェクトを生成する。

### SVG生成とルーティングエンジン

#### SVGレンダリング

- **パスの直接埋め込み**: Base64エンコードを用いず、各主体アイコン（`reference/image/*.svg`）から `<path>` 等のベクター要素を直接抽出し、`<g transform="...">` としてネイティブに埋め込むことで、美しさと描画の安定性を両立。
- **スタイルと配色**: 全ての矢印は基本色 "#000000" (黒) で統一し、矢印の先端マーカーの形状（`￥`, `〇`, `□` など）で種類を視覚的に表現する。
- **コメント**: "#DDDDDD" (ライトグレー) のしっぽ付き吹き出しとして描画し、対象主体と点線で接続する。

#### Arrowルーティングアルゴリズム（5x5グリッド方式）

矢印は主体と被らないよう、L字や迂回ルートを動的に計算して描画される。

1. **基本経路選択**: 2つの主体間の相対位置関係（行・列の差）をもとに、あらかじめ定義されたルートパターン（後述の「ルート定義一覧」）から候補を決定する。
2. **ルート検証と確定**: 経路上のマスに他の主体が配置されていないか、また他の矢印と不当に交差しないかを検証し、最適な経路を採用する。
3. **オフセット適用**: 全く同じ経路を通る複数の矢印が存在する場合、ラベルや矢印線が重ならないよう、経路の垂直方向に平行移動（オフセット）させる。
4. **SVGパスの生成**: 確定した経路（基本経路＋オフセット）を `M (x1),(y1) L (x2),(y2) ...` の形式で出力する。

### 実行時バリデーション

堅牢性を高めるため、以下の厳密な実行時チェックを行なっている。

1. **Entityのバリデーション** : 名称の空チェック、型の妥当性（`:user`, `:business`等）
2. **位置指定のバリデーション** : 範囲外の数値、無効なシンボル、配列要素数の不正検知
3. **流れ（Arrow）のバリデーション** : 型の妥当性、`from`/`to` に指定された主体が存在するかの参照チェック
4. **構造的バリデーション** : 同じ位置への複数主体の配置禁止、自動配置行の空き枠チェック（※自動配置は現在廃止）
5. **コメントのバリデーション** : 空テキストの禁止、対象主体の存在チェック


付録
----

### アイコンアセット一覧

各エンティティのSVG画像（`reference/image/` 配下）

| ヒト (`:person`) | 会社 (`:company`) | カネ (`:money`) | モノ (`:object`) | 情報 (`:information`) | スマートフォン (`:smartphone`) | 店舗 (`:store`) | その他 (`:other`) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ![](./reference/image/entity_person.svg) | ![](./reference/image/entity_company.svg) | ![](./reference/image/entity_money.svg) | ![](./reference/image/entity_object.svg) | ![](./reference/image/entity_information.svg) | ![](./reference/image/entity_smartphone.svg) | ![](./reference/image/entity_store.svg) | ![](./reference/image/entity_other.svg) |

### ルート定義一覧

- Bizgramの3x3レイアウトを奇数行・列に、主体間の隙間を偶数行・列で表現している（最大5x5のテーブル）
- 矢印は主体間の隙間だけでなく、主体を配置する9マス上も通過できるが、主体が配置されているマス自体は通過できない
- 以下の表は2つの主体間の相対位置関係を示しており、実際の座標ではない。

<details>
<style>
  table.rt td { background-color: gray; }
  table.rt th, table.rt td { text-align: center; }
</style>
<summary>レイアウト（主体は〇、矢印のルートは罫線にて表現）</summary>

<table class="rt">
  <caption>相対位置：(1, 0) or (-1, 0)</caption>
	<tr><th>〇</th><td>─</td><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(0, 1) or (0, -1)</caption>
	<tr><th>〇</th></tr>
	<tr><td>│</td></tr>
	<tr><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(1, 1) or (-1, -1)</caption>
	<tr><th>〇</th><td>─</td><th>┐</th></tr>
	<tr><td>│</td><td>＼</td><td>│</td></tr>
	<tr><th>└</th><td>─</td><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(-1, 1) or (1, -1)</caption>
	<tr><th>┌</th><td>─</td><th>〇</th></tr>
	<tr><td>│</td><td>／</td><td>│</td></tr>
	<tr><th>〇</th><td>─</td><th>┘</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(0, 2) or (0, -2)</caption>
	<tr><th>〇</th></tr>
	<tr><td>│</td></tr>
	<tr><th>│</th></tr>
	<tr><td>│</td></tr>
	<tr><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(2, 0) or (-2, 0)</caption>
	<tr><th>〇</th><td>─</td><th>─</th><td>─</td><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(2, 2) or (-2, -2)</caption>
	<tr><th>〇</th><td>─</td><th>┐</th></tr>
	<tr><td>│</td><td> </td><td>│</td></tr>
	<tr><th>│</th><td> </td><th>│</th></tr>
	<tr><td>│</td><td> </td><td>│</td></tr>
	<tr><th>└</th><td>─</td><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(-1, 2) or (1, -2)</caption>
	<tr><th>┌</th><td>─</td><th>〇</th></tr>
	<tr><td>│</td><td> </td><td>│</td></tr>
	<tr><th>│</th><td> </td><th>│</th></tr>
	<tr><td>│</td><td> </td><td>│</td></tr>
	<tr><th>〇</th><td>─</td><th>┘</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(2, 1) or (-2, -1)</caption>
	<tr><th>〇</th><td>─</td><th>─</th><td>─</td><th>┐</th></tr>
	<tr><td>│</td><td> </td><td> </td><td> </td><td>│</td></tr>
	<tr><th>└</th><td>─</td><th>─</th><td>─</td><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(-2, 1) or (2, -1)</caption>
	<tr><th>┌</th><td>─</td><th>─</th><td>─</td><th>〇</th></tr>
	<tr><td>│</td><td> </td><td> </td><td> </td><td>│</td></tr>
	<tr><th>〇</th><td>─</td><th>─</th><td>─</td><th>┘</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(2, 2) or (-2, -2)</caption>
	<tr><th>〇</th><td>─</td><th>─</th><td>─</td><th>┐</th></tr>
	<tr><td>│</td><td> </td><td> </td><td> </td><td>│</td></tr>
	<tr><th>│</th><td> </td><th> </th><td> </td><th>│</th></tr>
	<tr><td>│</td><td> </td><td> </td><td> </td><td>│</td></tr>
	<tr><th>└</th><td>─</td><th>─</th><td>─</td><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(-2, 2) or (2, -2)</caption>
	<tr><th>┌</th><td>─</td><th>─</th><td>─</td><th>〇</th></tr>
	<tr><td>│</td><td> </td><td> </td><td> </td><td>│</td></tr>
	<tr><th>│</th><td> </td><th> </th><td> </td><th>│</th></tr>
	<tr><td>│</td><td> </td><td> </td><td> </td><td>│</td></tr>
	<tr><th>〇</th><td>─</td><th>─</th><td>─</td><th>┘</th></tr>
</table>
</details>
