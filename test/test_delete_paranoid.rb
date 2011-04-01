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
    end

    should 'hard delete with destroy!'

    context 'when an instance has_many' do
      setup do
        @comment = Comment.create! :text => 'bar'
        @blog = Blog.create!(:title => 'foo').tap do |blog|
          blog.comments << @comment
        end
        @blog.destroy
      end
      should 'not be included in all results' do
        assert !Blog.all.include?(@blog)
        assert !Comment.all.include?(@comment)
      end
      should 'be included when wrapped in with_deleted block' do
        Blog.with_deleted do
          Comment.with_deleted do
            assert Blog.all.include?(@blog)
            assert Comment.all.include?(@comment)
          end
        end
      end
    end
  end
end
