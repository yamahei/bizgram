require 'ripper'

module Bizgram
  class ValidationError < StandardError; end

  class Validator
    # 許可されたシンタックスノードのリスト
    ALLOWED_NODES = %i[
      program
      assign
      var_field
      var_ref
      vcall
      fcall
      command
      method_add_arg
      args_add_block
      arg_paren
      @ident
      string_literal
      string_content
      @tstring_content
      symbol_literal
      symbol
      binary
      array
      @int
      unary
      comment
      void_stmt
      method_add_block
      call
      @const
      brace_block
      do_block
      bodystmt
      block_var
      params
      ident
    ].freeze

    def self.validate!(dsl_string)
      ast = Ripper.sexp(dsl_string)
      raise ValidationError, "Syntax error or empty code" if ast.nil?

      new.validate_ast(ast)
    end

    def validate_ast(ast)
      unless ast[0] == :program
        raise ValidationError, "Invalid root node"
      end

      stmts = ast[1]
      if stmts.nil? || stmts.empty?
        raise ValidationError, "Empty program"
      end

      # トップレベルには Bizgram.draw do ... end (または空行・コメント) しか許可しない
      has_draw_block = false

      stmts.each do |stmt|
        type = stmt[0]
        if type == :void_stmt || type == :comment
          next
        elsif type == :method_add_block
          if has_draw_block
            raise ValidationError, "Only a single Bizgram.draw block is allowed"
          end
          validate_root_statement(stmt)
          has_draw_block = true
        else
          raise ValidationError, "Top level must be a Bizgram.draw block (found #{type})"
        end
      end

      unless has_draw_block
        raise ValidationError, "Missing Bizgram.draw block"
      end
    end

    private

    def allowed_methods
      @allowed_methods ||= Bizgram::Builder.public_instance_methods(false).map(&:to_s)
    end

    def validate_root_statement(node)
      # node is [:method_add_block, call_node, block_node]
      call_node = node[1]
      block_node = node[2]

      if call_node[0] == :method_add_arg
        # Bizgram.draw("title")
        actual_call = call_node[1]
        args_node = call_node[2]
        validate_call_is_bizgram_draw(actual_call)
        validate_node(args_node)
      else
        # Bizgram.draw (no arguments)
        validate_call_is_bizgram_draw(call_node)
      end

      validate_block(block_node)
    end

    def validate_call_is_bizgram_draw(node)
      unless node[0] == :call
        raise ValidationError, "Top level must be Bizgram.draw"
      end

      receiver = node[1]
      method = node[3]

      is_bizgram_receiver = false
      if receiver[0] == :var_ref && receiver[1][0] == :@const && receiver[1][1] == "Bizgram"
        is_bizgram_receiver = true
      end

      unless is_bizgram_receiver
        raise ValidationError, "Top level receiver must be Bizgram"
      end

      unless method[0] == :@ident && method[1] == "draw"
        raise ValidationError, "Top level method must be draw"
      end
    end

    def validate_block(node)
      type = node[0]
      unless [:do_block, :brace_block].include?(type)
        raise ValidationError, "Expected a block for Bizgram.draw"
      end

      # ブロック引数 (例: |title|) がある場合
      block_var_node = node[1]
      if block_var_node && block_var_node[0] == :block_var
        # ブロック引数は許可
      end

      bodystmt = node.find { |n| n.is_a?(Array) && n[0] == :bodystmt }
      return unless bodystmt

      stmts = bodystmt[1]
      stmts.each do |stmt|
        validate_node(stmt)
      end
    end

    def validate_node(node)
      return if node.nil? || !node.is_a?(Array)
      return if node.empty?

      type = node[0]

      unless ALLOWED_NODES.include?(type)
        raise ValidationError, "Unauthorized syntax node: #{type}"
      end

      case type
      when :void_stmt, :@tstring_content, :@int, :@ident, :@const, :comment
        # OK (leaf nodes)
      when :string_content
        node[1..-1].each do |child|
          unless child.is_a?(Array) && child[0] == :@tstring_content
            raise ValidationError, "String interpolation (\#{...}) is not allowed"
          end
        end
      when :string_literal, :symbol_literal, :symbol, :arg_paren
        validate_node(node[1]) if node[1]
      when :var_field
        validate_node(node[1])
      when :vcall, :var_ref
        ident = node[1]
        if type == :vcall && ident && ident[0] == :@ident
          name = ident[1]
          unless allowed_methods.include?(name)
            raise ValidationError, "Unauthorized method call: #{name}"
          end
        end
      when :fcall, :command
        ident = node[1]
        name = ident[1]
        unless allowed_methods.include?(name)
          raise ValidationError, "Unauthorized method call: #{name}"
        end
        node[2..-1].each { |child| validate_node(child) }
      when :method_add_arg
        validate_node(node[1])
        validate_node(node[2])
      when :args_add_block
        node[1].each { |child| validate_node(child) } if node[1]
        validate_node(node[2]) if node[2]
      when :assign
        validate_node(node[1])
        validate_node(node[2])
      when :binary
        op = node[2]
        unless [:-, :>].include?(op)
          raise ValidationError, "Unauthorized binary operator: #{op}"
        end
        validate_node(node[1])
        validate_node(node[3])
      when :array
        if node[1]
          node[1].each { |child| validate_node(child) }
        end
      when :unary
        op = node[1]
        unless [:-].include?(op)
          raise ValidationError, "Unauthorized unary operator: #{op}"
        end
        validate_node(node[2])
      when :call
        # トップレベルのBizgram.draw以外のレシーバ付き呼び出しはすべて禁止
        raise ValidationError, "Receiver-based method calls are not allowed"
      end
    end
  end
end
