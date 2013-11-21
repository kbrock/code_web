module CodeWeb
  # method call reference
  class MethodCall
    # where in our code is this originating
    attr_accessor :src
    # method name
    attr_accessor :name
    # what arguments are passed in
    attr_accessor :args
    # is this calling a yield block
    attr_accessor :is_yielding

    def initialize(src, name, args, is_yielding=false)
      @src = src
      @name = name
      @args = args
      @is_yielding = is_yielding
    end

    def ==(other)
      other &&
        other.name == @name &&
        other.args == @args &&
        other.is_yielding == @is_yielding
    end
  end
end
