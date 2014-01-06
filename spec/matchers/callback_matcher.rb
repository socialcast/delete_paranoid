
class CallbackMatcher
  CALLBACK_EVENTS = [:before, :after]
  CALLBACK_TYPES = [:create, :update, :destroy, :save, :commit]

  module ActiveRecordHooks

    def self.included(base)
      base.class_eval do
        class_attribute :callback_tester_attrs
        self.callback_tester_attrs = []

        CALLBACK_EVENTS.each do |ce|
          CALLBACK_TYPES.each do |ct|
            next if ce == :before && ct == :commit
            callback_name = :"#{ce}_#{ct}"
            callback_attr = :"called_#{callback_name}"

            callback_tester_attrs << callback_attr
            attr_accessor callback_attr

            send( callback_name ) {
              send(:"#{callback_attr}=", true)
            }
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

end

require 'rspec/matchers'

RSpec::Matchers.define :trigger_callbacks_for do |types|

  check_for_match = ->(model_instance, types) {
    @called = []
    @not_called = []
    Array.wrap(types).each do |ct|
      CallbackMatcher::CALLBACK_EVENTS.each do |ce|
        callback_name = "#{ce}_#{ct}"
        result = model_instance.send("called_#{callback_name}".to_sym)
        @called << callback_name if result
        @not_called << callback_name unless result
      end
    end
  }

  match_for_should do |model_instance|
    check_for_match.call(model_instance, types)
    result = true
    result = false unless @called.present?
    result = false if @not_called.present?
    result
  end

  match_for_should_not do |model_instance|
    check_for_match.call(model_instance, types)
    result = true
    result = false unless @not_called.present?
    result = false if @called.present?
    result
  end

  failure_message_for_should do |actual|
    ["Called:\t#{@called.join("\n\t")}", "Not called:\t#{@called.join("\n\t")}"].join("\n")
  end

  failure_message_for_should_not do |actual|
    ["Called:\t#{@called.join("\n\t")}", "Not called:\t#{@called.join("\n\t")}"].join("\n")
  end

end

