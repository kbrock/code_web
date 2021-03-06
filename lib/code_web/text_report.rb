module CodeWeb
  class TextReport
    # @!attribute :method_calls [r]
    #   list of all the method_Calls
    #   @return [Array<MethodCall>]
    attr_accessor :method_calls
    attr_accessor :arg_regex
    attr_accessor :base_url
    def arg_regex? ; ! arg_regex.nil? ; end

    def initialize(method_calls, class_map={}, arg_regex=nil, out=STDOUT, options = {})
      @method_calls = method_calls
      @arg_regex = arg_regex
      @base_url = options[:base_url]
      @url_and_file = options[:url_and_file]
      @out = out
    end
    
    def report
      methods_by_name.each do |methods|
        @out.puts "---- #{methods.name} ----"
        methods.group_by(:signature, arg_regex).each do |methods_with_signature|
          if arg_regex?
            @out.puts " --> #{arg_regex.inspect}=#{methods_with_signature.name}"
          else
            @out.puts " --> #{methods_with_signature.name}"
          end
          methods_with_signature.each_with_index do |method, i|
            @out.puts
            @out.puts method.signature
            @out.puts "#{method.filename}:#{method.line}"
          end
          @out.puts
          @out.puts
        end
        @out.puts
      end
    end

    def methods_by_name
      MethodList.group_by(method_calls, :short_method_name)
    end
  end
end
