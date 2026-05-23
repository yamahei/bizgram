# frozen_string_literal: true

require 'base64'

module Bizgram
  class LayoutError < StandardError; end

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

      connections = Hash.new(0)
      arrows.each do |arrow|
        connections[arrow.from] += 1
        connections[arrow.to] += 1
      end

      business_types = [:company, :business, :operator, :store]
      unassigned.sort_by! do |e|
        deg = connections[e.id]
        is_biz = business_types.include?(e.type) ? 1 : 0
        [-deg, -is_biz, e.id]
      end

      if !occupied_positions.include?(4) && !unassigned.empty?
        center_entity = unassigned.shift
        center_entity.position = 4
        occupied_positions.add(4)
      end

      empty_positions = (0..8).to_a - occupied_positions.to_a
      
      unassigned.each do |e|
        related_placed_ids = arrows.select { |a| a.from == e.id || a.to == e.id }
                                   .map { |a| a.from == e.id ? a.to : a.from }
                                   .uniq
                                   .select { |id| entities.find { |ent| ent.id == id }&.position }
        
        best_pos = nil
        if related_placed_ids.empty?
          preferred = [1, 7, 3, 5, 0, 2, 6, 8]
          best_pos = preferred.find { |p| empty_positions.include?(p) }
        else
          best_pos = empty_positions.min_by do |p|
            px, py = p % 3, p / 3
            sum_dist = 0
            related_placed_ids.each do |r_id|
              r_ent = entities.find { |ent| ent.id == r_id }
              rx, ry = r_ent.position % 3, r_ent.position / 3
              sum_dist += (px - rx).abs + (py - ry).abs
            end
            sum_dist
          end
        end
        
        raise LayoutError, "エンティティの数が9個を超過しているため、自動配置できません。" unless best_pos
        
        e.position = best_pos
        occupied_positions.add(best_pos)
        empty_positions.delete(best_pos)
      end
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
        "id" => "marker_#{m_type}",
        "markerWidth" => "10", "markerHeight" => "10",
        "refX" => "9", "refY" => "3",
        "orient" => "auto", "markerUnits" => "strokeWidth"
      })
      path = REXML::Element.new("path")
      path.add_attributes({ "d" => "M 0,0 L 10,3 L 0,6 Z", "fill" => "#000000" })
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
    grid.add_element(line2)
    svg.add_element(grid)

    render_entities(svg)
    render_arrows(svg)
    render_comments(svg)

    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    output = String.new
    formatter.write(doc, output)
    output + "\n"
  end

  private

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
        "fill" => "#000000", "word-spacing" => "0", "letter-spacing" => "0",
        "style" => "white-space: pre-wrap; word-wrap: break-word;"
      })
      text_el.text = entity.name
      g.add_element(text_el)

      entities_g.add_element(g)
    end
    
    parent.add_element(entities_g)
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

      path = bfs_route(arrow, gx1, gy1, gx2, gy2, true)
      path = bfs_route(arrow, gx1, gy1, gx2, gy2, false) if path.nil?
      
      raise "Error: 仕様可能なルートがありません (from: #{arrow.from_pos}, to: #{arrow.to_pos})" if path.nil?
      path
    end

    def bfs_route(arrow, gx1, gy1, gx2, gy2, avoid_intersection)
      require 'set'
      queue = [ [[gx1, gy1]] ]
      visited = Set.new([[gx1, gy1]])
      
      while !queue.empty?
        path = queue.shift
        curr_x, curr_y = path.last
        
        return path if curr_x == gx2 && curr_y == gy2
        
        dirs = [[0, 1], [0, -1], [1, 0], [-1, 0]]
        if path.length > 1
          prev_dx = curr_x - path[-2][0]
          prev_dy = curr_y - path[-2][1]
          dirs.sort_by! { |d| d == [prev_dx, prev_dy] ? 0 : 1 }
        end
        
        dirs.each do |dx, dy|
          nx, ny = curr_x + dx, curr_y + dy
          next if nx < 0 || nx > 4 || ny < 0 || ny > 4
          next if visited.include?([nx, ny])
          
          if nx.even? && ny.even?
            is_target = (nx == gx2 && ny == gy2)
            if !is_target
              pos = (ny / 2) * 3 + (nx / 2)
              next if @entities_by_position.key?(pos)
            end
          end
          
          if avoid_intersection
            intersect = false
            @routed_paths.each do |routed|
              r_pair = [routed[:arrow].from_pos, routed[:arrow].to_pos].sort
              my_pair = [arrow.from_pos, arrow.to_pos].sort
              next if my_pair == r_pair
              
              if routed[:path].include?([nx, ny])
                unless (nx == gx1 && ny == gy1) || (nx == gx2 && ny == gy2)
                  intersect = true
                  break
                end
              end
            end
            next if intersect
          end
          
          visited.add([nx, ny])
          queue << (path + [[nx, ny]])
        end
      end
      nil
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

    router = GridRouter.new(@entities_by_position)
    routes = router.route_all(router_arrows)

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
        is_reversed = (from_entity.position != pair[0])
        
        offset = (index - (arrows_in_group.length - 1) / 2.0) * 25.0
        offset = -offset if is_reversed
        
        grid_path = routes[arrow.id]
        svg_points = grid_path.map { |pt| svg_coords_from_grid(pt[0], pt[1]) }
        
        if svg_points.length >= 2
          adjust_to_edge(svg_points[0], svg_points[1], true)
          adjust_to_edge(svg_points[-1], svg_points[-2], false)
        end
        
        shifted_points = apply_offset_to_path(svg_points, offset)

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
        is_vertical_segment = (best_p1[0] - best_p2[0]).abs < (best_p1[1] - best_p2[1]).abs

        text_anchor = "middle"
        if is_vertical_segment
          dy = best_p2[1] - best_p1[1]
          actual_shift_x = (dy > 0 ? -1 : 1) * offset
          if actual_shift_x < 0
            label_x -= 16
            text_anchor = "end"
          else
            label_x += 16
            text_anchor = "start"
          end
          label_y += 5
        else
          dx = best_p2[0] - best_p1[0]
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
            "fill" => "#000000", "text-anchor" => text_anchor,
            "style" => "white-space: pre-wrap; word-wrap: break-word;"
          })
          text_el.text = arrow.name
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

  def render_comments(parent)
    return if @comments.empty?

    comments_g = REXML::Element.new("g")
    comments_g.add_attribute("id", "comments")

    @comments.each do |_id, comment|
      target_entity = @entities[comment.to]
      target_center_x, target_center_y = position_to_svg_coords(target_entity.position)
      target_top_y = target_center_y - SVG_ENTITY_HEIGHT / 2.0

      comment_width = [comment.text.length * 14 + 20, 80].max
      comment_height = 40

      comment_x = target_center_x + 10
      comment_y = target_top_y - 70
      comment_box_center_x = comment_x + comment_width / 2.0
      comment_box_center_y = comment_y + comment_height / 2.0

      tail_width = 16
      tail_height = 16
      cx = comment_box_center_x
      cy = comment_y + comment_height
      
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

      g = REXML::Element.new("g")
      g.add_attribute("id", "comment_#{comment.id}")
      
      path_el = REXML::Element.new("path")
      path_el.add_attributes({
        "d" => path_d,
        "fill" => "#dddddd",
        "stroke" => "none"
      })
      g.add_element(path_el)
      
      text_el = REXML::Element.new("text")
      text_el.add_attributes({
        "x" => comment_box_center_x.to_s, "y" => comment_box_center_y.to_s,
        "font-size" => "14", "font-family" => SVG_FONT_FAMILY,
        "text-anchor" => "middle", "dominant-baseline" => "middle",
        "fill" => "#000000"
      })
      text_el.text = comment.text
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
