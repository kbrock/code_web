module CodeWeb
  class TextReport
    # @!attribute :method_calls [r]
    #   list of all the method_Calls
    #   @return [Array<MethodCall>]
    attr_accessor :method_calls
    def initialize(method_calls, main_file)
      @method_calls = method_calls
      @main_file = main_file || /$^/ #by default don't match
    end
    
    def report
      method_calls.each_pair do |name, methods|
        puts "---- #{name} ----"
        method_groupings = methods.group_by {|m| m.method_types }
        show_signatures  = method_groupings.count != 1

        method_groupings.sort_by {|t,s| t}.each do |(method_types, methods_with_signature)|
          puts "-------- #{method_types}" if show_signatures
          methods_with_signature.sort_by {|m| m.signature }.each do |method|
            puts method.signature
          end
        end
        puts
      end
    end
  end
end
