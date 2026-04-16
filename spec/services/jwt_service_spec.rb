require 'rails_helper'

RSpec.describe JwtService, type: :service do
  let(:user) { create(:user) }

  # ---- encode ----

  describe '.encode' do
    it 'creates a JWT token' do
      token = JwtService.encode(user_id: user.id)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'includes exp in the payload' do
      token = JwtService.encode(user_id: user.id)
      decoded = JWT.decode(token, JwtService::SECRET_KEY, true, { algorithm: JwtService::ALGORITHM })[0]
      expect(decoded['exp']).to be_present
    end

    it 'includes iat in the payload' do
      token = JwtService.encode(user_id: user.id)
      decoded = JWT.decode(token, JwtService::SECRET_KEY, true, { algorithm: JwtService::ALGORITHM })[0]
      expect(decoded['iat']).to be_present
    end

    it 'includes jti in the payload' do
      token = JwtService.encode(user_id: user.id)
      decoded = JWT.decode(token, JwtService::SECRET_KEY, true, { algorithm: JwtService::ALGORITHM })[0]
      expect(decoded['jti']).to be_present
    end

    it 'includes custom payload data' do
      token = JwtService.encode(user_id: user.id, role: 'admin')
      decoded = JWT.decode(token, JwtService::SECRET_KEY, true, { algorithm: JwtService::ALGORITHM })[0]
      expect(decoded['user_id']).to eq(user.id)
      expect(decoded['role']).to eq('admin')
    end
  end

  # ---- decode ----

  describe '.decode' do
    it 'decodes a valid token' do
      token = JwtService.encode(user_id: user.id)
      decoded = JwtService.decode(token)
      expect(decoded).to be_a(Hash)
      expect(decoded['user_id']).to eq(user.id)
    end

    it 'returns nil for expired token' do
      token = JwtService.encode({ user_id: user.id }, 1.second.ago)
      sleep 0.1
      expect(JwtService.decode(token)).to be_nil
    end

    it 'returns nil for token with invalid signature' do
      token = JwtService.encode(user_id: user.id)
      # Tamper with the token
      parts = token.split('.')
      parts[1] = Base64.urlsafe_encode64('tampered', padding: false)
      tampered_token = parts.join('.')
      expect(JwtService.decode(tampered_token)).to be_nil
    end

    it 'returns nil for malformed token' do
      expect(JwtService.decode('not.a.valid.token')).to be_nil
    end
  end

  # ---- decode_allowing_expired ----

  describe '.decode_allowing_expired' do
    it 'decodes an expired token while verifying signature' do
      token = JwtService.encode({ user_id: user.id }, 1.second.ago)
      sleep 0.1
      decoded = JwtService.decode_allowing_expired(token)
      expect(decoded).to be_a(Hash)
      expect(decoded['user_id']).to eq(user.id)
    end

    it 'returns nil for token with invalid signature' do
      token = JwtService.encode(user_id: user.id)
      parts = token.split('.')
      parts[1] = Base64.urlsafe_encode64('tampered', padding: false)
      tampered_token = parts.join('.')
      expect(JwtService.decode_allowing_expired(tampered_token)).to be_nil
    end

    it 'decodes a valid non-expired token' do
      token = JwtService.encode(user_id: user.id)
      decoded = JwtService.decode_allowing_expired(token)
      expect(decoded['user_id']).to eq(user.id)
    end
  end

  # ---- valid_token? ----

  describe '.valid_token?' do
    it 'returns true for a valid, non-blacklisted token' do
      token = JwtService.encode(user_id: user.id)
      expect(JwtService.valid_token?(token)).to be true
    end

    it 'returns false for an expired token' do
      token = JwtService.encode({ user_id: user.id }, 1.second.ago)
      sleep 0.1
      expect(JwtService.valid_token?(token)).to be false
    end

    it 'returns false for a blacklisted token' do
      token = JwtService.encode(user_id: user.id)
      JwtService.blacklist_token!(token, user.id)
      expect(JwtService.valid_token?(token)).to be false
    end
  end

  # ---- blacklist_token! ----

  describe '.blacklist_token!' do
    it 'creates a TokenBlacklist record' do
      token = JwtService.encode(user_id: user.id)
      expect do
        JwtService.blacklist_token!(token, user.id)
      end.to change(TokenBlacklist, :count).by(1)
    end

    it 'handles duplicate gracefully by returning true' do
      token = JwtService.encode(user_id: user.id)
      JwtService.blacklist_token!(token, user.id)
      result = JwtService.blacklist_token!(token, user.id)
      expect(result).to be true
    end
  end

  # ---- blacklisted? ----

  describe '.blacklisted?' do
    it 'returns true when jti is blacklisted' do
      token = JwtService.encode(user_id: user.id)
      JwtService.blacklist_token!(token, user.id)
      jti = JwtService.extract_jti_from_token(token)
      expect(JwtService.blacklisted?(jti)).to be true
    end

    it 'returns false when jti is not blacklisted' do
      expect(JwtService.blacklisted?(SecureRandom.uuid)).to be false
    end
  end

  # ---- extract_jti_from_token ----

  describe '.extract_jti_from_token' do
    it 'extracts jti from a valid token' do
      token = JwtService.encode(user_id: user.id)
      decoded = JwtService.decode(token)
      expect(JwtService.extract_jti_from_token(token)).to eq(decoded['jti'])
    end

    it 'extracts jti from an expired token' do
      token = JwtService.encode({ user_id: user.id }, 1.second.ago)
      sleep 0.1
      decoded = JwtService.decode_allowing_expired(token)
      expect(JwtService.extract_jti_from_token(token)).to eq(decoded['jti'])
    end

    it 'returns nil for an invalid token' do
      expect(JwtService.extract_jti_from_token('invalid')).to be_nil
    end
  end
end
