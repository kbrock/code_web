module CodeWeb
  class CLI
    def self.parse(args)
      code_parser = CodeWeb::CodeParser.new
      args.each do |arg|
        if File.exist?(arg)
          code_parser.parse arg
        else
          Dir[arg].each do |file_name|
            code_parser.parse(file_name)
          end
        end
      end
    end
  end
end
