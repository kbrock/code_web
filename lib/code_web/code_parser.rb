require 'ruby_parser'

module CodeWeb
  class CodeParser
    SPACES = (0..10).map { |i| "  " * i}

    # Map<String,Array<MethodCall>>
    attr_accessor :method_calls

    def initialize
      @cur_method=[]
      @parser = RubyParser.new
      @indent = 0
      @method_calls={}
    end

    def traverse(ast)
      puts "#{spaces}||#{collapse_ast(ast)}||" if $verbose
      case ast.first
      when :block #statements[]
        traverse_nodes(ast, 1..-1)
      when :module #name, class[]
        in_context ast[1] do
          traverse_nodes(ast, 2..-1)
        end
      when :class #name, parent, statements[]
        in_context ast[1], true, true do
          traverse_nodes(ast, 3..-1)
        end
      when :defs #self[], name, args[], call[]
        in_context ast[2], true, true do
          traverse_nodes(ast, 4..-1)
        end
      when :defn #name, args[], call[]
        in_context ast[1], true, true do
          traverse_nodes(ast, 3..-1)
        end
      when :iter #call[], yield_args[], yield_{block|call}[]
        traverse(ast[1])
        in_context 'yield', true do
          traverse(ast[3])
        end
      when :if #call[], call[], call[]
        in_context 'if', true do
          traverse_nodes(ast, 1..-1)
        end
      when :call # object, statement? || const symbol, args
        handle_method_call(ast[1..-1])
        ast[2..-1].each do |node|
          traverse(node) if node.is_a?(Array) && [:call].include?(node[0])
        end
      when :lit, :lvar, :const, :str, :nil #not used, but remove false errors
      else
        #STDERR.puts "*** unknown node_type #{ast.first}"
        STDERR.puts "#{src}\n  unknown node: #{collapse_ast(ast)}"
      end
    end

    def traverse_nodes(ast, *ranges)
      ranges.each do |range|
        #range = range..range unless range.is_a?(Range)
        ast[range].each do |node|
          traverse(node) if node.is_a?(Array)
        end
      end
    end


    def add_method(method_name, args=[], is_yield=false)
      @method_calls[method_name] ||= []
      @method_calls[method_name] << CodeWeb::MethodCall.new(@cur_method.dup, method_name, args, is_yield)
    end

    def handle_method_call(method_ast, is_yield=false)
      method_name = method_name_from_ast(method_ast[0..1])
      args = method_ast[2..-1].map {|arg| collapse_ast(arg)}

      add_method(method_name, args, is_yield)

      print "#{spaces}#{method_name}(#{collapse_ast(args.first)}" if $debug
      if args.length > 1
        args[1..-1].each do | arg |
          print ", #{collapse_ast(arg)}"  if $debug
        end
      end
      print ")#{" do" if is_yield}\n" if $debug
    end

    def method_name_from_ast(ast)
      ast.map { |node|
        method_node_from_ast(node)
      }.compact.join(".")
    end

    #TODO: add collapse_ast
    # this one creates the true classes, not the string versions
    # (so don't add double quotes, or do 'nil')
    def method_node_from_ast(ast)
      if ast.is_a?(Array)
        case ast[0]
        when :hash
          ret = {}
          ast[1..-1].each_slice(2) do |name, value|
            ret[method_node_from_ast(name)] = method_node_from_ast(value)
          end
          ret
        when :array
          if ast[0] == :call
            "#{ast[1]}()"
          else
            ast[1..-1].map {|node| method_node_from_ast(node)}
          end
        when :lit, :lvar, :const, :str, :nil
          ast[1]
        when :call
          "#{method_name_from_ast(ast[1..2])}#{'(...)' if ast.length > 3}"
        else
          binding.pry
          "#{ast[0]}[]"
        end
      elsif ast.nil?
        nil
      else
        ast
      end
    end

    def collapse_ast(ast, separator=", ", max=1)
      if ast.is_a?(Array)
        case ast[0]
        when :hash
          ret = {}
          ast[1..-1].each_slice(2) do |name, value|
            ret[method_node_from_ast(name)] = method_node_from_ast(value)
          end
          ret
        when :array
          ast[1..-1].map {|node| method_node_from_ast(node)}
        when :str
          "\"#{ast[1]}\""
        when :lit, :lvar, :const
          ast[1]
        when :call
          #simplify sub calls for now
          "#{method_name_from_ast(ast[1..2])}#{'(...)' if ast.length > 3}"
        else
          if max > 0
            ast.map {|node| collapse_ast(node, separator, max-1)}.compact.join(separator)
          else
            "#{ast[0]}[]"
          end
        end        
      elsif ast.nil?
        "nil"
      else
        "#{ast}"
      end
    end

    def parse(file_name, file_data=nil, required_string=nil)
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
