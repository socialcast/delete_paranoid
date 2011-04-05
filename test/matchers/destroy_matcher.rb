  
class DestroyMatcher
  
  module MatcherMethods
    def soft_destroy
      DestroyMatcher.new :soft
    end
    def hard_destroy
      DestroyMatcher.new :hard
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
