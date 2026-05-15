require_relative "../lib/bizgram"

# Test case 1: Multiple arrows between same entity pair
# Expected: Arrows should be offset (separated) not overlapping
puts "=== Test 1: Multiple arrows between same pair ==="
result1 = Bizgram.draw("Test 1: Multiple arrows between same pair") do
  user1 = user("User A", :lt)
  user2 = user("User B", :rt)

  # 3 arrows from user1 to user2
  arrow(:object, "Arrow 1 (object)", user1, user2)
  arrow(:money, "Arrow 2 (money)", user1, user2)
  arrow(:information, "Arrow 3 (info)", user1, user2)
end
puts "Generated: #{result1.lines.count} lines"
File.write("example/test1_multi_arrows.svg", result1)

puts "\n=== Test 2: Bidirectional arrows ==="
# Test case 2: Bidirectional arrows
# Expected: Arrows should be offset left/right from centerline
result2 = Bizgram.draw("Test 2: Bidirectional arrows") do
  company1 = company("Company A", :lt)
  company2 = company("Company B", :rb)

  # Forward and reverse arrows
  arrow(:money, "Payment A→B", company1, company2)
  arrow(:money, "Refund B→A", company2, company1)
end
puts "Generated: #{result2.lines.count} lines"
File.write("example/test2_bidirectional.svg", result2)

puts "\n=== Test 3: Mixed scenario ==="
# Test case 3: Mixed scenario
# Expected: Multiple groups with different offset strategies
result3 = Bizgram.draw("Test 3: Mixed scenario") do
  a = user("A", :lt)
  b = business("B", :cm)
  c = company("C", :rt)

  # Group 1: A → B (2 arrows)
  arrow(:object, "Data 1", a, b)
  arrow(:information, "Data 2", a, b)

  # Group 2: B ↔ C (bidirectional)
  arrow(:money, "Payment B→C", b, c)
  arrow(:money, "Commission C→B", c, b)
end
puts "Generated: #{result3.lines.count} lines"
File.write("example/test3_mixed.svg", result3)

puts "\n✓ All test files generated successfully"

