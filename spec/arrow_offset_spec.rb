require_relative "../lib/bizgram"

describe "Arrow offset feature" do
  describe "Multiple arrows between same pair" do
    subject do
      Bizgram.draw("Test") do
        user1 = user("User A", :lt)
        user2 = user("User B", :rt)
        arrow(:object, "Arrow 1", user1, user2)
        arrow(:money, "Arrow 2", user1, user2)
        arrow(:information, "Arrow 3", user1, user2)
      end
    end

    it "should generate 3 arrows" do
      arrow_count = subject.scan(/<g id="arrow_\d+">/m).size
      expect(arrow_count).to eq(3)
    end

    it "should have different text label Y positions (offset applied)" do
      # For horizontal routing (LT→RT), offset is applied to Y-axis (vertical separation)
      # Extract text elements that are inside arrow groups
      text_y_values = []
      subject.scan(/<g id="arrow_(\d+)">(.*?)<\/g>/m) do |arrow_id, content|
        if content =~ /<text[^>]*y="([\d.]+)"/
          text_y_values << $1.to_f
        end
      end

      expect(text_y_values.size).to eq(3), "Should have 3 text labels"
      unique_y_values = text_y_values.uniq
      expect(unique_y_values.size).to eq(3), "All text labels should have different Y positions"
    end

    it "text labels should be offset by approximately 10px apart" do
      # For horizontal routing (LT→RT), offset is applied to Y-axis (vertical separation)
      text_y_values = []
      subject.scan(/<g id="arrow_(\d+)">(.*?)<\/g>/m) do |arrow_id, content|
        if content =~ /<text[^>]*y="([\d.]+)"/
          text_y_values << $1.to_f
        end
      end

      # Sort and check differences
      sorted = text_y_values.sort
      diff_1_2 = (sorted[1] - sorted[0]).abs
      diff_2_3 = (sorted[2] - sorted[1]).abs

      expect(diff_1_2).to be_within(0.1).of(10.0), "First two labels should be ~10px apart"
      expect(diff_2_3).to be_within(0.1).of(10.0), "Last two labels should be ~10px apart"
    end
  end
end
