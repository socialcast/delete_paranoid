
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
      end
    end
  end
end

require 'rspec/matchers'

RSpec::Matchers.define :trigger_callbacks_for do |expected_callback_type|
  def check_for_match(model_instance, expected_callback_type)
    @called = []
    @not_called = []
    CallbackMatcher::CALLBACK_EVENTS.each do |ce|
      callback_name = "#{ce}_#{expected_callback_type}"
      result = model_instance.send("called_#{callback_name}".to_sym)
      @called << callback_name if result
      @not_called << callback_name unless result
    end
  end

  match do |model_instance|
    check_for_match(model_instance, expected_callback_type)
    result = true
    result = false unless @called.present?
    result = false if @not_called.present?
    result
  end

  match_when_negated do |model_instance|
    check_for_match(model_instance, expected_callback_type)
    result = true
    result = false unless @not_called.present?
    result = false if @called.present?
    result
  end

  failure_message do |actual|
    ["Called:\t#{@called.join("\n\t")}", "Not called:\t#{@not_called.join("\n\t")}"].join("\n")
  end

  failure_message_when_negated do |actual|
    ["Called:\t#{@called.join("\n\t")}", "Not called:\t#{@not_called.join("\n\t")}"].join("\n")
  end
end

