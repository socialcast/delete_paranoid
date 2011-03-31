require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  class Blog < ActiveRecord::Base
    acts_as_paranoid
  end
  context 'with paranoid class' do
    should 'have delete_all! method' do
      assert Blog.respond_to? :delete_all!
    end
    context 'when on instance destroyed' do
      setup do
        @blog = Blog.create! :title => 'foo'
        @blog.destroy
      end
      should 'not be included in all results' do
        assert !Blog.all.include?(@blog)
      end
    end

    should 'fire destroy callbacks'
  end
end
