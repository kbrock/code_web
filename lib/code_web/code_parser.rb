require 'ruby_parser'

#$verbose=true
#$debug=true

module CodeWeb
  class CodeParser
    SPACES = Hash.new {|h, n| h[n] = "  " * h.to_i }

    attr_accessor :method_cache
    attr_accessor :file_count
    attr_accessor :exit_on_error
    def method_regex=(regex) ; @method_cache.method_regex= regex ; end
    def method_calls ; @method_cache.method_calls ; end

    def initialize
      @cur_method=[]
      @parser = RubyParser.new
      @indent = 0
      @file_count = 0
      @exit_on_error = false
      @method_cache = CodeWeb::MethodCache.new
    end

    def traverse(ast, has_yield=false)
      puts "#{spaces}||#{collapse_ast(ast,1)}||" if $verbose
      puts src if ast.nil?
      case ast.node_type
      #dstr = define string ("abc#{here}"),
      #evstr evaluate string (#{HERE})
      #attrasgn = attribute assignment
      when :block, :if, :ensure, :rescue, :case, :when, :begin,
           :while, :until, :defined, :resbody, :match2, :match3, :dot2, :dot3,
           :dstr, :evstr, :dsym, :dregx, :hash, :array, :return, :and, :or,
           :next, :to_ary, :splat, :block_pass, :until, :yield,
           /asgn/, :ivar, :arglist, :args, :zsuper, :not, #statements[]
           :super, :xstr, :for, :until, :dxstr, 
      #these end up being no-ops:
           :lit, :lvar, :const, :str, :nil, :gvar, :back_ref,
           :true, :false, :colon2, :colon3, :self, :next, :alias,
           :nth_ref, :sclass, :cvdecl, :break, :retry, :undef,
      #random
           :svalue, :cvar
        traverse_nodes(ast, 1..-1)
      when :module, :cdecl #name, statements[]
        in_context ast[1] do
          traverse_nodes(ast, 2..-1)
        end
      when :class, #name, parent, statements[]
           :defn #name, args[], call[]
        in_context ast[1], true, true do
          traverse_nodes(ast, 2..-1)
        end
      when :defs #self[], name, args[], call[]
        in_context ast[2], true, true do
          traverse_nodes(ast, 2..-1)
        end
      when :iter #call[], yield_args[], yield_{block|call}[]
        traverse(ast[1], :has_yield)
        in_context 'yield', true do
          traverse_nodes(ast, 2..-1)
        end
      when :call # object, statement? || const symbol, args
        handle_method_call(ast, has_yield)
        traverse_nodes(ast, 1..-1)
      else
        STDERR.puts "#{src}\n  unknown node: #{ast.node_type} #{collapse_ast(ast,1)}"
        if exit_on_error
          binding.pry if defined?(Pry)
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

      method_cache << MethodCall.new(ast.file, ast.line, method_name, args, is_yield)

      puts "#{spaces}#{method_name}(#{args.map{|arg|arg.inspect}.join(", ")})#{" do" if is_yield}" if $debug
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
        case ast.node_type
        when :hash #name, value, name, value, ...
          Hash[*ast[1..-1].map {|i| collapse_ast(i)}]
        when :array
          ast[1..-1].map {|node| collapse_ast(node)}
        when :lit, :lvar, :const, :str, :ivar, :cvar
          ast[1]
        when :true, :false, :self, :nil
          ast[0]
        when :call
          if ast[2] == :[]
            "#{method_name_from_ast(ast[1..1]).join('.')}[#{collapse_ast(ast[3])}]"
          else
            "#{method_name_from_ast(ast[1..2]).join('.')}#{'(...)' if ast.length > 3}"
          end
        when :evstr
          "#"+"{#{collapse_asts(ast[1..-1]).join}}"
        when :colon2 #TODO: fix
          "#{method_name_from_ast(ast[1..-1]).join('.')}"
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
      @file_count += 1
      file_data ||= File.binread(file_name)
      if required_string.nil? || file_date.include?(required_string)
        in_context file_name do
          traverse @parser.process file_data, file_name
        end
      end
    end

    private

    # where in the source are we?
    def src
      "#{@cur_method.first} | #{@cur_method[1..-1].join('.')}"
    end

    # mark the context of the method call.
    # optionally indents output as well
    # @param name [String] name of the block - file, module, class, method, 'yield'
    # @param indent [boolean] (false) indent this block
    # @param print_me [boolean] (false) print a tracer on this method
    def in_context name, indent=false, print_me=false
      @cur_method << name
      puts ">> #{src}" if $debug && print_me 
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
