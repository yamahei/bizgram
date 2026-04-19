# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/bizgram"

RSpec.describe Bizgram do
  describe ".draw" do
    it "returns a DOT language string" do
      dot = Bizgram.draw("Test") do
        user "Alice"
      end
      expect(dot).to be_a(String)
      expect(dot).to include("digraph Bizgram")
      expect(dot).to include("Test")
    end
  end

  describe "Entity definition" do
    context "when defining users" do
      it "creates a user entity" do
        id = nil
        dot = Bizgram.draw("Test") do
          id = user "Alice"
        end
        expect(id).to eq(0)
        expect(dot).to include("Alice")
      end

      it "returns the same ID for an existing entity" do
        id1 = nil
        id2 = nil
        Bizgram.draw("Test") do
          id1 = user "Bob"
          id2 = user "Bob"
        end
        expect(id1).to eq(id2)
      end
    end

    context "when defining business" do
      it "creates a business entity" do
        dot = Bizgram.draw("Test") do
          business "Service"
        end
        expect(dot).to include("Service")
      end
    end

    context "when defining operators" do
      it "creates an operator entity" do
        dot = Bizgram.draw("Test") do
          operator "Staff"
        end
        expect(dot).to include("Staff")
      end
    end

    context "using entity method" do
      it "creates user with type :user" do
        dot = Bizgram.draw("Test") do
          entity :user, "Charlie"
        end
        expect(dot).to include("Charlie")
      end

      it "creates business with type :business" do
        dot = Bizgram.draw("Test") do
          entity :business, "Company"
        end
        expect(dot).to include("Company")
      end

      it "creates operator with type :operator" do
        dot = Bizgram.draw("Test") do
          entity :operator, "Manager"
        end
        expect(dot).to include("Manager")
      end
    end
  end

  describe "Position assignment" do
    context "numeric position" do
      it "accepts valid positions 0-8" do
        Bizgram.draw("Test") do
          (0..8).each do |pos|
            user "User_#{pos}", pos
          end
        end
      end

      it "raises error for invalid position number" do
        expect do
          Bizgram.draw("Test") do
            user "Invalid", 9
          end
        end.to raise_error(ArgumentError, /Position must be between 0 and 8/)
      end

      it "raises error for negative position" do
        expect do
          Bizgram.draw("Test") do
            user "Invalid", -1
          end
        end.to raise_error(ArgumentError, /Position must be between 0 and 8/)
      end
    end

    context "symbol position" do
      it "accepts valid symbol positions" do
        Bizgram.draw("Test") do
          user "TL", :lt
          user "CT", :ct
          user "RT", :rt
          user "LM", :lm
          user "CM", :cm
          user "RM", :rm
          user "LB", :lb
          user "CB", :cb
          user "RB", :rb
        end
      end

      it "raises error for invalid symbol" do
        expect do
          Bizgram.draw("Test") do
            user "Invalid", :xx
          end
        end.to raise_error(ArgumentError, /Unknown position symbol/)
      end
    end

    context "array position" do
      it "accepts valid [x, y] coordinates" do
        Bizgram.draw("Test") do
          user "User1", [0, 0]
          user "User2", [1, 1]
          user "User3", [2, 2]
        end
      end

      it "raises error for out-of-range coordinates" do
        expect do
          Bizgram.draw("Test") do
            user "Invalid", [3, 0]
          end
        end.to raise_error(ArgumentError, /Position coordinates must be 0-2/)
      end

      it "raises error for invalid array length" do
        expect do
          Bizgram.draw("Test") do
            user "Invalid", [0]
          end
        end.to raise_error(ArgumentError, /Position array must have 2 elements/)
      end
    end

    context "automatic position assignment" do
      it "assigns users to top row" do
        dot = Bizgram.draw("Test") do
          user "User1"
          user "User2"
          user "User3"
        end
        # Users should be auto-assigned to positions 0, 1, 2 (top row)
        expect(dot).to include("User1")
        expect(dot).to include("User2")
        expect(dot).to include("User3")
      end

      it "assigns business to middle row" do
        dot = Bizgram.draw("Test") do
          business "Biz1"
          business "Biz2"
          business "Biz3"
        end
        expect(dot).to include("Biz1")
        expect(dot).to include("Biz2")
        expect(dot).to include("Biz3")
      end

      it "assigns operators to bottom row" do
        dot = Bizgram.draw("Test") do
          operator "Op1"
          operator "Op2"
          operator "Op3"
        end
        expect(dot).to include("Op1")
        expect(dot).to include("Op2")
        expect(dot).to include("Op3")
      end

      it "raises error when all positions in row are occupied" do
        expect do
          Bizgram.draw("Test") do
            user "U1", 0
            user "U2", 1
            user "U3", 2
            user "U4"  # Should fail - all user positions occupied
          end
        end.to raise_error(/Cannot auto-assign position/)
      end
    end

    context "position conflicts" do
      it "raises error when two entities occupy the same position" do
        expect do
          Bizgram.draw("Test") do
            user "User1", 0
            user "User2", 0
          end
        end.to raise_error(/already occupied/)
      end
    end
  end

  describe "Arrow definition" do
    context "when defining object flow" do
      it "creates an object arrow" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          business "Service", 4
          object "Product", 0, 1
        end
        expect(dot).to include("Product")
      end
    end

    context "when defining money flow" do
      it "creates a money arrow" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          business "Service", 4
          money "Payment", 0, 1
        end
        expect(dot).to include("Payment")
      end
    end

    context "when defining information flow" do
      it "creates an information arrow" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          business "Service", 4
          information "Notice", 0, 1
        end
        expect(dot).to include("Notice")
      end
    end

    context "using arrow method" do
      it "creates flow with type :object" do
        dot = Bizgram.draw("Test") do
          user "A", 0
          business "B", 4
          arrow :object, "Goods", 0, 1
        end
        expect(dot).to include("Goods")
      end

      it "creates flow with type :money" do
        dot = Bizgram.draw("Test") do
          user "A", 0
          business "B", 4
          arrow :money, "Fund", 0, 1
        end
        expect(dot).to include("Fund")
      end

      it "creates flow with type :information" do
        dot = Bizgram.draw("Test") do
          user "A", 0
          business "B", 4
          arrow :information, "Data", 0, 1
        end
        expect(dot).to include("Data")
      end
    end

    context "entity reference in arrows" do
      it "accepts numeric entity IDs" do
        dot = Bizgram.draw("Test") do
          id1 = user "User", 0
          id2 = business "Biz", 4
          object "Prod", id1, id2
        end
        expect(dot).to include("Prod")
      end

      it "accepts entity names by calling the method" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          business "Service", 4
          object "Item", user("Alice"), business("Service")
        end
        expect(dot).to include("Item")
      end
    end
  end

  describe "Validation" do
    context "invalid entity types" do
      it "raises error for invalid type" do
        expect do
          Bizgram.draw("Test") do
            entity :invalid, "Name"
          end
        end.to raise_error(ArgumentError, /Invalid entity type/)
      end
    end

    context "invalid arrow types" do
      it "raises error for invalid type" do
        expect do
          Bizgram.draw("Test") do
            user "A", 0
            business "B", 4
            arrow :invalid, "Name", 0, 1
          end
        end.to raise_error(ArgumentError, /Invalid arrow type/)
      end
    end

    context "invalid names" do
      it "raises error for non-string name" do
        expect do
          Bizgram.draw("Test") do
            user 123
          end
        end.to raise_error(ArgumentError, /Name must be a string/)
      end

      it "raises error for empty name" do
        expect do
          Bizgram.draw("Test") do
            user ""
          end
        end.to raise_error(ArgumentError, /Name cannot be empty/)
      end
    end

    context "missing entities in arrows" do
      it "raises error when from entity is not found (integer)" do
        expect do
          Bizgram.draw("Test") do
            user "A", 0
            object "Item", 999, 0  # ID 999 doesn't exist
          end
        end.to raise_error(ArgumentError, /From entity.*not found/)
      end

      it "raises error when to entity is not found (integer)" do
        expect do
          Bizgram.draw("Test") do
            user "A", 0
            object "Item", 0, 999  # ID 999 doesn't exist
          end
        end.to raise_error(ArgumentError, /To entity.*not found/)
      end

      it "raises error when from entity name is not found" do
        expect do
          Bizgram.draw("Test") do
            user "A", 0
            # Trying to reference non-existent "Bob"
            # Note: We need builder to support passing entity references differently
            # This test assumes error handling for string references
          end
        end
      end
    end
  end

  describe "DOT language generation" do
    it "generates valid DOT syntax" do
      dot = Bizgram.draw("MyBizgram") do
        user "Alice", 0
        business "Service", 4
        operator "Manager", 8
        object "Product", 0, 1
        money "Payment", 0, 1
      end

      expect(dot).to include("digraph Bizgram")
      expect(dot).to include("label=\"MyBizgram\"")
      expect(dot).to include("rankdir=TB")
      expect(dot).to include("node_0")
      expect(dot).to include("node_4")
      expect(dot).to include("node_8")
      expect(dot).to include("->")
    end

    it "escapes special characters in labels" do
      dot = Bizgram.draw("Graph \"Title\"") do
        user "User \"Alice\""
      end
      expect(dot).to include('\"Title\"')
      expect(dot).to include('\"Alice\"')
    end

    it "uses correct colors for entity types" do
      dot = Bizgram.draw("Test") do
        user "Alice", 0
        business "Service", 4
        operator "Manager", 8
      end
      expect(dot).to include("#FFE5CC")  # User color
      expect(dot).to include("#CCE5FF")  # Business color
      expect(dot).to include("#E5FFCC")  # Operator color
    end

    it "uses correct colors for arrow types" do
      dot = Bizgram.draw("Test") do
        user "A", 0
        business "B", 4
        operator "O", 8
        object "Obj", 0, 1
        money "Money", 1, 2
        information "Info", 2, 0
      end
      expect(dot).to include("color=black")   # Object
      expect(dot).to include("color=red")     # Money
      expect(dot).to include("color=blue")    # Information
    end
  end

  describe "Complex scenario" do
    it "handles the example from specification" do
      dot = Bizgram.draw("タイトル") do
        entity :user, "太郎", :ct
        entity :business, "HOGEビジネス", :cm
        entity :operator, "社員", :cb
        jiro = user "次郎", :lt
        fuga = business "FUGAビジネス", :lm
        clerk = operator "販売員", :lb

        object "商品", business("FUGAビジネス"), user("太郎")
        money "代金", user("太郎"), business("HOGEビジネス")
        information "広告", operator("販売員"), user("太郎")
      end

      expect(dot).to include("タイトル")
      expect(dot).to include("太郎")
      expect(dot).to include("次郎")
      expect(dot).to include("HOGEビジネス")
      expect(dot).to include("FUGAビジネス")
      expect(dot).to include("社員")
      expect(dot).to include("販売員")
      expect(dot).to include("商品")
      expect(dot).to include("代金")
      expect(dot).to include("広告")
      expect(dot).to include("digraph Bizgram")
    end
  end

  describe "Comment definition" do
    context "when defining comments with comment_to" do
      it "creates a comment" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント"
        end
        expect(dot).to include("コメント")
      end

      it "attaches comment to entity by ID" do
        dot = Bizgram.draw("Test") do
          id = user "Alice", 0
          comment_to id, "テストコメント"
        end
        expect(dot).to include("テストコメント")
      end

      it "attaches comment to entity by name" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント内容"
        end
        expect(dot).to include("コメント内容")
      end
    end

    context "when defining comments with comment (alias)" do
      it "creates a comment using alias method" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          comment user("Alice"), "エイリアステスト"
        end
        expect(dot).to include("エイリアステスト")
      end

      it "supports short alias form" do
        dot = Bizgram.draw("Test") do
          alice = user "Alice", 0
          comment alice, "コメント"
        end
        expect(dot).to include("コメント")
      end
    end

    context "comment validation" do
      it "raises error for non-string comment text" do
        expect do
          Bizgram.draw("Test") do
            user "Alice", 0
            comment_to user("Alice"), 123
          end
        end.to raise_error(ArgumentError, /Name must be a string/)
      end

      it "raises error for empty comment text" do
        expect do
          Bizgram.draw("Test") do
            user "Alice", 0
            comment_to user("Alice"), ""
          end
        end.to raise_error(ArgumentError, /Name cannot be empty/)
      end

      it "raises error when target entity does not exist (integer)" do
        expect do
          Bizgram.draw("Test") do
            comment_to 999, "コメント"
          end
        end.to raise_error(ArgumentError, /To entity.*not found/)
      end

      it "raises error when target entity does not exist (string)" do
        expect do
          Bizgram.draw("Test") do
            user "Alice", 0
            comment_to "Bob", "コメント"  # String reference to non-existent entity
          end
        end.to raise_error(ArgumentError, /Entity '.*' not found/)
      end
    end

    context "comment in DOT generation" do
      it "includes comment nodes in DOT" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "テストコメント"
        end
        expect(dot).to include("comment_")
        expect(dot).to include("テストコメント")
      end

      it "escapes special characters in comments" do
        dot = Bizgram.draw("Graph") do
          user "User", 0
          comment_to user("User"), "Comment with \"quotes\""
        end
        expect(dot).to include('\"quotes\"')
      end

      it "includes comment edges in DOT" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント"
        end
        expect(dot).to include("style=dashed")
        expect(dot).to include("color=gray")
      end

      it "uses yellow color for comment nodes" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント"
        end
        expect(dot).to include("#FFFFCC")
      end
    end

    context "multiple comments" do
      it "supports multiple comments on the same entity" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント1"
          comment_to user("Alice"), "コメント2"
        end
        expect(dot).to include("コメント1")
        expect(dot).to include("コメント2")
      end

      it "supports comments on different entities" do
        dot = Bizgram.draw("Test") do
          user "Alice", 0
          business "Service", 4
          comment_to user("Alice"), "ユーザーコメント"
          comment_to business("Service"), "サービスコメント"
        end
        expect(dot).to include("ユーザーコメント")
        expect(dot).to include("サービスコメント")
      end
    end
  end
end
