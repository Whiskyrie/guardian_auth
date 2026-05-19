require 'rails_helper'

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }

  # ---- Validations ----

  describe 'validations' do
    it 'is invalid without jti' do
      session = build(:session, jti: nil)
      expect(session).not_to be_valid
    end

    it 'is invalid without expires_at' do
      session = build(:session, expires_at: nil)
      expect(session).not_to be_valid
    end

    it 'enforces unique jti' do
      jti = SecureRandom.uuid
      create(:session, user: user, jti: jti)
      duplicate = build(:session, user: user, jti: jti)
      expect(duplicate).not_to be_valid
    end
  end

  # ---- Scopes ----

  describe 'scopes' do
    describe '.active' do
      it 'returns non-revoked, non-expired sessions' do
        active = create(:session, user: user)
        revoked = create(:session, :revoked, user: user)
        expired = create(:session, :expired, user: user)

        expect(Session.active).to include(active)
        expect(Session.active).not_to include(revoked, expired)
      end
    end

    describe '.revoked' do
      it 'returns only revoked sessions' do
        active = create(:session, user: user)
        revoked = create(:session, :revoked, user: user)

        expect(Session.revoked).to include(revoked)
        expect(Session.revoked).not_to include(active)
      end
    end

    describe '.expired' do
      it 'returns only expired sessions' do
        active = create(:session, user: user)
        expired = create(:session, :expired, user: user)

        expect(Session.expired).to include(expired)
        expect(Session.expired).not_to include(active)
      end
    end
  end

  # ---- .issue! ----

  describe '.issue!' do
    it 'returns a token string and a persisted Session' do
      token, session = Session.issue!(user: user, ip: '1.2.3.4', user_agent: 'TestAgent/1.0')

      expect(token).to be_a(String)
      expect(session).to be_persisted
      expect(session.user).to eq(user)
      expect(session.ip_address.to_s).to eq('1.2.3.4')
      expect(session.user_agent).to eq('TestAgent/1.0')
      expect(session.expires_at).to be_present
      expect(session.jti).to be_present
    end

    it 'encodes a valid JWT' do
      token, = Session.issue!(user: user, ip: '1.2.3.4', user_agent: nil)
      decoded = JwtService.decode(token)

      expect(decoded['user_id']).to eq(user.id)
    end

    it 'truncates user_agent to 512 chars' do
      long_ua = 'A' * 600
      _, session = Session.issue!(user: user, ip: nil, user_agent: long_ua)

      expect(session.user_agent.length).to eq(512)
    end
  end

  # ---- #revoke! ----

  describe '#revoke!' do
    it 'sets revoked_at and revoked_reason' do
      session = create(:session, user: user)
      session.revoke!(reason: 'user_revoked')

      session.reload
      expect(session.revoked_at).to be_present
      expect(session.revoked_reason).to eq('user_revoked')
    end

    it 'adds the jti to TokenBlacklist' do
      session = create(:session, user: user)
      expect { session.revoke! }.to change(TokenBlacklist, :count).by(1)

      entry = TokenBlacklist.find_by(jti: session.jti)
      expect(entry).to be_present
      expect(entry.reason).to eq('logout')
    end

    it 'maps admin_revoked reason to admin_logout in TokenBlacklist' do
      session = create(:session, user: user)
      session.revoke!(reason: 'admin_revoked')

      expect(TokenBlacklist.find_by(jti: session.jti).reason).to eq('admin_logout')
    end

    it 'returns true on success' do
      session = create(:session, user: user)
      expect(session.revoke!).to be true
    end

    it 'returns false and is idempotent when already revoked' do
      session = create(:session, :revoked, user: user)
      original_time = session.revoked_at

      expect(session.revoke!).to be false
      expect(session.reload.revoked_at).to be_within(1.second).of(original_time)
    end
  end

  # ---- Predicates ----

  describe '#active?' do
    it 'returns true for a non-revoked, non-expired session' do
      session = create(:session, user: user)
      expect(session.active?).to be true
    end

    it 'returns false when revoked' do
      session = create(:session, :revoked, user: user)
      expect(session.active?).to be false
    end

    it 'returns false when expired' do
      session = create(:session, :expired, user: user)
      expect(session.active?).to be false
    end
  end
end
