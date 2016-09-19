require 'spec_helper'

describe DeleteParanoid do

  shared_examples_for "soft-deleted" do
    it do
      expect(subject.class.where(:id => subject.id)).not_to exist
      subject.class.with_deleted do
        expect(subject.class.where(:id => subject.id)).to exist
      end
    end
  end

  shared_examples_for "permanently-deleted" do
    it do
      expect(subject.class.where(:id => subject.id)).not_to exist
      subject.class.with_deleted do
        expect(subject.class.where(:id => subject.id)).not_to exist
      end
    end
  end

  context 'with non-paranoid activerecord class' do
    it { expect(Link).not_to be_paranoid }
  end

  context 'with paranoid activerecord class' do
    it { expect(Blog).to be_paranoid }
  end

  let!(:blog) { Blog.create! :title => 'foo' }

  context 'with instance of paranoid class' do
    subject { blog }
    context 'when destroying instance with instance.destroy' do
      before { blog.destroy }
      it do
        is_expected.to be_destroyed
        is_expected.to be_frozen
        is_expected.to trigger_callbacks_for :destroy
        is_expected.to_not trigger_callbacks_for :update
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
        is_expected.to trigger_callbacks_for :destroy
        is_expected.not_to trigger_callbacks_for :update
      end
    end
    context 'when destroying instance with instance.delete_permanently' do
      before { blog.delete_permanently }
      it_behaves_like "permanently-deleted"
      it do
        is_expected.not_to trigger_callbacks_for :destroy
        is_expected.not_to trigger_callbacks_for :update
      end
    end
  end

  context 'with paranoid instance that belongs to paranoid instance via dependent => destroy' do
    let!(:comment) { blog.comments.create! :text => 'bar' }
    subject { comment }

    context 'when destroying parent paranoid instance with destroy' do
      before { blog.destroy }
      it do
        is_expected.to be_destroyed
        is_expected.to be_frozen
        is_expected.to trigger_callbacks_for :destroy
        is_expected.not_to trigger_callbacks_for :update
      end
    end
    context 'when destroying parent paranoid instance with delete_all_permanently' do
      before { Blog.where(:id => blog.id).delete_all_permanently }
      it do
        is_expected.not_to be_destroyed
        is_expected.not_to be_frozen
        is_expected.not_to trigger_callbacks_for :destroy
        expect(Comment.where(:id => comment.id)).to exist
      end
    end
  end

  context 'with non-paranoid instance that belongs to paranoid instance via dependent => destroy' do
    let!(:link) { blog.links.create! :name => 'bar' }
    subject { link }

    context 'when destroying parent paranoid instance with destroy' do
      before { blog.destroy }
      it do
        is_expected.to be_destroyed
        is_expected.to be_frozen
        is_expected.to trigger_callbacks_for :destroy
        is_expected.not_to trigger_callbacks_for :update
        expect(Link.where(:id => link.id)).not_to exist
      end
    end

    context 'when destroying parent paranoid instance with delete_all_permanently' do
      before { Blog.where(:id => blog.id).delete_all_permanently }
      it do
        is_expected.not_to be_destroyed
        is_expected.not_to be_frozen
        is_expected.not_to trigger_callbacks_for :destroy
        expect(Link.where(:id => link.id)).to exist
      end
    end
  end
end

