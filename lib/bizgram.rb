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
          <defs>
            <!-- Arrow head markers for different arrow types -->
            <marker id="marker_object" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
              <path d="M 0,0 L 10,3 L 0,6 Z" fill="#000000"/>
            </marker>
            <marker id="marker_money" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
              <path d="M 0,0 L 10,3 L 0,6 Z" fill="#FF0000"/>
            </marker>
            <marker id="marker_information" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
              <path d="M 0,0 L 10,3 L 0,6 Z" fill="#0000FF"/>
            </marker>
            <marker id="marker_other" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
              <path d="M 0,0 L 10,3 L 0,6 Z" fill="#000000"/>
            </marker>
          </defs>
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

      # Group arrows by (from, to) pair for offset calculation
      arrow_groups = {}
      @arrows.each do |_id, arrow|
        pair = [arrow.from, arrow.to]
        arrow_groups[pair] ||= []
        arrow_groups[pair] << arrow
      end

      # Also detect reverse pairs for bidirectional arrows
      reverse_pairs = {}
      arrow_groups.each do |pair, arrows|
        reverse_pair = [pair[1], pair[0]]
        if arrow_groups.key?(reverse_pair)
          # Both directions exist - treat as bidirectional
          reverse_pairs[pair] = true
          reverse_pairs[reverse_pair] = true
        end
      end

      # Render arrows with offset for parallel arrows
      arrow_groups.each do |pair, arrows_in_group|
        # Check if this is a bidirectional pair that needs offset
        is_bidirectional = reverse_pairs[pair]

        arrows_in_group.each_with_index do |arrow, index|
          from_entity = @entities[arrow.from]
          to_entity = @entities[arrow.to]
          from_x, from_y = position_to_svg_coords(from_entity.position)
          to_x, to_y = position_to_svg_coords(to_entity.position)

          # Get edge connection points with direction info
          # Now passing entity positions for pattern-based routing
          from_exit_x, from_exit_y, to_enter_x, to_enter_y, from_dir, to_dir, route_strategy =
            get_edge_connection_points(from_x, from_y, to_x, to_y, from_entity.position, to_entity.position)

          # Calculate offset for multi-arrow case (10px spacing)
          # For bidirectional arrows with same from_x and to_x, use alternating offsets
          offset = if is_bidirectional && from_x == to_x
                     # Bidirectional case: alternate left/right based on pair order
                     if pair[0] < pair[1]
                       -15.0  # First pair: left
                     else
                       15.0   # Reverse pair: right
                     end
                   else
                     # Multi-arrow normal spacing
                     (index - (arrows_in_group.length - 1) / 2.0) * 10.0
                   end

          # Apply offset to entry/exit points based on routing strategy
          # This ensures the entire arrow (both start and end) is offset perpendicular to routing direction
          if offset != 0
            case route_strategy
            when :horizontal_primary
              # Horizontal routing: apply offset to Y-axis for vertical separation
              from_exit_y += offset
              to_enter_y += offset
            when :vertical_primary
              # Vertical routing: apply offset to X-axis for horizontal separation
              from_exit_x += offset
              to_enter_x += offset
            end
          end

          # Generate L-shaped path with offset applied
          # Use offset-aware routing for parallel/bidirectional arrows
          if offset == 0
            # No offset needed: use simple routing
            path_data = get_l_shaped_path(from_exit_x, from_exit_y, to_enter_x, to_enter_y, from_dir, to_dir)
          else
            # Offset already applied to exit/entry points, generate standard L-shaped path
            path_data = get_l_shaped_path(from_exit_x, from_exit_y, to_enter_x, to_enter_y, from_dir, to_dir)
          end

          color = ARROW_COLORS[arrow.type]
          marker_id = "marker_#{arrow.type}"

          # Arrow label position (at midpoint of the offset-adjusted path)
          label_x = (from_exit_x + to_enter_x) / 2.0
          label_y = (from_exit_y + to_enter_y) / 2.0

          # Arrow with L-shaped routing using path element
          lines << "  <g id=\"arrow_#{arrow.id}\">"
          lines << "    <path d=\"#{path_data}\" stroke=\"#{color}\" stroke-width=\"#{SVG_ARROW_STROKE_WIDTH}\" fill=\"none\" marker-end=\"url(##{marker_id})\" />"

          # Arrow label (with offset-adjusted position)
          lines << "    <text x=\"#{label_x}\" y=\"#{label_y - 10}\" font-size=\"16\" font-family=\"#{SVG_FONT_FAMILY}\" text-anchor=\"middle\" fill=\"#000000\">#{escape_xml(arrow.name)}</text>"
          lines << "  </g>"
        end
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
        comment_box_center_x = comment_x + comment_width / 2.0
        comment_box_center_y = comment_y + comment_height / 2.0

        # Connection from comment box to target entity (from bottom of box to top of entity)
        from_exit_x = comment_box_center_x
        from_exit_y = comment_y + comment_height
        to_enter_x = target_center_x
        to_enter_y = target_y

        lines << "  <g id=\"comment_#{comment.id}\">"
        lines << "    <rect x=\"#{comment_x}\" y=\"#{comment_y}\" width=\"#{comment_width}\" height=\"#{comment_height}\" fill=\"#{SVG_COMMENT_BG_COLOR}\" stroke=\"#000000\" stroke-width=\"#{SVG_COMMENT_STROKE_WIDTH}\" rx=\"5\" />"
        lines << "    <text x=\"#{comment_box_center_x}\" y=\"#{comment_box_center_y}\" font-size=\"14\" font-family=\"#{SVG_FONT_FAMILY}\" text-anchor=\"middle\" dominant-baseline=\"middle\" fill=\"#000000\">#{escape_xml(comment.text)}</text>"
        # Connection line (dashed)
        lines << "    <line x1=\"#{from_exit_x}\" y1=\"#{from_exit_y}\" x2=\"#{to_enter_x}\" y2=\"#{to_enter_y}\" stroke=\"#999999\" stroke-width=\"2\" stroke-dasharray=\"5,5\" />"
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

    def get_route_pattern(from_pos, to_pos)
      # Calculate relative position pattern (row_diff, col_diff)
      # Position layout: 0 1 2 / 3 4 5 / 6 7 8
      from_row = from_pos / 3
      from_col = from_pos % 3
      to_row = to_pos / 3
      to_col = to_pos % 3

      row_diff = to_row - from_row
      col_diff = to_col - from_col

      # Route pattern lookup based on specification
      # (矢印のルートパターン一覧（基本ルート）参照)
      #
      # Strategy for L-shaped routing:
      # - Prioritize the larger absolute difference as primary direction
      # - But for asymmetric cases (|row_diff|=1, |col_diff|=2 or vice versa),
      #   consider vertical-first to avoid entity blocking
      #
      # Returns: [from_dir, to_dir, route_strategy]

      if row_diff.abs > col_diff.abs
        # Vertical is primary direction
        if row_diff > 0
          [:bottom, :top, :vertical_primary]
        else
          [:top, :bottom, :vertical_primary]
        end
      elsif col_diff.abs > row_diff.abs
        # Horizontal is primary direction
        # Exception: if col_diff=±2 and row_diff=±1, use vertical-primary
        # to avoid routing through intermediate column
        if col_diff.abs == 2 && row_diff.abs == 1
          # Asymmetric case (1,2) or (-1,-2): prefer vertical routing
          if row_diff > 0
            [:bottom, :top, :vertical_primary]
          else
            [:top, :bottom, :vertical_primary]
          end
        else
          # Standard horizontal-primary for col_diff > row_diff
          if col_diff > 0
            [:right, :left, :horizontal_primary]
          else
            [:left, :right, :horizontal_primary]
          end
        end
      else
        # Equal distance: vertical is default
        if row_diff > 0
          [:bottom, :top, :vertical_primary]
        elsif row_diff < 0
          [:top, :bottom, :vertical_primary]
        elsif col_diff > 0
          [:right, :left, :horizontal_primary]
        else
          [:left, :right, :horizontal_primary]
        end
      end
    end

    def get_edge_connection_points(from_x, from_y, to_x, to_y, from_pos, to_pos)
      # Calculate edge connection points based on route pattern
      # Returns: [from_exit_x, from_exit_y, to_enter_x, to_enter_y, from_dir, to_dir]

      from_center_x = from_x + SVG_ENTITY_WIDTH / 2.0
      from_center_y = from_y + SVG_ENTITY_HEIGHT / 2.0
      to_center_x = to_x + SVG_ENTITY_WIDTH / 2.0
      to_center_y = to_y + SVG_ENTITY_HEIGHT / 2.0

      from_dir, to_dir, _route_strategy = get_route_pattern(from_pos, to_pos)

      # Calculate exit and entry points based on direction
      case from_dir
      when :right
        from_exit_x = from_x + SVG_ENTITY_WIDTH
        from_exit_y = from_center_y
      when :left
        from_exit_x = from_x
        from_exit_y = from_center_y
      when :bottom
        from_exit_x = from_center_x
        from_exit_y = from_y + SVG_ENTITY_HEIGHT
      when :top
        from_exit_x = from_center_x
        from_exit_y = from_y
      end

      case to_dir
      when :right
        to_enter_x = to_x + SVG_ENTITY_WIDTH
        to_enter_y = to_center_y
      when :left
        to_enter_x = to_x
        to_enter_y = to_center_y
      when :bottom
        to_enter_x = to_center_x
        to_enter_y = to_y + SVG_ENTITY_HEIGHT
      when :top
        to_enter_x = to_center_x
        to_enter_y = to_y
      end

      [from_exit_x, from_exit_y, to_enter_x, to_enter_y, from_dir, to_dir, _route_strategy]
    end

    def get_l_shaped_path(from_x, from_y, to_x, to_y, from_dir, to_dir)
      # Generate L-shaped routing path based on exit/entry directions
      # Path follows the direction indicated by from_dir and to_dir

      # Special case: same X coordinate → pure vertical path
      if (from_x - to_x).abs < 0.01
        return "M #{from_x},#{from_y} L #{from_x},#{to_y}"
      end

      # Special case: same Y coordinate → pure horizontal path
      if (from_y - to_y).abs < 0.01
        return "M #{from_x},#{from_y} L #{to_x},#{to_y}"
      end

      case [from_dir, to_dir]
      when [:right, :left], [:right, :top], [:right, :bottom]
        # Exiting right: horizontal first
        mid_x = (from_x + to_x) / 2.0
        "M #{from_x},#{from_y} L #{mid_x},#{from_y} L #{mid_x},#{to_y} L #{to_x},#{to_y}"
      when [:left, :right], [:left, :top], [:left, :bottom]
        # Exiting left: horizontal first
        mid_x = (from_x + to_x) / 2.0
        "M #{from_x},#{from_y} L #{mid_x},#{from_y} L #{mid_x},#{to_y} L #{to_x},#{to_y}"
      when [:bottom, :top], [:bottom, :left], [:bottom, :right]
        # Exiting bottom: vertical first
        mid_y = (from_y + to_y) / 2.0
        "M #{from_x},#{from_y} L #{from_x},#{mid_y} L #{to_x},#{mid_y} L #{to_x},#{to_y}"
      when [:top, :bottom], [:top, :left], [:top, :right]
        # Exiting top: vertical first
        mid_y = (from_y + to_y) / 2.0
        "M #{from_x},#{from_y} L #{from_x},#{mid_y} L #{to_x},#{mid_y} L #{to_x},#{to_y}"
      else
        # Fallback: horizontal first
        mid_x = (from_x + to_x) / 2.0
        "M #{from_x},#{from_y} L #{mid_x},#{from_y} L #{mid_x},#{to_y} L #{to_x},#{to_y}"
      end
    end

    def get_l_shaped_path_with_offset(from_x, from_y, to_x, to_y, offset, from_dir, to_dir, route_strategy)
      # Generate L-shaped routing path with offset for parallel arrows
      # Key principle: offset is perpendicular to routing direction
      # - Horizontal-primary routing: offset Y-axis (vertical separation)
      # - Vertical-primary routing: offset X-axis (horizontal separation)
      # Note: from_x/from_y/to_x/to_y are EXIT/ENTRY points, not entity corners

      case route_strategy
      when :horizontal_primary
        # Horizontal-primary routing: horizontal then vertical
        # Apply offset to vertical bend (perpendicular to horizontal flow)
        mid_x = (from_x + to_x) / 2.0
        mid_y = (from_y + to_y) / 2.0 + offset
        "M #{from_x},#{from_y} L #{mid_x},#{from_y} L #{mid_x},#{mid_y} L #{to_x},#{mid_y} L #{to_x},#{to_y}"
      when :vertical_primary
        # Vertical-primary routing: vertical then horizontal
        # Apply offset to horizontal bend (perpendicular to vertical flow)
        mid_x = (from_x + to_x) / 2.0 + offset
        mid_y = (from_y + to_y) / 2.0
        "M #{from_x},#{from_y} L #{from_x},#{mid_y} L #{mid_x},#{mid_y} L #{to_x},#{mid_y} L #{to_x},#{to_y}"
      else
        # Fallback: horizontal-primary assumed
        mid_x = (from_x + to_x) / 2.0
        mid_y = (from_y + to_y) / 2.0 + offset
        "M #{from_x},#{from_y} L #{mid_x},#{from_y} L #{mid_x},#{mid_y} L #{to_x},#{mid_y} L #{to_x},#{to_y}"
      end
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
