# frozen_string_literal: true

require_relative '../lib/bizgram'

svg = Bizgram.draw("DSL拡張テスト") do
  u = user("ユーザー", :lt)
  c = company("会社", :rt)
  s = store("店舗", :lb)

  # 旧記法
  arrow(:information, "旧記法の情報", u, c)

  # 新記法：情報あり（- ... >）
  u -info("ログイン情報")> c


end

File.write("example/test_dsl.svg", svg)
puts "Generated example/test_dsl.svg"
