# CodeWeb

This uses ruby parser to read code and find references.
Works best when looking for finding static methods that possibly span multiple lines

It generates an html file with the list of each method and the invocations.
Each reference has a url to the place in code where it is found.

The urls use textmate url format, which also works with sublime.
I use lincastor on my machine to wire the urls to the actual editor, so any program
will do.

## Installation

Add this line to your application's Gemfile:

    gem 'code_web'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install code_web

## Usage

    # if you find the reference in a file named miq_queue.rb, then color the url with #999
    # if you find the reference in a file with the director tools, then color the url with #ccc 
    # look for the class name MiqQueue
    # look in the directories app, tools, and lib
    # output the report to miq_queue.html (in html format)

    $ code_web -p 'miq_queue.rb$=#999' -p 'tools/=#ccc' 'MiqQueue\b' app tools lib -o miq_queue.html

## Url handline

Currently, this generates urls using the textmate file protocol.

I use [LinCastor] to map the url to my editor of choice, sublime.
But there are many tools that will do this for you.
LinCastor has worked for many many years, including my current version, 10.12.3

I use the following script to wire it together:

[LinCastor]: https://onflapp.wordpress.com/lincastor/

```ruby
#!/usr/bin/ruby

# Parse a url according to 
# http://blog.macromates.com/2007/the-textmate-url-scheme/
# opens the file

SUBL_PATH="/Applications/Sublime Text.app"
SUBL_BIN_PATH="#{SUBL_PATH}/Contents/SharedSupport/bin/subl"

#require 'logger'
require 'uri'
require 'cgi'

#DEBUG = Logger.new(File.open("#{ENV['HOME']}/sublime_cmd.txt", File::WRONLY | File::APPEND|File::CREAT))

subl_url=ENV['URL']
p=CGI.parse(URI.parse(subl_url).query)
subl_file="#{p["url"].first[7..-1]}:#{p["line"].first}"

#DEBUG.info(subl_file)

ret=`"#{SUBL_BIN_PATH}" "#{subl_file}"`
#DEBUG.info("#{SUBL_BIN_PATH} #{subl_file}")
#DEBUG.info("/handle_url")

exit 0 # the handler has finished successfully
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
