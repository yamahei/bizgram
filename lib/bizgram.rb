# frozen_string_literal: true

require 'base64'

module Bizgram
  # SVG Layout Constants - Compact and centered
  SVG_ENTITY_WIDTH = 120.0
  SVG_ENTITY_HEIGHT = 120.0
  SVG_GRID_SPACING_X = 240.0
  SVG_GRID_SPACING_Y = 240.0
  SVG_PADDING_X = 200.0
  SVG_PADDING_Y = 200.0

  SVG_CANVAS_WIDTH = SVG_PADDING_X * 2 + SVG_GRID_SPACING_X * 2
  SVG_CANVAS_HEIGHT = SVG_PADDING_Y * 2 + SVG_GRID_SPACING_Y * 2

  # Grid row Y positions (Centers)
  SVG_GRID_ROWS = [
    SVG_PADDING_Y,
    SVG_PADDING_Y + SVG_GRID_SPACING_Y,
    SVG_PADDING_Y + SVG_GRID_SPACING_Y * 2
  ].freeze

  # Grid column X positions (Centers)
  SVG_GRID_COLS = [
    SVG_PADDING_X,
    SVG_PADDING_X + SVG_GRID_SPACING_X,
    SVG_PADDING_X + SVG_GRID_SPACING_X * 2
  ].freeze

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
          <!-- Background Grid Lines -->
          <g id="background_grid" stroke="#cccccc" stroke-width="2" stroke-dasharray="8,8">
            <line x1="#{SVG_PADDING_X - 40}" y1="#{(SVG_GRID_ROWS[0] + SVG_GRID_ROWS[1]) / 2.0}" x2="#{SVG_CANVAS_WIDTH - SVG_PADDING_X + 40}" y2="#{(SVG_GRID_ROWS[0] + SVG_GRID_ROWS[1]) / 2.0}" />
            <line x1="#{SVG_PADDING_X - 40}" y1="#{(SVG_GRID_ROWS[1] + SVG_GRID_ROWS[2]) / 2.0}" x2="#{SVG_CANVAS_WIDTH - SVG_PADDING_X + 40}" y2="#{(SVG_GRID_ROWS[1] + SVG_GRID_ROWS[2]) / 2.0}" />
          </g>
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

        # x, y are the center coordinates
        left_x = x - SVG_ENTITY_WIDTH / 2.0
        top_y = y - SVG_ENTITY_HEIGHT / 2.0

        # Entity group
        lines << "  <g id=\"entity_#{entity.id}\">"

        # Embedded entity SVG content directly
        svg_content = load_entity_svg_with_transform(entity.type, left_x, top_y)
        if svg_content
          lines << svg_content
        else
          # Fallback if svg loading fails
          lines << "    <rect x=\"#{left_x}\" y=\"#{top_y}\" width=\"#{SVG_ENTITY_WIDTH}\" height=\"#{SVG_ENTITY_HEIGHT}\" fill=\"#eeeeee\" stroke=\"#000000\" stroke-width=\"2\" />"
        end

        # Entity text label (below image)
        label_y = top_y + SVG_ENTITY_HEIGHT + 8  # 8px margin below image
        lines << "    <text x=\"#{x}\" y=\"#{label_y}\" font-size=\"14\" font-family=\"#{SVG_FONT_FAMILY}\" text-anchor=\"middle\" dominant-baseline=\"text-before-edge\" fill=\"#000000\" word-spacing=\"0\" letter-spacing=\"0\" style=\"white-space: pre-wrap; word-wrap: break-word;\">#{escape_xml(entity.name)}</text>"
        lines << "  </g>"
      end
      lines.join("\n")
    end

