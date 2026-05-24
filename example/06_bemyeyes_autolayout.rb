require_relative "../lib/bizgram"

svg = Bizgram.draw("Be My Eyesのビジネスモデル") do

  user("視覚障害者")
  
  user("目が見えるボランティア")
  comment("目が見えるボランティア", "賞味期限の確認などちょっとしたことに対応")

  smartphone("Be My Eyes")
  
  company("企業のサポート窓口")
  comment("企業のサポート窓口", "視覚に障害のある顧客や従業員のためにアプリを活用")
  
  company("Accessibly Inc.")

  arrow(:other, "ビデオ通話で助けを求める", "視覚障害者", "Be My Eyes")
  arrow(:other, "連携", "Be My Eyes", "目が見えるボランティア")
  arrow(:other, "連携", "Be My Eyes", "企業のサポート窓口")
  arrow(:other, "困り事の解決", "目が見えるボランティア", "視覚障害者")
  arrow(:other, "社員や従業員の困り事の解決", "企業のサポート窓口", "視覚障害者")
  arrow(:money, "開発・運営", "Accessibly Inc.", "Be My Eyes")
  arrow(:money, "利用料", "企業のサポート窓口", "Accessibly Inc.")
end

File.write("example/06_bemyeyes_autolayout.svg", svg)
puts "Generated example/06_bemyeyes_autolayout.svg"
