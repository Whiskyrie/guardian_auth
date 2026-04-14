require 'rails_helper'

RSpec.describe TokenBlacklist, type: :model do
  # ---- Validations ----

  describe 'validations' do
    it 'requires jti' do
      entry = build(:token_blacklist, jti: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:jti]).to include("can't be blank")
    end

    it 'requires unique jti' do
      existing = create(:token_blacklist)
      duplicate = build(:token_blacklist, jti: existing.jti)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:jti]).to include('has already been taken')
    end

    it 'requires expires_at' do
      entry = build(:token_blacklist, expires_at: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:expires_at]).to include("can't be blank")
    end

    it 'validates reason inclusion' do
      entry = build(:token_blacklist, reason: 'invalid_reason')
      expect(entry).not_to be_valid
      expect(entry.errors[:reason]).to include('is not included in the list')
    end

    TokenBlacklist::VALID_REASONS.each do |reason|
      it "accepts reason: #{reason}" do
        entry = build(:token_blacklist, reason: reason)
        expect(entry).to be_valid
      end
    end
  end

  # ---- Scopes ----

  describe 'scopes' do
    let!(:expired_entry) { create(:token_blacklist, expires_at: 1.hour.ago) }
    let!(:active_entry) { create(:token_blacklist, expires_at: 1.hour.from_now) }

    describe '.expired' do
      it 'returns entries where expires_at is in the past' do
        expect(TokenBlacklist.expired).to include(expired_entry)
        expect(TokenBlacklist.expired).not_to include(active_entry)
      end
    end

    describe '.active' do
      it 'returns entries where expires_at is now or in the future' do
        expect(TokenBlacklist.active).to include(active_entry)
        expect(TokenBlacklist.active).not_to include(expired_entry)
      end
    end
  end

  # ---- Class Methods ----

  describe '.blacklisted?' do
    it 'returns true when jti is in active blacklist' do
      entry = create(:token_blacklist, expires_at: 1.hour.from_now)
      expect(TokenBlacklist.blacklisted?(entry.jti)).to be true
    end

    it 'returns false when jti is not in active blacklist' do
      expect(TokenBlacklist.blacklisted?('nonexistent')).to be false
    end

    it 'returns false when jti is in expired blacklist entry' do
      entry = create(:token_blacklist, expires_at: 1.hour.ago)
      expect(TokenBlacklist.blacklisted?(entry.jti)).to be false
    end
  end

  # ---- Instance Methods ----

  describe '#expired?' do
    it 'returns true when expires_at is in the past' do
      entry = build(:token_blacklist, expires_at: 1.hour.ago)
      expect(entry.expired?).to be true
    end

    it 'returns false when expires_at is in the future' do
      entry = build(:token_blacklist, expires_at: 1.hour.from_now)
      expect(entry.expired?).to be false
    end
  end

  describe '#active?' do
    it 'returns true when expires_at is in the future' do
      entry = build(:token_blacklist, expires_at: 1.hour.from_now)
      expect(entry.active?).to be true
    end

    it 'returns false when expires_at is in the past' do
      entry = build(:token_blacklist, expires_at: 1.hour.ago)
      expect(entry.active?).to be false
    end
  end
end