class GridRouter
  def initialize(entities_by_position)
    @entities_by_position = entities_by_position
    @routed_paths = [] 
  end

  def route_all(arrows)
    sorted_arrows = arrows.sort_by do |arr|
      dx = (arr.to_pos % 3) - (arr.from_pos % 3)
      dy = (arr.to_pos / 3) - (arr.from_pos / 3)
      -(dx.abs + dy.abs)
    end

    results = {}
    sorted_arrows.each do |arr|
      path = find_route(arr)
      @routed_paths << {arrow: arr, path: path}
      results[arr.id] = path
    end
    results
  end

  private

  def find_route(arrow)
    fx = arrow.from_pos % 3
    fy = arrow.from_pos / 3
    tx = arrow.to_pos % 3
    ty = arrow.to_pos / 3

    gx1, gy1 = fx * 2, fy * 2
    gx2, gy2 = tx * 2, ty * 2

    candidates = generate_candidates(gx1, gy1, gx2, gy2)
    
    valid_candidates = candidates.select { |path| valid_path?(path, arrow) }
    
    if valid_candidates.empty?
      raise "Error: 仕様可能なルートがありません (from: #{arrow.from_pos}, to: #{arrow.to_pos})"
    end
    
    valid_candidates.first
  end

  def generate_candidates(gx1, gy1, gx2, gy2)
    dx = gx2 - gx1
    dy = gy2 - gy1

    return [generate_straight(gx1, gy1, gx2, gy2)] if dx == 0 || dy == 0

    candidates = []
    candidates << generate_l_shape(gx1, gy1, gx2, gy2, :horizontal)
    candidates << generate_l_shape(gx1, gy1, gx2, gy2, :vertical)

    if dx.abs == 2 && dy.abs == 2
      candidates << [[gx1, gy1], [gx1 + dx/2, gy1 + dy/2], [gx2, gy2]]
    end

    candidates
  end

  def generate_straight(gx1, gy1, gx2, gy2)
    path = []
    if gx1 == gx2
      step = gy2 > gy1 ? 1 : -1
      gy1.step(gy2, step) { |y| path << [gx1, y] }
    else
      step = gx2 > gx1 ? 1 : -1
      gx1.step(gx2, step) { |x| path << [x, gy1] }
    end
    path
  end

  def generate_l_shape(gx1, gy1, gx2, gy2, first_dir)
    path = []
    if first_dir == :horizontal
      step_x = gx2 > gx1 ? 1 : -1
      gx1.step(gx2, step_x) { |x| path << [x, gy1] }
      step_y = gy2 > gy1 ? 1 : -1
      y_start = gy1 + step_y
      y_start.step(gy2, step_y) { |y| path << [gx2, y] }
    else
      step_y = gy2 > gy1 ? 1 : -1
      gy1.step(gy2, step_y) { |y| path << [gx1, y] }
      step_x = gx2 > gx1 ? 1 : -1
      x_start = gx1 + step_x
      x_start.step(gx2, step_x) { |x| path << [x, gy2] }
    end
    path
  end

  def valid_path?(path, arrow)
    path[1...-1].each do |x, y|
      if x.even? && y.even?
        pos = (y / 2) * 3 + (x / 2)
        return false if @entities_by_position.key?(pos)
      end
    end

    require 'set'
    pair = [arrow.from_pos, arrow.to_pos].sort
    path_points = path.to_set

    @routed_paths.each do |routed|
      r_pair = [routed[:arrow].from_pos, routed[:arrow].to_pos].sort
      next if pair == r_pair
      
      intersection = path_points & routed[:path].to_set
      intersection.each do |x, y|
        is_endpoint = (x == path.first[0] && y == path.first[1]) || (x == path.last[0] && y == path.last[1])
        return false unless is_endpoint && x.even? && y.even?
      end
    end
    true
  end
end

class RouterArrow
  attr_reader :id, :from_pos, :to_pos
  def initialize(id, from_pos, to_pos)
    @id = id
    @from_pos = from_pos
    @to_pos = to_pos
  end
end

