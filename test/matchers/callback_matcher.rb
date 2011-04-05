
class CallbackMatcher
  CALLBACK_EVENTS = [:before, :after, :after_commit_on]
  CALLBACK_TYPES = [:create, :update, :destroy, :save]
  
  module MatcherMethods
    
    def trigger_callbacks_for(callback_types)
      CallbackMatcher.new Array.wrap(callback_types)
    end
    
  end
  
  module ActiveRecordHooks
    
    def self.included(base)
      base.class_eval do
        class << self
          attr_accessor :callback_tester_attrs
        end
        @callback_tester_attrs = []
        CALLBACK_EVENTS.each do |ce|
          CALLBACK_TYPES.each do |ct|
            callback_name = :"#{ce}_#{ct}"
            callback_attr = :"called_#{callback_name}"
            callback_method, has_on_option = (ce.to_s =~ /_on/ ? [ce.to_s.gsub('_on',''), true] : [callback_name, false]) 
            @callback_tester_attrs << callback_attr
            attr_accessor callback_attr
            send( callback_method, (has_on_option ? {:on => ct} : {})) {
              instance_variable_set(:"@#{callback_attr}", true)
            }
          
            define_method :"#{callback_attr}?" do
              instance_variable_get(:"@#{callback_attr}")
            end
          end
        end
        alias_method_chain :initialize, :callback_init
      end
    end

    def initialize_with_callback_init(*args)
      reset_callback_flags!
      initialize_without_callback_init(*args)
    end

    def reset_callback_flags!
      self.class.callback_tester_attrs.each do |attr|
        send("#{attr}=", false)
      end
    end

  end
  
  def initialize(callback_types)
    @callback_types = callback_types
  end
  
  def failure_message
    "Expected #{@subject} #{expectation}:"
  end
  
  def negative_failure_message
    "Did not expect #{@subject} #{expectation}:"
  end
  
  def description
    "check that #{@callback_types.join(', ')} callbacks were called"
  end
  
  def expectation
    @expectations.join("\n")
  end
  
  def matches?(subject)
    @subject = subject
    @expectations = []
    result = true
    @callback_types.each do |ct|
      CALLBACK_EVENTS.each do |ce|
        called = @subject.send(:"called_#{ce}_#{ct}?")
        result &&= called
        @expectations << "#{ce}_#{ct} callbacks to be triggered"
      end
    end
    result
  end
  
end

