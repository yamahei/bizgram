require_relative "../lib/bizgram"

dot = Bizgram.draw("スマートフォン販売ビジネスモデル") do
  # 利用者の定義
  consumer = user "消費者"

  # 事業の定義
  retail_biz = business "小売事業"
  telecom_biz = business "通信事業"

  # 事業者の定義
  telecom_provider = operator "通信事業者"

  # モノの流れ
  object "スマートフォン", retail_biz, consumer
  object "通信サービス", telecom_biz, consumer

  # カネの流れ
  money "購入代金", consumer, retail_biz
  money "通信料金", consumer, telecom_biz

  # 情報の流れ
  information "広告", telecom_provider, consumer

  # コメント（補足情報）の追加
  comment consumer, "最終ユーザー"
  comment_to retail_biz, "端末の販売"
  comment telecom_biz, "通信サービス提供"
  comment_to telecom_provider, "サポート体制"
end

puts dot