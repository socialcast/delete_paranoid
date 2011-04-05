require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  class Blog < ActiveRecord::Base
    has_many :comments, :dependent => :destroy
    has_many :links
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
  end
  
  context "with non-paranoid class" do
    should "have paranoid? but not be paranoid" do
      assert Link.respond_to? :paranoid?
      assert !Link.paranoid?
    end
  end
  
  context 'with paranoid class' do
    should 'have have new class methods methods' do
      [:destroy, :delete!, :destroy_all!, :delete_all!].each do |method|
        assert Blog.respond_to? method
      end  
    end
    should "have new instance methods" do
      [:destroy!, :delete!].each do |method|
        assert Blog.new.respond_to? method
      end
    end
    
    context "an instance of the class" do
      setup do
        @blog = Blog.create!(:title => 'foo')
      end
      
      context 'is destroyed softly' do
        subject { @blog.destroy; @blog }
        should soft_destroy
        should trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
      end
      
      context 'is deleted softly' do
        subject { @blog.delete; @blog }
        should soft_destroy
        should_not trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
      end
      
      context "is destroyed hardly" do
        subject { @blog.destroy!; @blog }
        should hard_destroy
        should trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
      end
      
      context "is deleted hardly" do
        subject { @blog.delete!; @blog }
        should hard_destroy
        should_not trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
      end
      
    end
    
    context 'instance with a dependent' do
      setup do
        @blog = Blog.create!(:title => 'foo')
        @comment = @blog.comments.create! :text => 'bar'
      end
      
      context "destroyed softly" do
        setup { @blog.destroy }
        context "the instance" do
          subject { @blog }
          should soft_destroy
          should trigger_callbacks_for :destroy
          should_not trigger_callbacks_for :update
        end

        context "the dependent" do
          subject { @comment }
          should soft_destroy
          should trigger_callbacks_for :destroy
          should_not trigger_callbacks_for :update
        end
      end
      
      context "deleted softly" do
        setup { @blog.delete }
        context "the instance" do
          subject { @blog }
          should soft_destroy
          should_not trigger_callbacks_for :destroy
          should_not trigger_callbacks_for :update
        end

        context "the dependent" do
          subject { @comment }
          should_not soft_destroy
          should_not trigger_callbacks_for :destroy
          should_not trigger_callbacks_for :update
        end
      end
      
      context "destroyed hardly" do
        setup { @blog.destroy! }
        context "the instance" do
          subject { @blog }
          should hard_destroy
          should trigger_callbacks_for :destroy
          should_not trigger_callbacks_for :update
        end

        context "the dependent" do
          subject { @comment }
          should hard_destroy
          should trigger_callbacks_for :destroy
          should_not trigger_callbacks_for :update
        end
      end
      
      context "deleted hardly" do
        setup { @blog.delete! }
        context "the instance" do
          subject { @blog }
          should hard_destroy
          should_not trigger_callbacks_for :destroy
          should_not trigger_callbacks_for :update
        end

        context "the dependent" do
          subject { @comment }
          should_not hard_destroy
          should_not trigger_callbacks_for :destroy
          should_not trigger_callbacks_for :update
        end
      end
    end
  end
end
