module CodeWeb
  class MethodCache
    # Map<String,Array<MethodCall>>
    attr_accessor :method_calls

    # only store the information on these methods
    attr_accessor :method_regex

    def initialize(method_regex=//)
      @method_calls=[]
      @method_regex = method_regex      
    end

    def add_method(src, method_name, args=[], is_yield=false)
      if method_name.join('.') =~ method_regex
        @method_calls << CodeWeb::MethodCall.new(src, method_name, args, is_yield)
      end
    end
  end
end
