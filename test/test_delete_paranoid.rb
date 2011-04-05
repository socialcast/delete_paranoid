require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  class Blog < ActiveRecord::Base
    has_many :comments, :dependent => :destroy
    acts_as_paranoid
    attr_accessible :title
    include CallbackMatcher::ActiveRecordHooks
  end

  class Comment < ActiveRecord::Base
    acts_as_paranoid
    attr_accessible :text
    belongs_to :blog
    include CallbackMatcher::ActiveRecordHooks
  end

  class Link < ActiveRecord::Base
    belongs_to :blog
    attr_accessible :name
    include CallbackMatcher::ActiveRecordHooks
  end

  context 'with non-paranoid activerecord class' do
    should 'not be paranoid' do
      assert !Link.paranoid?
    end
  end
  context 'with paranoid activerecord class' do
    should 'be paranoid' do
      assert Blog.paranoid?
    end
  end
  context 'with instance of paranoid class' do
    subject do
      @blog = Blog.create! :title => 'foo'
    end
    context 'when destroying instance with instance.destroy' do
      setup do
        @now = Time.now.utc
        Timecop.travel @now do
          @blog.destroy
        end
      end
      
      should destroy_subject.softly.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      should_not trigger_callbacks_for :update
    end
    context 'when destroying instance with Class.destroy_all' do
      setup do
        Blog.destroy_all :id => @blog.id
      end
      should destroy_subject.softly
    end
    context "when destroying instance with Class.delete_all!" do
      setup do
        Blog.where({:id => @blog.id}).delete_all!
      end
      should destroy_subject
    end
    context "when destroying instance with Class.delete!" do
      setup do
        Blog.delete! @blog.id
      end
      should destroy_subject
    end
    context 'when destroying instance with instance.destroy!' do
      setup do
        @blog.destroy!
      end
      should destroy_subject
      should trigger_callbacks_for :destroy
      should_not trigger_callbacks_for :update
    end
    context 'when destroying instance with instance.delete!' do
      setup do
        @blog.delete!
      end
      should destroy_subject
    end
  end

  context 'with paranoid instance that has belongs to paranoid instance' do
    subject do
      @blog = Blog.create!(:title => 'foo')
      @comment = @blog.comments.create! :text => 'bar'
    end
    context 'when destroying parent paranoid instance with destroy' do
      setup do
        @blog.destroy
      end

      should destroy_subject.softly.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      #should_not trigger_callbacks_for :update
    end
    context 'when destroying parent paranoid instance with delete_all!' do
       setup do
         Blog.where({:id => @blog.id}).delete_all!
       end

       should_not destroy_subject
     end
  end

  context 'with non-paranoid instance that has belongs to paranoid instance' do
    subject do
      @blog = Blog.create!(:title => 'foo')
      @link = @blog.links.create! :name => 'bar'
    end
    context 'when destroying parent paranoid instance with destroy' do
      setup do
        @blog.destroy
      end

      should destroy_subject.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      #should_not trigger_callbacks_for :update
    end
    context 'when destroying parent paranoid instance with delete_all!' do
       setup do
         Blog.where({:id => @blog.id}).delete_all!
       end

       should_not destroy_subject
     end
  end
end

