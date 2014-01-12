module CodeWeb
  # method call reference
  class MethodCall
    # file that has this method call
    attr_accessor :filename
    # line number that has this method
    attr_accessor :line
    # method name
    attr_accessor :name
    # what arguments are passed in
    attr_accessor :args
    def arguments ; args ; end
    # is this calling a yield block
    attr_accessor :is_yielding

    def initialize(filename, line, name=nil, args=[], is_yielding=false)
      @filename = filename
      @line = line
      @name = name
      @args = sorted_hash(args)
      @is_yielding = !! is_yielding
    end

    def args?
      args.nil? || args.empty?
    end

    def yields?
      is_yielding
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
      "#{full_method_name}(#{sorted_args.to_s})#{" yields" if is_yielding}"
    end

    def short_method_name
      Array(name).last
    end

    def full_method_name
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

    def hash_args?
      args.first.class == Hash
    end

    def hash_arg
      args.first
    end

    def arg_keys
      args.first.keys
    end

    def ==(other)
      other &&
        other.name == @name &&
        other.args == @args &&
        other.is_yielding == @is_yielding
    end
  end
end
