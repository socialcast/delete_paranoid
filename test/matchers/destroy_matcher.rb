
module DeleteParanoid
  class DestroyMatcher
    def softly
      @softly = true
      self
    end
    def and_freeze
      @frozen = true
      self
    end
    def and_mark_as_destroyed
      @destroyed = true
      self
    end
    def description
      "destroy the subject"
    end
    def matches?(subject)
      @subject = subject
      errors.empty?
    end
    def failure_message
      "Expected #{@subject.inspect} to be destroyed: #{errors.join("\n")}"
    end
    def errors
      return @errors if @errors
      @errors = []
      @errors << "was found in database" if subject_found?
      @errors << "was not found with_deleted in database" if softly? && !subject_found_with_deleted?
      @errors << "did not populate deleted_at timestamp" if softly? && !subject_deleted_at?
      @errors << "did not freeze instance" if frozen? && !@subject.frozen?
      @errors << "did not destroy instance" if destroyed? && !@subject.destroyed?
      @errors
    end
    def softly?
      !!@softly
    end
    def frozen?
      !!@frozen
    end
    def destroyed?
      !!@destroyed
    end
    def subject_found?
      !!@subject.class.find(@subject.id)
    rescue ActiveRecord::RecordNotFound
      false
    end
    def subject_found_with_deleted?
      @subject.class.with_deleted do
        !!@subject.class.find(@subject.id)
      end
    rescue ActiveRecord::RecordNotFound
      false
    end
    def subject_deleted_at?
      @subject.class.with_deleted do
        @subject.class.find(@subject.id).deleted_at
      end
    rescue ActiveRecord::RecordNotFound
      false
    end

  end
end

class DestroyMatcher
  module MatcherMethods
    def soft_destroy
      DestroyMatcher.new :soft
    end
    def hard_destroy
      DestroyMatcher.new :hard
    end
    def destroy_subject
      DeleteParanoid::DestroyMatcher.new
    end
  end
  
  def initialize(force)
    @force = force
  end
  
  def hard?
    @force == :hard
  end
  
  def soft?
    @force == :soft
  end
  
  def failure_message
    "Expected #{@subject} to be #{@force}ly destroyed:\n #{expectation}"
  end
  
  def negative_failure_message
    "Did not expect #{@subject} to be #{@force}ly destroyed:\n #{expectation}"
  end
  
  def description
    "#{@force} destroy the record"
  end
  
  def expectation
    [].tap do |msgs|
      msgs << 'has deleted_at set' if @set_deleted_at_failed
      msgs << 'responds as destroyed' if @set_destroyed_failed
      msgs << 'responds as frozen' if @set_frozen_failed
      msgs << 'cannot be found normally' if @not_found_normally_failed
      msgs << 'can be found with_deleted' if @found_with_deleted_failed
    end.join("\n")
  end
   
  def anything_fail?
    @set_deleted_at_failed || @set_destroyed_failed || @set_frozen_failed || @not_found_normally_failed || @found_with_deleted_failed
  end
  
  def matches?(subject)
    @subject = subject
    @set_deleted_at_failed = soft? && subject.deleted_at.nil?
    @set_destroyed_failed = !subject.destroyed?
    @set_frozen_failed = !subject.frozen?
    @not_found_normally_failed = found_normally?
    @found_with_deleted_failed = hard? ? found_with_deleted? : !found_with_deleted?
    !anything_fail?
  end
  
  def found_normally?
    !! @subject.class.find( @subject.id )
  rescue ActiveRecord::RecordNotFound
    false
  end
  
  def found_with_deleted?
    @subject.class.with_deleted do
      !! @subject.class.find( @subject.id )
    end
  rescue ActiveRecord::RecordNotFound
    false
  end
  
end
