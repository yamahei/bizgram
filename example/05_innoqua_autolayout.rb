require_relative "../lib/bizgram"

svg = Bizgram.draw("株式会社イノカのビジネスモデル") do


  # Entities (手動配置によるベースライン生成)
  company("企業・自治体")
  comment("企業・自治体", "施設の集客やこどもたち\nに環境を学ぶ機会を提供\nしたい企業や自治体")

  user("来場者")
  comment("来場者", "施設に設置さ\nれたサンゴ礁\nの水槽を通\nし、観察・対\n話によって自\n然を学べるイ\nベントに参加")

  other("海の生態系を\n再現する事業")

  information("環境移送技術")
  comment("環境移送技術", "海をはじめと\nした水域の自\n然環境を水槽\nを用いて陸地\nで再現する独\n自の技術")

  company("株式会社イノカ")

  # Arrows
  arrow(:money, "販促費\nスポンサー", "企業・自治体", "海の生態系を\n再現する事業")
  arrow(:information, "海洋教育", "海の生態系を\n再現する事業", "来場者")
  arrow(:information, "技術を社会に", "環境移送技術", "海の生態系を\n再現する事業")
  arrow(:money, "運営", "株式会社イノカ", "海の生態系を\n再現する事業")
  arrow(:money, "売上", "海の生態系を\n再現する事業", "株式会社イノカ")
  arrow(:information, "開発", "株式会社イノカ", "環境移送技術")
  arrow(:other, "施設に人が\n集まる", "来場者", "企業・自治体")
end

File.write("example/05_innoqua_autolayout.svg", svg)
puts "Generated example/05_innoqua_autolayout.svg"
