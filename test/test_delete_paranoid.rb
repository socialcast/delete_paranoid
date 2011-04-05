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
    context 'when an instance destroyed softly' do
      setup do
        @blog = Blog.create! :title => 'foo'
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
    
    context 'when an instance with dependents is destroyed softly' do
      setup do
        @comment = Comment.create! :text => 'bar'
        @blog = Blog.create!(:title => 'foo').tap do |blog|
          blog.comments << @comment
        end
        @blog.destroy
      end

      should_soft_destroy :blog
      should_trigger_destroy_callbacks :blog
      should_not_trigger_update_callbacks :blog
      
      should_soft_destroy :comment
      should_trigger_destroy_callbacks :comment
    end
    
    context "when on instance deleted hardly" do
      setup do
        @blog = Blog.create! :title => 'foo'
        Blog.where({:id => @blog.id}).delete_all!
      end
      should_hard_destroy :blog
    end
    
    context 'when an instance with dependents is destroyed hardly' do
       setup do
         @comment = Comment.create! :text => 'bar'
         @blog = Blog.create!(:title => 'foo').tap do |blog|
           blog.comments << @comment
         end
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
