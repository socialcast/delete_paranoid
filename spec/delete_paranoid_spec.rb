require 'spec_helper'

describe DeleteParanoid do

  shared_examples_for "soft-deleted" do
    it do
      subject.class.where(:id => subject.id).should_not exist
      subject.class.with_deleted do
        subject.class.where(:id => subject.id).should exist
      end
    end
  end

  shared_examples_for "permanently-deleted" do
    it do
      subject.class.where(:id => subject.id).should_not exist
      subject.class.with_deleted do
        subject.class.where(:id => subject.id).should_not exist
      end
    end
  end

  context 'with non-paranoid activerecord class' do
    it { Link.should_not be_paranoid }
  end

  context 'with paranoid activerecord class' do
    it { Blog.should be_paranoid }
  end

  let!(:blog) { Blog.create! :title => 'foo' }

  context 'with instance of paranoid class' do
    subject { blog }
    context 'when destroying instance with instance.destroy' do
      before { blog.destroy }
      it do
        should be_destroyed
        should be_frozen
        should trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
      end
      it_behaves_like "soft-deleted"
    end

    context 'when destroying instance with Class.destroy_all' do
      before { Blog.where(:id => blog.id).destroy_all }
      it_behaves_like "soft-deleted"
    end

    context "when destroying instance with Class.delete_all_permanently" do
      before { Blog.where(:id => blog.id).delete_all_permanently }
      it_behaves_like "permanently-deleted"
    end

    context "when destroying instance with Class.delete_permanently" do
      before { Blog.delete_permanently blog.id }
      it_behaves_like "permanently-deleted"
    end
    context 'when destroying instance with instance.destroy_permanently' do
      before { blog.destroy_permanently }
      it_behaves_like "permanently-deleted"
      it do
        should trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
      end
    end
    context 'when destroying instance with instance.delete_permanently' do
      before { blog.delete_permanently }
      it_behaves_like "permanently-deleted"
      it do
        should_not trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
      end
    end
  end

  context 'with paranoid instance that belongs to paranoid instance via dependent => destroy' do
    let!(:comment) { blog.comments.create! :text => 'bar' }
    subject { comment }

    context 'when destroying parent paranoid instance with destroy' do
      before { blog.destroy }
      it do
        should be_destroyed
        should be_frozen
        should trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
      end
    end
    context 'when destroying parent paranoid instance with delete_all_permanently' do
      before { Blog.where(:id => blog.id).delete_all_permanently }
      it do
        should_not be_destroyed
        should_not be_frozen
        should_not trigger_callbacks_for :destroy
        Comment.where(:id => comment.id).should exist
      end
    end
  end

  context 'with non-paranoid instance that belongs to paranoid instance via dependent => destroy' do
    let!(:link) { blog.links.create! :name => 'bar' }
    subject { link }

    context 'when destroying parent paranoid instance with destroy' do
      before { blog.destroy }
      it do
        should be_destroyed
        should be_frozen
        should trigger_callbacks_for :destroy
        should_not trigger_callbacks_for :update
        Link.where(:id => link.id).should_not exist
      end
    end

    context 'when destroying parent paranoid instance with delete_all_permanently' do
      before { Blog.where(:id => blog.id).delete_all_permanently }
      it do
        should_not be_destroyed
        should_not be_frozen
        should_not trigger_callbacks_for :destroy
        Link.where(:id => link.id).should exist
      end
    end
  end
end

