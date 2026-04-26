require_relative "../lib/bizgram"

dot = Bizgram.draw("例）買い切り型のスマホゲーム") do
  # 主体の定義
  user = user("ゲーム利用者", :ct)
  device = smartphone("利用者のデバイス", :cm)
  site = other("ゲーム配布サイト", 5)
  company = company("(株)HOGEゲームズ", 7)
  # モノ・カネ・情報の定義
  arrow(:money, "ゲーム購入", user, site)
  arrow(:object, "インストール", site, device)
  arrow(:other, "プレイ", user, device)
  arrow(:object, "作品アップロード", company, site)
  arrow(:money, "売上", site, company)
  # コメントの定義
  comment_to(site, "Google Play的な")
end

puts dot