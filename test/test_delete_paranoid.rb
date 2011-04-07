require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  
  context 'with non-paranoid activerecord class' do
    should 'not be paranoid' do
      assert !Link.paranoid?
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
      @blog.reset_callback_flags!
    end
    context 'when destroying instance with instance.destroy' do
       subject do
         @blog.destroy
         @blog
       end
       
       should destroy_subject.softly.and_freeze.and_mark_as_destroyed
       should trigger_callbacks.for :destroy
       should_not trigger_callbacks.for :update
     end
     context 'when destroying instance with instance.destroy!' do
       subject do
         @blog.destroy!
         @blog
       end
       
       should destroy_subject.and_freeze.and_mark_as_destroyed
       should trigger_callbacks.for :destroy
       should_not trigger_callbacks.for :update
     end
    
    context "when destroying collection with reflection destroy_all" do
      subject do
        Blog.where({:id => @blog.id}).destroy_all
        @blog
      end
      should destroy_subject.softly
    end
    context "when destroying collection with reflection destroy_all!" do
      subject do
        Blog.where({:id => @blog.id}).delete_all!
        @blog
      end
      should destroy_subject
    end
    context "when destroying collection with reflection delete_all" do
      subject do
        Blog.where({:id => @blog.id}).delete_all
        @blog
      end
      should destroy_subject.softly
    end
    context "when destroying collection with reflection delete_all!!" do
      subject do
        Blog.where({:id => @blog.id}).delete_all!
        @blog
      end
      should destroy_subject
    end

  end
  
  context 'with paranoid instance that has belongs to paranoid instance' do
    setup do
      @blog = Blog.create!(:title => 'foo')
      @comment = @blog.comments.create! :text => 'bar'
      @comment.reset_callback_flags!
    end
    context 'when destroying parent paranoid instance with delete' do
      subject do
        @blog.delete
        @comment
      end
  
      should_not destroy_subject
      should_not trigger_callbacks
    end
    context 'when destroying parent paranoid instance with delete!' do
      subject do
        @blog.delete!
        @comment
      end
  
      should_not destroy_subject
      should_not trigger_callbacks
    end
    context 'when destroying parent paranoid instance with destroy' do
      subject do
        @blog.destroy
        @comment
      end
  
      should destroy_subject.softly.and_freeze.and_mark_as_destroyed
      should trigger_callbacks.for :destroy
      should_not trigger_callbacks.for :update
    end
    context 'when destroying parent paranoid instance with destroy!' do
      subject do
        @blog.destroy!
        @comment
      end
  
      should destroy_subject.and_freeze.and_mark_as_destroyed
      should trigger_callbacks.for :destroy
      should_not trigger_callbacks.for :update
    end
    context 'when destroying parent paranoid instance with delete_all!' do
      subject do
        Blog.where({:id => @blog.id}).delete_all!
        @comment
      end
   
      should_not destroy_subject
    end
    context 'when destroying parent paranoid instance with destroy_all!' do
      subject do
        Blog.where({:id => @blog.id}).destroy_all!
        @comment
      end
  
      should destroy_subject
    end
  end
  
  context 'with non-paranoid instance that has belongs to paranoid instance' do
    setup do
      @blog = Blog.create!(:title => 'foo')
      @link = @blog.links.create! :name => 'bar'
      @link.reset_callback_flags!
    end
    context 'when destroying parent paranoid instance with destroy' do
      subject do
        @blog.delete
        @link
      end
  
      should_not destroy_subject
      should_not trigger_callbacks
    end
    context 'when destroying parent paranoid instance with destroy!' do
      subject do
        @blog.delete!
        @link
      end
  
      should_not destroy_subject
      should_not trigger_callbacks
    end
    context 'when destroying parent paranoid instance with destroy' do
      subject do
        @blog.destroy
        @link
      end
  
      should destroy_subject.and_freeze.and_mark_as_destroyed
      should trigger_callbacks.for :destroy
      should_not trigger_callbacks.for :update
    end
    context 'when destroying parent paranoid instance with destroy!' do
      subject do
        @blog.destroy!
        @link
      end
  
      should destroy_subject.and_freeze.and_mark_as_destroyed
      should trigger_callbacks.for :destroy
      should_not trigger_callbacks.for :update
    end
    context 'when destroying parent paranoid instance with delete_all!' do
      subject do
        Blog.where({:id => @blog.id}).delete_all!
        @link
      end
      should_not destroy_subject
    end
    context 'when destroying parent paranoid instance with destroy_all!' do
      subject do
        Blog.where({:id => @blog.id}).destroy_all!
        @link
      end
      should destroy_subject
    end
  end

end