def render_arrows
  lines = []
  lines << "  <!-- Arrows -->"

  router_arrows = @arrows.values.map do |arr|
    from_entity = @entities[arr.from]
    to_entity = @entities[arr.to]
    RouterArrow.new(arr.id, from_entity.position, to_entity.position)
  end

  router = GridRouter.new(@entities_by_position)
  routes = router.route_all(router_arrows)

  # Group by pair to compute offset
  arrow_groups = {}
  @arrows.each do |_id, arrow|
    from_pos = @entities[arrow.from].position
    to_pos = @entities[arrow.to].position
    pair = [from_pos, to_pos].sort
    arrow_groups[pair] ||= []
    arrow_groups[pair] << arrow
  end

  arrow_groups.each do |pair, arrows_in_group|
    arrows_in_group.each_with_index do |arrow, index|
      from_entity = @entities[arrow.from]
      
      # Is it reversed relative to pair?
      is_reversed = (from_entity.position != pair[0])
      
      # Increased offset multiplier from 10.0 to 25.0 to avoid text overlap between parallel arrows
      offset = (index - (arrows_in_group.length - 1) / 2.0) * 25.0
      offset = -offset if is_reversed
      
      grid_path = routes[arrow.id]
      
      svg_points = grid_path.map { |pt| svg_coords_from_grid(pt[0], pt[1]) }
      
      # Adjust first and last point to entity edges
      if svg_points.length >= 2
        adjust_to_edge(svg_points[0], svg_points[1], true)
        adjust_to_edge(svg_points[-1], svg_points[-2], false)
      end
      
      # Apply offset to the whole path
      shifted_points = apply_offset_to_path(svg_points, offset)

      color = ARROW_COLORS[arrow.type]
      marker_id = "marker_#{arrow.type}"

      # Path string
      path_data = "M #{shifted_points.first[0]},#{shifted_points.first[1]} "
      shifted_points[1..-1].each do |pt|
        path_data += "L #{pt[0]},#{pt[1]} "
      end

      # Find longest segment for label
      max_len = -1
      best_p1 = nil
      best_p2 = nil
      (0...shifted_points.length - 1).each do |i|
        p_curr = shifted_points[i]
        p_next = shifted_points[i+1]
        len = Math.sqrt((p_next[0] - p_curr[0])**2 + (p_next[1] - p_curr[1])**2)
        if len > max_len
          max_len = len
          best_p1 = p_curr
          best_p2 = p_next
        end
      end

      label_x = (best_p1[0] + best_p2[0]) / 2.0
      label_y = (best_p1[1] + best_p2[1]) / 2.0
      is_vertical_segment = (best_p1[0] - best_p2[0]).abs < (best_p1[1] - best_p2[1]).abs

      text_anchor = "middle"
      if is_vertical_segment
        dy = best_p2[1] - best_p1[1]
        actual_shift_x = (dy > 0 ? -1 : 1) * offset
        if actual_shift_x < 0
          label_x -= 8
          text_anchor = "end"
        else
          label_x += 8
          text_anchor = "start"
        end
        label_y += 5
      else
        dx = best_p2[0] - best_p1[0]
        actual_shift_y = (dx > 0 ? 1 : -1) * offset
        if actual_shift_y > 0
          label_y += 18 # below
        else
          label_y -= 8  # above
        end
      end

      lines << "  <g id=\"arrow_#{arrow.id}\">"
      lines << "    <path d=\"#{path_data.strip}\" stroke=\"#{color}\" stroke-width=\"#{SVG_ARROW_STROKE_WIDTH}\" fill=\"none\" stroke-linejoin=\"round\" marker-end=\"url(##{marker_id})\" />"
      lines << "    <text x=\"#{label_x}\" y=\"#{label_y}\" font-size=\"16\" font-family=\"#{SVG_FONT_FAMILY}\" text-anchor=\"#{text_anchor}\" fill=\"#000000\">#{escape_xml(arrow.name)}</text>"
      lines << "  </g>"
    end
  end
  lines.join("\n")
end

def svg_coords_from_grid(gx, gy)
  col = gx / 2
  row = gy / 2
  
  if gx.even?
    x = SVG_GRID_COLS[col]
  else
    x = (SVG_GRID_COLS[col] + SVG_GRID_COLS[col + 1]) / 2.0
  end
  
  if gy.even?
    y = SVG_GRID_ROWS[row]
  else
    y = (SVG_GRID_ROWS[row] + SVG_GRID_ROWS[row + 1]) / 2.0
  end
  [x, y]
end

def adjust_to_edge(pt, neighbor, is_start)
  dx = neighbor[0] - pt[0]
  dy = neighbor[1] - pt[1]
  
  if dx.abs > dy.abs
    # Horizontal exiting/entering
    if dx > 0
      pt[0] += SVG_ENTITY_WIDTH / 2.0
    else
      pt[0] -= SVG_ENTITY_WIDTH / 2.0
    end
  else
    # Vertical exiting/entering
    if dy > 0
      # Offset more on the bottom edge to avoid text label (height/2 + 8 margin + 20 text height + padding)
      pt[1] += SVG_ENTITY_HEIGHT / 2.0 + 35.0
    else
      pt[1] -= SVG_ENTITY_HEIGHT / 2.0
    end
  end
end

