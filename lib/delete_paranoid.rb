require 'active_record'

module DeleteParanoid
  module ActiveRecordExtensions
    def acts_as_paranoid
      class << self
        alias_method :destroy!, :destroy
        alias_method :delete_all!, :delete_all
      end
      alias_method :delete!, :delete
      alias_method :destroy!, :destroy
      default_scope where(:deleted_at => nil)
      extend DeleteParanoid::ClassMethods
      include DeleteParanoid::InstanceMethods  
    end
    
    def paranoid?
      self.included_modules.include?(InstanceMethods)
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
    
    def self.included(base)
      base.class_eval do
        alias_method_chain :destroy!, :paranoid_dependents
      end
    end
    
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
