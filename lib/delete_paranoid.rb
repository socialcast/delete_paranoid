require 'active_record'

module DeleteParanoid
  module ActiveRecordExtensions
    def acts_as_paranoid
      class << self
        alias_method :delete_all!, :delete_all
      end
      alias_method :destroy!, :destroy
      default_scope where(:deleted_at => nil)
      extend DeleteParanoid::ClassMethods
      include DeleteParanoid::InstanceMethods  
    end
  end
  
  module ClassMethods
    def with_deleted
      self.unscoped do
        yield
      end
    end
    
    def delete_all(conditions = nil)
      update_all ["deleted_at = ?", Time.now.utc], conditions
    end

    def destroy_all!(conditions = nil)
      if conditions
        where(conditions).destroy_all!
      else
        to_a.each {|object| object.destroy! }.tap { reset }
      end
    end
  end
  
  module InstanceMethods
    def destroy
      if persisted?
        with_transaction_returning_status do
          _run_destroy_callbacks do
            self.deleted_at = Time.now.utc
            self.class.update_all ["deleted_at = ?", self.deleted_at ], { :id => self.id }
            @destroyed = true
          end
        end
      else
        @destroyed = true
      end
      
      freeze
    end
  end
end

ActiveRecord::Base.send(:extend, DeleteParanoid::ActiveRecordExtensions)
