# frozen_string_literal: true

require 'base64'

module Bizgram
  class LayoutError < StandardError; end

  # SVG Layout Constants - Compact and centered
  SVG_ENTITY_WIDTH = 120.0
  SVG_ENTITY_HEIGHT = 120.0
  SVG_GRID_SPACING_X = 240.0
  SVG_GRID_SPACING_Y = 240.0
  SVG_PADDING_X = 240.0
  SVG_PADDING_Y = 240.0

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
    attr_reader :id, :name, :type
    attr_accessor :position

    def initialize(id, name, type, position, builder = nil)
      @id = id
      @name = name
      @type = type
      @position = position
      @builder = builder
    end

    def -(other)
      if other.is_a?(PendingArrow)
        HalfArrow.new(@builder, self, other)
      elsif other.is_a?(Entity) && [:money, :object, :information, :info, :other].include?(other.type)
        @builder.remove_entity(other)
        pending = PendingArrow.new(other.type, other.name)
        HalfArrow.new(@builder, self, pending)
      else
        raise ArgumentError, "Expected PendingArrow after '-', got #{other.class}"
      end
    end
  end

  class PendingArrow
    attr_reader :type, :name
    def initialize(type, name)
      @type = type
      @name = name
    end
  end

  class HalfArrow
    def initialize(builder, from, pending_arrow)
      @builder = builder
      @from = from
      @pending_arrow = pending_arrow
    end

    def >(to_entity)
      raise ArgumentError, "Expected Entity after '>', got #{to_entity.class}" unless to_entity.is_a?(Entity)
      @builder.arrow(@pending_arrow.type, @pending_arrow.name, @from, to_entity)
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
        # Skip resolution, it will be assigned later
        nil
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

    def self.auto_assign(entities, occupied_positions, arrows = [])
      unassigned = entities.select { |e| e.position.nil? }
      return if unassigned.empty?

      connections = Hash.new { |h, k| h[k] = [] }
      arrows.each do |arrow|
        connections[arrow.from] << arrow.to
        connections[arrow.to] << arrow.from
      end

      # DFS-based placement
      while unassigned.any?
        placed_ids = entities.reject { |e| e.position.nil? }.map(&:id)
        
        best_candidate = unassigned.max_by do |e|
          connected_to_placed = (connections[e.id] & placed_ids).size
          total_connections = connections[e.id].size
          [connected_to_placed, total_connections]
        end
        
        if placed_ids.empty?
          pos = 4
          if !occupied_positions.include?(pos)
            best_candidate.position = pos
            occupied_positions.add(pos)
            unassigned.delete(best_candidate)
            next
          else
            pos = ((0..8).to_a - occupied_positions.to_a).first
            best_candidate.position = pos
            occupied_positions.add(pos)
            unassigned.delete(best_candidate)
            next
          end
        end

        related_placed_ids = (connections[best_candidate.id] & placed_ids)
        best_pos = nil

        if related_placed_ids.empty?
          empty_positions = (0..8).to_a - occupied_positions.to_a
          preferred = [1, 7, 3, 5, 0, 2, 6, 8, 4]
          best_pos = preferred.find { |p| empty_positions.include?(p) }
        else
          best_pos = find_best_adjacent_position(best_candidate, related_placed_ids, entities, occupied_positions)
        end
        
        raise LayoutError, "エンティティの数が9個を超過しているため、自動配置できません。" unless best_pos
        
        best_candidate.position = best_pos
        occupied_positions.add(best_pos)
        unassigned.delete(best_candidate)
      end
    end

    def self.find_best_adjacent_position(entity, related_placed_ids, entities, occupied_positions)
      target_id = related_placed_ids.first
      target_ent = entities.find { |e| e.id == target_id }
      
      dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]]
      
      # 1. 単純に空いているマスを探す
      dirs.each do |dx, dy|
        tx = target_ent.position % 3
        ty = target_ent.position / 3
        nx, ny = tx + dx, ty + dy
        if (0..2).include?(nx) && (0..2).include?(ny)
          pos = ny * 3 + nx
          return pos unless occupied_positions.include?(pos)
        end
      end
      
      # 2. 盤外にはみ出す場合、シフト可能ならシフトする
      dirs.each do |dx, dy|
        tx = target_ent.position % 3
        ty = target_ent.position / 3
        nx, ny = tx + dx, ty + dy
        if nx < 0 && try_shift_grid(1, 0, entities, occupied_positions)
          return ty * 3 + 0
        elsif nx > 2 && try_shift_grid(-1, 0, entities, occupied_positions)
          return ty * 3 + 2
        elsif ny < 0 && try_shift_grid(0, 1, entities, occupied_positions)
          return 0 * 3 + tx
        elsif ny > 2 && try_shift_grid(0, -1, entities, occupied_positions)
          return 2 * 3 + tx
        end
      end
      
      # 3. 隣接マスの斜めを試す
      diag_dirs = [[-1, -1], [1, -1], [-1, 1], [1, 1]]
      diag_dirs.each do |dx, dy|
        tx = target_ent.position % 3
        ty = target_ent.position / 3
        nx, ny = tx + dx, ty + dy
        if (0..2).include?(nx) && (0..2).include?(ny)
          pos = ny * 3 + nx
          return pos unless occupied_positions.include?(pos)
        end
      end
      
      # 4. どこか空いているマスを距離順で返す
      empty_positions = (0..8).to_a - occupied_positions.to_a
      tx = target_ent.position % 3
      ty = target_ent.position / 3
      empty_positions.min_by do |p|
        px = p % 3
        py = p / 3
        (px - tx).abs + (py - ty).abs
      end
    end

    def self.try_shift_grid(dx, dy, entities, occupied_positions)
      placed = entities.reject { |e| e.position.nil? }
      can_shift = placed.all? do |e|
        x = e.position % 3
        y = e.position / 3
        nx = x + dx
        ny = y + dy
        (0..2).include?(nx) && (0..2).include?(ny)
      end
      
      return false unless can_shift
      
      new_occupied = Set.new
      placed.each do |e|
        x = e.position % 3
        y = e.position / 3
        nx = x + dx
        ny = y + dy
        new_pos = ny * 3 + nx
        e.position = new_pos
        new_occupied.add(new_pos)
      end
      
      occupied_positions.clear
      new_occupied.each { |p| occupied_positions.add(p) }
      
      true
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

      if position
        pos = PositionResolver.resolve(position, type, @occupied_positions)
        raise LayoutError, "Position #{pos} is already occupied" if @occupied_positions.include?(pos)
        @occupied_positions.add(pos)
      else
        pos = nil
      end

      id = next_id
      ent = Entity.new(id, name, type, pos, self)
      @entities[name] = ent
      @entities_by_id[id] = ent

      ent
    end

    def remove_entity(ent)
      @entities.delete(ent.name)
      @entities_by_id.delete(ent.id)
      if ent.position
        @occupied_positions.delete(ent.position)
      end
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

    # 新記法用
    def flow(type, name)
      PendingArrow.new(type, name)
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
      raise ArgumentError, "Name must be a string" unless name.is_a?(String)

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
      PositionResolver.auto_assign(@entities_by_id.values, @occupied_positions, @arrows_by_id.values)
      SvgGenerator.new(@entities_by_id, @arrows_by_id, @comments).generate(title)
    end

    private

    def validate_entity_type(type)
      valid_types = [:person, :user, :company, :business, :money, :object, :goods, :information, :info, :smartphone, :device, :store, :shop, :other]
      raise ArgumentError, "Invalid entity type: #{type}" unless valid_types.include?(type)
    end

    def validate_arrow_type(type)
      raise ArgumentError, "Invalid arrow type: #{type}" unless [:object, :goods, :money, :information, :info, :other].include?(type)
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



