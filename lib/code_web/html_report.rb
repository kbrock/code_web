require 'set'
require 'erb'

module CodeWeb
  class HtmlReport
    # @!attribute :method_calls [r]
    #   list of all the method_Calls
    #   @return [Array<MethodCall>]
    attr_accessor :method_calls
    attr_accessor :arg_regex
    attr_accessor :base_url
    def arg_regex? ; ! arg_regex.nil? ; end

    # @!attribute :class_map [rw]
    #   map from regex to class name
    #   if the filename that has the method matches the regex, the classname
    #     will get assigned to the link (to emphasize certain files/directories)
    #   @return [Map<Regexp,color>] regex expressing name of main file
    attr_accessor :class_map

    def initialize(method_calls, class_map={}, arg_regex=nil, base_url=nil, out=STDOUT)
      @method_calls = method_calls
      @class_map = class_map
      @arg_regex = arg_regex
      @base_url = base_url
      @out = out
    end

    TEMPLATE=%{<html>
<head><style>
table {border-collapse:collapse;}
table, td, th { border:1px solid black;  }
<%- @class_map.each_with_index do |(pattern, color), i| -%>
.f<%=i%>, a.f<%=i%> { color: <%=color%>; }
<%- end -%>
</style>
</head>
<body>
<%- methods_by_name.each do |methods| -%>
  <h2><%=methods.name%></h2>
  <%- methods.group_by(:hash_args?).each do |methods_with_hash| -%>
    <%- if methods_with_hash.hash_args? -%>
      <%- methods_with_hash.group_by(:method_types).each do |methods_with_type| -%>
        <%- display_yield_column = methods_with_type.detect(&:yields?) -%>
        <table>
        <thead><tr>
          <%- methods_with_type.arg_keys.each do |arg| -%>
            <td><%=arg%></td>
          <%- end -%>
          <%- if display_yield_column -%>
          <td>yield?</td>
          <%- end -%>
          <td>ref</td>
        </tr></thead>
        <tbody>
        <%- methods_with_type.group_by(:signature, arg_regex).each do |methods_by_signature| -%>
          <tr>
          <%- methods_with_type.arg_keys.each do |arg| -%>
            <td><%= simplified_argument(methods_by_signature.hash_arg[arg]) if methods_by_signature.hash_arg.key?(arg) %></td>
          <%- end -%>
            <%- if display_yield_column -%>
            <td><%= methods_by_signature.f.yields? %></td>
            <%- end -%>
            <td>
            <%- methods_by_signature.group_by(:filename).each do |methods_by_filename| -%>
            <%- methods_by_filename.each_with_index do |method, i| -%>
              <%= method_link(method, i == 0 ? nil : i+1) %>
            <%- end -%>
            <%- end -%>
            </td>
          </tr>
        <%- end -%>
        </tbody>
        </table>
      <%- end -%>
    <%- else -%>
      <table>
      <tbody>
      <%- methods_with_hash.group_by(:method_types).each do |methods_with_type| -%>
        <%- display_yield_column = methods_with_type.detect(&:yields?) -%>
        <%- methods_with_type.group_by(:signature, nil, :small_signature).each do |methods_by_signature| -%>
          <tr>
          <%- methods_by_signature.f.args.each do |arg| -%>
            <td><%= arg.inspect %></td>
          <%- end -%>
          <%- if display_yield_column -%>
            <td><%= methods_by_signature.f.yields? ? 'yields' : 'no yield'%></td>
          <%- end -%>
            <td>
            <%- methods_by_signature.group_by(:filename).each do |methods_by_filename| -%>
            <%- methods_by_filename.each_with_index do |method, i| -%>
              <%= method_link(method, i == 0 ? nil : i+1) %>
            <%- end -%>
            <%- end -%>
            </td>
          </tr>
        <%- end -%>
      <%- end -%>
      </tbody>
      </table>
    <%- end -%>
  <%- end -%>

<%- end -%>
</body>
</html>
}

    def report
      template = ERB.new(TEMPLATE, nil, "-")
      @out.puts template.result(binding)
    rescue => e
      e.backtrace.detect { |l| l =~ /\(erb\):([0-9]+)/ }
      line_no=$1.to_i
      raise RuntimeError, "error in #{__FILE__}:#{line_no+28} #{e}\n\n #{TEMPLATE.split(/\n/)[line_no-1]}\n\n ",
        e.backtrace
    end

    # helpers

    def methods_by_name
      MethodList.group_by(method_calls, :short_method_name)
    end

    private

    # shorten the argument
    def simplified_argument(arg)
      short_arg = case arg
      when nil
        "nil"
      when String
        arg.split("::").last[0..12]
      else
        arg.to_s[0..12]
      end
      if short_arg == arg || short_arg == "nil"
        short_arg
      else
        %{<span title="#{html_safe(arg)}">#{short_arg}</span>}
      end
    end

    def html_safe(str)
      str.to_s.gsub('"','&quot;')
    end

    # @param collection [Array<Method>] methods (with a hash first argument)
    # @return [Array<String>] list of all keys for all hashes
    def all_hash_names(collection)
      collection.inject(Set.new) {|acc, m| m.arg_keys.each {|k| acc << k} ; acc}.sort_by {|n| n}
    end

    # create a link to a method
    # add a class if the method is in a particular file

    def method_link(m, count=nil)
      name = count ? "[#{count}]" : m.short_filename
      class_name = nil
      class_map.each_with_index do |(pattern, color), i|
        if m.filename =~ pattern
          class_name = "f#{i}"
          break
        end
      end
      url = if base_url
              "#{m.filename.gsub(pwd, base_url)}#L#{m.line}"
            else
              #NOTE: may want to CGI::escape(m.filename)
              "subl://open?url=file://#{m.filename}&amp;line=#{m.line}"
            end
        %{<a href="#{url}" title="#{html_safe(m.signature)}"#{" class=\"#{class_name}\"" if class_name}>#{name}</a>}
    end

    def pwd
      @pwd ||= `pwd`.chomp
    end
  end
end
