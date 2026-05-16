Specification 仕様書
====================

概要
----

- [Bizgram](https://bizgram.zukai.co/)（ビズグラム）をコードで書くためのDSLをRubyで作成する
  - Bizgram（ビジネスモデル図解）を表す SVG ドキュメントを直接生成する
- [Mermaid](https://mermaid.js.org/)や[PlantUML](https://mermaid.js.org/)のような独自の言語にはしない
  - 独自の文法&パーサーを作る労力が大きいこと、Ruby製DDLの使い勝手は悪くないことから、現時点ではDDLで十分と判断する
- 書き方の自由度や実行方法の柔軟性は意識したい
  - [外部仕様](#外部仕様)で整理する

### Bizgram（ビズグラム）

- [図解の説明書](https://bizgram.zukai.co/howto)

> ビジネスモデル図解とは、**「そのビジネスは誰（何）が関係してるの？ どんな関係なの？ を知るためのツール」** である。そして、ビジネスモデル図解は、よりシンプルでわかりやすく相手にそのビジネスについての情報を伝えるために、いくつかのルールがある。
> - `ルール1` 主体を３×３で構成する
> - `ルール2` モノ・カネ・情報の流れを矢印で説明する
> - `ルール3` 説明しきれない部分はふきだしの補足で説明する

- [ビズグラム(ビジネスモデル図解)](https://zukai.co/pages/bizgram)

> **ビズグラム(ビジネスモデル図解)とはなにか？**
> ビズグラム(ビジネスモデル図解)とは、ある企業のサービスの事業者や利用者がどう関わりお金が循環するのかを表現している図です。そのビジネスがどのように経済合理性を実現しているのか、そのビジネスの特徴は何かが一目で分かります。
>
> ビズグラムを使うことで、自社のビジネスを可視化するだけでなく、自社の経営資源や強みを把握したり、投資家や経営陣に対する説明資料としても活用することができます。

> **ビズグラムの説明書**
> - 主体（ビジネスにおける重要な関係者・物）が、3×3マスに配置される。
> - 上段は利用者、中段は事業、下段は事業者になる。
> - まずは、中央の縦列をみて、①誰のために事業が行われているのか？②何が事業として行われるのか？③誰がどの事業を行なっているのか？を確認する。
> - 次に、中央の横列を見て、④利用者は何にお金を出しているのか？⑤事業者はどうお金を回しているのか？を確認する。
> - そして、4隅をみて、⑥提携している起業や、重要な関係会社はあるのか？を確認する。
> - 最後に、矢印や補足を見て、モノ・カネ・情報の流れがどうなっているか？を確認する。

本も出ている模様。

- [ビジネスモデル3.0図鑑](https://www.amazon.co.jp/dp/4046075724)

### DSL

#### DSLとは

- [ドメイン固有言語](https://ja.wikipedia.org/wiki/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E5%9B%BA%E6%9C%89%E8%A8%80%E8%AA%9E)

> ドメイン特化言語（ドメインとっかげんご、英語: domain-specific language、DSL）は、特定のタスク向けに設計されたコンピュータ言語[1]である。汎用プログラミング言語の対義語として用いられる。

> 例えば、ハードウェア記述言語のVerilog HDLやVHDL、データベースへの問い合わせ言語（SQLなど）、文脈自由文法を記述するBNFや正規文法を記述する正規表現、図を作成する言語を構築する Generic Eclipse Modeling System（英語版）、音響や音楽の合成用のCsound、グラフ（ネットワーク）描画システムGraphvizのDOT言語、ファイルの最終変更時刻と依存関係記述にもとづいたタスクランナーであるmakeなどがある。

#### RubyでDSL

- [RubyでDSLが書きやすい理由を整理する](https://qiita.com/getty104/items/b3fcc1f86846fb86f168)
- [Rubyによる内部DSLを用いた設定ファイルの作り方](https://www.key-p.com/blog/staff/archives/43226)
- [Rubyで簡単DSL](https://tyfkda.github.io/blog/2008/03/21/easy-dsl.html)
- [Rubyで自然なDSLを作るコツ：値を設定するときはグループ化して代入](https://www.clear-code.com/blog/2014/2/13.html)
- [Rubyの魔法：instance_evalとinstance_execを使いこなす](https://techracho.bpsinc.jp/kazz/2025_11_04/154120)


仕様
----

### 外部仕様

#### コードサンプル

```ruby
require "bizgram"

Bizgram.draw "タイトル" do

  # 主体の定義
  entity :user, "太郎", :ct # 利用者
  entity :business, "HOGEビジネス", :cm # 事業
  entity :operator, "社員", :cb # 事業者
  jiro = user "次郎", [1, 0] # 利用者のショートカット
  fuga = business "FUGAビジネス", [1, 1] # 事業のショートカット
  clerk = operator "販売員", [1, 2] # 事業者のショートカット

  # モノ・カネ・情報の流れの定義
  arrow :object, "商品", business("FUGAビジネス"), user("太郎") # モノの流れ
  arrow :money, "代金", user("太郎"), business("HOGEビジネス") # カネの流れ
  arrow :information, "広告", operator("販売員"), to: user("太郎") # 情報の流れ
  arrow :object, "商品", fuga, jiro # モノの流れ
  arrow :money, "代金", jiro, fuga # カネの流れ
  arrow :information, "広告", clerk, jiro # 情報の流れ

  # その他の補足情報（コメント）の定義
  comment_to user("太郎"), "太郎君"
  comment_to jiro, "次郎君" # IDで対象を指定する
  comment clerk, "広告" # 3文字だけ短く書けるショートカット

end
```

#### 図そのものを定義するメソッド

##### `draw`メソッド
- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|title| * |string|この図を端的に表す名称|

- 戻値

Bizgramを描画するための SVG ドキュメント文字列


#### 主体を定義するメソッド

##### `entity`メソッド

主体を定義する基本メソッド。
次項のショートカットメソッドは、`entity` メソッドを便利に呼び出すための仕組み。

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|type| * |symbol|主体の種類。以下の値を指定可能：`:person`(`:user`), `:company`(`:business`), `:money`, `:object`(`:goods`), `:information`(`:info`), `:smartphone`(`:device`), `:store`(`:shop`), `:other`|
|name| * |string|主体の名称|
|position| * |number\|symbol\|array|主体の配置位置。number: 3x3マスの左上から右下に向けて`0`～`8`を指定する。 symbol: 横方向（l,c,r）と縦方向（t, m, b）の組み合わせ（例：`:ct` は中央上段）。 array: `[x, y]`の座標指定(`0`～`2`) |

- 戻値

主体を表す `Entity` オブジェクト

##### `entity`のショートカットメソッド

`person`(`user`), `company`(`business`), `money`, `object`(`goods`), `information`(`info`), `smartphone`(`device`), `store`(`shop`), `other` メソッドは、`entity` メソッドの便利なショートカットメソッド。

- 引数：※`entity`メソッドの`type`なし
- 戻値：※`entity`メソッドと同じ

**ショートカットメソッド一覧**

|メソッド名|entity type|説明|図形|
|----------|-----------|----|----|
|`person`(`user`)|`:person`(`:user`)|ヒト（利用者、人物）|![](./reference/image/entity_person.svg)|
|`company`(`business`)|`:company`(`:business`)|会社（事業者）|![](./reference/image/entity_company.svg)|
|`money`|`:money`|カネ（金銭）|![](./reference/image/entity_money.svg)|
|`object`(`goods`)|`:object`(`:goods`)|モノ（商品、物資）|![](./reference/image/entity_object.svg)|
|`information`(`info`)|`:information`(`:info`)|情報、知識|![](./reference/image/entity_information.svg)|
|`smartphone`(`device`)|`:smartphone`(`:device`)|スマートフォン(デバイス)|![](./reference/image/entity_smartphone.svg)|
|`store`(`shop`)|`:store`(`:shop`)|店舗|![](./reference/image/entity_store.svg)|
|`other`|`:other`|その他の要素|![](./reference/image/entity_other.svg)|

#### モノ・カネ・情報の流れを定義するメソッド

##### `arrow`メソッド

流れを定義するメソッド。

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|type| * |symbol|流れの種類 `:object`: モノ `:money`: お金 `:information`: 情報 `:other`: その他|
|name| * |string|流れの名称|
|from| * |Entity, number, or string|矢印の元の主体。Entity オブジェクト、主体の ID（number）、または主体の名称（string）|
|to| * |Entity, number, or string|矢印の先の主体。Entity オブジェクト、主体の ID（number）、または主体の名称（string）|

- 戻値

流れを表す `Arrow` オブジェクト


#### その他の補足情報（コメント）を定義するメソッド

##### `comment_to`（`comment`）メソッド

`comment`は`comment_to`のエイリアスであり、挙動は全く同じ。

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|to| * |Entity, number, or string|コメントを付与する対象の主体。Entity オブジェクト、主体の ID（number）、または主体の名称（string）|
|text| * |string|コメント内容の文字列|

- 戻値

補足を表す `Comment` オブジェクト


#### 主体と流れを視覚的に表現するためのメソッド

以下の文法を実現するためのメソッド

```rb
# ※`entity.position`未指定については検討が必要
other("サイト") --info("情報")--> user("太郎")
```

##### `Entity.--`メソッド

Entithを呼び出し元（from）としたArrowを生成する。
（toはnil）

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|type| * |symbol|流れの種類 `:object`: モノ `:money`: お金 `:information`: 情報 `:other`: その他|
|name|  |string|流れの名称|

- 戻値

流れを表す `Arrow` オブジェクト※
※`Array.from`は呼び出し元の`Entity`オブジェクトが設定済み、`Array.to`は未設定の状態

**`--`のショートカットメソッド**

`--object`, `--money`(`--yen`), `--information`(`--info`), `--other` メソッドは、`--` メソッドの便利なショートカットメソッド。

- 引数：※`--`メソッドの`type`なし
- 戻値：※`--`メソッドと同じ

##### `Arrow.-->`メソッド

※`Array.from != nil`かつ`Array.to == nil`でないArrayで呼び出した場合エラー

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|to| * |Entity, number, or string|矢印の先の主体。Entity オブジェクト、主体の ID（number）、または主体の名称（string）|

- 戻値

流れを表す `Arrow` オブジェクト※
※`Array.from`は呼び出し元の`Entity`オブジェクトが設定済み、`Array.to`は未設定の状態

##### 矢印のルートパターン一覧

###### 基本ルール

- 2つの主体を結ぶ矢印のルートは、あらかじめ定義された中から選択する（定義は[ルート定義一覧](#ルート定義一覧)参照）
- 矢印は交差することはできないが、同じ主体間の往復など、全く同じルートに複数の矢印を配置することができる（描画の際には、座標をオフセットして、矢印が被ってしまうのを防ぐ）
- 矢印は基本的に水平方向と垂直方向の直線で構成されており、1回だけ直角に方向転換することが許されているが、主体の相対位置が「(1, 1) or (-1, -1)、(-1, 1) or (1, -1)」の右上/右下/左上/左下の位置の場合、例外的に斜め45度の直線の矢印が許される

###### ルーティングの考え方（アルゴリズム）

以下のルールにて、複数のテーブルを行列的に操作（合成）し、基本ルートを決定する

1. 主体と主体間の隙間を表現した5x5テーブル（ベースと呼ぶ）を準備する
2. ベースに全ての主体を配置する
2. 矢印で結ばれた2主体の配置から、次項の「[ルート定義一覧](#ルート定義一覧)」を検索する（ルート候補と呼ぶ）
   ※主体間の相対距離が遠い2主体から順にルートを決定する
3. ルート候補をベースに合成して、以下を満たしているルートを採用する
   ※ルート候補は2パターン以上あるので、以下を満たすどれかを採用する
   - 配置済みの主体に被っていないこと
   - 配置済みの矢印に被っていないこと
     ただし、完全に一致するルートであれば許容する

###### ルート定義一覧

- Bizgramの3x3レイアウトを奇数行・列に、主体間の隙間を偶数行・列で表現している（最大5x5のテーブル）
- Bizgramの3x3レイアウトは`<th/>`、主体間の隙間は`<td/>`で表現している
- 主体は3x3レイアウト(`<th/>`)にしか配置できない
- 矢印は主体間の隙間(`<td/>`)だけでなく、主体を配置する9マス(`<th/>`)上も通過できるが、主体が配置されているマスは通過できない
- ルート一覧上の主体は、2つの主体間の相対位置関係を示しており、本来の主体の座標ではない点に注意する（このため、テーブルの行列サイズは必ずしも3x3レイアウトになっていない）
- ルート候補は複数あり、相対位置ごとにまとめて記載している
  （他の主体上を通過しない、かつ他の矢印と交差しないルートを選定すること）

<details>
<style>
  table.rt td { background-color: gray; }
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
	<tr><td>│</td><th>＼</th><td>│</td></tr>
	<tr><th>└</th><td>─</td><th>〇</th></tr>
</table>

<table class="rt">
  <caption>相対位置：(-1, 1) or (1, -1)</caption>
	<tr><th>┌</th><td>─</td><th>〇</th></tr>
	<tr><td>│</td><th>／</th><td>│</td></tr>
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

#### 体裁・装飾の参考資料

（AIに読んでもらうために一部分割、編集している）

- ビジネスモデル図解ツールキット配布版P3描画要素
  - [主体](./reference/ビジネスモデル図解ツールキット配布版P3描画要素/ビジネスモデル図解ツールキット配布版P3描画要素_部分抽出_主体.svg), [矢印](./reference/ビジネスモデル図解ツールキット配布版P3描画要素/ビジネスモデル図解ツールキット配布版P3描画要素_部分抽出_矢印.svg), [補足](./reference/ビジネスモデル図解ツールキット配布版P3描画要素/ビジネスモデル図解ツールキット配布版P3描画要素_部分抽出_補足.svg), [全体](./reference/ビジネスモデル図解ツールキット配布版P3描画要素/ビジネスモデル図解ツールキット配布版P3描画要素_部分抽出_全体.svg)

各エンティティSVG（個別に切り出し）

|ヒト|会社|カネ|モノ|情報|スマートフォン|店舗|その他|
|-|-|-|-|-|-|-|-|
| ![](./reference/image/entity_person.svg) | ![](./reference/image/entity_company.svg) | ![](./reference/image/entity_money.svg) | ![](./reference/image/entity_object.svg) | ![](./reference/image/entity_information.svg) | ![](./reference/image/entity_smartphone.svg) | ![](./reference/image/entity_store.svg) | ![](./reference/image/entity_other.svg) |


内部仕様
--------

### アーキテクチャ

```
Bizgram
  ├── Builder（ブロック内での操作を受け取る）
  │   ├── entity / person(user) / company(business) / money / object(goods) / information(info) / smartphone(device) / store(shop) / other（主体定義）
  │   ├── arrow（流れ定義）
  │   ├── comment_to(comment)（コメント定義）
  │   └── to_svg（SVG生成へ）
  ├── PositionResolver（位置指定の解決）
  │   ├── 数値指定（0-8）
  │   ├── シンボル指定（:lt, :ct等）
  │   └── 座標指定（[x,y]）
  ├── SvgGenerator（SVGコード生成）
  │   ├── SVGヘッダー/フッター出力
  │   ├── Entity出力（SVG画像埋め込み）
  │   ├── Arrow出力（5x5グリッド・ルーティングおよびオフセット処理）
  │   └── Comment出力
  ├── Entity（主体の内部表現）
  ├── Arrow（流れの内部表現）
  └── Comment（コメントの内部表現）
```

### クラス と責務

#### `Entity`クラス

主体（利用者、事業、事業者）の内部表現。

**属性**
- `id` : 一意の識別子（number）。全オブジェクト（Entity, Arrow, Comment）間で一意。
- `name` : 主体の名称（string）
- `type` : 主体の種類（:user, :business, :operator）
- `position` : 3×3マスでの配置位置（0-8のnumber）
**メソッド**
- `--` : TODO

#### `Arrow`クラス

流れ（モノ・カネ・情報）の内部表現。

**属性**
- `id` : 一意の識別子（number）。全オブジェクト（Entity, Arrow, Comment）間で一意。
- `name` : 流れの名称（string）
- `type` : 流れの種類（:object, :money, :information, :other）
- `from` : 流れの開始主体ID（number）
- `to` : 流れの終了主体ID（number）
**メソッド**
- `-->` : TODO


#### `Comment`クラス

補足情報（コメント）の内部表現。

**属性**
- `id` : 一意の識別子（number）。全オブジェクト（Entity, Arrow, Comment）間で一意。
- `to` : コメント対象の主体ID（number）
- `text` : コメント内容（string）

#### `PositionResolver`クラス

主体の配置位置を解決する責務を持つ。

**処理**

1. **数値指定の解決**
   - 0～8の範囲内であることを検証
        ```
        0 1 2   (上段：利用者)
        3 4 5   (中段：事業)
        6 7 8   (下段：事業者)
        ```
   - 範囲外ならば`ArgumentError`を発生

2. **シンボル指定の解決**
   - 横軸：l（左）, c（中央）, r（右）
   - 縦軸：t（上）, m（中）, b（下）
   - 組み合わせ：:lt, :ct, :rt, :lm, :cm, :rm, :lb, :cb, :rb
   - 無効なシンボルならば`ArgumentError`を発生

3. **座標指定の解決**
   - [x, y]形式、x: 0～2, y: 0～2
   - 配列がない、要素数が不正、範囲外ならば`ArgumentError`を発生
   - 変換式：`position = y * 3 + x`

#### `Builder`クラス

DSLのブロック内での操作を受け取り、Entity と Arrow 、Comment を管理する。

##### 内部状態
- `@entities` : {name => Entity} マップ（名前による参照）
- `@entities_by_id` : {id => Entity} マップ（IDによる参照）
- `@arrows` : {name => Arrow} マップ（名前による参照）
- `@arrows_by_id` : {id => Arrow} マップ（IDによる参照）
- `@comments` : {id => Comment} マップ（IDによる参照）
- `@next_global_id` : 次のグローバルID（Entity, Arrow, Commentで共有）
- `@occupied_positions` : 占有済みの位置（Set）

##### 主要メソッド


###### `user` / `business` / `operator` / `entity`メソッド

```ruby
Bizgram.draw("Example") do
  user "ユーザー名"
  user "ユーザー名", :ct          # シンボル位置指定
  user "ユーザー名", [0, 0]       # 座標指定
  user "ユーザー名", 1            # 数値位置指定

  business "事業名"
  business "事業名", :cm          # 中央

  operator "事業者名"
  operator "事業者名", :cb        # 中央下
end
```
```ruby
Bizgram.draw("Example") do
  entity :user, "ユーザー"
  entity :business, "事業"
  entity :operator, "事業者"
end
```

- `entity(type, name, position)` / `user/business/operator(name, position)`
  1. nameが既に登録済みか確認 → Yes: 既存のIDを返す
  2. 位置指定を`PositionResolver`で解決
  3. 位置が占有されていないか確認 → 占有済み: エラー
  4. Entity を作成し、各マップに登録
  5. 位置を占有として記録
  6. IDを返す

###### `arrow`メソッド

```ruby
Bizgram.draw("Example") do
  user "Customer", 1
  business "Shop", 4

  arrow :object "商品", user("Customer"), business("Shop")
  arrow :money "代金", user("Customer"), business("Shop")
  arrow :information "広告", operator("Staff"), user("Customer")
end
```

- `arrow(type, name, from, to)`
  1. from, to の Entity参照を解決（ID または名前）
  2. 両Entity が存在するか確認 → 存在しない: エラー
  3. Arrow を作成し、各マップに登録
  4. IDを返す

###### `comment_to` / `comment`メソッド

```ruby
Bizgram.draw("Example") do
  user "Alice", 0
  comment_to user("Alice"), "コメント内容"
  comment alice_id, "短い書き方"  # comment_to のエイリアス
end
```

- `comment_to(to, text)` / `comment(to, text)`
  1. text をバリデーション
  2. to の Entity参照を解決（ID または名前）
  3. Entity が存在するか確認 → 存在しない: エラー
  4. Comment を作成し、マップに登録
  5. IDを返す

- `to_svg(title)` → `SvgGenerator`に委譲

#### `SvgGenerator`クラス

Entity と Arrow、Comment から直接 SVG ドキュメントを生成する。

**配色とスタイル**
- Arrowスタイル
  - `:object` → "#000000" (黒)
  - `:money` → "#FF0000" (赤)
  - `:information` → "#0000FF" (青)
  - `:other` → "#000000" (黒)
- Comment背景色: "#FFFC41" (黄系)

**生成ロジック**

1. SVGキャンバス（1440x900）の枠組みを作成
2. `reference/image/` 配下にある各主体のSVGファイルをBase64エンコードし、`<image>`タグとして指定座標に埋め込む
3. 各Entityの下部に名称テキストを配置
4. Arrowのルーティングと描画（後述）
5. コメントボックスを描画し、対象のEntityまで点線をつなぐ

**Arrowルーティングアルゴリズム（5x5グリッド方式）**

Arrow（矢印）は単なる直線ではなく、仕様書上部で定義された「ルート定義一覧」に基づき、他の主体と被らないように迂回・直角で描画される。
また、全く同じ経路を通る矢印が複数存在する場合は、重ならないように一定のピクセル数分オフセット（平行移動）させる。

1. **基本経路選択**: Entity同士の相対位置関係（行の差・列の差）から、ルートパターンの候補を決定する
2. **ルート検証と確定**: 複数のルート候補がある場合、主体が配置されている座標や既存の矢印と被らない経路を採用する
3. **オフセット適用**: 複数の矢印が完全に同じ経路を通る（または双方向に通る）場合、経路の垂直方向に平行にずらす（例：1本あたり10pxのオフセット）
4. **SVGパスの生成**: 確定した経路（基本経路＋オフセット）をもとに、`M (x1),(y1) L (x2),(y2) ...` の形式で、直角を基本とするL字型などのSVGパスデータ（`d`属性）を出力する

#### `Bizgram.draw`メソッド

ユーザーからの呼び出しエントリーポイント。

**処理**
1. Builder インスタンスを作成
2. ブロックを`instance_eval`で Builder上で実行
   - ブロック内のメソッド呼び出しは、全てBuilder のメソッドへ委譲される
3. `to_svg(title)`で SVG ドキュメントを生成
4. 生成された SVG ドキュメント文字列を返す

### バリデーション

実装されているバリデーション：

1. **Entity名のバリデーション**
   - 空文字列NG → `ArgumentError`
   - 非文字列NG → `ArgumentError`

2. **位置指定のバリデーション**
   - 数値：0～8の範囲外NG → `ArgumentError`
   - シンボル：未知のシンボルNG → `ArgumentError`
   - 配列：要素数不正、座標範囲外NG → `ArgumentError`

3. **Entity型のバリデーション**
   - :user, :business, :operator 以外NG → `ArgumentError`

4. **流れ型のバリデーション**
   - :object, :money, :information 以外NG → `ArgumentError`

5. **流れの参照チェック**
   - from/to で指定されたEntity が存在しないNG → `ArgumentError`

6. **位置の競合チェック**
   - 同じ位置に複数のEntity を配置NG → `RuntimeError`

7. **自動配置の限界チェック**
   - 該当行（利用者行/事業行/事業者行）に空き位置がないNG → `RuntimeError`

8. **コメント内容のバリデーション**
   - 空文字列NG → `ArgumentError`
   - 非文字列NG → `ArgumentError`

9. **コメント対象のバリデーション**
   - to で指定されたEntity が存在しないNG → `ArgumentError`

### SVG生成の仕組みと特徴

- **画像ファイルの埋め込み**: 各Entityに割り当てられた `reference/image/*.svg` ファイルを Base64エンコードのData URIスキーマ（`data:image/svg+xml;base64,...`）として直接SVGファイルに埋め込んでいます。これにより、出力された1つのSVGファイルを共有するだけで、全ての画像要素が欠落せずに表示されます。
- **マーカー定義**: 矢印の終点（三角）は、`<defs><marker>` 要素として定義されており、各パスから `marker-end` 属性で参照されています。
- **5x5グリッドルーティングの実現**: 指定された相対位置に対して、直進・L字曲がり・迂回などのルートを動的に計算し、中間地点となる座標をつなぐ直線（`<path d="M... L... L...">`）として描画されます。

