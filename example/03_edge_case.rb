require_relative "../lib/bizgram"

svg = Bizgram.draw("03_edge_case: 意地悪な配置と多重矢印") do
  a = user("A", :lt)
  b = business("B", :cm)
  c = company("C", :rt)
  d = smartphone("D", :lb)

  # Group 1: A → B (2 arrows)
  arrow(:object, "Data 1", a, b)
  arrow(:information, "Data 2", a, b)

  # Group 2: B ↔ C (bidirectional)
  arrow(:money, "Payment B→C", b, c)
  arrow(:money, "Commission C→B", c, b)

  # Group 3: D to A (diagonal reverse)
  arrow(:other, "Feedback", d, a)
end

File.write("example/03_edge_case.svg", svg)
puts "Generated example/03_edge_case.svg"
