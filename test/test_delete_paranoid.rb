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
      
      should_soft_destroy :blog
      should_trigger_destroy_callbacks :blog
      should_not_trigger_update_callbacks :blog
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
      should_soft_destroy :comment
      should_trigger_destroy_callbacks :blog
      should_not_trigger_update_callbacks :blog
      should_trigger_destroy_callbacks :comment
      should_not_trigger_update_callbacks :comment
    end
    
    context "when on instance destroyed hardly" do
      setup do
        @blog = Blog.create! :title => 'foo'
        @blog.destroy!
      end

      should_hard_destroy :blog
      should_trigger_destroy_callbacks :blog
      should_not_trigger_update_callbacks :blog
    end
    
    context 'when an instance with dependents is destroyed hardly' do
       setup do
         @comment = Comment.create! :text => 'bar'
         @blog = Blog.create!(:title => 'foo').tap do |blog|
           blog.comments << @comment
         end
         @blog.destroy!
       end

       should_hard_destroy :blog
       should_hard_destroy :comment
       should_trigger_destroy_callbacks :blog
       should_not_trigger_update_callbacks :blog
       should_trigger_destroy_callbacks :comment
       should_not_trigger_update_callbacks :comment
     end
    
  end
end
