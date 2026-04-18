Specification 仕様書
====================

概要
----

- [Bizgram](https://bizgram.zukai.co/)（ビズグラム）をコードで書くためのDSLをRubyで作成する
  - [DOT言語](https://ja.wikipedia.org/wiki/DOT%E8%A8%80%E8%AA%9E)コードを生成して、[Graphiz](https://graphviz.org/)で描画する
- [Mermaid](https://mermaid.js.org/)や[PlantUML](https://mermaid.js.org/)のような独自の言語にはしない
  - 独自の文法&パーサーを作る労力が大きいこと、Ruby製DDLの使い勝手は悪くないことから、現時点ではDDLで十分と判断する
- 書き方の自由度や実行方法の柔軟性は意識したい
  - [外部仕様](#外部仕様)で整理する

### Bizgram（ビズグラム）

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

- [図解の説明書](https://bizgram.zukai.co/howto)

> ビジネスモデル図解とは、**「そのビジネスは誰（何）が関係してるの？ どんな関係なの？ を知るためのツール」** である。そして、ビジネスモデル図解は、よりシンプルでわかりやすく相手にそのビジネスについての情報を伝えるために、いくつかのルールがある。
> - `ルール1` 主体を３×３で構成する
> - `ルール2` モノ・カネ・情報の流れを矢印で説明する
> - `ルール3` 説明しきれない部分はふきだしの補足で説明する

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
  object "商品", fuga, jiro # モノの流れのエイリアス（ID指定）
  money "代金", jiro, fuga # カネの流れのエイリアス（ID指定）
  information "広告", clerk, jiro # 情報の流れの流れのエイリアス（ID指定）

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

##### `user`, `business`, `operator`メソッド

主体（利用者、事業、事業者）を定義する。
同じ名称は使えない。（同じ名称の場合、定義済みのIDを返す）

定義した主体を指し示す場合、戻り値のIDか、定義済みの名称を使う。
（`jiro = user "次郎"`で定義した利用者「次郎」は、`user("次郎")`と`jiro`で同じ意味にになる）

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|name| * |string|主体の名称|
|position| |number\|symbol\|array|主体の配置位置。省略時の自動配置は以下のルール：type（利用者/事業/事業者）に応じて位置を分ける。 number: 3x3マスの左上から右下に向けて0~8を指定する。 symbol: 横方向（l,c,r）と縦方向（t, m, b）の組み合わせ（例：:ct は中央上段）。 array: [x, y]の座標指定(0~2) |

- 戻値

オブジェクトを一位に特定するID（number）

##### `entity`メソッド

`user`, `business`, `operator`メソッドと同様に、主体を定義するメソッド。
（むしろ`user`, `business`, `operator`メソッドは`entity`メソッドのエイリアス）

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|type| * |symbol|主体の種類 :user : 利用者 :business : 事業 :operator : 事業者|
|name| * |string|主体の名称|
|position| |number\|symbol\|array|主体の配置位置。省略時の自動配置は以下のルール：type（利用者/事業/事業者）に応じて位置を分ける。 number: 3x3マスの左上から右下に向けて0~8を指定する。 symbol: 横方向（l,c,r）と縦方向（t, m, b）の組み合わせ（例：:ct は中央上段）。 array: [x, y]の座標指定(0~2) |

- 戻値

オブジェクトを一位に特定するID（number）


#### モノ・カネ・情報の流れを定義するメソッド

##### `object`, `money`, `information`メソッド

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|name| * |string|主体の名称|
|from| * |number|矢印の元の主体ID|
|to| * |number|矢印の先の主体ID|


- 戻値

オブジェクトを一位に特定するID（number）
※使い道はないけど、主体に合わせてる（読み捨ててよい）

##### `arrow`メソッド

`object`, `money`, `information`メソッドと同様に、流れを定義するメソッド。
（むしろ`object`, `money`, `information`メソッドは`arrow`メソッドのエイリアス）

- 引数

|仮引数|必須|型|説明|
|------|----|--|----|
|type| * |symbol|流れの種類 :object : モノ :money : お金 :information : 情報|
|name| * |string|主体の名称|
|from| * |number|矢印の元の主体ID|
|to| * |number|矢印の先の主体ID|

- 戻値

オブジェクトを一位に特定するID（number）
※使い道はないけど、主体に合わせてる（読み捨ててよい）

内部仕様
----

### アーキテクチャ

```
Bizgram
  ├── Builder（ブロック内での操作を受け取る）
  │   ├── user/business/operator（主体定義）
  │   ├── object/money/information（流れ定義）
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
- `type` : 流れの種類（:object, :money, :information）
- `from` : 流れの開始主体ID（number）
- `to` : 流れの終了主体ID（number）

#### `PositionResolver`クラス

主体の配置位置を解決する責務を持つ。

**処理**

1. **数値指定の解決**
   - 0～8の範囲内であることを検証
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

**内部状態**
- `@entities` : {name => Entity} マップ（名前による参照）
- `@entities_by_id` : {id => Entity} マップ（IDによる参照）
- `@arrows` : {name => Arrow} マップ（名前による参照）
- `@arrows_by_id` : {id => Arrow} マップ（IDによる参照）
- `@next_entity_id` : 次のEntity ID
- `@next_arrow_id` : 次のArrow ID
- `@occupied_positions` : 占有済みの位置（Set）

**主要メソッド**

- `entity(type, name, position)` / `user/business/operator(name, position)`
  1. nameが既に登録済みか確認 → Yes: 既存のIDを返す
  2. 位置指定を`PositionResolver`で解決
  3. 位置が占有されていないか確認 → 占有済み: エラー
  4. Entity を作成し、各マップに登録
  5. 位置を占有として記録
  6. IDを返す

- `arrow(type, name, from, to)` / `object/money/information(name, from, to)`
  1. from, to の Entity参照を解決（ID または名前）
  2. 両Entity が存在するか確認 → 存在しない: エラー
  3. Arrow を作成し、各マップに登録
  4. IDを返す

- `to_dot(title)` → `DotGenerator`に委譲

#### `DotGenerator`クラス

Entity と Arrow から DOT言語コードを生成する。

**配色**
- `:user` → "#FFE5CC"（オレンジ系）
- `:business` → "#CCE5FF"（青系）
- `:operator` → "#E5FFCC"（緑系）

**エッジスタイル**
- `:object` → color: black
- `:money` → color: red
- `:information` → color: blue

**生成ロジック**

1. `digraph Bizgram { ... }` の枠組みを作成
2. graph属性でタイトルを指定
3. ノード定義：`node_{id} [label="name", shape=box, style=filled, fillcolor="color"];` の形式で全Entity を出力
4. エッジ定義：`node_{from} -> node_{to} [label="name", color=color];` の形式で全Arrow を出力
5. 文字列をDOT言語の特殊文字（"など）をエスケープ

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

### DOT言語の生成例

```
digraph Bizgram {
  graph [label="タイトル", labelloc=top];
  rankdir=LR;

  node_0 [label="太郎", shape=box, style=filled, fillcolor="#FFE5CC"];
  node_1 [label="次郎", shape=box, style=filled, fillcolor="#FFE5CC"];
  node_2 [label="HOGEビジネス", shape=box, style=filled, fillcolor="#CCE5FF"];
  node_3 [label="FUGAビジネス", shape=box, style=filled, fillcolor="#CCE5FF"];
  node_4 [label="社員", shape=box, style=filled, fillcolor="#E5FFCC"];
  node_5 [label="販売員", shape=box, style=filled, fillcolor="#E5FFCC"];

  node_3 -> node_0 [label="商品", color=black];
  node_0 -> node_2 [label="代金", color=red];
  node_5 -> node_0 [label="広告", color=blue];
}
```
