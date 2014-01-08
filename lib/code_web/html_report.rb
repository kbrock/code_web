require 'set'

module CodeWeb
  class HtmlReport
    # @!attribute :method_calls [r]
    #   list of all the method_Calls
    #   @return [Array<MethodCall>]
    attr_accessor :method_calls

    # @!attribute :class_map [rw]
    #   map from regex to class name
    #   if the filename that has the method matches the regex, the classname
    #     will get assigned to the link (to emphasize certain files/directories)
    #   @return [Map<Regexp,class_name>] regex expressing name of main file
    attr_accessor :class_map

    def initialize(method_calls, class_map={}, out=STDOUT)
      @method_calls = method_calls
      @class_map = class_map
      @out = out
    end
    
    # helpers

    def methods_by_name
      method_calls.group_by {|m| m.short_method_name }
    end

    def methods_by_arg_types(methods)
      methods.group_by {|m| m.method_types }.sort_by {|t,s| t}
    end

    def hash_method?(methods)
      methods.first.args.first.class == Hash
    end

    def methods_by_signatues(methods)
      methods.group_by {|m| m.signature }.values.sort_by {|m| m.first.signature }
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
      methods_by_name.each_pair do |name, methods|
        @out.puts "<h2>#{name}</h2>"
        methods_by_arg_types(methods).each do |(method_types, methods_with_signature)|
          #methods with hashes, lets create a table with hash keys along the top
          if hash_method?(methods_with_signature)
            arg_names = all_hash_names(methods_with_signature)
            @out.puts "<table>"
            @out.puts "<thead><tr>"
            @out.puts arg_names.map {|arg| "<td>#{arg}</td>"}.join("\n")
            @out.puts "<td>yield?</td>"
            @out.puts "<td>ref</td>"
            @out.puts "</tr></thead><tbody>"

            #group by same arguments
            methods_by_signatues(methods_with_signature).each do |method_list|
              common_method = method_list.first
              common_hash = common_method.args.first
              @out.puts "<tr>"
              #argument values
              @out.puts arg_names.map {|arg| "<td>#{simplified_argument(common_hash[arg])}</td>"}.join("\n")
              @out.puts "<td>#{common_method.is_yielding}</td>"
              #references to the methods. all are numbered.
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
            #group by same arguments
            methods_by_signatues(methods_with_signature).each do |method_list|
              #display refs. first is the signature, others are numbered.
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
      class_name = nil
      class_map.each_pair do |pattern, clazz|
        if m.filename =~ pattern
          class_name = clazz
          break
        end
      end
      #NOTE: may want to CGI::escape(m.src.first)
      "<a href='subl://open?url=file://#{m.filename}&line=#{m.line}' title='#{m.signature}'#{" class='#{class_name}'" if class_name}>#{name}</a>"
    end
  end
end
