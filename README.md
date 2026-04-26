bizgram
=======

Bizgram（ビジネスモデル図解）をRubyコードで書くためのDSLライブラリです。
このライブラリで定義したビジネスモデルは、[DOT言語](https://ja.wikipedia.org/wiki/DOT%E8%A8%80%E8%AA%9E)コードとして出力され、[Graphviz](https://graphviz.org/)を通すことで、Bizgram（ビジネスモデル図解）として描画できます。

- 資料：[ビジネスモデル図解ツールキット配布版](./reference/ビジネスモデル図解ツールキット配布版.pdf)

特徴
----

- **Rubyの内部DSL** - Rubyの文法をそのまま活用でき、専用パーサーが不要
- **シンプルな記述ルール** - Rubyを知らなくてもBizgramが定義できる？
- **テキストで定義** - 変更差分がGitで管理しやすいテキストデータ

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

### 例

```ruby
require "bizgram"

dot = Bizgram.draw("例）買い切り型のスマホゲーム") do
  # 主体の定義
  user = user("ゲーム利用者", :ct)
  device = smartphone("利用者のデバイス", :cm)
  site = other("ゲーム配布サイト", 5)
  company = company("(株)HOGEゲームズ", 7)
  # モノ・カネ・情報の定義
  arrow(:money, "ゲーム購入", user, site)
  arrow(:object, "インストール", site, device)
  arrow(:other, "プレイ", user, device)
  arrow(:object, "作品アップロード", company, site)
  arrow(:money, "売上", site, company)
  # コメントの定義
  comment_to(site, "Google Play的な")
end

puts dot
```

このコードは以下のような DOT言語コードを出力します：

```sh
ruby example/game.rb
```
```
digraph Bizgram {
  graph [label="例）買い切り型のスマホゲーム", labelloc=top];
  rankdir=TB;

  node_1 [label="ゲーム利用者", shape=box, style=filled, fillcolor="#FFE5CC"];
  node_4 [label="利用者のデバイス", shape=box, style=filled, fillcolor="#FFCCFF"];
  node_5 [label="ゲーム配布サイト", shape=box, style=filled, fillcolor="#F0F0F0"];
  node_7 [label="(株)HOGEゲームズ", shape=box, style=filled, fillcolor="#CCE5FF"];
  comment_9 [label="Google Play的な", shape=box, style="filled,rounded", fillcolor="#FFFFCC"];

  node_1 -> node_5 [label="ゲーム購入", color=red];
  node_5 -> node_4 [label="インストール", color=black];
  node_1 -> node_4 [label="プレイ", color=black];
  node_7 -> node_5 [label="作品アップロード", color=black];
  node_5 -> node_7 [label="売上", color=red];
  comment_9 -> node_5 [style=dashed, color=gray];
}
```
このコードは以下のような 図を出力します：

```sh
ruby example/game.rb | dot -Tsvg -o example/game.svg
```
![](./example/game.svg)

#### DOT言語コードを Graphviz で画像化

生成された DOT言語コードを Graphviz で処理して図を作成できます：

```bash
# SVG形式で出力
dot -Tsvg output.dot -o diagram.svg

# PNG形式で出力
dot -Tpng output.dot -o diagram.png

# Ruby スクリプトの出力を直接 Graphviz に渡す
ruby example.rb | dot -Tsvg -o diagram.svg
```

オンラインツール：https://dreampuf.github.io/GraphvizOnline/ で試すこともできます。

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

この先の開発の方向性については、以下を参照してください：

- [ロードマップ](./ROADMAP.md) - やりたいことに優先度付けしたリスト


参照
----

- [Bizgram（ビジネスモデル図解）](https://bizgram.zukai.co/)
- [図解の説明書](https://bizgram.zukai.co/howto)
- [Graphviz](https://graphviz.org/)
- [DOT言語](https://ja.wikipedia.org/wiki/DOT%E8%A8%80%E8%AA%9E)