def apply_offset_to_path(points, offset)
  return points if offset == 0
  shifted = []
  
  (0...points.length).each do |i|
    p = points[i]
    
    if i == 0
      p_next = points[i+1]
      dx = p_next[0] - p[0]
      dy = p_next[1] - p[1]
      if dx.abs > dy.abs
        shifted << [p[0], p[1] + (dx > 0 ? 1 : -1) * offset]
      else
        shifted << [p[0] + (dy > 0 ? -1 : 1) * offset, p[1]]
      end
    elsif i == points.length - 1
      p_prev = points[i-1]
      dx = p[0] - p_prev[0]
      dy = p[1] - p_prev[1]
      if dx.abs > dy.abs
        shifted << [p[0], p[1] + (dx > 0 ? 1 : -1) * offset]
      else
        shifted << [p[0] + (dy > 0 ? -1 : 1) * offset, p[1]]
      end
    else
      p_prev = points[i-1]
      p_next = points[i+1]
      
      dx1 = p[0] - p_prev[0]
      dy1 = p[1] - p_prev[1]
      dx2 = p_next[0] - p[0]
      dy2 = p_next[1] - p[1]
      
      shift_x = 0
      shift_y = 0
      
      if dx1.abs > dy1.abs
        shift_y = (dx1 > 0 ? 1 : -1) * offset
      else
        shift_x = (dy1 > 0 ? -1 : 1) * offset
      end
      
      if dx2.abs > dy2.abs
        shift_y = (dx2 > 0 ? 1 : -1) * offset
      else
        shift_x = (dy2 > 0 ? -1 : 1) * offset
      end
      
      shifted << [p[0] + shift_x, p[1] + shift_y]
    end
  end
  shifted
end

    def render_comments
      lines = []
      return lines.join("\n") if @comments.empty?

      lines << "  <!-- Comments -->"
      @comments.each do |_id, comment|
        target_entity = @entities[comment.to]
        target_center_x, target_center_y = position_to_svg_coords(target_entity.position)
        target_top_y = target_center_y - SVG_ENTITY_HEIGHT / 2.0

        # Dynamic width based on text length (approx 14px per char + 20px padding)
        comment_width = [comment.text.length * 14 + 20, 80].max
        comment_height = 40

        # Position comment offset to the top-right to avoid vertical arrows
        comment_x = target_center_x + 10
        comment_y = target_top_y - 70
        comment_box_center_x = comment_x + comment_width / 2.0
        comment_box_center_y = comment_y + comment_height / 2.0

        # Connection from comment box to target entity
        # We replace the dashed line with a speech bubble tail
        tail_width = 16
        tail_height = 16
        cx = comment_box_center_x
        cy = comment_y + comment_height
        
        # Original style speech bubble
        path_d = "M #{comment_x + 5},#{comment_y} " +
                 "H #{comment_x + comment_width - 5} " +
                 "Q #{comment_x + comment_width},#{comment_y} #{comment_x + comment_width},#{comment_y + 5} " +
                 "V #{cy - 5} " +
                 "Q #{comment_x + comment_width},#{cy} #{comment_x + comment_width - 5},#{cy} " +
                 "H #{comment_x + 20 + tail_width} " +
                 "L #{comment_x + 10},#{cy + tail_height + 5} " +
                 "L #{comment_x + 20},#{cy} " +
                 "H #{comment_x + 5} " +
                 "Q #{comment_x},#{cy} #{comment_x},#{cy - 5} " +
                 "V #{comment_y + 5} " +
                 "Q #{comment_x},#{comment_y} #{comment_x + 5},#{comment_y} Z"

        lines << "  <g id=\"comment_#{comment.id}\">"
        lines << "    <path d=\"#{path_d}\" fill=\"#dddddd\" stroke=\"none\" />"
        lines << "    <text x=\"#{comment_box_center_x}\" y=\"#{comment_box_center_y}\" font-size=\"14\" font-family=\"#{SVG_FONT_FAMILY}\" text-anchor=\"middle\" dominant-baseline=\"middle\" fill=\"#000000\">#{escape_xml(comment.text)}</text>"
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
      ref_width = 20.236225
      ref_height = 36.561409
      
      # Preserve aspect ratio by using the minimum scale
      scale_val = [SVG_ENTITY_WIDTH / ref_width, SVG_ENTITY_HEIGHT / ref_height].min
      
      # Calculate centering offsets
      offset_x = (SVG_ENTITY_WIDTH - ref_width * scale_val) / 2.0
      offset_y = (SVG_ENTITY_HEIGHT - ref_height * scale_val) / 2.0

      # Build nested g elements for explicit transform order
      lines = []

      # Outermost: Center within the entity box
      lines << "<g transform=\"translate(#{offset_x}, #{offset_y})\">"

      # Middle: scale transformation (uniform)
      lines << "  <g transform=\"scale(#{scale_val}, #{scale_val})\">"

      if layer_transform
        # Innermost: layer1's transform (coordinate normalization back to 0,0)
        lines << "    <g transform=\"#{layer_transform}\">"
      end

      # Innermost: content
      content_lines = content.split("\n")
      content_lines.each do |line|
        lines << "      #{line}" if line.strip.length > 0
      end

      if layer_transform
        lines << "    </g>"
      end

      lines << "  </g>"
      lines << "</g>"

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
