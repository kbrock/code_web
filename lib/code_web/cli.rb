require 'optparse'

module CodeWeb
  class CLI
    def self.parse(args)
      new(args).run
    end

    attr_accessor :code_parser
    def method_calls ; code_parser.method_calls ; end
    def files_parsed ; code_parser.file_count ; end
    def arg_regex ; code_parser.arg_regex ; end
    def method_regex=(val) ; code_parser.method_regex = val ; end
    def arg_regex=(val) ; code_parser.arg_regex = val ; end
    def exit_on_error=(val) ; code_parser.exit_on_error = val ; end
    def verbose=(val) ; code_parser.verbose = val ; end
    def debug=(val) ; code_parser.debug = val ; end
    def debug? ; code_parser.debug? ; end

    # @attribute report_generator [rw]
    #   @return class that runs the report (i.e.: TextReport, HtmlReport) 
    attr_accessor :report_generator

    # @attribute class_map
    #   @return [Map<Regexp,html_class>] files/directories with specal emphasis
    attr_accessor :class_map

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
      @class_map = {}
    end

    def run
      parse_arguments
      parse_files
      display_results
    end

    def parse_arguments
      #defaults
      self.report_generator = ::CodeWeb::HtmlReport
      self.output = STDOUT

      #parsing the command line
      OptionParser.new do |opt|
        opt.banner = "Usage: code_web regex [file_name ...]"
#       opt.on('-n', '--requests=count',   Integer, "Number of requests (default: #{requests})")  { |v| options[:requests] = v }
        opt.on('-t', '--text',                      'Use text reports')                           { |v| self.report_generator = ::CodeWeb::TextReport }
        opt.on('-a', '--arg ARG_REGEX',             'Only files with hash argument')              { |v| self.arg_regex = Regexp.new(v) }
        opt.on('-o', '--output FILENAME',           'Output filename')                            { |v| self.output = (v == '-') ? STDOUT : File.new(v,'w') }
        opt.on('-e', '--error-out',                 'exit on unknown tags')                       { |v| self.exit_on_error = true}
        opt.on('-V', '--verbose',                   'verbose parsing')                            { |v| self.verbose = true}
        opt.on('-D', '--debug',                     'debug parsing')                              { |v| self.debug = true}
        opt.on('-p', '--pattern FILENAME_REGEX=COLOR','color to emphasize a file')                { |v| v = v.split('=') ; self.class_map[Regexp.new(v.first)] = v.last }
        opt.on('--byebug') { require "byebug" }
        opt.on('--pry') { require "pry" }
        opt.on_tail("-h", "--help", "Show this message")                                          { puts opt ; exit }
        opt.on_tail("-v", "--version", "Show version_information")                                { puts "Code Web version #{CodeWeb::VERSION}" ; exit }
        opt.parse!(arguments)

        if arguments.length == 0
          puts opt
          exit
        end
      end
      self.method_regex = Regexp.new(arguments[0])
      self.filenames = arguments[1..-1] || "."
    end
       
    def parse_files
      filenames.each do |arg|
        arg = "#{arg}/**/*.rb" if Dir.exists?(arg)
        if File.exist?(arg)
          puts arg if debug?
          code_parser.parse arg
        else
          Dir[arg].each do |file_name|
            puts arg if debug?
            code_parser.parse(file_name)
          end
        end
      end
    end

    def display_results
      STDOUT.puts "parsed #{files_parsed} files"
      report_generator.new(method_calls, class_map, arg_regex, output).report
    end
  end
end
