#!/usr/bin/env ruby
# frozen_string_literal: true

require "bizgram"

# POC B2: 補足ボックス機能テスト
dot = Bizgram.draw "オンライン書店のビジネスモデル（補足付き）" do
  # 主体の定義
  user "読者", :ct
  business "書籍販売事業", :cm
  operator "書店スタッフ", :cb

  # フロー定義
  money "書籍代金", user("読者"), business("書籍販売事業")
  object "書籍", business("書籍販売事業"), user("読者")
  information "PR", operator("書店スタッフ"), user("読者")

  # POC B2: 補足を追加
  comment "クレジット払いも対応", for_arrow: "書籍代金"
  comment "在庫あるものは即日配送", for_arrow: "書籍"
  comment "SNS・メール配信", for_arrow: "PR"
end

puts dot
