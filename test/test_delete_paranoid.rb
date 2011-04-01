require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  class Blog < ActiveRecord::Base
    acts_as_paranoid

    has_many :comments, :dependent => :destroy
    
    attr_accessor :called_before_destroy, :called_after_destroy, :called_after_commit_on_destroy

    before_destroy :call_me_before_destroy
    after_destroy :call_me_after_destroy

    after_commit :call_me_after_commit_on_destroy, :on => :destroy

    def initialize(*attrs)
      @called_before_destroy = @called_after_destroy = @called_after_commit_on_destroy = false
      super(*attrs)
    end

    def call_me_before_destroy
      @called_before_destroy = true
    end

    def call_me_after_destroy
      @called_after_destroy = true
    end

    def call_me_after_commit_on_destroy
      @called_after_commit_on_destroy = true
    end
  end

  class Comment < ActiveRecord::Base
    acts_as_paranoid
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
