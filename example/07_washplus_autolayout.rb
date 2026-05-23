require_relative "../lib/bizgram"

svg = Bizgram.draw("wash+のビジネスモデル") do

  user("人や環境に配慮して\n洗濯する人")
  comment("人や環境に配慮して\n洗濯する人", "アプリで空き状況の\n確認・事前予約・\nキャッシュレス決済\nまで完結できる")

  store("街中のコイン\nランドリー")
  comment("街中のコイン\nランドリー", "山本製作所\n製機器と接\n続でき、多\n言語表示や\n通知などの\n機能を一体\nで提供する")

  object("wash+\n専用洗濯機")

  information("洗浄・IoT技術")
  comment("洗浄・IoT技術", "アルカリイ\nオン電解水\nで洗剤を使\nわずに洗\nい、肌刺激\nと排水負荷\nを同時に抑\nえる")

  user("フランチャイズ\nオーナー")
  comment("フランチャイズ\nオーナー", "無人運営と遠\n隔監視で人員\n配置を最小化\nし、夜間も含\nめ安定稼働さ\nせる")

  company("株式会社\nwash-plus")
  
  company("山本製作所")
  comment("山本製作所", "機器メー\nカーと共同\n開発した制\n御基盤を後\nから更新で\nき、導入後\nの機能劣化\nを防ぐ")

  arrow(:other, "訪れる", "人や環境に配慮して\n洗濯する人", "街中のコイン\nランドリー")
  arrow(:money, "決済", "人や環境に配慮して\n洗濯する人", "wash+\n専用洗濯機")
  arrow(:information, "空き状況など", "wash+\n専用洗濯機", "人や環境に配慮して\n洗濯する人")
  arrow(:object, "", "街中のコイン\nランドリー", "wash+\n専用洗濯機")
  arrow(:information, "技術", "洗浄・IoT技術", "wash+\n専用洗濯機")
  arrow(:money, "売上", "街中のコイン\nランドリー", "フランチャイズ\nオーナー")
  arrow(:other, "店舗を運営", "フランチャイズ\nオーナー", "街中のコイン\nランドリー")
  arrow(:money, "直営\n売上", "街中のコイン\nランドリー", "株式会社\nwash-plus")
  arrow(:money, "開発", "株式会社\nwash-plus", "wash+\n専用洗濯機")
  arrow(:information, "権利", "株式会社\nwash-plus", "フランチャイズ\nオーナー")
  arrow(:money, "ロイヤリティ等", "フランチャイズ\nオーナー", "株式会社\nwash-plus")
  arrow(:information, "技術開発", "山本製作所", "洗浄・IoT技術")
  arrow(:other, "共同開発", "株式会社\nwash-plus", "山本製作所")
  arrow(:other, "", "山本製作所", "株式会社\nwash-plus")
end

File.write("example/07_washplus_autolayout.svg", svg)
puts "Generated example/07_washplus_autolayout.svg"
