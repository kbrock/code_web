module CodeWeb
  class TextReport
    # @!attribute :method_calls [r]
    #   list of all the method_Calls
    #   @return [Array<MethodCall>]
    attr_accessor :method_calls

    def initialize(method_calls, class_map=nil, out=STDOUT)
      @method_calls = method_calls
      @out = out
    end
    
    def report
      method_calls.group_by {|m| m.short_method_name }.each_pair do |name, methods|
        @out.puts "---- #{name} ----"
        method_groupings = methods.group_by {|m| m.method_types }
        show_signatures  = method_groupings.count != 1

        method_groupings.sort_by {|t,s| t}.each do |(method_types, methods_with_signature)|
          @out.puts "-------- #{method_types}" if show_signatures
          methods_with_signature.sort_by {|m| m.signature }.each do |method|
            @out.puts method.signature
          end
        end
        @out.puts
      end
    end
  end
end
