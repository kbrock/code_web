require 'set'

module CodeWeb
  class HtmlReport
    # @!attribute :method_calls [r]
    #   list of all the method_Calls
    #   @return [Array<MethodCall>]
    attr_accessor :method_calls

    # @!attribute :main_file [rw]
    #   regex for the primary file (Defining the method we are searching for)
    #   so references can look different
    #   @return [Regexp] regex expressing name of main file
    attr_accessor :main_file

    # these are of lower importance
    attr_accessor :secondary_file

    def initialize(method_calls, main_file=/$^/, out=STDOUT)
      @method_calls = method_calls
      @main_file = main_file
      @secondary_file = /tools/
      @out = out
    end
    
    def report
      @out.puts "<html>"
      @out.puts "<head><style>"
      @out.puts "table {border-collapse:collapse;}"
      @out.puts "table, td, th { border:1px solid black;  }"
      @out.puts ".secondary, a.secondary { color: #ccc; }"
      @out.puts ".primary, a.primary { color: #999; }"
      @out.puts "</style>"
      @out.puts "</head>"
      @out.puts "<body>"

      # all methods references
      method_calls.group_by {|m| m.short_method_name }.each_pair do |name, methods|
        @out.puts "<h2>#{name}</h2>"
        method_groupings = methods.group_by {|m| m.method_types }
        show_signatures  = method_groupings.count != 1

        # group them with same signatures
        method_groupings.sort_by {|t,s| t}.each do |(method_types, methods_with_signature)|
          if methods_with_signature.first.args.first.class == Hash
            arg_names = all_hash_names(methods_with_signature)
            @out.puts "<table>"
            #@out.puts "<caption>#{method_types}</caption>" if show_signatures
            @out.puts "<thead><tr>"
            @out.puts arg_names.map {|arg| "<td>#{arg}</td>"}.join("\n")
            @out.puts "<td>yield?</td>"
            @out.puts "<td>ref</td>"
            @out.puts "</tr></thead><tbody>"

            #group by same arguments
  
            methods_with_signature.group_by {|m| m.signature }.values.sort_by {|m| m.first.signature }.each do |method_list|
              common_method = method_list.first
              common_hash = common_method.args.first
              @out.puts "<tr>"
              #argument values
              @out.puts arg_names.map {|arg| "<td>#{simplified_argument(common_hash[arg])}</td>"}.join("\n")
              #references to the methods (all are numbers)
              @out.puts "<td>#{common_method.is_yielding}</td>"
              @out.puts "<td>"
                method_list.each_with_index do |method, i|
                  @out.puts method_link(method, i+1)
                end
              @out.puts "</td>"
              @out.puts "</tr>"
            end
            @out.puts "</tbody>"
            @out.puts "</table>"
          else
#            @out.puts "<h3>#{method_types}</h3>" if show_signatures
            #group by same arguments
            methods_with_signature.group_by {|m| m.signature }.values.sort_by {|m| m.first.signature }.each do |method_list|
              #display name, first is name, rest is refs
              @out.puts method_list.each_with_index.map { |method, i|
                method_link(method, ( i > 0) && (i+1))
              }.join(" ") + "</br>"
            end
          end
        end
        @out.puts
      end
      @out.puts "</body>"
      @out.puts "</html>"
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
      if m.src.first =~ main_file
        class_name = 'primary'
      elsif m.src.first =~ secondary_file
        class_name = 'secondary'
      end
      #NOTE: may want to CGI::escape(m.src.first)
      "<a href='subl://open?url=file://#{m.filename}' title='#{m.signature}'  #{" class='#{class_name}'" if class_name}>#{name}</a>"
    end
  end
end
