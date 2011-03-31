require 'active_record'

module DeleteParanoid
  module ActiveRecordExtensions
    def acts_as_paranoid
      class << self
        alias_method :delete_all!, :delete_all
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
    def delete_all(conditions = nil)
      self.update_all ["deleted_at = ?", Time.now.utc], conditions
    end
  end
end

ActiveRecord::Base.send(:extend, DeleteParanoid::ActiveRecordExtensions)
