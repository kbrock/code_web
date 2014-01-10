module CodeWeb
  class MethodCache
    # Map<String,Array<MethodCall>>
    attr_accessor :method_calls

    # only store the information on these methods
    attr_accessor :method_regex
    attr_accessor :arg_regex

    def initialize(method_regex=//)
      @method_calls=[]
      @method_regex = method_regex      
    end

    def <<(mc)
      @method_calls << mc if mc.full_method_name =~ method_regex &&
        (
          arg_regex.nil? || (
            mc.hash_args? &&
            mc.arg_keys.detect {|key| key =~ arg_regex }
          )
        )
    end
  end
end
