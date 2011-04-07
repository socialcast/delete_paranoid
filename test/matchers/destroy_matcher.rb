
module DeleteParanoid

  class DestroyMatcher
  
    module MatcherMethods
      def soft_destroy
        DestroyMatcher.new :soft
      end
      def hard_destroy
        DestroyMatcher.new :hard
      end
      def destroy_subject
        DestroyMatcher.new
      end
    end
  
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
      @errors << 'was found with_deleted in database' if !softly? && subject_paranoid? && subject_found_with_deleted?
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
    def subject_paranoid?
      @subject.class.paranoid?
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
