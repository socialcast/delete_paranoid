require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'
require 'mocha'
require "ruby-debug"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'delete_paranoid'
require 'database_setup'
require 'matchers/callback_matcher'
require 'matchers/destroy_matcher'

class Test::Unit::TestCase
  extend DestroyMatcher::MatcherMethods
  extend CallbackMatcher::MatcherMethods
end


