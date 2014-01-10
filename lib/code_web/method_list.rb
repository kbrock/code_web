#collection of similar method calls
class MethodList
  include Enumerable

  # what was used in the group by
  attr_accessor :name
  # the collection (actually [[k,[v1,v2]],[k2,[v1,v2]]])
  attr_accessor :collection

  def initialize(name, collection)
    @name = name
    @collection = collection
  end

  def group_by(name)
    MethodList.new(name, collection.group_by {|m| m.send(name)}.sort_by {|n, ms| n })
  end

  def f
    collection.first
  end

  def detect(&block)
    collection.detect(&block)
  end

  def each(&block)
    collection.each do |n, c|
      yield MethodList.new(n,c)
    end
  end

  def each_with_index(&block)
    collection.each_with_index(&block)
  end

  # specific to the report
  def hash_arg
    @hash ||= f.args.first
  end

  def arg_keys
    @arg_keys ||= collection.inject(Set.new) {|acc, m| m.arg_keys.each {|k| acc << k} ; acc}.sort_by {|n| n}
  end

  def arg_value(key)
    @hash[key]
  end

  def self.group_by(collection, name)
    MethodList.new(nil, collection).group_by(name)
  end
end
