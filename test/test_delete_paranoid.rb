require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  class Blog < ActiveRecord::Base
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
    end

    should 'fire destroy callbacks'
    should 'hard delete with destroy!'
  end
end
