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

  class User < ActiveRecord::Base
  end
  context 'with non-paranoid activerecord class' do
    should 'not be paranoid' do
      assert !User.paranoid?
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
    context 'when destroying instance' do
      setup do
        @now = Time.now.utc
        Timecop.travel @now do
          @blog.destroy
        end
      end
      
      should soft_destroy
      should trigger_callbacks_for :destroy
      should_not trigger_callbacks_for :update
      should 'save deleted_at timestamp on database record' do
        blog = Blog.find_by_sql(['SELECT deleted_at FROM blogs WHERE id = ?', @blog.id]).first
        assert_not_nil blog
        assert_not_nil blog.deleted_at
        assert_equal @now.to_i, blog.deleted_at.to_i
      end
    end
    context 'when destroying instance with destroy_all' do
      setup do
        Blog.destroy_all :id => @blog.id
      end
      should "not find instance normally" do
        assert_raises ActiveRecord::RecordNotFound do
          Blog.find @blog.id
        end
      end
      should "find instance when in with_deleted block" do
        Blog.with_deleted do
          assert_nothing_raised ActiveRecord::RecordNotFound do
            Blog.find @blog.id
          end
        end
      end
    end
    context "when destroying instance with delete_all!" do
      setup do
        @blog = Blog.create! :title => 'foo'
        Blog.where({:id => @blog.id}).delete_all!
      end
      should hard_destroy
    end
    context "when destroying instance with delete!" do
      setup do
        @blog = Blog.create! :title => 'foo'
        Blog.delete! @blog.id
      end
      should hard_destroy
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

      should soft_destroy
      should trigger_callbacks_for :destroy
      #should_not trigger_callbacks_for :update
    end
    context 'when destroying parent paranoid instance with delete_all!' do
       setup do
         Blog.where({:id => @blog.id}).delete_all!
       end

       should hard_destroy
       should 'not destroy associated comment' do
         assert_not_nil @comment.reload
         assert_nil @comment.blog
       end
     end
  end
end

