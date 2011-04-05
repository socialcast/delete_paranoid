require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  class Blog < ActiveRecord::Base
    has_many :comments, :dependent => :destroy
    acts_as_paranoid
    attr_accessible :title
    include CallbackTester
  end

  class Comment < ActiveRecord::Base
    acts_as_paranoid
    attr_accessible :text
    belongs_to :blog
    include CallbackTester
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
    setup do
      @blog = Blog.create! :title => 'foo'
    end
    context 'when destroying instance with instance.destroy' do
      setup do
        @now = Time.now.utc
        Timecop.travel @now do
          @blog.destroy
        end
      end
      
      should_soft_destroy :blog
      should_trigger_destroy_callbacks :blog
      should_not_trigger_update_callbacks :blog
      should 'save deleted_at timestamp on database record' do
        blog = Blog.find_by_sql(['SELECT deleted_at FROM blogs WHERE id = ?', @blog.id]).first
        assert_not_nil blog
        assert_not_nil blog.deleted_at
        assert_equal @now.to_i, blog.deleted_at.to_i
      end
    end
    context 'when destroying instance with Class.destroy_all' do
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
    context "when destroying instance with Class.delete_all!" do
      setup do
        Blog.where({:id => @blog.id}).delete_all!
      end
      should_hard_destroy :blog
    end
    context "when destroying instance with Class.delete!" do
      setup do
        Blog.delete! @blog.id
      end
      should_hard_destroy :blog
    end
    context 'when destroying instance with instance.destroy!' do
      setup do
        @blog.destroy!
      end
      should_hard_destroy :blog
    end
    context 'when destroying instance with instance.delete!' do
      setup do
        @blog.delete!
      end
      should_hard_destroy :blog
    end
  end

  context 'with paranoid instance that has dependents' do
    setup do
      @blog = Blog.create!(:title => 'foo')
      @comment = @blog.comments.create! :text => 'bar'
    end
    context 'when destroying paranoid instance' do
      setup do
        @blog.destroy
      end

      should_soft_destroy :blog
      should_trigger_destroy_callbacks :blog
      should_not_trigger_update_callbacks :blog
      
      should_soft_destroy :comment
      should_trigger_destroy_callbacks :comment
    end
    context 'when destroying paranoid instance with delete_all!' do
       setup do
         Blog.where({:id => @blog.id}).delete_all!
       end

       should_hard_destroy :blog
       should 'not destroy associated comment' do
         assert_not_nil @comment.reload
         assert_nil @comment.blog
       end
     end
  end
end
