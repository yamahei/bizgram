require_relative '../lib/bizgram'

File.write("09_systemize.svg", Bizgram.draw("ECプラットフォームのシステム化範囲") do
  # 主体（Entity）の定義
  u = user "ユーザー", :lt
  app = smartphone "スマホアプリ", :lm
  
  ec = business "EC基盤", :cm
  pay = business "決済代行", :rt
  
  store = store "加盟店", :cb
  delivery = business "配送業者", :rb
  
  # 矢印（Arrow）の定義
  a1 = arrow :info, "商品検索\n注文", u, app
  a2 = arrow :info, "API連携", app, ec
  a3 = arrow :money, "決済要求", ec, pay
  a4 = arrow :info, "発注データ", ec, store
  a5 = arrow :object, "商品集荷", store, delivery
  a6 = arrow :object, "配達", delivery, u
  
  # システム化範囲（Systemize）の定義
  # 1. ユーザー向けフロントエンド
  systemize "フロントエンド", app, a1, a2
  
  # 2. EC基盤バックエンド
  systemize "バックエンド", ec, a3, a4
  
  # 3. 外部連携システム
  systemize "外部システム", pay, delivery, a5, a6
end)
