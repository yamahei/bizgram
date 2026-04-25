require_relative "../lib/bizgram"

dot = Bizgram.draw("CRISP SALAD WORKS: https://bizgram.zukai.co/models/ivldryulmfg") do
  # 主体の定義
  user = user("オフィス街で働く人", :ct)
  salad = object("栄養満点で主食になるサラダ", :lm)
  service = device("CRISP SALAD WORKS", :cm)
  info = info("顧客の行動分析データ", :rm)
  company = company("株式会社CRISP", :cb)
  staff = user("従業員", :rb)
  # モノ・カネ・情報の定義
  arrow(:money, "デジタル注文/支払", user, service)
  arrow(:object, "短い待ち時間で提供", salad, user)
  arrow(:object, "店舗で手作り", service, salad)
  arrow(:information, "顧客データ", service, info)
  arrow(:other, "運用改善", info, service)
  arrow(:money, "売上", service, company)
  arrow(:money, "運営", company, service)
  arrow(:money, "時給", company, staff)
  arrow(:other, "勤務", staff, company)

end

puts dot