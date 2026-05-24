bizgram
=======

概要
--

Bizgram（ビジネスモデル図解）をRubyコードで書くためのDSLライブラリです。
このライブラリで定義したビジネスモデルは、Bizgramを表す SVG ドキュメントとして直接出力されます。

- 参考資料：[ビジネスモデル図解ツールキット配布版](./reference/ビジネスモデル図解ツールキット配布版.pdf)

> [!NOTE] これは非公式ツールです
> このツールは[Bizgram](https://bizgram.zukai.co/)が「人間が指示してAIが実装する」練習のテーマに丁度良いサイズだったという理由で、勝手に作ったものであり、[株式会社図解総研](https://zukai.co/)さまの許可は得ていません。

特徴
--

- **Rubyの内部DSL** : Rubyの文法をそのまま活用でき、専用のパーサーが不要です。
- **シンプルな記述ルール** : 直感的な矢印構文（`- ... >`）などをサポートしており、非エンジニアでも簡単に定義可能です。
- **テキストで定義** : 差分がGitなどのバージョン管理システムで追いやすく、チームでの共同作業に向いています。

セットアップ
------

### システム要件
- Ruby 3.0 以上

### インストール

```bash
bundle install
```

使用方法
----

### 基本的な例
```ruby
require "bizgram"

svg = Bizgram.draw("例）買い切り型のスマホゲーム") do
  # 主体の定義
  user = user("ゲーム利用者")
  device = smartphone("利用者のデバイス", :cm)# 明示的な配置指定
  site = other("ゲーム配布サイト")

  # モノ・カネ・情報の流れを定義
  user -money("ゲーム購入")> site
  site -object("インストール")> device
  arrow(:other, "プレイ", user, device)# 旧来の記法

  ## 主体は直接書くこともできる
  company("(株)HOGEゲームズ", :cb) -object("作品アップロード")> device# 明示的な配置指定
  site -money("売上")> company("(株)HOGEゲームズ")

  # コメントの定義
  comment_to(site, "Google Play的な")

end

puts svg
```

このコードは以下のような SVGドキュメントを出力します：

```sh
bundle exec ruby example/00_basic_sample.rb
```

![](./example/00_basic_sample.svg)

他にも複雑な配置や多重矢印を試すためのサンプルコードを用意しています。
以下のコマンドをコピペして実行することで、それぞれのSVGを生成できます。

```sh
# ①ごく普通のBizgramコード
bundle exec ruby ruby example/01_normal.rb

# ②複雑なBizgramコード
bundle exec ruby ruby example/02_complex.rb

# ③意地悪な（多重・双方向など）Bizgramコード
bundle exec ruby ruby example/03_edge_case.rb

# ④新しい直感的なDSL記法のBizgramコード
bundle exec ruby ruby example/04_test_dsl.rb

# ⑤〜⑧ 実際のギャラリーに基づく複雑なBizgramコード（手動配置ベースライン）
bundle exec ruby ruby example/05_innoqua.rb
bundle exec ruby ruby example/06_bemyeyes.rb
bundle exec ruby ruby example/07_washplus.rb
bundle exec ruby ruby example/08_koto.rb

# ⑤〜⑧ の自動配置版Bizgramコード
bundle exec ruby ruby example/05_innoqua_autolayout.rb
bundle exec ruby ruby example/06_bemyeyes_autolayout.rb
bundle exec ruby ruby example/07_washplus_autolayout.rb
bundle exec ruby ruby example/08_koto_autolayout.rb
```

### レイアウトに関する注意事項

Bizgramのコード記述では、主体の位置を明示しない「自動配置」でほとんどの図を綺麗に生成できますが、以下の点にご留意ください。

1. **自動配置の限界**: 図が複雑すぎてどうしても自動配置アルゴリズムで解決できない場合、エラーになることがあります。
2. **要素の被り**: コメントの文字数が多い場合や、要素が密集している箇所では、図の骨格（矢印）を優先する仕様上、どうしても要素同士の被りが発生することがあります。
3. **手動配置での調整**: 出力された図の配置が気に入らない場合や上記のエラー・被りを解消したい場合は、各主体に配置ヒント（例：`:ct`, `:cm`, `5`など）を付与することで、部分的または全体的に手動で配置を調整することが可能です。



テスト
---

すべてのテストを実行：

```bash
bundle exec rspec
```

特定のテストファイルを実行：

```bash
bundle exec rspec spec/bizgram_spec.rb
```

仕様書
---

実装の詳細や内部の設計については、以下を参照してください：

- [外部仕様](./specification.md#外部仕様) : ユーザー向けのメソッド仕様やDSLの文法
- [内部仕様](./specification.md#内部仕様) : アーキテクチャ、クラス設計、SVG生成ロジック

この先の開発の方向性については、以下を参照してください：

- [ロードマップ](./ROADMAP.md) : 今後実装したい機能や改善タスクの優先順位リスト


参照
--

- [Bizgram（ビジネスモデル図解）公式サイト](https://bizgram.zukai.co/)
- [Bizgram 図解の説明書](https://bizgram.zukai.co/howto)