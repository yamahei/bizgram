require_relative "../lib/bizgram"

svg = Bizgram.draw("Be My Eyesのビジネスモデル") do

  user("視覚障害者", :ct)
  
  user("目が見える\nボランティア", :lm)
  comment("目が見える\nボランティア", "賞味期限の確認\nなどちょっとし\nたことに対応")

  smartphone("Be My Eyes", :cm)
  
  company("企業の\nサポート窓口", :rm)
  comment("企業の\nサポート窓口", "視覚に障害\nのある顧客\nや従業員の\nためにアプ\nリを活用")
  
  company("Accessibly Inc.", :cb)

  arrow(:other, "ビデオ通話で\n助けを求める", "視覚障害者", "Be My Eyes")
  arrow(:other, "連携", "Be My Eyes", "目が見える\nボランティア")
  arrow(:other, "連携", "Be My Eyes", "企業の\nサポート窓口")
  arrow(:other, "困り事の\n解決", "目が見える\nボランティア", "視覚障害者")
  arrow(:other, "社員や従業員の\n困り事の解決", "企業の\nサポート窓口", "視覚障害者")
  arrow(:money, "開発・運営", "Accessibly Inc.", "Be My Eyes")
  arrow(:money, "利用料", "企業の\nサポート窓口", "Accessibly Inc.")
end

File.write("example/06_bemyeyes.svg", svg)
puts "Generated example/06_bemyeyes.svg"
