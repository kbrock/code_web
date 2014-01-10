require 'set'
require 'erb'

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
    #   @return [Map<Regexp,color>] regex expressing name of main file
    attr_accessor :class_map

    def initialize(method_calls, class_map={}, out=STDOUT)
      @method_calls = method_calls
      @class_map = class_map
      @out = out
    end

    TEMPLATE=%{
<html>
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
  <%- methods.group_by(:method_types).each do |methods_with_type| -%>
  <!-- METHOD BY ARG TYPE -->
    <%- if methods_with_type.f.hash_args? -%>
      <%- display_yield_column = methods_with_type.detect(&:yields?) -%>
      <table><!-- HASH_METHOD -->
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
      <%- methods_with_type.group_by(:signature).each do |methods_by_signature| -%>
        <tr>
        <%- methods_with_type.arg_keys.each do |arg| -%>
          <td><%= simplified_argument(methods_by_signature.hash_arg[arg]) %></td>
        <%- end -%>
          <%- if display_yield_column -%>
          <td><%= methods_by_signature.f.yields? %></td>
          <%- end -%>
          <td><% methods_by_signature.collection.each_with_index do |method, i| %>
              <%= method_link(method, i+1) %>
          <% end %></td>
        </tr>
      <%- end -%>
      </tbody>
      </table><!-- HASH_METHOD -->
    <%- else -%>
      <% methods_with_type.group_by(:signature).each do |methods_by_signature| %>
        <%= methods_by_signature.collection.each_with_index.map { |method, i|
          method_link(method, ( i > 0) && (i+1))
        }.join(" ") + "</br>" %>
      <%- end -%>
    <%- end -%>
  <!-- /METHOD BY ARG TYPE -->
  <%- end -%>

<%- end -%>
</body>
</html>
}

    def report
      template = ERB.new(TEMPLATE, nil, "-")
      @out.puts template.result(binding)
    end

    # helpers

    def methods_by_name
      MethodList.group_by(method_calls, :short_method_name)
    end

    def hash_method?(collection)
      collection.first.hash_args?
    end

    def methods_by_signatues(collection)
      collection.group_by {|m| m.signature }.sort_by {|t,m| t }
    end

    private

    # shorten the argument
    def simplified_argument(arg)
      short_arg = arg.nil? ? nil : arg.to_s[0..12]
      %{<span title="#{arg.to_s.gsub('"','&quot;')}">#{short_arg}</span>}
    end

    # @param collection [Array<Method>] methods (with a hash first argument)
    # @return [Array<String>] list of all keys for all hashes
    def all_hash_names(collection)
      collection.inject(Set.new) {|acc, m| m.arg_keys.each {|k| acc << k} ; acc}.sort_by {|n| n}
    end

    # create a link to a method
    # add a class if the method is in a particular file

    def method_link(m, count=nil)
      name = count ? "[#{count}]" : m.signature
      class_name = nil
      class_map.each_with_index do |(pattern, color), i|
        if m.filename =~ pattern
          class_name = "f#{i}"
          break
        end
      end
      #NOTE: may want to CGI::escape(m.filename)
      %{<a href="subl://open?url=file://#{m.filename}&line=#{m.line}" title="#{m.signature.gsub('"','&quot;')}"#{" class=\"#{class_name}\"" if class_name}>#{name}</a>}
    end
  end
end
