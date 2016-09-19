require 'active_support/all'
require 'active_record'

module ActiveRecord
  class Relation
    alias_method :delete_all_permanently, :delete_all
    def delete_all
      if @klass.paranoid?
        update_all(:deleted_at => Time.now.utc)
      else
        delete_all_permanently
      end
    end
  end
end

module DeleteParanoid
  module ActiveRecordExtensions
    def acts_as_paranoid
      default_scope { where(:deleted_at => nil) }

      extend DeleteParanoid::ClassMethods
      include DeleteParanoid::InstanceMethods
    end

    def paranoid?
      false
    end
  end

  module ClassMethods
    # permanently delete the record from the database
    def delete_permanently(id_or_array)
      where(self.primary_key => id_or_array).delete_all_permanently
    end
    # allow for queries within block to find soft deleted records
    def with_deleted
      self.unscoped do
        yield
      end
    end
    def paranoid?
      true
    end
  end

  module InstanceMethods
    # permanently delete this specific instance from the database
    def destroy_permanently
      result = destroy
      return result unless result
      self.class.with_deleted do
        self.class.delete_permanently self.id
      end
      result
    end
    # permenantly delete this specific instance from the database
    def delete_permanently
      result = delete
      self.class.with_deleted do
        self.class.delete_permanently self.id
      end
      result
    end
  end
end

ActiveRecord::Base.send(:extend, DeleteParanoid::ActiveRecordExtensions)
