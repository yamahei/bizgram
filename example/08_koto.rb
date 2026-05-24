require_relative "../lib/bizgram"

svg = Bizgram.draw("KOTOのビジネスモデル") do

  user("地元の人や旅行客", :lt)
  comment("地元の人や旅行客", "食事をすることは職業訓練生の実践経験となり、お金を払うことが訓練生の支援に")

  user("恵まれない境遇にある若者たち", :ct)
  comment("恵まれない境遇にある若者たち", "家庭環境や経済的事情により、教育や就労の機会が限られている")

  company("個人・企業および財団", :rt)
  comment("個人・企業および財団", "教育・社会貢献に関心のある企業・財団とレストランでの体験で共感を得た個人などが支持者")

  store("直営レストラン", :lm)
  comment("直営レストラン", "職業訓練の場であると同時にKOTOの理念を社会に伝える生きた教室")

  other("職業訓練プログラム", :cm)
  comment("職業訓練プログラム", "2年間の寮生活と、調理・飲食サービスなどの職業訓練に加え、生活面や社会性の基礎スキルを育む支援を行う")

  money("寄付や助成", :rm)

  company("Know One,Teach One", :cb)
  comment("Know One,Teach One", "ベトナム発の社会企業。活動自体は1999年から")
  comment("Know One,Teach One", "ケータリングや料理教室、スタディツアー、物販などの関連事業も展開し、その収益を職業訓練プログラムの運営資金として活用")

  company("KOTOInternational Ltd.", :rb)
  comment("KOTOInternational Ltd.", "グローバルな資金調達やパートナーシップを通じてKOTOを支える非営利組織")

  arrow(:money, "利用", "地元の人や旅行客", "直営レストラン")
  arrow(:other, "場の提供", "直営レストラン", "職業訓練プログラム")
  arrow(:other, "実践機会", "職業訓練プログラム", "直営レストラン")
  arrow(:other, "職業スキル", "恵まれない境遇にある若者たち", "職業訓練プログラム")
  arrow(:other, "全寮制教育・生活支援の無償提供", "職業訓練プログラム", "恵まれない境遇にある若者たち")
  arrow(:money, "寄付", "個人・企業および財団", "寄付や助成")
  arrow(:money, "集める", "寄付や助成", "KOTOInternational Ltd.")
  arrow(:money, "運営", "Know One,Teach One", "直営レストラン")
  arrow(:money, "売上", "直営レストラン", "Know One,Teach One")
  arrow(:money, "運営", "Know One,Teach One", "職業訓練プログラム")
  arrow(:money, "支援資金", "KOTOInternational Ltd.", "Know One,Teach One")
  arrow(:information, "成果報告", "Know One,Teach One", "KOTOInternational Ltd.")
  arrow(:money, "支援資金", "寄付や助成", "Know One,Teach One")
end

File.write("example/08_koto.svg", svg)
puts "Generated example/08_koto.svg"
