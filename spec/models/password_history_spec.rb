require 'rails_helper'

RSpec.describe PasswordHistory, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it 'is valid with user and password_digest' do
      history = build(:password_history, user: user)
      expect(history).to be_valid
    end

    it 'is invalid without user' do
      history = build(:password_history, user: nil)
      expect(history).not_to be_valid
    end

    it 'is invalid without password_digest' do
      history = build(:password_history, user: user, password_digest: nil)
      expect(history).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      history = create(:password_history, user: user)
      expect(history.user).to eq(user)
    end

    it 'is destroyed when user is destroyed' do
      create(:password_history, user: user)
      expect { user.destroy }.to change(PasswordHistory, :count).by(-1)
    end
  end
end
