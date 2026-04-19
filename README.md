bizgram
=======

Bizgram（ビジネスモデル図解）をRubyコードで書くためのDSLライブラリです。
このライブラリで定義したビジネスモデルは、[DOT言語](https://ja.wikipedia.org/wiki/DOT%E8%A8%80%E8%AA%9E)コードとして出力され、[Graphviz](https://graphviz.org/)を通すことで、Bizgram（ビジネスモデル図解）として描画できます。

- 資料：[ビジネスモデル図解ツールキット配布版](./ビジネスモデル図解ツールキット配布版.pdf)

特徴
----

- **Rubyの内部DSL** - Rubyの文法をそのまま活用でき、専用パーサーが不要
- **シンプルな記述ルール** - Rubyを知らなくてもBizgramが定義できる
- **DOT言語出力** - 変更差分がGitで管理しやすいテキストデータ

セットアップ
-----------

### 要件
- Ruby 3.0 以上

### インストール

```bash
bundle install
```

使用方法
--------

### 基本的な例

```ruby
require "bizgram"

# 図を定義する
dot_code = Bizgram.draw("オンライン書店のビジネスモデル") do
  # 利用者の定義
  user "読者"

  # 事業の定義
  business "書籍販売事業"

  # 事業者の定義
  operator "書店スタッフ"

  # 流れの定義
  money "書籍代金", user("読者"), business("書籍販売事業")
  object "書籍", business("書籍販売事業"), user("読者")
  information "PR", operator("書店スタッフ"), user("読者")
end

# DOT言語コードを出力（Graphvizで処理可能）
puts dot_code
```

#### 出力結果

##### DOT（これが出力される）

```
digraph Bizgram {
  graph [label="オンライン書店のビジネスモデル", labelloc=top];
  rankdir=TB;

  node_0 [label="読者", shape=box, style=filled, fillcolor="#FFE5CC"];
  node_3 [label="書籍販売事業", shape=box, style=filled, fillcolor="#CCE5FF"];
  node_6 [label="書店スタッフ", shape=box, style=filled, fillcolor="#E5FFCC"];

  node_0 -> node_3 [label="書籍代金", color=red];
  node_3 -> node_0 [label="書籍", color=black];
  node_6 -> node_0 [label="PR", color=blue];
}
```

##### SVG（Graphizに食わせて生成した結果）

![](./example/example_bookstore.svg)



### 完全な例

```ruby
require "bizgram"

dot = Bizgram.draw("スマートフォン販売") do
  # 利用者
  user "消費者"

  # 事業
  business "小売事業"
  business "通信事業"
  provider = operator "通信事業者"

  # モノの流れ
  object "スマートフォン", business("小売事業"), user("消費者")
  object "通信サービス", business("通信事業"), user("消費者")

  # カネの流れ
  money "購入代金", user("消費者"), business("小売事業")
  money "通信料金", user("消費者"), business("通信事業")

  # 情報の流れ
  information "広告", provider, user("消費者")
end

puts dot
```

#### 生成されたDOT言語をGraphvizで画像化

生成されたDOT言語コードをGraphvizで処理します：

```bash
# SVG形式で出力
dot -Tsvg output.dot -o diagram.svg

# PNG形式で出力
dot -Tpng output.dot -o diagram.png

# 一気に実行→出力（svg）
ruby example/example_smartphone-seller.rb | dot -Tsvg -o bookstore.svg
```

オンラインツール：https://dreampuf.github.io/GraphvizOnline/
（[出力結果](./example/example_smartphone-seller.svg)）

テスト
------

すべてのテストを実行：

```bash
bundle exec rspec
```

特定のテストファイルを実行：

```bash
bundle exec rspec spec/bizgram_spec.rb
```

仕様書
------

実装の詳細や内部の設計については、以下を参照してください：

- [外部仕様](./specification.md#外部仕様) - ユーザー向けのメソッド仕様
- [内部仕様](./specification.md#内部仕様) - アーキテクチャ、クラス設計、バリデーション

参照
----

- [Bizgram（ビジネスモデル図解）](https://bizgram.zukai.co/)
- [図解の説明書](https://bizgram.zukai.co/howto)
- [Graphviz](https://graphviz.org/)
- [DOT言語](https://ja.wikipedia.org/wiki/DOT%E8%A8%80%E8%AA%9E)