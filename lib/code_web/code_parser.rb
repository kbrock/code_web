require 'ruby_parser'

module CodeWeb
  class CodeParser
    extend Forwardable
    SPACES = Hash.new {|h, n| h[n] = "  " * n.to_i }

    attr_accessor :method_cache
    attr_accessor :file_count
    attr_accessor :exit_on_error
    attr_accessor :debug
    attr_accessor :verbose
    def verbose? ; @verbose ; end
    def debug? ; @debug ; end
    def_delegators :@method_cache, :method_regex=, :arg_regex=, :arg_regex, :method_calls

    def initialize
      @cur_method=[]
      @indent = 0
      @file_count = 0
      @exit_on_error = false
      @method_cache = CodeWeb::MethodCache.new
    end

    def traverse(ast, has_yield=false)
      puts "#{spaces}||#{collapse_ast(ast,1)}||" if verbose?
      puts src if ast.nil?
      case ast.node_type
      #dstr = define string ("abc#{here}"),
      #evstr evaluate string (#{HERE})
      #attrasgn = attribute assignment
      when :block, :lambda, :if, :ensure, :rescue, :case, :when, :begin,
           :while, :until, :defined, :resbody, :match2, :match3, :dot2, :dot3,
           :dstr, :evstr, :dsym, :dregx, :hash, :array, :return, :and, :or,
           :next, :to_ary, :splat, :block_pass, :until, :yield,
           /asgn/, :ivar, :arglist, :args, :kwarg, :kwargs, :kwsplat, :zsuper, :not, #statements[]
           :super, :xstr, :for, :until, :dxstr, 
      #these end up being no-ops:
           :lit, :lvar, :const, :str, :nil, :gvar, :back_ref,
           :true, :false, :colon2, :colon3, :next, :alias,
           :nth_ref, :sclass, :cvdecl, :break, :retry, :undef,
      #random
           :svalue, :cvar
        traverse_nodes(ast, 1..-1)
      when :self
        traverse_nodes(ast, 1..-1)
      when :module, #name, statements[]
           :class #name, parent, statements[]
        in_context ast[1], true, true do
          traverse_nodes(ast, 2..-1)
        end
      when :cdecl, #name, statements[]
           :defn #name, args[], call[]
        in_context ast[1], true do
          traverse_nodes(ast, 2..-1)
        end
      when :defs #self[], name, args[], call[] # static method
        in_context ast[2], :static do
          traverse_nodes(ast, 2..-1)
        end
      when :iter #call[], yield_args[], yield_{block|call}[]
        traverse(ast[1], :has_yield)
        in_context 'yield', true do
          traverse_nodes(ast, 2..-1)
        end
      when :call, :safe_call # object, statement? || const symbol, args
        handle_method_call(ast, has_yield)
        traverse_nodes(ast, 1..-1)
      else
        STDERR.puts "#{src}\n  unknown node: #{ast.node_type} #{collapse_ast(ast,1)}"
        if exit_on_error
          if defined?(Pry)
            binding.pry
          elsif defined?(Byebug)
            byebug
          end
          raise "error"
        end
        traverse_nodes(ast, 1..-1)
      end
    end

    def traverse_nodes(ast, *ranges)
      ranges = [0..-1] if ranges.empty?
      ranges.each do |range|
        ast[range].each do |node|
          should_call = node.is_a?(Sexp)
          traverse(node) if should_call
        end
      end
    end

    def handle_method_call(ast, is_yield=false)
      method_name = method_name_from_ast(ast[1..2])
      args = ast[3..-1].map {|arg| collapse_ast(arg,1)}

      mc = MethodCall.new(ast.file, ast.line, method_name, args, is_yield)
      method_cache << mc
      puts mc.to_s(spaces) if debug? # && method_cache.detect?(mc)
    end

    def method_name_from_ast(ast)
      ast.map { |node|
        collapse_ast(node)
      }.compact
    end

    #TODO: add collapse_ast
    # this one creates the true classes, not the string versions
    # (so don't add double quotes, or do 'nil')
    def collapse_ast(ast, max=20)
      if ast.is_a?(Sexp)
        if static?
          ast = ast.gsub(Sexp.new(:self), Sexp.new(:const, self_name))
        else
          ast = ast.gsub(Sexp.new(:call, Sexp.new(:self),:class), Sexp.new(:const, self_name))
        end
        case ast.node_type
        when :hash #name, value, name, value, ...
          if ast[1].is_a?(Sexp) && ast[1].node_type == :kwsplat
            ast[1..-1].map { |i| collapse_ast(i) }
          else
            Hash[*ast[1..-1].map { |i| collapse_ast(i) }]
          end
        when :array
          ast[1..-1].map {|node| collapse_ast(node)}
        when :lit, :lvar, :const, :str, :ivar, :cvar
          ast[1]
        when :true
          true
        when :false
          false
        when :nil
          nil
        when :self
          ast[0]
        when :call
          if ast[2] == :[]
            "#{method_name_from_ast(ast[1..1]).join('.')}[#{collapse_ast(ast[3])}]"
          else
            "#{method_name_from_ast(ast[1..2]).join('.')}#{'(...)' if ast.length > 3}"
          end
        when :evstr
          "#"+"{#{collapse_asts(ast[1..-1]).join}}"
        when :colon2
          "#{method_name_from_ast(ast[1..-1]).join('::')}"
        when :dot2
          "#{collapse_ast(ast[1])}..#{collapse_ast(ast[2])}"
        when :colon3
          "::#{collapse_asts(ast[1..-1]).join}"
        when :[]
          "[#{collapse_asts(ast[1..-1]).join}]"
        when :dstr
          "#{collapse_asts(ast[1..-1]).join}"
        #backref?
        else
          if max > 0
            ast.map {|node| collapse_ast(node, max-1)}
          else
            "#{ast.node_type}[]"
          end
        end
      elsif ast.nil?
        nil
      else
        ast
      end
    end

    def collapse_asts(ast, max=20)
      ast.map {|node| collapse_ast(node)}
    end

    def parse(file_name, file_data=nil, required_string=nil)
      #may make more sense to get this into cli (and an option for absolute path)
      file_name = File.realpath(file_name)
      file_data ||= File.binread(file_name)
      begin
        if required_string.nil? || file_data.include?(required_string)
          in_context file_name do
            traverse RubyParser.new.process(file_data, file_name)
          end
        end
        @file_count += 1
      rescue => e
        STDERR.puts("#{e}: [#{file_data.size}] #{file_name}")
      end
    end

    private

    # where in the source are we?
    def src
      "#{@cur_method.first.first} | #{@cur_method.map(&:first)[1..-1].join('.')}"
    end

    # return nil if we haven't hit a class yet
    def self_name
      #cm[1] == true for module/class definitions
      node=@cur_method.select {|cm| cm[1] == true}.last
      node.first unless node.nil?
    end

    def static?
      @cur_method.last.last
    end

    # mark the context of the method call.
    # optionally indents output as well
    # @param name [String] name of the block - file, module, class, method, 'yield'
    # @param indent [boolean] (false) indent this block (pass :static if this is a static method)
    # @param class_def [boolean] (false) true if this is a class definition
    def in_context name, indent=false, class_def=false
      name = collapse_ast(name) #split("::").last
      @cur_method << [ name, class_def, indent == :static]
      puts ">> #{'self.' if static?}#{src}" if debug? && indent
      @indent += 1 if indent
      ret = yield
      @indent -= 1 if indent
      @cur_method.pop
      ret
    end

    #print appropriate # of spaces
    def spaces
      SPACES[@indent]
    end
  end
end
