require_relative "lib/bizgram"

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
