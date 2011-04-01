require 'active_record'

module DeleteParanoid
  module ActiveRecordExtensions
    def acts_as_paranoid
      class << self
        alias_method :destroy!, :destroy
      end
      default_scope where(:deleted_at => nil)
      include DeleteParanoid::InstanceMethods
      extend DeleteParanoid::ClassMethods
    end
  end
  module ClassMethods
    def with_deleted(&block)
      self.unscoped do
        yield
      end
    end
  end
  module InstanceMethods
    def destroy
      if persisted?
        with_transaction_returning_status do
          _run_destroy_callbacks do
            update_attributes(:deleted_at => Time.now.utc)
            @destroyed = true
          end
        end
      end
      
      freeze
    end
  end
end

ActiveRecord::Base.send(:extend, DeleteParanoid::ActiveRecordExtensions)
