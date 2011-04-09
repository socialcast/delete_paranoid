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
    def destroy_all!(conditions = nil)
      if @klass.paranoid?
        @klass.with_deleted do
          where(conditions).each do |record|
            record.destroy!
          end
        end
      else
        where(conditions).each do |record|
          record.destroy
        end
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
    # permenantly destroy the record(s) from the database
    def destroy!(id_or_array)
      where(self.primary_key => id_or_array).destroy_all!
    end
    # permenantly delete the record(s) from the database
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
    # permenantly destroy this record and all dependent records from the database
    def destroy!
      enable_hard_dependent_destroy_callbacks
      destroy.tap do |result|
        self.class.with_deleted do
          self.class.delete! self.id
        end
      end
    end

    # permenantly delete this specific record from the database
    def delete!
      delete.tap do |result|
        self.class.with_deleted do
          self.class.delete! self.id
        end
      end
    end
    
    # softly delete this record from the database
    def delete
      if persisted?
        self.deleted_at = Time.now.utc
        self.class.update_all ["deleted_at = ?", self.deleted_at ], { :id => self.id }
      end
      @destroyed = true
      freeze        
    end
    
  private
  
    def dependent_destroy_reflections
      self.class.reflect_on_all_associations.select do |reflection|
        reflection.klass.paranoid? and reflection.options[:dependent] == :destroy
      end
    end
    
    def replace_single_dependent_callback(reflection)
      (class << self; self; end).class_eval do
        define_method(:"#{reflection.macro}_dependent_destroy_for_#{reflection.name}") do 
          reflection.klass.with_deleted do
            association = send(reflection.name)
            association.destroy! if association
          end
        end
      end
    end
    
    def replace_multiple_dependent_callback(reflection)
      (class << self; self; end).class_eval do
        define_method(:"#{reflection.macro}_dependent_destroy_for_#{reflection.name}") do 
          reflection.klass.with_deleted do
            send(reflection.name).each do |dependent|
              disable_dependent_counter_cache(dependent)
              dependent.destroy!
            end
          end
        end
      end
    end
  
    def disable_dependent_counter_cache(dependent)
      counter_method = :"belongs_to_counter_cache_before_destroy_for_#{self.class.name.downcase}"
      if dependent.respond_to? counter_method
        class << dependent
          self
        end.send(:define_method, counter_method, lambda {})
      end
    end
  
    def enable_hard_dependent_destroy_callbacks
      dependent_destroy_reflections.each do |reflection|
        case reflection.macro
        when :has_one, :belongs_to
          replace_single_dependent_callback(reflection)
        when :has_many
          replace_multiple_dependent_callback(reflection)
        end
      end
    end
  end
end

ActiveRecord::Base.send(:extend, DeleteParanoid::ActiveRecordExtensions)
