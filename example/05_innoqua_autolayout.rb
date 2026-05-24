require_relative "../lib/bizgram"

svg = Bizgram.draw("株式会社イノカのビジネスモデル") do


  # Entities (手動配置によるベースライン生成)
  company("企業・自治体")
  comment("企業・自治体", "施設の集客やこどもたちに環境を学ぶ機会を提供したい企業や自治体")

  user("来場者")
  comment("来場者", "施設に設置されたサンゴ礁の水槽を通し、観察・対話によって自然を学べるイベントに参加")

  other("海の生態系を再現する事業")

  information("環境移送技術")
  comment("環境移送技術", "海をはじめとした水域の自然環境を水槽を用いて陸地で再現する独自の技術")

  company("株式会社イノカ")

  # Arrows
  arrow(:money, "販促費スポンサー", "企業・自治体", "海の生態系を再現する事業")
  arrow(:information, "海洋教育", "海の生態系を再現する事業", "来場者")
  arrow(:information, "技術を社会に", "環境移送技術", "海の生態系を再現する事業")
  arrow(:money, "運営", "株式会社イノカ", "海の生態系を再現する事業")
  arrow(:money, "売上", "海の生態系を再現する事業", "株式会社イノカ")
  arrow(:information, "開発", "株式会社イノカ", "環境移送技術")
  arrow(:other, "施設に人が集まる", "来場者", "企業・自治体")
end

File.write("example/05_innoqua_autolayout.svg", svg)
puts "Generated example/05_innoqua_autolayout.svg"
