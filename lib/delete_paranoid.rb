require 'active_support/all'
require 'active_record'

module ActiveRecord
  class Relation
    alias_method :delete_all!, :delete_all
    def delete_all(conditions = nil)
      delete_all!(conditions) unless @klass.paranoid?
      update_all({:deleted_at => Time.now.utc}, conditions)
    end
  end
end

module DeleteParanoid
  module ActiveRecordExtensions
    def acts_as_paranoid
      default_scope where(:deleted_at => nil)

      extend DeleteParanoid::ClassMethods
    end

    def paranoid?
      false
    end
  end

  module ClassMethods
    def with_deleted
      self.unscoped do
        yield
      end
    end
    def paranoid?
      true
    end
  end
end

ActiveRecord::Base.send(:extend, DeleteParanoid::ActiveRecordExtensions)
