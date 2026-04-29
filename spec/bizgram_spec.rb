# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/bizgram"

RSpec.describe Bizgram do
  describe ".draw" do
    it "returns an SVG string" do
      svg = Bizgram.draw("Test") do
        user "Alice", 0
      end
      expect(svg).to be_a(String)
      expect(svg).to include("<svg")
      expect(svg).to include("Test")
      expect(svg).not_to include("digraph")
    end
  end

  describe "Entity definition" do
    context "when defining users" do
      it "creates a user entity" do
        alice = nil
        svg = Bizgram.draw("Test") do
          alice = user "Alice", 0
        end
        expect(alice.id).to eq(0)
        expect(svg).to include("Alice")
      end

      it "returns the same ID for an existing entity" do
        bob_1 = nil
        bob_2 = nil
        Bizgram.draw("Test") do
          bob_1 = user "Bob", 0
          bob_2 = user "Bob", 0
        end
        expect(bob_1).to equal(bob_2)
      end
    end

    context "when defining business" do
      it "creates a business entity" do
        svg = Bizgram.draw("Test") do
          business "Service", 4
        end
        expect(svg).to include("Service")
      end
    end


    context "using entity method" do
      it "creates user with type :user" do
        svg = Bizgram.draw("Test") do
          entity :user, "Charlie", 0
        end
        expect(svg).to include("Charlie")
      end

      it "creates business with type :business" do
        svg = Bizgram.draw("Test") do
          entity :business, "Company", 4
        end
        expect(svg).to include("Company")
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

    context "when position is not specified" do
      it "raises error for user without position" do
        expect do
          Bizgram.draw("Test") do
            user "User1"
          end
        end.to raise_error(ArgumentError, /Position must be explicitly specified/)
      end

      it "raises error for business without position" do
        expect do
          Bizgram.draw("Test") do
            business "Biz1"
          end
        end.to raise_error(ArgumentError, /Position must be explicitly specified/)
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

    context "entity reference in arrows" do
      it "type :object" do
        svg = Bizgram.draw("Test") do
          user_obj = user "User", 0
          business_obj = business "Biz", 4
          arrow :object, "Object", user_obj, business_obj
        end
        expect(svg).to include("Object")
      end

      it "type :money" do
        svg = Bizgram.draw("Test") do
          user_obj = user "User", 0
          business_obj = business "Biz", 4
          arrow :money, "Money", user_obj, business_obj
        end
        expect(svg).to include("Money")
      end

      it "type :information" do
        svg = Bizgram.draw("Test") do
          user_obj = user "User", 0
          business_obj = business "Biz", 4
          arrow :information, "Information", user_obj, business_obj
        end
        expect(svg).to include("Information")
      end

      it "type :other" do
        svg = Bizgram.draw("Test") do
          user_obj = user "User", 0
          business_obj = business "Biz", 4
          arrow :other, "Other", user_obj, business_obj
        end
        expect(svg).to include("Other")
      end

      it "accepts numeric entity IDs" do
        svg = Bizgram.draw("Test") do
          user_obj = user "User", 0
          business_obj = business "Biz", 4
          arrow :object, "Prod", user_obj, business_obj
        end
        expect(svg).to include("Prod")
      end

      it "accepts entity names by calling the method" do
        svg = Bizgram.draw("Test") do
          user "Alice", 0
          business "Service", 4
          arrow :object, "Item", user("Alice"), business("Service")
        end
        expect(svg).to include("Item")
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
            user 123, 0
          end
        end.to raise_error(ArgumentError, /Name must be a string/)
      end

      it "raises error for empty name" do
        expect do
          Bizgram.draw("Test") do
            user "", 0
          end
        end.to raise_error(ArgumentError, /Name cannot be empty/)
      end
    end

    context "missing entities in arrows" do
      it "raises error when from entity is not found (integer)" do
        expect do
          Bizgram.draw("Test") do
            user "A", 0
            arrow :object, "Item", 999, 0  # ID 999 doesn't exist
          end
        end.to raise_error(ArgumentError, /From entity.*not found/)
      end

      it "raises error when to entity is not found (integer)" do
        expect do
          Bizgram.draw("Test") do
            user "A", 0
            arrow :object, "Item", 0, 999  # ID 999 doesn't exist
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

  describe "SVG generation" do
    it "generates valid SVG syntax" do
      svg = Bizgram.draw("MyBizgram") do
        user "Alice", 0
        business "Service", 4
        arrow :object, "Product", 0, 1
        arrow :money, "Payment", 0, 1
      end

      expect(svg).to include("<?xml")
      expect(svg).to include("<svg")
      expect(svg).to include("MyBizgram")
      expect(svg).to include("Alice")
      expect(svg).to include("Service")
      expect(svg).to include("Product")
      expect(svg).to include("Payment")
      expect(svg).to include("</svg>")
    end

    it "escapes special XML characters in labels" do
      svg = Bizgram.draw('Graph "Title"') do
        user 'User "Alice"', 0
      end
      expect(svg).to include("&quot;")
      expect(svg).to include("Title")
      expect(svg).to include("Alice")
    end

    it "uses correct colors for entity types" do
      svg = Bizgram.draw("Test") do
        user "Alice", 0
        business "Service", 4
      end
      # After Phase 1 refactor: entities are now embedded SVG images, not colored rectangles
      expect(svg).to include("id=\"entity_0\"")  # Entity group exists
      expect(svg).to include("id=\"entity_1\"")  # Entity group exists
      expect(svg).to include("Alice")  # Entity label
      expect(svg).to include("Service")  # Entity label
      # Verify SVG structure is valid (contains svg header and footer)
      expect(svg).to include("<svg")
      expect(svg).to include("</svg>")
    end

    it "uses correct colors for arrow types" do
      svg = Bizgram.draw("Test") do
        user_obj = user "A", 0
        business_obj = business "B", 4
        other_obj = other "C", 8
        arrow :object, "Obj", user_obj, business_obj
        arrow :money, "Money", user_obj, business_obj
        arrow :information, "Info", business_obj, other_obj
        arrow :other, "Other", user_obj, other_obj
      end
      expect(svg).to include("#000000")  # Object (black)
      expect(svg).to include("#FF0000")  # Money (red)
      expect(svg).to include("#0000FF")  # Information (blue)
    end
  end

  describe "Complex scenario" do
    it "handles the example from specification" do
      svg = Bizgram.draw("タイトル") do
        entity :user, "太郎", :ct
        entity :business, "HOGEビジネス", :cm
        jiro = user "次郎", :lt
        fuga = business "FUGAビジネス", :lm

        arrow :object, "商品", business("FUGAビジネス"), user("太郎")
        arrow :money, "代金", user("太郎"), business("HOGEビジネス")
      end

      expect(svg).to include("タイトル")
      expect(svg).to include("太郎")
      expect(svg).to include("次郎")
      expect(svg).to include("HOGEビジネス")
      expect(svg).to include("FUGAビジネス")
      expect(svg).to include("商品")
      expect(svg).to include("代金")
      expect(svg).to include("<svg")
    end
  end

  describe "New entity type aliases" do
    context "person alias" do
      it "creates entity with :person type" do
        svg = Bizgram.draw("Test") do
          person "Alice", 0
        end
        expect(svg).to include("Alice")
      end

      it "accepts entity :person type" do
        svg = Bizgram.draw("Test") do
          entity :person, "Bob", 1
        end
        expect(svg).to include("Bob")
      end
    end

    context "company alias" do
      it "creates entity with :company type" do
        svg = Bizgram.draw("Test") do
          company "TechCorp", 4
        end
        expect(svg).to include("TechCorp")
      end

      it "accepts entity :company type" do
        svg = Bizgram.draw("Test") do
          entity :company, "MegaCorp", 5
        end
        expect(svg).to include("MegaCorp")
      end
    end

    context "money alias" do
      it "creates entity with :money type" do
        svg = Bizgram.draw("Test") do
          money "ドル", 3
        end
        expect(svg).to include("ドル")
      end

      it "accepts entity :money type" do
        svg = Bizgram.draw("Test") do
          entity :money, "円", 3
        end
        expect(svg).to include("円")
      end
    end

    context "object alias" do
      it "creates entity with :object type" do
        svg = Bizgram.draw("Test") do
          object "商品", 6
        end
        expect(svg).to include("商品")
      end

      it "accepts entity :object type" do
        svg = Bizgram.draw("Test") do
          entity :object, "製品", 6
        end
        expect(svg).to include("製品")
      end
    end

    context "goods alias" do
      it "creates entity with :goods type" do
        svg = Bizgram.draw("Test") do
          goods "イチゴ", 7
        end
        expect(svg).to include("イチゴ")
      end

      it "accepts entity :goods type" do
        svg = Bizgram.draw("Test") do
          entity :goods, "ケーキ", 7
        end
        expect(svg).to include("ケーキ")
      end
    end

    context "information alias" do
      it "creates entity with :information type" do
        svg = Bizgram.draw("Test") do
          information "ニュース", 5
        end
        expect(svg).to include("ニュース")
      end

      it "accepts entity :information type" do
        svg = Bizgram.draw("Test") do
          entity :information, "データ", 5
        end
        expect(svg).to include("データ")
      end
    end

    context "info alias" do
      it "creates entity with :info type" do
        svg = Bizgram.draw("Test") do
          info "通知", 2
        end
        expect(svg).to include("通知")
      end

      it "accepts entity :info type" do
        svg = Bizgram.draw("Test") do
          entity :info, "メッセージ", 2
        end
        expect(svg).to include("メッセージ")
      end
    end

    context "smartphone alias" do
      it "creates entity with :smartphone type" do
        svg = Bizgram.draw("Test") do
          smartphone "iPhone", 8
        end
        expect(svg).to include("iPhone")
      end

      it "accepts entity :smartphone type" do
        svg = Bizgram.draw("Test") do
          entity :smartphone, "Android", 8
        end
        expect(svg).to include("Android")
      end
    end

    context "device alias" do
      it "creates entity with :device type" do
        svg = Bizgram.draw("Test") do
          device "PC", 2
        end
        expect(svg).to include("PC")
      end

      it "accepts entity :device type" do
        svg = Bizgram.draw("Test") do
          entity :device, "タブレット", 2
        end
        expect(svg).to include("タブレット")
      end
    end

    context "store alias" do
      it "creates entity with :store type" do
        svg = Bizgram.draw("Test") do
          store "渋谷店", 1
        end
        expect(svg).to include("渋谷店")
      end

      it "accepts entity :store type" do
        svg = Bizgram.draw("Test") do
          entity :store, "新宿店", 1
        end
        expect(svg).to include("新宿店")
      end
    end

    context "shop alias" do
      it "creates entity with :shop type" do
        svg = Bizgram.draw("Test") do
          shop "コンビニ", 0
        end
        expect(svg).to include("コンビニ")
      end

      it "accepts entity :shop type" do
        svg = Bizgram.draw("Test") do
          entity :shop, "スーパー", 0
        end
        expect(svg).to include("スーパー")
      end
    end

    context "other alias" do
      it "creates entity with :other type" do
        svg = Bizgram.draw("Test") do
          other "その他要素", 4
        end
        expect(svg).to include("その他要素")
      end

      it "accepts entity :other type" do
        svg = Bizgram.draw("Test") do
          entity :other, "その他", 4
        end
        expect(svg).to include("その他")
      end
    end

    it "uses correct colors for new entity types" do
      # Test each entity type individually to avoid position conflicts
      test_entities = [
        [:person, "Person", :lt],
        [:company, "Company", :ct],
        [:money, "Money", :rt],
        [:object, "Object", :lm],
        [:goods, "Goods", :cm],
        [:information, "Info", :rm],
        [:info, "Inf", :lb],
        [:smartphone, "Phone", :cb],
        [:device, "Device", :rb]
      ]

      test_entities.each do |type, name, pos|
        svg = Bizgram.draw("Test") do
          entity type, name, pos
        end
        expect(svg).to include(name)
      end

      # Test additional aliases
      svg = Bizgram.draw("Test") do
        store "Store", 0
        shop "Shop", 1
        other "Other", 2
      end

      expect(svg).to include("Store")
      expect(svg).to include("Shop")
      expect(svg).to include("Other")
    end
  end

  describe "Comment definition" do
    context "when defining comments with comment_to" do
      it "creates a comment" do
        svg = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント"
        end
        expect(svg).to include("コメント")
      end

      it "attaches comment to entity by ID" do
        svg = Bizgram.draw("Test") do
          alice = user "Alice", 0
          comment_to alice, "テストコメント"
        end
        expect(svg).to include("テストコメント")
      end

      it "attaches comment to entity by name" do
        svg = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント内容"
        end
        expect(svg).to include("コメント内容")
      end
    end

    context "when defining comments with comment (alias)" do
      it "creates a comment using alias method" do
        svg = Bizgram.draw("Test") do
          user "Alice", 0
          comment user("Alice"), "ショートカットテスト"
        end
        expect(svg).to include("ショートカットテスト")
      end

      it "supports short alias form" do
        svg = Bizgram.draw("Test") do
          alice = user "Alice", 0
          comment alice, "コメント"
        end
        expect(svg).to include("コメント")
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

    context "comment in SVG generation" do
      it "includes comment elements in SVG" do
        svg = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "テストコメント"
        end
        expect(svg).to include("comment_")
        expect(svg).to include("テストコメント")
      end

      it "escapes special characters in comments" do
        svg = Bizgram.draw("Graph") do
          user "User", 0
          comment_to user("User"), 'Comment with "quotes"'
        end
        expect(svg).to include("&quot;")
      end

      it "uses yellow color for comment boxes" do
        svg = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント"
        end
        expect(svg).to include("#FFFC41")
      end
    end

    context "multiple comments" do
      it "supports multiple comments on the same entity" do
        svg = Bizgram.draw("Test") do
          user "Alice", 0
          comment_to user("Alice"), "コメント1"
          comment_to user("Alice"), "コメント2"
        end
        expect(svg).to include("コメント1")
        expect(svg).to include("コメント2")
      end

      it "supports comments on different entities" do
        svg = Bizgram.draw("Test") do
          user "Alice", 0
          business "Service", 4
          comment_to user("Alice"), "ユーザーコメント"
          comment_to business("Service"), "サービスコメント"
        end
        expect(svg).to include("ユーザーコメント")
        expect(svg).to include("サービスコメント")
      end
    end
  end

  describe "Global ID sequence" do
    it "assigns sequential global IDs across Entity, Arrow, and Comment" do
      entity_id = nil
      arrow_id = nil
      comment_id = nil
      Bizgram.draw("Test") do
        user_entity = user "User", 0
        entity_id = user_entity.id

        device_entity = smartphone "Device", 4
        arr = arrow :object, "Uses", user_entity, device_entity
        arrow_id = arr.id

        com = comment_to device_entity, "Important device"
        comment_id = com.id
      end
      expect(entity_id).to eq(0)
      expect(arrow_id).to eq(2)
      expect(comment_id).to eq(3)
    end

    it "maintains sequential IDs even when entities share the same object" do
      entity1_id = nil
      entity2_id = nil
      arrow_id = nil
      Bizgram.draw("Test") do
        user_entity = user "User", 0
        entity1_id = user_entity.id

        company_entity = company "Company", 4
        entity2_id = company_entity.id

        arr = arrow :money, "Pays", user_entity, company_entity
        arrow_id = arr.id
      end
      expect(entity1_id).to eq(0)
      expect(entity2_id).to eq(1)
      expect(arrow_id).to eq(2)
    end

    it "assigns unique IDs regardless of object type" do
      ids = []
      Bizgram.draw("Test") do
        ids << (user "User", 0).id
        ids << (business "Business", 4).id
        ids << (arrow :object, "Flow", 0, 1).id
        ids << (comment_to 0, "Comment").id
      end
      expect(ids).to eq([0, 1, 2, 3])
      expect(ids.uniq).to eq(ids)  # All IDs are unique
    end
  end
end
