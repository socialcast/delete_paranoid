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

class Test::Unit::TestCase
end


module CallbackTester
  
  def self.included(base)
    base.class_eval do
      attr_accessor :called_before_destroy, :called_after_destroy, :called_after_commit_on_destroy
    
      before_destroy :call_me_before_destroy
      after_destroy :call_me_after_destroy

      after_commit :call_me_after_commit_on_destroy, :on => :destroy
    
      alias_method_chain :initialize, :callback_init
    end
  end
  
  def initialize_with_callback_init(*attrs)
    reset_callback_flags!
    initialize_without_callback_init(*attrs)
  end
  
  def reset_callback_flags!
    @called_before_destroy = @called_after_destroy = @called_after_commit_on_destroy = false
  end

  def call_me_before_destroy
    @called_before_destroy = true
  end

  def call_me_after_destroy
    @called_after_destroy = true
  end

  def call_me_after_commit_on_destroy
    @called_after_commit_on_destroy = true
  end
end
