require_relative "lib/bizgram"

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