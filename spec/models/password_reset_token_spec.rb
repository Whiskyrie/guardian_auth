require 'rails_helper'

RSpec.describe PasswordResetToken, type: :model do
  # ---- Validations ----

  describe 'validations' do
    it 'requires token_hash' do
      token = build(:password_reset_token, token_hash: nil)
      expect(token).not_to be_valid
      expect(token.errors[:token_hash]).to include("can't be blank")
    end

    it 'requires unique token_hash' do
      existing = create(:password_reset_token)
      duplicate = build(:password_reset_token, token_hash: existing.token_hash)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token_hash]).to include('has already been taken')
    end

    it 'requires user_id' do
      token = build(:password_reset_token, user: nil)
      expect(token).not_to be_valid
      expect(token.errors[:user_id]).to include("can't be blank")
    end

    it 'requires expires_at' do
      token = build(:password_reset_token, expires_at: nil)
      expect(token).not_to be_valid
      expect(token.errors[:expires_at]).to include("can't be blank")
    end
  end

  # ---- Scopes ----

  describe 'scopes' do
    let(:user) { create(:user) }

    let!(:active_token) { create(:password_reset_token, user: user, used: false, expires_at: 1.hour.from_now) }
    let!(:expired_token) { create(:password_reset_token, user: user, used: false, expires_at: 1.hour.ago) }
    let!(:used_token) do
      create(:password_reset_token,
             user: user, used: true,
             expires_at: 1.hour.from_now, used_at: 1.minute.ago)
    end

    describe '.active' do
      it 'returns unused tokens that have not expired' do
        expect(PasswordResetToken.active).to include(active_token)
        expect(PasswordResetToken.active).not_to include(expired_token, used_token)
      end
    end

    describe '.expired' do
      it 'returns tokens where expires_at is in the past' do
        expect(PasswordResetToken.expired).to include(expired_token)
        expect(PasswordResetToken.expired).not_to include(active_token)
      end
    end

    describe '.unused' do
      it 'returns tokens that have not been used' do
        expect(PasswordResetToken.unused).to include(active_token, expired_token)
        expect(PasswordResetToken.unused).not_to include(used_token)
      end
    end
  end

  # ---- Class Methods ----

  describe '.create_for_user' do
    let(:user) { create(:user) }

    it 'returns the raw token' do
      raw_token = PasswordResetToken.create_for_user(user)
      expect(raw_token).to be_a(String)
      expect(raw_token.length).to be > 0
    end

    it 'stores the hashed token, not the raw one' do
      raw_token = PasswordResetToken.create_for_user(user)
      token_record = PasswordResetToken.last
      expect(token_record.token_hash).to eq(Digest::SHA256.hexdigest(raw_token))
      expect(token_record.token_hash).not_to eq(raw_token)
    end

    it 'invalidates previous active tokens for the user' do
      first_raw = PasswordResetToken.create_for_user(user)
      first_token = PasswordResetToken.find_by(token_hash: Digest::SHA256.hexdigest(first_raw))
      expect(first_token.reload.used).to be false

      PasswordResetToken.create_for_user(user)
      expect(first_token.reload.used).to be true
    end

    it 'sets expires_at to EXPIRY_TIME from now' do
      PasswordResetToken.create_for_user(user)
      token_record = PasswordResetToken.last
      expect(token_record.expires_at).to be_within(5.seconds).of(PasswordResetToken::EXPIRY_TIME.from_now)
    end
  end

  describe '.verify_token' do
    let(:user) { create(:user) }

    it 'finds active token by raw token hash' do
      raw_token = PasswordResetToken.create_for_user(user)
      result = PasswordResetToken.verify_token(raw_token)
      expect(result).not_to be_nil
      expect(result.user).to eq(user)
    end

    it 'returns nil for invalid token' do
      result = PasswordResetToken.verify_token('invalid_token_value')
      expect(result).to be_nil
    end

    it 'returns nil for expired token' do
      raw_token = PasswordResetToken.create_for_user(user)
      token_record = PasswordResetToken.find_by(token_hash: Digest::SHA256.hexdigest(raw_token))
      token_record.update!(expires_at: 2.hours.ago)
      expect(PasswordResetToken.verify_token(raw_token)).to be_nil
    end

    it 'returns nil for used token' do
      raw_token = PasswordResetToken.create_for_user(user)
      token_record = PasswordResetToken.find_by(token_hash: Digest::SHA256.hexdigest(raw_token))
      token_record.mark_used!
      expect(PasswordResetToken.verify_token(raw_token)).to be_nil
    end
  end

  # ---- Instance Methods ----

  describe '#mark_used!' do
    it 'marks the token as used with a timestamp' do
      token = create(:password_reset_token)
      expect { token.mark_used! }.to change { token.reload.used }.from(false).to(true)
      expect(token.used_at).not_to be_nil
    end
  end

  describe '#expired?' do
    it 'returns true when expires_at is in the past' do
      token = build(:password_reset_token, expires_at: 1.hour.ago)
      expect(token.expired?).to be true
    end

    it 'returns false when expires_at is in the future' do
      token = build(:password_reset_token, expires_at: 1.hour.from_now)
      expect(token.expired?).to be false
    end
  end

  describe '#active?' do
    it 'returns true when not used and not expired' do
      token = build(:password_reset_token, used: false, expires_at: 1.hour.from_now)
      expect(token.active?).to be true
    end

    it 'returns false when used' do
      token = build(:password_reset_token, used: true, expires_at: 1.hour.from_now)
      expect(token.active?).to be false
    end

    it 'returns false when expired' do
      token = build(:password_reset_token, used: false, expires_at: 1.hour.ago)
      expect(token.active?).to be false
    end
  end
end
