require 'optparse'

module CodeWeb
  class CLI
    def self.parse(args)
      new(args).run
    end

    attr_accessor :code_parser
    def method_calls ; code_parser.method_calls ; end
    def files_parsed ; code_parser.file_count ; end
    def method_regex=(val) ; code_parser.method_regex = val ; end
    def exit_on_error=(val) ; code_parser.exit_on_error = val ; end

    # @attribute report_generator [rw]
    #   @return class that runs the report (i.e.: TextReport, HtmlReport) 
    attr_accessor :report_generator

    # @attribute method_filename
    #   @return [Regexp] name of the file that defines the report class 
    attr_accessor :method_filename

    # @attribute arguments [r]
    #   @return [Array<String>] command line arguments
    attr_accessor :arguments

    # @attribute filenames [rw]
    #   @return [Array<String>] regular expression filenames
    attr_accessor :filenames

    attr_accessor :output

    def initialize(arguments)
      @arguments = arguments
      @code_parser = CodeWeb::CodeParser.new
    end

    def run
      parse_arguments
      parse_files
      display_results
    end

    def parse_arguments
      #defaults
      self.report_generator = ::CodeWeb::HtmlReport
      self.method_filename = /miq_queue.rb$/
      self.method_regex = /MiqQueue\b/
      self.output = STDOUT

      #parsing the command line
      OptionParser.new do |opt|
        opt.banner = "Usage: code_web "
#       opt.on('-n', '--requests=count',   Integer, "Number of requests (default: #{requests})")  { |v| options[:requests] = v }
        opt.on('-t', '--text',                      'Use text reports')                           { |v| self.report_generator = ::CodeWeb::TextReport }
        opt.on('-o', '--output FILENAME',           'Output filename')                            { |v| self.output = (v == '-') ? STDOUT : File.new(v,'w') }
        opt.on('-e', '--error-out',                 'exit on unknown tagserrors')                 { |v| self.exit_on_error = true}
        opt.on_tail("-h", "--help", "Show this message")                                          { puts opt ; exit }
        opt.on_tail("-v", "--version", "Show version_information")                                { puts "Code Web version #{CodeWeb::VERSION}" ; exit }
        opt.parse!(arguments)

        self.filenames = arguments.dup
      end
    end
       
    def parse_files
      filenames.each do |arg|
        arg = "#{arg}/**/*.rb" if Dir.exists?(arg)
        if File.exist?(arg)
          code_parser.parse arg
        else
          Dir[arg].each do |file_name|
            code_parser.parse(file_name)
          end
        end
      end
    end

    def display_results
      STDOUT.puts "parsed #{files_parsed} files"
      report_generator.new(method_calls, method_filename, output).report
    end
  end
end
