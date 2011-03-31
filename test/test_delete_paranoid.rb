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
      should 'not be included in total count' do
        fail
      end
    end
  end
end
