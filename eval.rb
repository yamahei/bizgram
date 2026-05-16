require './lib/bizgram'
def dump_svg(filename)
  content = File.read(filename)
  paths = content.scan(/<path d="(.*?)" stroke="(.*?)"/)
  puts "=== #{filename} ==="
  paths.each do |d, color|
    puts "Path (#{color}): #{d}"
  end
end

begin
  dot1 = Bizgram.draw("game") do
    user = user("ゲーム利用者", :ct)
    device = smartphone("利用者のデバイス", :cm)
    site = other("ゲーム配布サイト", 5)
    company = company("(株)HOGEゲームズ", 7)
    arrow(:money, "ゲーム購入", user, site)
    arrow(:object, "インストール", site, device)
    arrow(:other, "プレイ", user, device)
    arrow(:object, "作品アップロード", company, site)
    arrow(:money, "売上", site, company)
  end
  File.write("example/game.svg", dot1)
  
  dot2 = Bizgram.draw("game_p2") do
    user = user("ゲーム利用者", :lt)
    device = smartphone("利用者のデバイス", :cm)
    site = other("ゲーム配布サイト", 5)
    company = company("(株)HOGEゲームズ", 8)
    arrow(:money, "ゲーム購入", user, site)
    arrow(:object, "インストール", site, device)
    arrow(:other, "プレイ", user, device)
    arrow(:object, "作品アップロード", company, site)
    arrow(:money, "売上", site, company)
  end
  File.write("example/game_p2.svg", dot2)

  dot3 = Bizgram.draw("multi_arrow") do
    b = business("B", 4)
    c = business("C", 5)
    arrow(:object, "作品アップロード", b, c)
    arrow(:money, "売上", c, b)
  end
  File.write("example/test3_mixed.svg", dot3)

  dump_svg("example/game.svg")
  dump_svg("example/game_p2.svg")
  dump_svg("example/test3_mixed.svg")
rescue => e
  puts "Error: #{e.message}"
end
