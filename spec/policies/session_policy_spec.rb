require 'rails_helper'

RSpec.describe SessionPolicy, type: :policy do
  subject(:policy) { described_class.new(actor, record) }

  let(:owner) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:other_user) { create(:user) }
  let(:record) { create(:session, user: owner) }

  describe '#show?' do
    context 'when owner' do
      let(:actor) { owner }
      it { is_expected.to be_show }
    end

    context 'when admin' do
      let(:actor) { admin }
      it { is_expected.to be_show }
    end

    context 'when third-party user' do
      let(:actor) { other_user }
      it { is_expected.not_to be_show }
    end

    context 'when unauthenticated' do
      let(:actor) { nil }
      it { is_expected.not_to be_show }
    end
  end

  describe '#destroy?' do
    context 'when owner' do
      let(:actor) { owner }
      it { is_expected.to be_destroy }
    end

    context 'when admin' do
      let(:actor) { admin }
      it { is_expected.to be_destroy }
    end

    context 'when third-party user' do
      let(:actor) { other_user }
      it { is_expected.not_to be_destroy }
    end

    context 'when unauthenticated' do
      let(:actor) { nil }
      it { is_expected.not_to be_destroy }
    end
  end

  describe 'Scope' do
    subject(:scope) { described_class::Scope.new(actor, Session.all).resolve }

    before { owner; admin; other_user }

    context 'when admin' do
      let(:actor) { admin }

      it 'returns all sessions' do
        create(:session, user: owner)
        create(:session, user: other_user)
        expect(scope.count).to eq(Session.count)
      end
    end

    context 'when regular user' do
      let(:actor) { owner }

      it 'returns only own sessions' do
        own_session = create(:session, user: owner)
        create(:session, user: other_user)

        expect(scope).to contain_exactly(own_session)
      end
    end

    context 'when unauthenticated' do
      let(:actor) { nil }

      it 'returns no sessions' do
        create(:session, user: owner)
        expect(scope).to be_empty
      end
    end
  end
end
