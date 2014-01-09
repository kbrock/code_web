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
    #   @return [Map<Regexp,class_name>] regex expressing name of main file
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
.secondary, a.secondary { color: #ccc; }
.primary, a.primary { color: #999; }
</style>
</head>
<body>
<%- methods_by_name.each_pair do |name, methods| -%>
  <h2><%=name%></h2>
  <%- methods_by_arg_types(methods).each do |(method_types, methods_with_signature)| -%>
  <!-- METHOD BY ARG TYPE -->
    <%- if hash_method?(methods_with_signature) -%>
      <%- arg_names = all_hash_names(methods_with_signature) -%>
      <table><!-- HASH_METHOD -->
      <thead><tr>
        <%- arg_names.each do |arg| -%>
          <td><%=arg%></td>
        <%- end -%>
        <td>yield?</td>
        <td>ref</td>
      </tr></thead>
      <tbody>
      <%- methods_by_signatues(methods_with_signature).each do |method_list|
        common_method = method_list.first
        common_hash = common_method.args.first
        -%>
        <tr>
        <%- arg_names.each do |arg| -%>
          <td><%= simplified_argument(common_hash[arg])%></td>
        <%- end -%>
          <td><%= common_method.is_yielding %></td>
          <td><% method_list.each_with_index do |method, i| %>
              <%= method_link(method, i+1) %>
          <% end %></td>
        </tr>
      <%- end -%>
      </tbody>
      </table><!-- HASH_METHOD -->
    <%- else -%>
      <% methods_by_signatues(methods_with_signature).each do |method_list| %>
        <%= method_list.each_with_index.map { |method, i|
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
