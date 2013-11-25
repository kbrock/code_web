require 'set'

module CodeWeb
  class HtmlReport
    # @!attribute :method_calls [r]
    #   list of all the method_Calls
    #   @return [Array<MethodCall>]
    attr_accessor :method_calls
    attr_accessor :main_file
    def initialize(method_calls, main_file)
      @method_calls = method_calls
      @main_file = main_file || /$^/ #by default don't match
    end
    
    def report
      puts "<html>"
      puts "<head><style>"
      puts "table {border-collapse:collapse;}"
      puts "table, td, th { border:1px solid black;  }"
      puts ".primary { font-text: bold}"
      puts "</style>"
      puts "</head>"
      puts "<body>"

      # all methods references
      method_calls.each_pair do |name, methods|
        puts "<h2>#{name}</h2>"
        method_groupings = methods.group_by {|m| m.method_types }
        show_signatures  = method_groupings.count != 1

        # group them with same signatures
        method_groupings.sort_by {|t,s| t}.each do |(method_types, methods_with_signature)|
          if methods_with_signature.first.args.first.class == Hash
            arg_names = all_hash_names(methods_with_signature)
            puts "<table>"
            #puts "<caption>#{method_types}</caption>" if show_signatures
            puts "<thead><tr>"
            puts arg_names.map {|arg| "<td>#{arg}</td>"}.join("\n")
            puts "<td>ref</td>"
            puts "</tr></thead><tbody>"

            #group by same arguments
  
            methods_with_signature.group_by {|m| m.signature }.values.sort_by {|m| m.first.signature }.each do |method_list|
              common_args = method_list.first.args
              common_hash = common_args.first
              puts "<tr>"
              #argument values
              puts arg_names.map {|arg| "<td>#{simplified_argument(common_hash[arg])}</td>"}.join("\n")
              #references to the methods (all are numbers)
              puts "<td>"
                method_list.each_with_index do |method, i|
                  puts method_link(method, i)
                end
              puts "</td>"
              puts "</tr>"
            end
            puts "</tbody>"
            puts "</table>"
          else
#            puts "<h3>#{method_types}</h3>" if show_signatures
            #group by same arguments
            methods_with_signature.group_by {|m| m.signature }.values.sort_by {|m| m.first.signature }.each do |method_list|
              #display name, first is name, rest is refs
              puts method_list.each_with_index.map { |method, i|
                method_link(method, ( i > 0) && i)
              }.join(" ") + "</br>"
            end
          end
        end
        puts
      end
      puts "</body>"
      puts "</html>"
    end

    private

    def simplified_argument(obj)
      obj.nil? ? nil : obj.to_s[0..15]
    end
    # @param methods [Array<Method>] array of methods (with a hash first argument)
    # @return [Array<String>] list of all keys for all hashes
    def all_hash_names(methods)
      methods.inject(Set.new) {|acc, m| m.args.first.keys.each {|k| acc << k} ; acc}.sort_by {|n| n}
    end

    def method_link(m, count=nil)
      name = count ? "[#{count}]" : m.signature
      "<a href='#{m.src.first}'#{" class='primary'" if m.src.first =~ main_file}>#{name}</a>"
    end
  end
end
