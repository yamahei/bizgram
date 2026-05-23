require_relative "../lib/bizgram"

svg = Bizgram.draw("KOTOのビジネスモデル") do

  user("地元の人や\n旅行客", :lt)
  comment("地元の人や\n旅行客", "食事をする\nことは職業\n訓練生の実\n践経験とな\nり、お金を\n払うことが\n訓練生の支\n援に")

  user("恵まれない境遇\nにある若者たち", :ct)
  comment("恵まれない境遇\nにある若者たち", "家庭環境や経\n済的事情によ\nり、教育や就\n労の機会が\n限られている")

  company("個人・企業\nおよび財団", :rt)
  comment("個人・企業\nおよび財団", "教育・社会貢\n献に関心のあ\nる企業・財団\nとレストラン\nでの体験で共\n感を得た個人\nなどが支持者")

  store("直営レストラン", :lm)
  comment("直営レストラン", "職業訓練の\n場であると\n同時に\nKOTOの理念\nを社会に伝\nえる生きた\n教室")

  other("職業訓練\nプログラム", :cm)
  comment("職業訓練\nプログラム", "2年間の寮生活\nと、調理・飲食\nサービスなどの職\n業訓練に加え、生\n活面や社会性の基\n礎スキルを育む支\n援を行う")

  money("寄付や助成", :rm)

  company("Know One,\nTeach One", :cb)
  comment("Know One,\nTeach One", "ベトナム発の社会\n企業。活動自体は\n1999年から")
  comment("Know One,\nTeach One", "ケータリング\nや料理教室、\nスタディツ\nアー、物販な\nどの関連事業\nも展開し、そ\nの収益を職業\n訓練プログラ\nムの運営資金\nとして活用")

  company("KOTO\nInternational Ltd.", :rb)
  comment("KOTO\nInternational Ltd.", "グローバル\nな資金調達\nやパート\nナーシップ\nを通じて\nKOTOを支\nえる非営利\n組織")

  arrow(:money, "利用", "地元の人や\n旅行客", "直営レストラン")
  arrow(:other, "場の提供", "直営レストラン", "職業訓練\nプログラム")
  arrow(:other, "実践機会", "職業訓練\nプログラム", "直営レストラン")
  arrow(:other, "職業\nスキル", "恵まれない境遇\nにある若者たち", "職業訓練\nプログラム")
  arrow(:other, "全寮制教育・\n生活支援の無償提供", "職業訓練\nプログラム", "恵まれない境遇\nにある若者たち")
  arrow(:money, "寄付", "個人・企業\nおよび財団", "寄付や助成")
  arrow(:money, "集める", "寄付や助成", "KOTO\nInternational Ltd.")
  arrow(:money, "運営", "Know One,\nTeach One", "直営レストラン")
  arrow(:money, "売上", "直営レストラン", "Know One,\nTeach One")
  arrow(:money, "運営", "Know One,\nTeach One", "職業訓練\nプログラム")
  arrow(:money, "支援資金", "KOTO\nInternational Ltd.", "Know One,\nTeach One")
  arrow(:information, "成果報告", "Know One,\nTeach One", "KOTO\nInternational Ltd.")
  arrow(:money, "支援\n資金", "寄付や助成", "Know One,\nTeach One")
end

File.write("example/08_koto.svg", svg)
puts "Generated example/08_koto.svg"
