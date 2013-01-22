require File.join(File.expand_path(File.dirname(__FILE__)), 'helper.rb')

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
    end
    context 'when destroying instance with instance.destroy' do
      subject do
        @blog.destroy
        @blog
      end
      should destroy_subject.softly.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      should_not trigger_callbacks_for :update
    end
    context 'when destroying instance with Class.destroy_all' do
      subject do
        Blog.destroy_all :id => @blog.id
        @blog
      end
      should destroy_subject.softly
    end
    context "when destroying instance with Class.delete_all_permanently" do
      subject do
        Blog.where({:id => @blog.id}).delete_all_permanently
        @blog
      end
      should destroy_subject
    end
    context "when destroying instance with Class.delete_permanently" do
      subject do
        Blog.delete_permanently @blog.id
        @blog
      end
      should destroy_subject
    end
    context 'when destroying instance with instance.destroy_permanently' do
      subject do
        @blog.destroy_permanently
        @blog
      end
      should destroy_subject
      should trigger_callbacks_for :destroy
      should_not trigger_callbacks_for :update
    end
    context 'when destroying instance with instance.delete_permanently' do
      subject do
        @blog.delete_permanently
        @blog
      end
      should destroy_subject
    end
  end

  context 'with paranoid instance that has belongs to paranoid instance' do
    setup do
      @blog = Blog.create!(:title => 'foo')
      @comment = @blog.comments.create! :text => 'bar'
    end
    context 'when destroying parent paranoid instance with destroy' do
      subject do
        @blog.destroy
        @comment
      end

      should destroy_subject.softly.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      #should_not trigger_callbacks_for :update
    end
    context 'when destroying parent paranoid instance with delete_all_permanently' do
       subject do
         Blog.where({:id => @blog.id}).delete_all_permanently
         @comment
       end

       should_not destroy_subject
     end
  end

  context 'with non-paranoid instance that has belongs to paranoid instance' do
    setup do
      @blog = Blog.create!(:title => 'foo')
      @link = @blog.links.create! :name => 'bar'
    end
    context 'when destroying parent paranoid instance with destroy' do
      subject do
        @blog.destroy
        @link
      end

      should destroy_subject.and_freeze.and_mark_as_destroyed
      should trigger_callbacks_for :destroy
      #should_not trigger_callbacks_for :update
    end
    context 'when destroying parent paranoid instance with delete_all_permanently' do
       subject do
         Blog.where({:id => @blog.id}).delete_all_permanently
         @link
       end

       should_not destroy_subject
     end
  end
end

