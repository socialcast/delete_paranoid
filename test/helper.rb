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
require 'timecop'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'delete_paranoid'
require 'database_setup'

class Test::Unit::TestCase
  
  def self.should_soft_destroy(subject)
    should "set #{subject} to destroyed" do
      assert instance_variable_get(:"@#{subject}").destroyed?
    end
    should "freeze #{subject}" do
      assert instance_variable_get(:"@#{subject}").frozen?
    end
    should "not find #{subject} normally" do
      destroyed_subject = instance_variable_get(:"@#{subject}")
      assert_raises ActiveRecord::RecordNotFound do
        destroyed_subject.class.find destroyed_subject.id
      end
    end
    should "find #{subject} when in with_deleted block" do
      destroyed_subject = instance_variable_get(:"@#{subject}")
      destroyed_subject.class.with_deleted do
        assert_nothing_raised ActiveRecord::RecordNotFound do
          destroyed_subject.class.find destroyed_subject.id
        end
      end
    end
  end
  
  def self.should_hard_destroy(subject)
    should "not find #{subject} normally" do
      destroyed_subject = instance_variable_get(:"@#{subject}")
      assert_raises ActiveRecord::RecordNotFound do
        destroyed_subject.class.find destroyed_subject.id
      end
    end
    should "not find #{subject} in with_deleted block" do
      destroyed_subject = instance_variable_get(:"@#{subject}")
      destroyed_subject.class.with_deleted do
        assert_raises ActiveRecord::RecordNotFound do
          destroyed_subject.class.find destroyed_subject.id
        end
      end
    end
  end
  
  def self.should_trigger_destroy_callbacks(subject)
    should "call before_destroy callbacks on #{subject}" do
      assert instance_variable_get(:"@#{subject}").called_before_destroy
    end
    should "call after_destroy callbacks on #{subject}" do
      assert instance_variable_get(:"@#{subject}").called_after_destroy
    end
    should "call after_commit_on_destroy callbacks on #{subject}" do
      assert instance_variable_get(:"@#{subject}").called_after_commit_on_destroy
    end
  end
  
  def self.should_not_trigger_update_callbacks(subject)
    should "not call before_update callbacks on #{subject}" do
      assert !instance_variable_get(:"@#{subject}").called_before_update
    end
    should "not call after_update callbacks on #{subject}" do
      assert !instance_variable_get(:"@#{subject}").called_after_update
    end
    should "not call after_commit_on_update callbacks on #{subject}" do
      assert !instance_variable_get(:"@#{subject}").called_after_commit_on_update
    end
  end

end


module CallbackTester
  ATTRS = %w{ called_before_destroy called_after_destroy called_after_commit_on_destroy called_before_update called_after_update called_after_commit_on_update }
  
  def self.included(base)
    base.class_eval do
      attr_accessor *ATTRS
  
      before_update :call_me_before_update
      after_update :call_me_after_update
  
      before_destroy :call_me_before_destroy
      after_destroy :call_me_after_destroy

      after_commit :call_me_after_commit_on_destroy, :on => :destroy
      after_commit :call_me_after_commit_on_update, :on => :update
  
      alias_method_chain :initialize, :callback_init
    end
  end
  
  def initialize_with_callback_init(*args)
    reset_callback_flags!
    initialize_without_callback_init(*args)
  end
  
  def reset_callback_flags!
    ATTRS.each do |attr|
      send("#{attr}=", false)
    end
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
  
  def call_me_before_update
    @called_before_update = true
  end

  def call_me_after_update
    @called_after_update = true
  end

  def call_me_after_commit_on_update
    @called_after_commit_on_update = true
  end
  
end
