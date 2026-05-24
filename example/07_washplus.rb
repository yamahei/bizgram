require_relative "../lib/bizgram"

svg = Bizgram.draw("wash+のビジネスモデル") do

  user("人や環境に配慮して洗濯する人", :ct)
  comment("人や環境に配慮して洗濯する人", "アプリで空き状況の確認・事前予約・キャッシュレス決済まで完結できる")

  store("街中のコインランドリー", :lm)
  comment("街中のコインランドリー", "山本製作所製機器と接続でき、多言語表示や通知などの機能を一体で提供する")

  object("wash+専用洗濯機", :cm)

  information("洗浄・IoT技術", :rm)
  comment("洗浄・IoT技術", "アルカリイオン電解水で洗剤を使わずに洗い、肌刺激と排水負荷を同時に抑える")

  user("フランチャイズオーナー", :lb)
  comment("フランチャイズオーナー", "無人運営と遠隔監視で人員配置を最小化し、夜間も含め安定稼働させる")

  company("株式会社wash-plus", :cb)
  
  company("山本製作所", :rb)
  comment("山本製作所", "機器メーカーと共同開発した制御基盤を後から更新でき、導入後の機能劣化を防ぐ")

  arrow(:other, "訪れる", "人や環境に配慮して洗濯する人", "街中のコインランドリー")
  arrow(:money, "決済", "人や環境に配慮して洗濯する人", "wash+専用洗濯機")
  arrow(:information, "空き状況など", "wash+専用洗濯機", "人や環境に配慮して洗濯する人")
  arrow(:object, "", "街中のコインランドリー", "wash+専用洗濯機")
  arrow(:information, "技術", "洗浄・IoT技術", "wash+専用洗濯機")
  arrow(:money, "売上", "街中のコインランドリー", "フランチャイズオーナー")
  arrow(:other, "店舗を運営", "フランチャイズオーナー", "街中のコインランドリー")
  arrow(:money, "直営売上", "街中のコインランドリー", "株式会社wash-plus")
  arrow(:money, "開発", "株式会社wash-plus", "wash+専用洗濯機")
  arrow(:information, "権利", "株式会社wash-plus", "フランチャイズオーナー")
  arrow(:money, "ロイヤリティ等", "フランチャイズオーナー", "株式会社wash-plus")
  arrow(:information, "技術開発", "山本製作所", "洗浄・IoT技術")
  arrow(:other, "共同開発", "株式会社wash-plus", "山本製作所")
  arrow(:other, "", "山本製作所", "株式会社wash-plus")
end

File.write("example/07_washplus.svg", svg)
puts "Generated example/07_washplus.svg"
