Specification 仕様書
====================

> [!NOTE]
> このドキュメントの役割分担は（基本的に）以下の通り
> （ただし、typoその他の明らかな誤りを修正する場合はこの限りではない）
> - [外部仕様](#外部仕様)までは人間がメンテナンスする（AIには読み取り専用とする）
> - [内部仕様](#内部仕様)以降はAIがメンテナンスする

概要
----

- [Bizgram](https://bizgram.zukai.co/)（ビズグラム）をコードで書くためのDSLをRubyで作成する
  - [DOT言語](https://ja.wikipedia.org/wiki/DOT%E8%A8%80%E8%AA%9E)コードを生成して、[Graphiz](https://graphviz.org/)で描画する
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
  jiro = user "次郎", [1, 0] # 利用者のエイリアス
  fuga = business "FUGAビジネス", [1, 1] # 事業のエイリアス
  clerk = operator "販売員", [1, 2] # 事業者のエイリアス

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
  comment clerk, "広告" # 3文字だけ短く書けるエイリアス

end
```

#### 図そのものを定義するメソッド

##### `draw`メソッド
- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|title| * |string|この図を端的に表す名称|

- 戻値

[Graphiz](https://graphviz.org/)で描画可能な[DOT言語](https://ja.wikipedia.org/wiki/DOT%E8%A8%80%E8%AA%9E)コード文字列


#### 主体を定義するメソッド

##### `entity`メソッド

主体を定義する基本メソッド。
次項のエイリアスメソッドは、`entity` メソッドを便利に呼び出すための仕組み。

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|type| * |symbol|主体の種類。以下の値を指定可能：`:person`(`:user`), `:company`(`:business`), `:money`, `:object`(`:goods`), `:information`(`:info`), `:smartphone`(`:device`), `:store`(`:shop`), `:other`|
|name| * |string|主体の名称|
|position| * |number\|symbol\|array|主体の配置位置。number: 3x3マスの左上から右下に向けて0~8を指定する。 symbol: 横方向（l,c,r）と縦方向（t, m, b）の組み合わせ（例：:ct は中央上段）。 array: [x, y]の座標指定(0~2) |

- 戻値

オブジェクトを一位に特定するID（number）

##### エイリアスメソッド

`person`(`user`), `company`(`business`), `money`, `object`(`goods`), `information`(`info`), `smartphone`(`device`), `store`(`shop`), `other` メソッドは、`entity` メソッドの便利なエイリアスメソッド。

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|name| * |string|主体の名称|
|position| * |number\|symbol\|array|主体の配置位置。number: 3x3マスの左上から右下に向けて0~8を指定する。 symbol: 横方向（l,c,r）と縦方向（t, m, b）の組み合わせ（例：:ct は中央上段）。 array: [x, y]の座標指定(0~2) |

- 戻値

オブジェクトを一位に特定するID（number）

- エイリアスメソッド一覧

|メソッド名|entity type|説明|
|----------|-----------|---|
|`person`(`user`)|`:person`(`:user`)|ヒト（利用者、人物）|
|`company`(`business`)|`:company`(`:business`)|会社（事業者）|
|`money`|`:money`|カネ（金銭）|
|`object`(`goods`)|`:object`(`:goods`)|モノ（商品、物資）|
|`information`(`info`)|`:information`(`:info`)|情報、知識|
|`smartphone`(`device`)|`:smartphone`(`:device`)|スマートフォン(デバイス)|
|`store`(`shop`)|`:store`(`:shop`)|店舗|
|`other`|`:other`|その他の要素|


#### モノ・カネ・情報の流れを定義するメソッド

##### `arrow`メソッド

流れを定義するメソッド。

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|type| * |symbol|流れの種類 :object : モノ :money : お金 :information : 情報 :other : その他|
|name| * |string|主体の名称|
|from| * |number|矢印の元の主体ID|
|to| * |number|矢印の先の主体ID|

- 戻値

オブジェクトを一位に特定するID（number）
※使い道はないけど、主体に合わせてる（読み捨ててよい）



#### その他の補足情報（コメント）を定義するメソッド

##### `comment_to`（`comment`）メソッド

`comment`は`comment_to`のエイリアスであり、挙動は全く同じ。

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|to| * |number|コメントを付与する対象の主体ID|
|text| * |string|コメント内容の文字列|

- 戻値

オブジェクトを一位に特定するID（number）
※使い道はないけど、主体に合わせてる（読み捨ててよい）


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
  │   ├── user/business/operator（主体定義）
  │   ├── arrow（流れ定義）
  │   └── to_dot（DOT言語生成へ）
  ├── PositionResolver（位置指定の解決）
  │   ├── 数値指定（0-8）
  │   ├── シンボル指定（:lt, :ct等）
  │   ├── 座標指定（[x,y]）
  │   └── 自動配置ロジック
  ├── DotGenerator（DOT言語コード生成）
  │   ├── ノード定義（Entity → node）
  │   └── エッジ定義（Arrow → edge）
  ├── Entity（主体の内部表現）
  └── Arrow（流れの内部表現）
```

### クラス と責務

#### `Entity`クラス

主体（利用者、事業、事業者）の内部表現。

**属性**
- `id` : 一意の識別子（number）
- `name` : 主体の名称（string）
- `type` : 主体の種類（:user, :business, :operator）
- `position` : 3×3マスでの配置位置（0-8のnumber）

#### `Arrow`クラス

流れ（モノ・カネ・情報）の内部表現。

**属性**
- `id` : 一意の識別子（number）
- `name` : 流れの名称（string）
- `type` : 流れの種類（:object, :money, :information, :other）
- `from` : 流れの開始主体ID（number）
- `to` : 流れの終了主体ID（number）

#### `Comment`クラス

補足情報（コメント）の内部表現。

**属性**
- `id` : 一意の識別子（number）
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

4. **自動配置**
   - 位置指定がない場合、typeに応じて配置
   - `:user` → 上段（0, 1, 2）から利用可能な位置を選択
   - `:business` → 中段（3, 4, 5）から利用可能な位置を選択
   - `:operator` → 下段（6, 7, 8）から利用可能な位置を選択
   - 該当行の位置が全て埋まっていれば、アルゴリズム実行時に`RuntimeError`を発生

#### `Builder`クラス

DSLのブロック内での操作を受け取り、Entity と Arrow を管理する。

##### 内部状態
- `@entities` : {name => Entity} マップ（名前による参照）
- `@entities_by_id` : {id => Entity} マップ（IDによる参照）
- `@arrows` : {name => Arrow} マップ（名前による参照）
- `@arrows_by_id` : {id => Arrow} マップ（IDによる参照）
- `@comments` : {id => Comment} マップ（IDによる参照）
- `@next_entity_id` : 次のEntity ID
- `@next_arrow_id` : 次のArrow ID
- `@next_comment_id` : 次のComment ID
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

- `to_dot(title)` → `DotGenerator`に委譲

#### `DotGenerator`クラス

Entity と Arrow から DOT言語コードを生成する。また、Comment も処理する。

**配色**
- `:user` → "#FFE5CC"（オレンジ系）
- `:business` → "#CCE5FF"（青系）
- `:operator` → "#E5FFCC"（緑系）
- Comment → "#FFFFCC"（黄系）

**エッジスタイル**
- `:object` → color: black
- `:money` → color: red
- `:information` → color: blue

**生成ロジック**

1. `digraph Bizgram { ... }` の枠組みを作成
2. graph属性でタイトルを指定
3. ノード定義：`node_{id} [label="name", shape=box, style=filled, fillcolor="color"];` の形式で全Entity を出力
4. コメントノード定義：`comment_{id} [label="text", shape=box, style="filled,rounded", fillcolor="#FFFFCC"];` の形式で全Comment を出力
5. エッジ定義：`node_{from} -> node_{to} [label="name", color=color];` の形式で全Arrow を出力
6. コメントエッジ定義：`comment_{id} -> node_{target} [style=dashed, color=gray];` の形式で全Comment を出力
7. 文字列をDOT言語の特殊文字（"など）をエスケープ

#### `Bizgram.draw`メソッド

ユーザーからの呼び出しエントリーポイント。

**処理**
1. Builder インスタンスを作成
2. ブロックを`instance_eval`で Builder上で実行
   - ブロック内のメソッド呼び出しは、全てBuilder のメソッドへ委譲される
3. `to_dot(title)`で DOT言語コードを生成
4. 生成されたDOT言語文字列を返す

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

### DOT言語の生成例

```
digraph Bizgram {
  graph [label="タイトル", labelloc=top];
  rankdir=TB;

  node_0 [label="太郎", shape=box, style=filled, fillcolor="#FFE5CC"];
  node_1 [label="次郎", shape=box, style=filled, fillcolor="#FFE5CC"];
  node_3 [label="HOGEビジネス", shape=box, style=filled, fillcolor="#CCE5FF"];
  node_4 [label="FUGAビジネス", shape=box, style=filled, fillcolor="#CCE5FF"];
  node_6 [label="社員", shape=box, style=filled, fillcolor="#E5FFCC"];
  node_7 [label="販売員", shape=box, style=filled, fillcolor="#E5FFCC"];
  comment_0 [label="太郎君", shape=box, style="filled,rounded", fillcolor="#FFFFCC"];
  comment_1 [label="次郎君", shape=box, style="filled,rounded", fillcolor="#FFFFCC"];

  node_4 -> node_0 [label="商品", color=black];
  node_0 -> node_3 [label="代金", color=red];
  node_7 -> node_0 [label="広告", color=blue];
  comment_0 -> node_0 [style=dashed, color=gray];
  comment_1 -> node_1 [style=dashed, color=gray];
}
```