require 'rexml/document'

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
    object: '#000000',
    goods: '#000000',
    money: '#000000',
    information: '#000000',
    info: '#000000',
    other: '#000000'
  }.freeze

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
    @entity_svg_cache = {}
    @rendered_arrow_lines = []
  end

  def generate(title)
    doc = REXML::Document.new
    doc << REXML::XMLDecl.new("1.0", "UTF-8", "no")

    svg = REXML::Element.new("svg")
    svg.add_attributes({
      "version" => "1.1",
      "viewBox" => "0.0 0.0 #{SVG_CANVAS_WIDTH} #{SVG_CANVAS_HEIGHT}",
      "width" => SVG_CANVAS_WIDTH.to_i.to_s,
      "height" => SVG_CANVAS_HEIGHT.to_i.to_s,
      "xmlns" => "http://www.w3.org/2000/svg"
    })
    doc.add_element(svg)

    title_el = REXML::Element.new("title")
    title_el.text = title
    svg.add_element(title_el)

    # Title Text and Underline
    text_el = REXML::Element.new("text")
    text_el.add_attributes({
      "x" => (SVG_CANVAS_WIDTH / 2.0).to_s,
      "y" => "40",
      "font-size" => "28",
      "font-family" => SVG_FONT_FAMILY,
      "font-weight" => "bold",
      "fill" => "#000000",
      "text-anchor" => "middle",
      "dominant-baseline" => "hanging"
    })
    text_el.text = title
    svg.add_element(text_el)

    line_el = REXML::Element.new("line")
    line_el.add_attributes({
      "x1" => "0", "y1" => "80", "x2" => SVG_CANVAS_WIDTH.to_s, "y2" => "80",
      "stroke" => "#000000", "stroke-width" => "1"
    })
    svg.add_element(line_el)

    # defs
    defs = REXML::Element.new("defs")
    %w[object money information other].each do |m_type|
      marker = REXML::Element.new("marker")
      marker.add_attributes({
        "id" => "marker_#{m_type}", "markerWidth" => "5", "markerHeight" => "3.5",
        "refX" => "5", "refY" => "1.75",
        "orient" => "auto", "markerUnits" => "strokeWidth"
      })
      path = REXML::Element.new("path")
      path.add_attributes({ "d" => "M 0,0 L 5,1.75 L 0,3.5 Z", "fill" => "#000000" })
      marker.add_element(path)
      defs.add_element(marker)
    end
    svg.add_element(defs)

    # Background Grid Lines
    grid = REXML::Element.new("g")
    grid.add_attributes({
      "id" => "background_grid",
      "stroke" => "#cccccc",
      "stroke-width" => "2",
      "stroke-dasharray" => "8,8"
    })
    
    line1 = REXML::Element.new("line")
    y1 = (SVG_GRID_ROWS[0] + SVG_GRID_ROWS[1]) / 2.0
    line1.add_attributes({
      "x1" => (SVG_PADDING_X - 40).to_s, "y1" => y1.to_s,
      "x2" => (SVG_CANVAS_WIDTH - SVG_PADDING_X + 40).to_s, "y2" => y1.to_s
    })
    grid.add_element(line1)

    line2 = REXML::Element.new("line")
    y2 = (SVG_GRID_ROWS[1] + SVG_GRID_ROWS[2]) / 2.0
    line2.add_attributes({
      "x1" => (SVG_PADDING_X - 40).to_s, "y1" => y2.to_s,
      "x2" => (SVG_CANVAS_WIDTH - SVG_PADDING_X + 40).to_s, "y2" => y2.to_s
    })
    render_grid_lines(svg)
    render_entities(svg)
    render_arrows(svg)
    render_comments(svg)

    output = String.new
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true
    formatter.write(doc, output)
    output + "\n"
  end

  private

  def render_grid_lines(parent)
    lines_g = REXML::Element.new("g")
    lines_g.add_attribute("id", "grid_lines")

    [
      SVG_PADDING_Y + SVG_GRID_SPACING_Y / 2.0,
      SVG_PADDING_Y + SVG_GRID_SPACING_Y * 1.5
    ].each do |y|
      line = REXML::Element.new("line")
      line.add_attributes({
        "x1" => "0", "y1" => y.to_s,
        "x2" => SVG_CANVAS_WIDTH.to_s, "y2" => y.to_s,
        "stroke" => "#dddddd", "stroke-width" => "1",
        "stroke-dasharray" => "8,8"
      })
      lines_g.add_element(line)
    end
    
    parent.add_element(lines_g)
  end

  def wrap_text(text, max_width_px, font_size)
    char_width = font_size
    lines = []
    text.split("\n").each do |orig_line|
      curr_line = ""
      orig_line.each_char do |c|
        if (curr_line.length + 1) * char_width > max_width_px
          lines << curr_line unless curr_line.empty?
          curr_line = c
        else
          curr_line += c
        end
      end
      lines << curr_line unless curr_line.empty?
    end
    lines
  end

  def render_entities(parent)
    entities_g = REXML::Element.new("g")
    entities_g.add_attribute("id", "entities")
    
    @entities_by_position.each do |pos, entity|
      x, y = position_to_svg_coords(pos)
      left_x = x - SVG_ENTITY_WIDTH / 2.0
      top_y = y - SVG_ENTITY_HEIGHT / 2.0

      g = REXML::Element.new("g")
      g.add_attribute("id", "entity_#{entity.id}")

      svg_content = load_entity_svg_with_transform(entity.type, left_x, top_y)
      if svg_content
        # Wrap the extracted svg content so we can parse it
        wrapper = REXML::Document.new("<wrapper>#{svg_content}</wrapper>")
        wrapper.root.elements.each do |el|
          g.add_element(el)
        end
      else
        rect = REXML::Element.new("rect")
        rect.add_attributes({
          "x" => left_x.to_s, "y" => top_y.to_s,
          "width" => SVG_ENTITY_WIDTH.to_s, "height" => SVG_ENTITY_HEIGHT.to_s,
          "fill" => "#eeeeee", "stroke" => "#000000", "stroke-width" => "2"
        })
        g.add_element(rect)
      end

      label_y = top_y + SVG_ENTITY_HEIGHT + 8
      text_el = REXML::Element.new("text")
      text_el.add_attributes({
        "x" => x.to_s, "y" => label_y.to_s,
        "font-size" => "14", "font-family" => SVG_FONT_FAMILY,
        "text-anchor" => "middle", "dominant-baseline" => "text-before-edge",
        "fill" => "#000000"
      })
      
      lines = entity.name.split("\n")
      lines.each_with_index do |line_text, idx|
        tspan = REXML::Element.new("tspan")
        tspan.add_attributes({
          "x" => x.to_s,
          "dy" => idx == 0 ? "0" : "16"
        })
        tspan.text = line_text
        text_el.add_element(tspan)
      end
      
      g.add_element(text_el)

      entities_g.add_element(g)
    end
    
    parent.add_element(entities_g)
  end

  class GridMap
    attr_reader :grid

    def initialize(entities)
      @grid = Array.new(7) { Array.new(7) }
      entities.each do |_id, e|
        pos = e.position
        next unless pos
        x = (pos % 3) * 2 + 1
        y = (pos / 3) * 2 + 1
        @grid[y][x] = {type: :entity, id: e.id}
      end
    end

    def place_arrow(path, group_id)
      path.each do |(x, y)|
        # 主体のマスは矢印のマスとしては上書きしない
        next if @grid[y][x] && @grid[y][x][:type] == :entity
        @grid[y][x] = {type: :arrow, group_id: group_id}
      end
    end

    def place_comment(x, y, id)
      @grid[y][x] = {type: :comment, id: id}
    end

    def can_arrow_pass?(x, y, group_id, strict = true)
      return false if x < 0 || x > 6 || y < 0 || y > 6
      cell = @grid[y][x]
      return true if cell.nil?
      return true if strict == :fallback && cell[:type] == :comment
      return false if cell[:type] == :comment
      return true if cell[:type] == :arrow && cell[:group_id] == group_id
      return true if cell[:type] == :arrow && (strict == false || strict == :fallback)
      false
    end

    def can_comment_place?(x, y)
      return false if x < 0 || x > 6 || y < 0 || y > 6
      @grid[y][x].nil?
    end
  end

  class GridMapRouter
    def initialize(grid_map)
      @grid_map = grid_map
    end

    def route_groups(groups)
      results = {}
      
      # 中心に近いエンティティからのルートを優先する等のソート
      sorted_groups = groups.sort_by do |group_id, arrs|
        arr = arrs.first
        dx = (arr.to_pos % 3) - (arr.from_pos % 3)
        dy = (arr.to_pos / 3) - (arr.from_pos / 3)
        (dx.abs + dy.abs)
      end

      sorted_groups.each do |group_id, arrs|
        arr = arrs.first
        path = find_route(arr, group_id)
        @grid_map.place_arrow(path, group_id)
        
        arrs.each do |a|
          if a.from_pos == arr.from_pos
            results[a.id] = simplify_path(path)
          else
            results[a.id] = simplify_path(path.reverse)
          end
        end
      end
      results
    end

    private

    def find_route(arrow, group_id, strict = true)
      start_pos = [(arrow.from_pos % 3) * 2 + 1, (arrow.from_pos / 3) * 2 + 1]
      end_pos = [(arrow.to_pos % 3) * 2 + 1, (arrow.to_pos / 3) * 2 + 1]

      open_set = { [start_pos, nil] => 0 }
      came_from = {}
      g_score = { [start_pos, nil] => 0 }

      until open_set.empty?
        current_state, _ = open_set.min_by { |_, f| f }
        open_set.delete(current_state)

        curr_pos, curr_dir = current_state

        if curr_pos == end_pos
          return reconstruct_path(came_from, current_state)
        end

        neighbors(curr_pos).each do |next_pos|
          # 終点以外の主体マスは通過不可
          if next_pos != end_pos
            cell = @grid_map.grid[next_pos[1]][next_pos[0]]
            next if cell && cell[:type] == :entity
          end

          # その他のマスは占有チェック
          next if next_pos != end_pos && !@grid_map.can_arrow_pass?(next_pos[0], next_pos[1], group_id, strict)

          next_dir = direction(curr_pos, next_pos)
          next if curr_dir && is_opposite?(curr_dir, next_dir)

          is_diagonal = next_dir.to_s.include?('_')
          step_c = is_diagonal ? 21 : 10
          
          # 曲がり角に対するペナルティ
          if curr_dir && curr_dir != next_dir
            was_diagonal = curr_dir.to_s.include?('_')
            if was_diagonal || is_diagonal
              # 直行⇔斜めの混ざり、または斜め⇔斜めの曲がりは強く禁止（純粋な斜め直線のみを許可）
              step_c += 1000
            else
              # 直行⇔直行の曲がり（L字・クランク）は微小ペナルティ
              step_c += 1
            end
          end
          
          # strict=falseや:fallbackの場合の他矢印との交差ペナルティ
          if (strict == false || strict == :fallback) && next_pos != end_pos
            cell = @grid_map.grid[next_pos[1]][next_pos[0]]
            step_c += 1000 if cell && cell[:type] == :arrow && cell[:group_id] != group_id
            step_c += 5000 if cell && cell[:type] == :comment && strict == :fallback
          end

          next_state = [next_pos, next_dir]
          tentative_g = g_score[current_state] + step_c

          if !g_score.key?(next_state) || tentative_g < g_score[next_state]
            came_from[next_state] = current_state
            g_score[next_state] = tentative_g
            f_score = tentative_g + heuristic(next_pos, end_pos)
            open_set[next_state] = f_score
          end
        end
      end

      if strict == true
        # 厳密なチェックで見つからなかった場合は、既存の矢印と交差しても良い（ペナルティあり）として再探索
        return find_route(arrow, group_id, false)
      elsif strict == false
        # 矢印交差を許容しても見つからない場合、コメントも貫通して再探索
        return find_route(arrow, group_id, :fallback)
      end

      # 経路が見つからない場合の最後のフォールバック（直線）
      [start_pos, end_pos]
    end

    def neighbors(pos)
      x, y = pos
      [
        [x + 1, y], [x - 1, y],
        [x, y + 1], [x, y - 1],
        [x + 1, y + 1], [x + 1, y - 1],
        [x - 1, y + 1], [x - 1, y - 1]
      ].select { |nx, ny| nx >= 0 && nx <= 6 && ny >= 0 && ny <= 6 }
    end

    def direction(from, to)
      dx = to[0] - from[0]
      dy = to[1] - from[1]
      
      if dx > 0 && dy == 0
        return :right
      elsif dx < 0 && dy == 0
        return :left
      elsif dx == 0 && dy > 0
        return :down
      elsif dx == 0 && dy < 0
        return :up
      elsif dx > 0 && dy > 0
        return :down_right
      elsif dx > 0 && dy < 0
        return :up_right
      elsif dx < 0 && dy > 0
        return :down_left
      elsif dx < 0 && dy < 0
        return :up_left
      end
    end

    def is_opposite?(d1, d2)
      opposites = {
        right: :left, left: :right, up: :down, down: :up,
        down_right: :up_left, up_left: :down_right,
        up_right: :down_left, down_left: :up_right
      }
      opposites[d1] == d2
    end

    def heuristic(pos, goal)
      dx = (pos[0] - goal[0]).abs
      dy = (pos[1] - goal[1]).abs
      if dx > dy
        21 * dy + 10 * (dx - dy)
      else
        21 * dx + 10 * (dy - dx)
      end
    end

    def reconstruct_path(came_from, current)
      path = [current[0]]
      while came_from.key?(current)
        current = came_from[current]
        path.unshift(current[0])
      end
      path
    end

    def simplify_path(path)
      return path if path.length <= 2
      simplified = [path.first]
      prev_dir = direction(path[0], path[1])
      
      (1...path.length - 1).each do |i|
        curr_dir = direction(path[i], path[i+1])
        if curr_dir != prev_dir
          simplified << path[i]
          prev_dir = curr_dir
        end
      end
      simplified << path.last
      simplified
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

  def render_arrows(parent)
    arrows_g = REXML::Element.new("g")
    arrows_g.add_attribute("id", "arrows")

    router_arrows = @arrows.values.map do |arr|
      from_entity = @entities[arr.from]
      to_entity = @entities[arr.to]
      RouterArrow.new(arr.id, from_entity.position, to_entity.position)
    end

    @grid_map = GridMap.new(@entities)
    
    # 1. 矢印のルーティングを先に決定・予約する
    arrow_groups = {}
    router_arrows.each do |arr|
      group_id = [arr.from_pos, arr.to_pos].sort
      arrow_groups[group_id] ||= []
      arrow_groups[group_id] << arr
    end

    router = GridMapRouter.new(@grid_map)
    routes = router.route_groups(arrow_groups)

    # 2. コメントの配置位置を空きマスに決定・予約する
    @comment_placements = {}
    sorted_comments = @comments.values.sort_by do |comment|
      pos = @entities[comment.to].position
      pos == 4 ? 1 : 0
    end

    sorted_comments.each do |comment|
      target_entity = @entities[comment.to]
      next unless target_entity.position
      
      ex = (target_entity.position % 3) * 2 + 1
      ey = (target_entity.position / 3) * 2 + 1

      all_dirs = [ [-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [1, -1], [-1, 1], [1, 1] ]
      allowed_dirs = all_dirs.sort_by do |dx, dy|
        score = 0
        score += 10 if dx != 0 && dy != 0 # 斜めは優先度を下げる
        score += 2 if dy != 0 && dx == 0  # 上下より左右を優先
        
        is_top_edge = [0, 1, 2].include?(target_entity.position)
        is_bottom_edge = [6, 7, 8].include?(target_entity.position)
        is_left_edge = [0, 3, 6].include?(target_entity.position)
        is_right_edge = [2, 5, 8].include?(target_entity.position)
        
        score += 20 if dy == -1 && is_top_edge
        score += 20 if dy == 1 && is_bottom_edge
        score += 5 if dx == -1 && is_left_edge
        score += 5 if dx == 1 && is_right_edge
        score
      end

      placed = false
      allowed_dirs.each do |dx, dy|
        cx, cy = ex + dx, ey + dy
        if @grid_map.can_comment_place?(cx, cy)
          @grid_map.place_comment(cx, cy, comment.id)
          @comment_placements[comment.id] = [dx, dy]
          placed = true
          break
        end
      end
      
      unless placed
        @comment_placements[comment.id] = [0, 1] # fallback to bottom
      end
    end

    route_groups = {}
    @arrows.each do |_id, arrow|
      path = routes[arrow.id]
      normalized_path = (path.first <=> path.last) < 0 ? path : path.reverse
      route_groups[normalized_path] ||= []
      route_groups[normalized_path] << arrow
    end

    terminal_groups = {}
    @arrows.values.each do |arrow|
      path = routes[arrow.id]
      next if path.length < 2
      
      # Start terminal (leaving)
      seg_start = [path[0], path[1]]
      v1 = [path[1][0] - path[0][0], path[1][1] - path[0][1]]
      if path.length >= 3
        v2 = [path[2][0] - path[1][0], path[2][1] - path[1][1]]
        cp = v1[0]*v2[1] - v1[1]*v2[0]
      else
        cp = 0
      end
      terminal_groups[seg_start] ||= []
      terminal_groups[seg_start] << { arrow: arrow, cp: cp, type: :leaving }
      
      # End terminal (entering)
      seg_end = [path[-1], path[-2]] # oriented OUTWARD
      v1_end = [path[-2][0] - path[-1][0], path[-2][1] - path[-1][1]]
      if path.length >= 3
        v2_end = [path[-3][0] - path[-2][0], path[-3][1] - path[-2][1]]
        cp_end = v1_end[0]*v2_end[1] - v1_end[1]*v2_end[0]
      else
        cp_end = 0
      end
      terminal_groups[seg_end] ||= []
      terminal_groups[seg_end] << { arrow: arrow, cp: cp_end, type: :entering }
    end

    suggested_offsets = {}
    @arrows.values.each { |a| suggested_offsets[a.id] = [] }

    terminal_groups.each do |seg, items|
      items.sort_by! do |item|
        id_key = item[:type] == :leaving ? item[:arrow].id : -item[:arrow].id
        [item[:cp], item[:type] == :leaving ? 0 : 1, id_key]
      end
      n = items.length
      items.each_with_index do |item, idx|
        base_offset = (idx - (n - 1) / 2.0) * 35.0
        global_offset = item[:type] == :entering ? -base_offset : base_offset
        suggested_offsets[item[:arrow].id] << global_offset
      end
    end

    final_offsets = {}
    suggested_offsets.each do |id, offsets|
      final_offsets[id] = offsets.empty? ? 0.0 : offsets.sum / offsets.length.to_f
    end

    route_groups.each do |normalized_path, arrows_in_group|
      arrows_in_group.each_with_index do |arrow, index|
        grid_path = routes[arrow.id]
        offset = final_offsets[arrow.id] || 0.0
        
        svg_points = grid_path.map { |pt| svg_coords_from_grid(pt[0], pt[1]) }
        
        if svg_points.length >= 2
          adjust_to_edge(svg_points[0], svg_points[1], true)
          adjust_to_edge(svg_points[-1], svg_points[-2], false)
        end
        
        shifted_points = apply_offset_to_path(svg_points, offset)
        
        shifted_points.each_cons(2) do |a, b|
          @rendered_arrow_lines << {
            x1: [a[0], b[0]].min - 10, y1: [a[1], b[1]].min - 10,
            x2: [a[0], b[0]].max + 10, y2: [a[1], b[1]].max + 10
          }
        end

        color = ARROW_COLORS[arrow.type]
        marker_id = "marker_#{arrow.type}"

        path_data = "M #{shifted_points.first[0]},#{shifted_points.first[1]} "
        shifted_points[1..-1].each do |pt|
          path_data += "L #{pt[0]},#{pt[1]} "
        end

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
        marker_x = label_x
        marker_y = label_y

        dx = best_p2[0] - best_p1[0]
        dy = best_p2[1] - best_p1[1]
        
        text_anchor = "middle"
        if dx != 0 && dy != 0 && dx.abs == dy.abs # 斜め
          label_x += (dx > 0 ? -1 : 1) * 20
          label_y += (dy > 0 ? -1 : 1) * 20
        elsif dx.abs < dy.abs # 縦
          actual_shift_x = (dy > 0 ? -1 : 1) * offset
          if actual_shift_x < 0
            label_x -= 16
            text_anchor = "end"
          else
            label_x += 16
            text_anchor = "start"
          end
          label_y += 5
        else # 横
          actual_shift_y = (dx > 0 ? 1 : -1) * offset
          if actual_shift_y > 0
            label_y += 26
          else
            label_y -= 16
          end
        end

        g = REXML::Element.new("g")
        g.add_attribute("id", "arrow_#{arrow.id}")

        path_el = REXML::Element.new("path")
        path_el.add_attributes({
          "d" => path_data.strip,
          "stroke" => color, "stroke-width" => SVG_ARROW_STROKE_WIDTH.to_s,
          "fill" => "none", "stroke-linejoin" => "round",
          "marker-end" => "url(##{marker_id})"
        })
        g.add_element(path_el)

        if arrow.name && !arrow.name.empty?
          text_el = REXML::Element.new("text")
          text_el.add_attributes({
            "x" => label_x.to_s, "y" => label_y.to_s,
            "font-size" => "16", "font-family" => SVG_FONT_FAMILY,
            "fill" => "#000000", "text-anchor" => text_anchor
          })
          
          lines = arrow.name.split("\n")
          lines.each_with_index do |line_text, idx|
            tspan = REXML::Element.new("tspan")
            tspan.add_attributes({
              "x" => label_x.to_s,
              "dy" => idx == 0 ? "0" : "18"
            })
            tspan.text = line_text
            text_el.add_element(tspan)
          end
          
          g.add_element(text_el)
        end
        
        case arrow.type
        when :money
          rect_el = REXML::Element.new("rect")
          rect_el.add_attributes({
            "x" => (marker_x - 14).to_s, "y" => (marker_y - 14).to_s,
            "rx" => "6", "ry" => "6", "width" => "28", "height" => "28",
            "fill" => "#fffc41", "stroke" => "#000000", "stroke-width" => "2"
          })
          g.add_element(rect_el)
          
          sym_el = REXML::Element.new("text")
          sym_el.add_attributes({
            "x" => marker_x.to_s, "y" => (marker_y + 5).to_s,
            "font-size" => "16", "font-family" => SVG_FONT_FAMILY,
            "font-weight" => "bold", "fill" => "#000000", "text-anchor" => "middle"
          })
          sym_el.text = "￥"
          g.add_element(sym_el)
        when :object, :goods
          circle_el = REXML::Element.new("circle")
          circle_el.add_attributes({
            "cx" => marker_x.to_s, "cy" => marker_y.to_s,
            "r" => "14", "fill" => "#d4fca9", "stroke" => "#000000", "stroke-width" => "2"
          })
          g.add_element(circle_el)
        when :information, :info
          rect_el = REXML::Element.new("rect")
          rect_el.add_attributes({
            "x" => (marker_x - 13).to_s, "y" => (marker_y - 13).to_s,
            "width" => "26", "height" => "26",
            "fill" => "#cbecfa", "stroke" => "#000000", "stroke-width" => "2"
          })
          g.add_element(rect_el)
        end

        arrows_g.add_element(g)
      end
    end
    
    parent.add_element(arrows_g)
  end

  def svg_coords_from_grid(x, y)
    # 7x7 grid mapping (x, y in 0..6, entities at 1,3,5)
    cx = SVG_PADDING_X + ((x - 1) / 4.0) * (SVG_CANVAS_WIDTH - 2 * SVG_PADDING_X)
    cy = SVG_PADDING_Y + ((y - 1) / 4.0) * (SVG_CANVAS_HEIGHT - 2 * SVG_PADDING_Y)
    [cx, cy]
  end

  def adjust_to_edge(pt, neighbor, is_start)
    dx = neighbor[0] - pt[0]
    dy = neighbor[1] - pt[1]
    
    if dx != 0 && dy != 0 && dx.abs == dy.abs # 斜め
      pt[0] += (dx > 0 ? 1 : -1) * SVG_ENTITY_WIDTH / 2.0
      pt[1] += (dy > 0 ? 1 : -1) * SVG_ENTITY_HEIGHT / 2.0
    elsif dx.abs > dy.abs
      if dx > 0
        pt[0] += SVG_ENTITY_WIDTH / 2.0
      else
        pt[0] -= SVG_ENTITY_WIDTH / 2.0
      end
    else
      if dy > 0
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
        norm = Math.sqrt(dx**2 + dy**2)
        shifted << [p[0] - (dy/norm)*offset, p[1] + (dx/norm)*offset]
      elsif i == points.length - 1
        p_prev = points[i-1]
        dx = p[0] - p_prev[0]
        dy = p[1] - p_prev[1]
        norm = Math.sqrt(dx**2 + dy**2)
        shifted << [p[0] - (dy/norm)*offset, p[1] + (dx/norm)*offset]
      else
        p_prev = points[i-1]
        p_next = points[i+1]
        
        dx1 = p[0] - p_prev[0]
        dy1 = p[1] - p_prev[1]
        dx2 = p_next[0] - p[0]
        dy2 = p_next[1] - p[1]
        
        norm1 = Math.sqrt(dx1**2 + dy1**2)
        s1x = -(dy1/norm1)*offset
        s1y = (dx1/norm1)*offset
        
        norm2 = Math.sqrt(dx2**2 + dy2**2)
        s2x = -(dy2/norm2)*offset
        s2y = (dx2/norm2)*offset
        
        denom = dx2 * dy1 - dy2 * dx1
        if denom == 0
          shifted << [p[0] + s1x, p[1] + s1y]
        else
          t2 = ((s2y - s1y) * dx1 - (s2x - s1x) * dy1) / denom.to_f
          shifted << [p[0] + s2x + t2 * dx2, p[1] + s2y + t2 * dy2]
        end
      end
    end
    shifted
  end

  def render_comments(parent)
    return if @comments.empty?

    comments_g = REXML::Element.new("g")
    comments_g.add_attribute("id", "comments")

    # 中心から遠い主体（周辺）のコメントを先に配置し、中央（4）を最後にする
    sorted_comments = @comments.values.sort_by do |comment|
      pos = @entities[comment.to].position
      pos == 4 ? 1 : 0
    end

    sorted_comments.each do |comment|
      target_entity = @entities[comment.to]
      target_center_x, target_center_y = position_to_svg_coords(target_entity.position)
      
      placement = @comment_placements[comment.id] || [0, 1]
      dx, dy = placement[0], placement[1]

      ex = (target_entity.position % 3) * 2 + 1
      ey = (target_entity.position / 3) * 2 + 1
      cx, cy = ex + dx, ey + dy

      is_outer_x = (cx == 0 || cx == 6)

      if cy == 0 || cy == 6
        max_width_px = 240 # 最上部・最下部は高さを抑えるため幅を広く許可
      elsif dx != 0
        max_width_px = is_outer_x ? 140 : 100
      else
        max_width_px = 160
      end

      lines = wrap_text(comment.text, max_width_px, 14)
      
      longest_line = lines.map(&:length).max || 0
      comment_width = [longest_line * 14 + 20, 60].max
      comment_height = [lines.length * 20 + 20, 40].max

      if dx == -1
        comment_x = target_center_x - SVG_ENTITY_WIDTH / 2.0 - comment_width - 10
      elsif dx == 1
        comment_x = target_center_x + SVG_ENTITY_WIDTH / 2.0 + 10
      else
        comment_x = target_center_x - comment_width / 2.0
      end

      if dy == -1
        comment_y = target_center_y - SVG_ENTITY_HEIGHT / 2.0 - comment_height - 10
        if cy == 0 && comment_y < 90
          comment_y = 90 # タイトル下に強制配置して被りを防ぐ
        end
      elsif dy == 1
        comment_y = target_center_y + SVG_ENTITY_HEIGHT / 2.0 + 35
      else
        comment_y = target_center_y - comment_height / 2.0
      end

      if dx == 1
        dir = dy == -1 ? :top_right : (dy == 1 ? :bottom_right : :right)
      elsif dx == -1
        dir = dy == -1 ? :top_left : (dy == 1 ? :bottom_left : :left)
      else
        dir = dy == -1 ? :top : :bottom
      end

      g = REXML::Element.new("g")
      g.add_attribute("id", "comment_#{comment.id}")
      
      box_el = REXML::Element.new("rect")
      box_el.add_attributes({
        "x" => comment_x.to_s, "y" => comment_y.to_s,
        "width" => comment_width.to_s, "height" => comment_height.to_s,
        "rx" => "5", "ry" => "5",
        "fill" => "#dddddd", "stroke" => "none"
      })
      g.add_element(box_el)
      
      tail_el = REXML::Element.new("polygon")
      if dir == :right
        pts = "#{comment_x},#{comment_y + 10} #{comment_x - 10},#{comment_y + 20} #{comment_x},#{comment_y + 30}"
      elsif dir == :left
        pts = "#{comment_x + comment_width},#{comment_y + 10} #{comment_x + comment_width + 10},#{comment_y + 20} #{comment_x + comment_width},#{comment_y + 30}"
      elsif dir == :top
        pts = "#{comment_x + comment_width/2 - 10},#{comment_y + comment_height} #{comment_x + comment_width/2},#{comment_y + comment_height + 10} #{comment_x + comment_width/2 + 10},#{comment_y + comment_height}"
      elsif dir == :bottom
        pts = "#{comment_x + comment_width/2 - 10},#{comment_y} #{comment_x + comment_width/2},#{comment_y - 10} #{comment_x + comment_width/2 + 10},#{comment_y}"
      elsif dir == :top_right
        bx1 = comment_x
        by1 = comment_y + comment_height - 15
        bx2 = comment_x + 15
        by2 = comment_y + comment_height
        tx = bx1 + (target_center_x - bx1) * 0.5
        ty = by2 + (target_center_y - by2) * 0.5
        pts = "#{bx1},#{by1} #{tx},#{ty} #{bx2},#{by2}"
      elsif dir == :top_left
        bx1 = comment_x + comment_width - 15
        by1 = comment_y + comment_height
        bx2 = comment_x + comment_width
        by2 = comment_y + comment_height - 15
        tx = bx2 + (target_center_x - bx2) * 0.5
        ty = by1 + (target_center_y - by1) * 0.5
        pts = "#{bx1},#{by1} #{tx},#{ty} #{bx2},#{by2}"
      elsif dir == :bottom_right
        bx1 = comment_x
        by1 = comment_y + 15
        bx2 = comment_x + 15
        by2 = comment_y
        tx = bx1 + (target_center_x - bx1) * 0.5
        ty = by2 + (target_center_y - by2) * 0.5
        pts = "#{bx1},#{by1} #{tx},#{ty} #{bx2},#{by2}"
      elsif dir == :bottom_left
        bx1 = comment_x + comment_width - 15
        by1 = comment_y
        bx2 = comment_x + comment_width
        by2 = comment_y + 15
        tx = bx2 + (target_center_x - bx2) * 0.5
        ty = by1 + (target_center_y - by1) * 0.5
        pts = "#{bx1},#{by1} #{tx},#{ty} #{bx2},#{by2}"
      end
      tail_el.add_attributes("points" => pts, "fill" => "#dddddd")
      g.add_element(tail_el)
      
      text_el = REXML::Element.new("text")
      text_el.add_attributes({
        "x" => (comment_x + comment_width / 2.0).to_s, 
        "y" => (comment_y + 20).to_s,
        "font-size" => "14", "font-family" => SVG_FONT_FAMILY,
        "text-anchor" => "middle", "fill" => "#000000"
      })
      
      lines.each_with_index do |line_text, idx|
        tspan = REXML::Element.new("tspan")
        tspan.add_attributes({
          "x" => (comment_x + comment_width / 2.0).to_s,
          "dy" => idx == 0 ? "0" : "20"
        })
        tspan.text = line_text
        text_el.add_element(tspan)
      end
      
      g.add_element(text_el)
      
      comments_g.add_element(g)
    end
    
    parent.add_element(comments_g)
  end

  def position_to_svg_coords(position)
    row = position / 3
    col = position % 3
    x = SVG_GRID_COLS[col]
    y = SVG_GRID_ROWS[row]
    [x, y]
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

    # Use g transform
    "<g transform=\"translate(#{x}, #{y})\">#{svg_content}</g>"
  end

  def extract_svg_content(svg_path)
    content = File.read(svg_path)

    if content.match(%r{<g\s+[^>]*id="layer1"[^>]*>(.*)</g>}m)
      layer_content = Regexp.last_match(1).strip

      layer_transform = nil
      if content.match(%r{<g\s+[^>]*id="layer1"[^>]*transform="([^"]*)"[^>]*>}m)
        layer_transform = Regexp.last_match(1)
      end

      layer_content = layer_content.gsub(/\s+inkscape:[^=]*="[^"]*"/, '')
      layer_content = layer_content.gsub(/\s+sodipodi:[^=]*="[^"]*"/, '')

      scale_svg_content(layer_content, layer_transform)
    else
      nil
    end
  end

  def scale_svg_content(content, layer_transform = nil)
    ref_width = 20.236225
    ref_height = 36.561409
    
    scale_val = [SVG_ENTITY_WIDTH / ref_width, SVG_ENTITY_HEIGHT / ref_height].min
    
    offset_x = (SVG_ENTITY_WIDTH - ref_width * scale_val) / 2.0
    offset_y = (SVG_ENTITY_HEIGHT - ref_height * scale_val) / 2.0

    # Wrap correctly
    result = "<g transform=\"translate(#{offset_x}, #{offset_y})\">"
    result += "<g transform=\"scale(#{scale_val}, #{scale_val})\">"
    if layer_transform
      result += "<g transform=\"#{layer_transform}\">"
    end
    result += content
    if layer_transform
      result += "</g>"
    end
    result += "</g></g>"
    result
  end
end
  def self.draw(title, &block)
    builder = Builder.new
    builder.instance_eval(&block)
    builder.to_svg(title)
  end
end
