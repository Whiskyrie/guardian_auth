require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject(:policy) { described_class.new(actor, record) }

  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:other_user) { create(:user) }

  describe '#show?' do
    context 'when user views own profile' do
      let(:actor) { regular_user }
      let(:record) { regular_user }

      it { is_expected.to be_show }
    end

    context 'when admin views any profile' do
      let(:actor) { admin }
      let(:record) { other_user }

      it { is_expected.to be_show }
    end

    context 'when user views another user' do
      let(:actor) { regular_user }
      let(:record) { other_user }

      it { is_expected.not_to be_show }
    end

    context 'when unauthenticated' do
      let(:actor) { nil }
      let(:record) { regular_user }

      it { is_expected.not_to be_show }
    end
  end

  describe '#create?' do
    let(:record) { User }

    context 'when unauthenticated' do
      let(:actor) { nil }

      it { is_expected.to be_create }
    end

    context 'when authenticated' do
      let(:actor) { regular_user }

      it { is_expected.to be_create }
    end
  end

  describe '#update?' do
    context 'when user updates own profile' do
      let(:actor) { regular_user }
      let(:record) { regular_user }

      it { is_expected.to be_update }
    end

    context 'when admin updates any user' do
      let(:actor) { admin }
      let(:record) { other_user }

      it { is_expected.to be_update }
    end

    context 'when user tries to update another user' do
      let(:actor) { regular_user }
      let(:record) { other_user }

      it { is_expected.not_to be_update }
    end
  end

  describe '#destroy?' do
    context 'when admin deletes another user' do
      let(:actor) { admin }
      let(:record) { other_user }

      it { is_expected.to be_destroy }
    end

    context 'when admin tries to delete themselves' do
      let(:actor) { admin }
      let(:record) { admin }

      it { is_expected.not_to be_destroy }
    end

    context 'when regular user tries to delete anyone' do
      let(:actor) { regular_user }
      let(:record) { other_user }

      it { is_expected.not_to be_destroy }
    end
  end

  describe '#index?' do
    context 'when admin lists users' do
      let(:actor) { admin }
      let(:record) { User }

      it { is_expected.to be_index }
    end

    context 'when regular user tries to list users' do
      let(:actor) { regular_user }
      let(:record) { User }

      it { is_expected.not_to be_index }
    end
  end

  describe '#deactivate?' do
    context 'when admin deactivates another user' do
      let(:actor) { admin }
      let(:record) { other_user }

      it { is_expected.to be_deactivate }
    end

    context 'when admin tries to deactivate themselves' do
      let(:actor) { admin }
      let(:record) { admin }

      it { is_expected.not_to be_deactivate }
    end

    context 'when regular user tries to deactivate anyone' do
      let(:actor) { regular_user }
      let(:record) { other_user }

      it { is_expected.not_to be_deactivate }
    end

    context 'when unauthenticated' do
      let(:actor) { nil }
      let(:record) { other_user }

      it { is_expected.not_to be_deactivate }
    end
  end

  describe '#activate?' do
    context 'when admin activates any user' do
      let(:actor) { admin }
      let(:record) { other_user }

      it { is_expected.to be_activate }
    end

    context 'when admin activates themselves' do
      let(:actor) { admin }
      let(:record) { admin }

      it { is_expected.to be_activate }
    end

    context 'when regular user tries to activate anyone' do
      let(:actor) { regular_user }
      let(:record) { other_user }

      it { is_expected.not_to be_activate }
    end

    context 'when unauthenticated' do
      let(:actor) { nil }
      let(:record) { other_user }

      it { is_expected.not_to be_activate }
    end
  end

  describe 'Scope' do
    subject(:scope) { described_class::Scope.new(actor, User.all).resolve }

    context 'when admin' do
      let(:actor) { admin }

      it 'returns all users' do
        create_list(:user, 2)
        expect(scope.count).to eq(User.count)
      end
    end

    context 'when regular user' do
      let(:actor) { regular_user }

      it 'returns only own record' do
        create(:user)
        expect(scope).to contain_exactly(regular_user)
      end
    end

    context 'when unauthenticated' do
      let(:actor) { nil }

      it 'returns no records' do
        expect(scope).to be_empty
      end
    end
  end
end
