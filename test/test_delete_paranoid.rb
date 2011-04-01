require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  class Blog < ActiveRecord::Base
    has_many :comments, :dependent => :destroy
    acts_as_paranoid
    include CallbackTester
  end

  class Comment < ActiveRecord::Base
    acts_as_paranoid
    include CallbackTester
  end
  
  context 'with paranoid class' do
    should 'have destroy! method' do
      assert Blog.respond_to? :destroy!
    end
    
    context 'when on instance destroyed softly' do
      setup do
        @blog = Blog.create! :title => 'foo'
        @blog.destroy
      end
      should 'not be included in all results' do
        assert !Blog.all.include?(@blog)
      end
      should 'be included when wrapped in with_deleted block' do
        Blog.with_deleted do
          assert Blog.all.include?(@blog)
        end
      end
      should "call before_destroy callbacks" do
        assert @blog.called_before_destroy
      end
      should "call after_destroy callbacks" do
        assert @blog.called_after_destroy
      end
      should "call after_commit_on_destroy callbacks" do
        assert @blog.called_after_commit_on_destroy
      end
      should "set deleted_at" do
        assert_not_nil @blog.deleted_at
      end
      context 'when an instance has dependent' do
        setup do
          @comment = Comment.create! :text => 'bar'
          @blog = Blog.create!(:title => 'foo').tap do |blog|
            blog.comments << @comment
          end
          @blog.destroy
        end
        should 'not be included in all results' do
          assert !Comment.all.include?(@comment)
        end
        should 'be included when wrapped in with_deleted block' do
          Blog.with_deleted do
            Comment.with_deleted do
              assert Comment.all.include?(@comment)
            end
          end
        end
        should "call before_destroy callbacks" do
          assert @comment.called_before_destroy
        end
        should "call after_destroy callbacks" do
          assert @comment.called_after_destroy
        end
        should "call after_commit_on_destroy callbacks" do
          assert @comment.called_after_commit_on_destroy
        end
        should "set deleted_at" do
          assert_not_nil @comment.deleted_at
        end
      end
    end
    context "when on instance destroyed hardly" do
      setup do
        @blog = Blog.create! :title => 'foo'
        @blog.destroy!
      end
      should 'not be included in all results' do
        assert !Blog.all.include?(@blog)
      end
      should 'not be included when wrapped in with_deleted block' do
        Blog.with_deleted do
          assert !Blog.all.include?(@blog)
        end
      end
      should "call before_destroy callbacks" do
        assert @blog.called_before_destroy
      end
      should "call after_destroy callbacks" do
        assert @blog.called_after_destroy
      end
      should "call after_commit_on_destroy callbacks" do
        assert @blog.called_after_commit_on_destroy
      end
    end
  end
end
