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

    def initialize(src=nil, name=nil, args=[], is_yielding=false)
      @src = src
      @name = name
      @args = sorted_hash(args)
      @is_yielding = !! is_yielding
    end

    def args?
      args.nil? || args.empty?
    end

    def method_types
      args.map { |arg|
        case arg
        when Array
          '[]'
        when Hash
          '{}'
        else
          'str'
        end
      }
    end

    def signature
      "#{method_name}(#{sorted_args.to_s})"
    end

    def method_name
      Array(name).compact.join(".")
    end

    def sorted_args(hash=@args)
      hash.map {|arg| sorted_hash(arg) }.join(", ")
    end

    def sorted_hash(args)
      case args
      when Hash
        args.each_pair.sort_by {|n,v| n }.inject({}) {|h, (n,v)| h[n]=sorted_hash(v); h}
      when Array
        args
      else
        args
      end
    end

    def ==(other)
      other &&
        other.name == @name &&
        other.args == @args &&
        other.is_yielding == @is_yielding
    end
  end
end
