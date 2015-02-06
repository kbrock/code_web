require 'forwardable'
#collection of similar method calls
module CodeWeb
  class MethodList
    extend Forwardable
    include Enumerable

    # what was used in the group by
    attr_accessor :name
    # the collection (actually [[k,[v1,v2]],[k2,[v1,v2]]])
    attr_accessor :collection

    def initialize(name, collection)
      @name = name
      @collection = collection
    end

    def group_by(name, arg_regex=nil, sort_by = nil, &block)
      if block.nil?
        if arg_regex.nil?
          block = Proc.new {|m| m.send(name)}
        else
          block = Proc.new {|m|
            if m.hash_args?
              m.hash_arg.collect {|n,v| v if n =~ arg_regex}.compact.join(" ")
            else
              m.signature
            end
          }
        end
      end
      MethodList.new(name, collection.group_by(&block).sort_by {|n, ms| sort_by ? ms.first.send(sort_by) : n })
    end

    def f
      collection.first
    end

    delegate [:detect, :each_with_index, :count] => :collection
    delegate [:args_size, :hash_arg, :hash_args?] => :f

    def detect(&block)
      collection.detect(&block)
    end

    def each(&block)
      collection.each do |n, c|
        yield MethodList.new(n,c)
      end
    end

    def arg_keys
      @arg_keys ||= collection.inject(Set.new) {|acc, m| m.arg_keys.each {|k| acc << k} ; acc}.sort_by {|n| n}
    end

    def self.group_by(collection, name)
      MethodList.new(nil, collection).group_by(name)
    end
  end
end
