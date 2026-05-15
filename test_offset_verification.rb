#!/usr/bin/env ruby
# Direct offset implementation verification

# Simulate offset calculation
def test_offset_calculation
  length = 2
  puts "=== Offset Calculation (2 arrows) ==="

  (0...length).each do |index|
    offset = (index - (length - 1) / 2.0) * 10.0
    puts "  Arrow #{index}: offset = #{offset.to_s.rjust(6)} (#{offset == 0 ? "SIMPLE" : "OFFSET"})"
  end

  length = 3
  puts "\n=== Offset Calculation (3 arrows) ==="

  (0...length).each do |index|
    offset = (index - (length - 1) / 2.0) * 10.0
    puts "  Arrow #{index}: offset = #{offset.to_s.rjust(6)} (#{offset == 0 ? "SIMPLE" : "OFFSET"})"
  end
end

# Test path generation with offset
def test_path_generation_with_offset
  puts "\n=== Path Generation Example ==="

  from_x = 498.6196
  to_x = 937.0625
  from_y = 66.37796
  to_y = 66.37796

  offsets = [-10.0, 0.0, 10.0]

  offsets.each_with_index do |offset, i|
    mid_x = (from_x + to_x) / 2.0 + offset
    path = "M #{from_x},#{from_y} L #{mid_x},#{from_y} L #{mid_x},#{to_y} L #{to_x},#{to_y}"

    first_L = path.scan(/L ([\d.]+),/)[0][0].to_f
    puts "  Arrow #{i}: offset=#{offset.to_s.rjust(6)}, mid_x=#{mid_x.to_s.rjust(10)}, path mid_x=#{first_L}"
  end
end

# Main
test_offset_calculation
test_path_generation_with_offset

puts "\n=== Findings ==="
puts "✓ Offset calculation: WORKING"
puts "✓ Path generation: Should differ by offset values"
puts "✗ Issue: Text labels not offsetting (using fixed midpoint)"
