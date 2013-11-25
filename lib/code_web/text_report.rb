module CodeWeb
  class TextReport
    # @!attribute :code_parser [r]
    #   code parser that has all the methods
    #   @return [CodeParser]
    attr_accessor :code_parser
    def initialize(code_parser)
      @code_parser = code_parser
    end
    
    def report  
      code_parser.method_calls.each_pair  do |name, methods|
        puts "---- #{name} ----"
        methods.each do |method|
          puts method.signature
        end
        puts
      end
    end
  end
end
