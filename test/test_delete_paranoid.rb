require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  class Blog < ActiveRecord::Base
    has_many :comments, :dependent => :destroy
    has_many :links, :dependent => :destroy
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
    setup do
      @blog = Blog.create! :title => 'foo'
    end
    context 'when destroying instance with instance.destroy' do
      subject do
        @blog.destroy
        @blog
      end
      
      should destroy_subject.softly.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      should_not trigger_callbacks_for :update
    end
    context 'when destroying instance with Class.destroy_all' do
      subject do
        Blog.destroy_all :id => @blog.id
        @blog
      end
      should destroy_subject.softly
    end
    context "when destroying instance with Class.delete_all!" do
      subject do
        Blog.where({:id => @blog.id}).delete_all!
        @blog
      end
      should destroy_subject
    end
    context "when destroying instance with Class.delete!" do
      subject do
        Blog.delete! @blog.id
        @blog
      end
      should destroy_subject
    end
    context 'when destroying instance with instance.destroy!' do
      subject do
        @blog.destroy!
        @blog
      end
      should destroy_subject
      should trigger_callbacks_for :destroy
      should_not trigger_callbacks_for :update
    end
    context 'when destroying instance with instance.delete!' do
      subject do
        @blog.delete!
        @blog
      end
      should destroy_subject
    end
  end

  context 'with paranoid instance that has belongs to paranoid instance' do
    setup do
      @blog = Blog.create!(:title => 'foo')
      @comment = @blog.comments.create! :text => 'bar'
    end
    context 'when destroying parent paranoid instance with destroy' do
      subject do
        @blog.destroy
        @comment
      end

      should destroy_subject.softly.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      #should_not trigger_callbacks_for :update
    end
    context 'when destroying parent paranoid instance with delete_all!' do
       subject do
         Blog.where({:id => @blog.id}).delete_all!
         @comment
       end

       should_not destroy_subject
     end
  end

  context 'with non-paranoid instance that has belongs to paranoid instance' do
    setup do
      @blog = Blog.create!(:title => 'foo')
      @link = @blog.links.create! :name => 'bar'
    end
    context 'when destroying parent paranoid instance with destroy' do
      subject do
        @blog.destroy
        @link
      end

      should destroy_subject.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      #should_not trigger_callbacks_for :update
    end
    context 'when destroying parent paranoid instance with delete_all!' do
       subject do
         Blog.where({:id => @blog.id}).delete_all!
         @link
       end

       should_not destroy_subject
     end
  end
end

