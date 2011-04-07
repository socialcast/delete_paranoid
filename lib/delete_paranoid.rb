require 'active_support/all'
require 'active_record'

module ActiveRecord
  class Relation
    alias_method :delete_all!, :delete_all
    def delete_all(conditions = nil)
      if @klass.paranoid?
        update_all({:deleted_at => Time.now.utc}, conditions)
      else
        delete_all!(conditions)
      end
    end
  end
end

module DeleteParanoid
  module ActiveRecordExtensions
    def acts_as_paranoid
      default_scope where(:deleted_at => nil)

      extend DeleteParanoid::ClassMethods
      include DeleteParanoid::InstanceMethods
    end

    def paranoid?
      false
    end
  end

  module ClassMethods
    # permenantly delete the record from the database
    def delete!(id_or_array)
      where(self.primary_key => id_or_array).delete_all!
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
    # permenantly delete this specific instance from the database
    def destroy!
      enable_hard_dependent_destroy_callbacks
      result = destroy
      self.class.with_deleted do
        self.class.delete! self.id
      end
      result
    end

    # permenantly delete this specific instance from the database
    def delete!
      result = delete
      self.class.with_deleted do
        self.class.delete! self.id
      end
      result
    end
    
    def destroy_with_paranoid_dependents!
      enable_hard_dependent_destroy_callbacks
      destroy_without_paranoid_dependents!
    end
    
    def delete
      if persisted?
        self.deleted_at = Time.now.utc
        self.class.update_all ["deleted_at = ?", self.deleted_at ], { :id => self.id }
      end
      @destroyed = true
      freeze        
    end
    
  private
    def enable_hard_dependent_destroy_callbacks
      eigenclass = class << self; self; end
      self.class.reflect_on_all_associations.each do |reflection|
        next unless reflection.klass.paranoid?
        next unless reflection.options[:dependent] == :destroy
        case reflection.macro
        when :has_one, :belongs_to
          eigenclass.class_eval do
            define_method(:"#{reflection.macro}_dependent_destroy_for_#{reflection.name}") do 
              association = send(reflection.name)
              association.destroy! if association
            end
          end
        when :has_many
          eigenclass.class_eval do
            define_method(:"has_many_dependent_destroy_for_#{reflection.name}") do 
              send(reflection.name).each do |o|
                # No point in executing the counter update since we're going to destroy the parent anyway
                counter_method = ('belongs_to_counter_cache_before_destroy_for_' + self.class.name.downcase).to_sym
                if(o.respond_to? counter_method) then
                  class << o
                    self
                  end.send(:define_method, counter_method, Proc.new {})
                end
                o.destroy!
              end
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send(:extend, DeleteParanoid::ActiveRecordExtensions)
