# frozen_string_literal: true

module Bizgram
  class Entity
    attr_reader :id, :name, :type, :position

    def initialize(id, name, type, position)
      @id = id
      @name = name
      @type = type
      @position = position
    end
  end

  class Arrow
    attr_reader :id, :name, :type, :from, :to

    def initialize(id, name, type, from, to)
      @id = id
      @name = name
      @type = type
      @from = from
      @to = to
    end
  end

  class Comment
    attr_reader :id, :to, :text

    def initialize(id, to, text)
      @id = id
      @to = to
      @text = text
    end
  end

  class PositionResolver
    SYMBOL_TO_POSITION = {
      lt: 0, ct: 1, rt: 2,
      lm: 3, cm: 4, rm: 5,
      lb: 6, cb: 7, rb: 8
    }.freeze

    POSITION_TO_COORDS = {
      0 => [0, 0], 1 => [1, 0], 2 => [2, 0],
      3 => [0, 1], 4 => [1, 1], 5 => [2, 1],
      6 => [0, 2], 7 => [1, 2], 8 => [2, 2]
    }.freeze

    def self.resolve(position, type, occupied_positions)
      case position
      when Integer
        validate_position_number(position)
        position
      when Symbol
        validate_and_resolve_symbol(position)
      when Array
        resolve_from_array(position)
      when nil
        raise ArgumentError, "Position must be explicitly specified (Integer, Symbol, or Array)"
      else
        raise ArgumentError, "Invalid position: #{position.inspect}"
      end
    end

    private

    def self.validate_position_number(pos)
      raise ArgumentError, "Position must be between 0 and 8, got #{pos}" unless (0..8).include?(pos)
    end

    def self.validate_and_resolve_symbol(sym)
      raise ArgumentError, "Unknown position symbol: #{sym.inspect}" unless SYMBOL_TO_POSITION.key?(sym)
      SYMBOL_TO_POSITION[sym]
    end

    def self.resolve_from_array(pos)
      raise ArgumentError, "Position array must have 2 elements [x, y]" unless pos.is_a?(Array) && pos.length == 2
      x, y = pos
      raise ArgumentError, "Position coordinates must be 0-2, got [#{x}, #{y}]" unless (0..2).include?(x) && (0..2).include?(y)
      y * 3 + x
    end
  end

  class Builder
    def initialize
      @entities = {}        # {name => Entity}
      @entities_by_id = {}  # {id => Entity}
      @arrows = {}          # {name => Arrow}
      @arrows_by_id = {}    # {id => Arrow}
      @comments = {}        # {id => Comment}
      @next_entity_id = 0
      @next_arrow_id = 0
      @next_comment_id = 0
      @occupied_positions = Set.new
    end

    def entity(type, name, position = nil)
      validate_entity_type(type)
      validate_name(name)

      return @entities[name].id if @entities.key?(name)

      pos = PositionResolver.resolve(position, type, @occupied_positions)
      raise "Position #{pos} is already occupied" if @occupied_positions.include?(pos)

      id = @next_entity_id
      @next_entity_id += 1

      ent = Entity.new(id, name, type, pos)
      @entities[name] = ent
      @entities_by_id[id] = ent
      @occupied_positions.add(pos)

      id
    end

    def user(name, position = nil)
      entity(:user, name, position)
    end

    def business(name, position = nil)
      entity(:business, name, position)
    end

    def operator(name, position = nil)
      entity(:operator, name, position)
    end

    def arrow(type, name, from, to)
      validate_arrow_type(type)
      validate_name(name)

      from_id = resolve_entity_reference(from)
      to_id = resolve_entity_reference(to)

      raise ArgumentError, "From entity (id: #{from_id}) not found" unless @entities_by_id.key?(from_id)
      raise ArgumentError, "To entity (id: #{to_id}) not found" unless @entities_by_id.key?(to_id)

      id = @next_arrow_id
      @next_arrow_id += 1

      arr = Arrow.new(id, name, type, from_id, to_id)
      @arrows[name] = arr
      @arrows_by_id[id] = arr

      id
    end

    def comment_to(to, text)
      validate_name(text)

      to_id = resolve_entity_reference(to)
      raise ArgumentError, "To entity (id: #{to_id}) not found" unless @entities_by_id.key?(to_id)

      id = @next_comment_id
      @next_comment_id += 1

      com = Comment.new(id, to_id, text)
      @comments[id] = com

      id
    end

    def comment(to, text)
      comment_to(to, text)
    end

    def to_dot(title)
      DotGenerator.new(@entities_by_id, @arrows_by_id, @comments).generate(title)
    end

    private

    def validate_entity_type(type)
      raise ArgumentError, "Invalid entity type: #{type}" unless [:user, :business, :operator].include?(type)
    end

    def validate_arrow_type(type)
      raise ArgumentError, "Invalid arrow type: #{type}" unless [:object, :money, :information].include?(type)
    end

    def validate_name(name)
      raise ArgumentError, "Name must be a string" unless name.is_a?(String)
      raise ArgumentError, "Name cannot be empty" if name.empty?
    end

    def resolve_entity_reference(ref)
      case ref
      when Integer
        ref
      when String
        raise ArgumentError, "Entity '#{ref}' not found" unless @entities.key?(ref)
        @entities[ref].id
      else
        raise ArgumentError, "Entity reference must be Integer or String, got #{ref.class}"
      end
    end
  end

  class DotGenerator
    ENTITY_COLORS = {
      user: "#FFE5CC",
      business: "#CCE5FF",
      operator: "#E5FFCC"
    }.freeze

    ARROW_STYLES = {
      object: { color: "black", label: "モノ" },
      money: { color: "red", label: "カネ" },
      information: { color: "blue", label: "情報" }
    }.freeze

    def initialize(entities_by_id, arrows_by_id, comments)
      @entities = entities_by_id
      @arrows = arrows_by_id
      @comments = comments
      # ノードID用に位置をキーとするエンティティマップを作成
      @entities_by_position = {}
      @entities.each do |_id, entity|
        @entities_by_position[entity.position] = entity
      end
    end

    def generate(title)
      lines = ["digraph Bizgram {"]
      lines << "  graph [label=\"#{escape_dot(title)}\", labelloc=top];"
      lines << "  rankdir=TB;"  # TB: Top to Bottom（上から下）
      lines << ""

      # ノードの定義（位置をベースにした node_pos で生成）
      @entities_by_position.each do |pos, entity|
        color = ENTITY_COLORS[entity.type]
        lines << "  node_#{pos} [label=\"#{escape_dot(entity.name)}\", shape=box, style=filled, fillcolor=\"#{color}\"];"
      end

      # コメントノードの定義
      @comments.each do |_id, comment|
        comment_node_id = "comment_#{comment.id}"
        lines << "  #{comment_node_id} [label=\"#{escape_dot(comment.text)}\", shape=box, style=\"filled,rounded\", fillcolor=\"#FFFFCC\"];"
      end

      lines << ""

      # エッジの定義
      @arrows.each do |_id, arrow|
        style = ARROW_STYLES[arrow.type]
        from_entity = @entities[arrow.from]
        to_entity = @entities[arrow.to]
        from_pos = from_entity.position
        to_pos = to_entity.position
        lines << "  node_#{from_pos} -> node_#{to_pos} [label=\"#{escape_dot(arrow.name)}\", color=#{style[:color]}];"
      end

      # コメント矢印の定義
      @comments.each do |_id, comment|
        target_entity = @entities[comment.to]
        target_pos = target_entity.position
        comment_node_id = "comment_#{comment.id}"
        lines << "  #{comment_node_id} -> node_#{target_pos} [style=dashed, color=gray];"
      end

      lines << "}"
      lines.join("\n")
    end

    private

    def escape_dot(str)
      str.gsub('"', '\\"')
    end
  end

  def self.draw(title, &block)
    builder = Builder.new
    builder.instance_eval(&block)
    builder.to_dot(title)
  end
end
