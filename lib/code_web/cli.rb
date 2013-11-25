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

      ::CodeWeb::HtmlReport.new(code_parser, /miq_queue.rb$/).report
    end
  end
end
