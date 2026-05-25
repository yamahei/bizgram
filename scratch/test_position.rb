require_relative '../lib/bizgram'

# テスト1: 後から位置指定を受け付けるか
begin
  Bizgram.draw("テスト1") do
    company("A")
    company("A", :cb)
  end
  puts "テスト1 OK: 後からの位置指定が成功しました"
rescue => e
  puts "テスト1 FAILED: #{e.class} - #{e.message}"
end

# テスト2: 複数回の位置指定をエラーとして弾くか
begin
  Bizgram.draw("テスト2") do
    company("B", :cb)
    company("B", :cb)
  end
  puts "テスト2 FAILED: エラーが発生しませんでした"
rescue ArgumentError => e
  puts "テスト2 OK: #{e.message}"
rescue => e
  puts "テスト2 FAILED (Unexpected error): #{e.class} - #{e.message}"
end

# テスト3: 異なる位置の重複指定をエラーとして弾くか
begin
  Bizgram.draw("テスト3") do
    company("C", :cb)
    company("C", :ct)
  end
  puts "テスト3 FAILED: エラーが発生しませんでした"
rescue ArgumentError => e
  puts "テスト3 OK: #{e.message}"
rescue => e
  puts "テスト3 FAILED (Unexpected error): #{e.class} - #{e.message}"
end
