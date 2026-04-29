# frozen_string_literal: true

require 'base64'

module Bizgram
  # SVG Layout Constants - from reference materials
  SVG_CANVAS_WIDTH = 1440.0
  SVG_CANVAS_HEIGHT = 900.0

  # Grid row Y positions
  SVG_GRID_ROWS = [
    0,
    350.26513,
    635.41785,
    900.0
  ].freeze

  # Grid column X positions (approximate from reference materials)
  SVG_GRID_COLS = [
    426.1472,
    683.23193,
    937.0625
  ].freeze

  # Entity box dimensions
  SVG_ENTITY_WIDTH = 72.47241
  SVG_ENTITY_HEIGHT = 132.75592

  # Styling constants
  SVG_ENTITY_STROKE_WIDTH = 4
  SVG_ARROW_STROKE_WIDTH = 3
  SVG_FONT_SIZE = 24
  SVG_FONT_FAMILY = "sans-serif"
  SVG_COMMENT_BG_COLOR = "#FFFC41"
  SVG_COMMENT_STROKE_WIDTH = 3

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
      @next_global_id = 0
      @occupied_positions = Set.new
    end

    def entity(type, name, position = nil)
      validate_entity_type(type)
      validate_name(name)

      return @entities[name] if @entities.key?(name)

      pos = PositionResolver.resolve(position, type, @occupied_positions)
      raise "Position #{pos} is already occupied" if @occupied_positions.include?(pos)

      id = next_id
      ent = Entity.new(id, name, type, pos)
      @entities[name] = ent
      @entities_by_id[id] = ent
      @occupied_positions.add(pos)

      ent
    end

    def person(name, position = nil)
      entity(:person, name, position)
    end

    def user(name, position = nil)
      entity(:user, name, position)
    end

    def company(name, position = nil)
      entity(:company, name, position)
    end

    def business(name, position = nil)
      entity(:business, name, position)
    end

    def money(name, position = nil)
      entity(:money, name, position)
    end

    def object(name, position = nil)
      entity(:object, name, position)
    end

    def goods(name, position = nil)
      entity(:goods, name, position)
    end

    def information(name, position = nil)
      entity(:information, name, position)
    end

    def info(name, position = nil)
      entity(:info, name, position)
    end

    def smartphone(name, position = nil)
      entity(:smartphone, name, position)
    end

    def device(name, position = nil)
      entity(:device, name, position)
    end

    def store(name, position = nil)
      entity(:store, name, position)
    end

    def shop(name, position = nil)
      entity(:shop, name, position)
    end

    def other(name, position = nil)
      entity(:other, name, position)
    end

    def arrow(type, name, from, to)
      validate_arrow_type(type)
      validate_name(name)

      from_id = resolve_entity_reference(from)
      to_id = resolve_entity_reference(to)

      raise ArgumentError, "From entity (id: #{from_id}) not found" unless @entities_by_id.key?(from_id)
      raise ArgumentError, "To entity (id: #{to_id}) not found" unless @entities_by_id.key?(to_id)

      id = next_id
      arr = Arrow.new(id, name, type, from_id, to_id)
      @arrows[name] = arr
      @arrows_by_id[id] = arr

      arr
    end

    def comment_to(to, text)
      validate_name(text)

      to_id = resolve_entity_reference(to)
      raise ArgumentError, "To entity (id: #{to_id}) not found" unless @entities_by_id.key?(to_id)

      id = next_id
      com = Comment.new(id, to_id, text)
      @comments[id] = com

      com
    end

    def comment(to, text)
      comment_to(to, text)
    end

    def to_dot(title)
      DotGenerator.new(@entities_by_id, @arrows_by_id, @comments).generate(title)
    end

    def to_svg(title)
      SvgGenerator.new(@entities_by_id, @arrows_by_id, @comments).generate(title)
    end

    private

    def validate_entity_type(type)
      valid_types = [:person, :user, :company, :business, :money, :object, :goods, :information, :info, :smartphone, :device, :store, :shop, :other]
      raise ArgumentError, "Invalid entity type: #{type}" unless valid_types.include?(type)
    end

    def validate_arrow_type(type)
      raise ArgumentError, "Invalid arrow type: #{type}" unless [:object, :money, :information, :other].include?(type)
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
      when Entity
        ref.id
      else
        raise ArgumentError, "Entity reference must be Integer, String, or Entity object, got #{ref.class}"
      end
    end

    def next_id
      id = @next_global_id
      @next_global_id += 1
      id
    end
  end

  class DotGenerator
    ENTITY_COLORS = {
      person: "#FFE5CC", user: "#FFE5CC",
      company: "#CCE5FF", business: "#CCE5FF",
      money: "#FFCCCC",
      object: "#E5E5E5", goods: "#E5E5E5",
      information: "#E5CCFF", info: "#E5CCFF",
      smartphone: "#FFCCFF", device: "#FFCCFF",
      store: "#FFFFCC", shop: "#FFFFCC",
      other: "#F0F0F0"
    }.freeze

    ARROW_STYLES = {
      object: { color: "black", label: "モノ" },
      money: { color: "red", label: "カネ" },
      information: { color: "blue", label: "情報" },
      other: { color: "black" }
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

  class SvgGenerator
    ENTITY_COLORS = {
      person: "#FFE5CC", user: "#FFE5CC",
      company: "#CCE5FF", business: "#CCE5FF",
      money: "#FFCCCC",
      object: "#E5E5E5", goods: "#E5E5E5",
      information: "#E5CCFF", info: "#E5CCFF",
      smartphone: "#FFCCFF", device: "#FFCCFF",
      store: "#FFFFCC", shop: "#FFFFCC",
      other: "#F0F0F0"
    }.freeze

    ARROW_COLORS = {
      object: "#000000",
      money: "#FF0000",
      information: "#0000FF",
      other: "#000000"
    }.freeze

    # Entity type to SVG image file mapping
    ENTITY_IMAGE_MAP = {
      person: "entity_person.svg",
      user: "entity_person.svg",
      company: "entity_company.svg",
      business: "entity_company.svg",
      money: "entity_money.svg",
      object: "entity_object.svg",
      goods: "entity_object.svg",
      information: "entity_information.svg",
      info: "entity_information.svg",
      smartphone: "entity_smartphone.svg",
      device: "entity_smartphone.svg",
      store: "entity_store.svg",
      shop: "entity_store.svg",
      other: "entity_other.svg"
    }.freeze

    def initialize(entities_by_id, arrows_by_id, comments)
      @entities = entities_by_id
      @arrows = arrows_by_id
      @comments = comments
      @entities_by_position = {}
      @entities.each do |_id, entity|
        @entities_by_position[entity.position] = entity
      end
      @entity_svg_cache = {} # Cache for loaded entity SVGs
    end

    def generate(title)
      lines = []
      lines << svg_header(title)
      lines << render_entities
      lines << render_arrows
      lines << render_comments
      lines << svg_footer
      lines.join("\n")
    end

    private

    def svg_header(title)
      <<~SVG
        <?xml version="1.0" encoding="UTF-8" standalone="no"?>
        <svg
          version="1.1"
          viewBox="0.0 0.0 #{SVG_CANVAS_WIDTH} #{SVG_CANVAS_HEIGHT}"
          width="#{SVG_CANVAS_WIDTH.to_i}"
          height="#{SVG_CANVAS_HEIGHT.to_i}"
          xmlns="http://www.w3.org/2000/svg">
          <title>#{escape_xml(title)}</title>
      SVG
    end

    def svg_footer
      "  </svg>\n"
    end

    def render_entities
      lines = []
      lines << "  <!-- Entities -->"
      @entities_by_position.each do |pos, entity|
        x, y = position_to_svg_coords(pos)

        # Entity group
        lines << "  <g id=\"entity_#{entity.id}\">"

        # Embedded entity SVG image as data URI
        data_uri = load_entity_svg_as_data_uri(entity.type)
        if data_uri
          lines << "    <image x=\"#{x}\" y=\"#{y}\" width=\"#{SVG_ENTITY_WIDTH}\" height=\"#{SVG_ENTITY_HEIGHT}\" href=\"#{data_uri}\"/>"
        end

        # Entity text label (below image)
        label_y = y + SVG_ENTITY_HEIGHT + 8  # 8px margin below image
        text_x = x + SVG_ENTITY_WIDTH / 2.0
        lines << "    <text x=\"#{text_x}\" y=\"#{label_y}\" font-size=\"14\" font-family=\"#{SVG_FONT_FAMILY}\" text-anchor=\"middle\" dominant-baseline=\"text-before-edge\" fill=\"#000000\" word-spacing=\"0\" letter-spacing=\"0\" style=\"white-space: pre-wrap; word-wrap: break-word;\">#{escape_xml(entity.name)}</text>"
        lines << "  </g>"
      end
      lines.join("\n")
    end

    def render_arrows
      lines = []
      lines << "  <!-- Arrows -->"
      @arrows.each do |_id, arrow|
        from_entity = @entities[arrow.from]
        to_entity = @entities[arrow.to]
        from_x, from_y = position_to_svg_coords(from_entity.position)
        to_x, to_y = position_to_svg_coords(to_entity.position)

        # Center of entities
        from_center_x = from_x + SVG_ENTITY_WIDTH / 2.0
        from_center_y = from_y + SVG_ENTITY_HEIGHT / 2.0
        to_center_x = to_x + SVG_ENTITY_WIDTH / 2.0
        to_center_y = to_y + SVG_ENTITY_HEIGHT / 2.0

        color = ARROW_COLORS[arrow.type]

        # Simple straight line for now
        lines << "  <g id=\"arrow_#{arrow.id}\">"
        lines << "    <line x1=\"#{from_center_x}\" y1=\"#{from_center_y}\" x2=\"#{to_center_x}\" y2=\"#{to_center_y}\" stroke=\"#{color}\" stroke-width=\"#{SVG_ARROW_STROKE_WIDTH}\" />"

        # Arrow label (midpoint)
        label_x = (from_center_x + to_center_x) / 2.0
        label_y = (from_center_y + to_center_y) / 2.0
        lines << "    <text x=\"#{label_x}\" y=\"#{label_y - 10}\" font-size=\"16\" font-family=\"#{SVG_FONT_FAMILY}\" text-anchor=\"middle\" fill=\"#000000\">#{escape_xml(arrow.name)}</text>"
        lines << "  </g>"
      end
      lines.join("\n")
    end

    def render_comments
      lines = []
      return lines.join("\n") if @comments.empty?

      lines << "  <!-- Comments -->"
      @comments.each do |_id, comment|
        target_entity = @entities[comment.to]
        target_x, target_y = position_to_svg_coords(target_entity.position)
        target_center_x = target_x + SVG_ENTITY_WIDTH / 2.0
        target_center_y = target_y + SVG_ENTITY_HEIGHT / 2.0

        # Simple comment box positioned above the target entity
        comment_x = target_center_x - 40
        comment_y = target_center_y - 80
        comment_width = 80
        comment_height = 40

        lines << "  <g id=\"comment_#{comment.id}\">"
        lines << "    <rect x=\"#{comment_x}\" y=\"#{comment_y}\" width=\"#{comment_width}\" height=\"#{comment_height}\" fill=\"#{SVG_COMMENT_BG_COLOR}\" stroke=\"#000000\" stroke-width=\"#{SVG_COMMENT_STROKE_WIDTH}\" rx=\"5\" />"
        lines << "    <text x=\"#{comment_x + comment_width / 2.0}\" y=\"#{comment_y + comment_height / 2.0}\" font-size=\"14\" font-family=\"#{SVG_FONT_FAMILY}\" text-anchor=\"middle\" dominant-baseline=\"middle\" fill=\"#000000\">#{escape_xml(comment.text)}</text>"
        lines << "  </g>"
      end
      lines.join("\n")
    end

    def position_to_svg_coords(position)
      row = position / 3
      col = position % 3
      x = SVG_GRID_COLS[col]
      y = SVG_GRID_ROWS[row]
      [x, y]
    end

    def load_entity_svg_as_data_uri(entity_type)
      return @entity_svg_cache[entity_type] if @entity_svg_cache.key?(entity_type)

      filename = ENTITY_IMAGE_MAP[entity_type]
      return nil unless filename

      svg_path = File.expand_path("../../reference/image/#{filename}", __FILE__)
      return nil unless File.exist?(svg_path)

      svg_content = File.read(svg_path)
      # Base64 encode the SVG content
      encoded = Base64.encode64(svg_content).gsub("\n", "")
      data_uri = "data:image/svg+xml;base64,#{encoded}"

      @entity_svg_cache[entity_type] = data_uri
      data_uri
    end

    def load_entity_svg(entity_type)
      return @entity_svg_cache[entity_type] if @entity_svg_cache.key?(entity_type)

      filename = ENTITY_IMAGE_MAP[entity_type]
      return nil unless filename

      svg_path = File.expand_path("../../reference/image/#{filename}", __FILE__)
      return nil unless File.exist?(svg_path)

      svg_content = extract_svg_content(svg_path)
      @entity_svg_cache[entity_type] = svg_content
      svg_content
    end

    def load_entity_svg_with_transform(entity_type, x, y)
      svg_content = load_entity_svg(entity_type)
      return nil unless svg_content

      # Wrap with indentation and translate transform
      lines = []
      lines << "    <g transform=\"translate(#{x}, #{y})\">"
      # Indent the svg_content lines
      svg_content.split("\n").each do |line|
        lines << "      #{line}" if line.strip.length > 0
      end
      lines << "    </g>"
      lines.join("\n")
    end

    def extract_svg_content(svg_path)
      content = File.read(svg_path)

      # Extract layer1 element with its transform attribute preserved
      # The layer1 transform is CRITICAL for coordinate normalization in Inkscape-generated SVGs
      if content.match(%r{<g\s+[^>]*id="layer1"[^>]*>(.*)</g>}m)
        layer_content = Regexp.last_match(1).strip

        # Extract layer1's transform attribute for coordinate normalization
        layer_transform = nil
        if content.match(%r{<g\s+[^>]*id="layer1"[^>]*transform="([^"]*)"[^>]*>}m)
          layer_transform = Regexp.last_match(1)
        end

        # Remove inkscape-specific attributes (inkscape:*, sodipodi:*, style attributes with transform-like content)
        # but preserve the actual SVG structure and transform chains
        layer_content = layer_content.gsub(/\s+inkscape:[^=]*="[^"]*"/, '')
        layer_content = layer_content.gsub(/\s+sodipodi:[^=]*="[^"]*"/, '')

        scaled_content = scale_svg_content(layer_content, layer_transform)
        scaled_content
      else
        nil
      end
    end

    def scale_svg_content(content, layer_transform = nil)
      # The reference images have viewBox="0 0 20.236225 36.561409"
      # We need to scale them to SVG_ENTITY_WIDTH x SVG_ENTITY_HEIGHT
      ref_width = 20.236225
      ref_height = 36.561409
      scale_x = SVG_ENTITY_WIDTH / ref_width
      scale_y = SVG_ENTITY_HEIGHT / ref_height

      # Build nested g elements for explicit transform order
      # Nested transforms are ALWAYS evaluated outer→inner, which is what we want
      lines = []

      if layer_transform
        # Outermost: layer1's transform (coordinate normalization)
        lines << "<g transform=\"#{layer_transform}\">"
      end

      # Middle: scale transformation
      lines << "  <g transform=\"scale(#{scale_x}, #{scale_y})\">"

      # Innermost: content
      content_lines = content.split("\n")
      content_lines.each do |line|
        lines << "    #{line}" if line.strip.length > 0
      end

      lines << "  </g>"

      if layer_transform
        lines << "</g>"
      end

      lines.join("\n")
    end

    def escape_xml(str)
      str.gsub("&", "&amp;")
         .gsub("<", "&lt;")
         .gsub(">", "&gt;")
         .gsub('"', "&quot;")
         .gsub("'", "&apos;")
    end
  end

  def self.draw(title, &block)
    builder = Builder.new
    builder.instance_eval(&block)
    builder.to_svg(title)
  end
end
