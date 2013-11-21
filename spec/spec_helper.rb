$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'code_web'

begin
  require 'pry'
rescue LoadError
end
