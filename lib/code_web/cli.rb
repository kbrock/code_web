module CodeWeb
  class CLI
    def self.parse(args)
      code_parser = CodeWeb::CodeParser.new
      code_parser.method_regex = /MiqQueue/
      args.each do |arg|
        if File.exist?(arg)
          code_parser.parse arg
        else
          Dir[arg].each do |file_name|
            code_parser.parse(file_name)
          end
        end
      end

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
