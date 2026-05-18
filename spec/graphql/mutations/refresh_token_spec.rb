require 'rails_helper'

RSpec.describe 'RefreshToken mutation', type: :graphql do
  let(:user) { create(:user) }
  let(:valid_token) { JwtService.encode(user_id: user.id) }

  let(:mutation) do
    <<~GRAPHQL
      mutation RefreshToken($token: String!) {
        refreshToken(input: { token: $token }) {
          success
          message
          token
          user { id email }
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(tok: valid_token)
    execute_graphql(query: mutation, variables: { token: tok })
  end

  describe 'successful refresh' do
    it 'returns a new token' do
      result = run_mutation
      data = gql_data(result)['refreshToken']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['message']).to eq('Token refreshed successfully')
      expect(data['token']).to be_present
      expect(data['token']).not_to eq(valid_token)
      expect(data['user']['email']).to eq(user.email)
    end

    it 'blacklists the old token' do
      decoded = JwtService.decode(valid_token)
      jti = decoded['jti']

      run_mutation

      expect(JwtService.blacklisted?(jti)).to be true
    end

    it 'updates last_login_at' do
      expect { run_mutation }.to change { user.reload.last_login_at }
    end
  end

  describe 'blank token' do
    it 'returns error for empty string' do
      result = run_mutation(tok: '')
      data = gql_data(result)['refreshToken']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('INVALID_INPUT')
    end
  end

  describe 'invalid token' do
    it 'returns error for malformed token' do
      result = run_mutation(tok: 'not.a.valid.jwt')
      data = gql_data(result)['refreshToken']

      expect(data['success']).to be false
      expect(data['token']).to be_nil
    end

    it 'returns error for token with wrong signature' do
      bad_token = JWT.encode({ user_id: user.id, exp: 1.hour.from_now.to_i,
                               iat: Time.current.to_i, jti: SecureRandom.uuid },
                             'wrong_secret', 'HS256')
      result = run_mutation(tok: bad_token)
      data = gql_data(result)['refreshToken']

      expect(data['success']).to be false
    end
  end

  describe 'blacklisted token' do
    it 'returns error when token was already revoked' do
      JwtService.blacklist_token!(valid_token, user.id, reason: 'logout')

      result = run_mutation
      data = gql_data(result)['refreshToken']

      expect(data['success']).to be false
      expect(data['message']).to eq('Token has been revoked')
    end
  end

  describe 'token invalidated by tokens_valid_after' do
    it 'returns error when token was issued before tokens_valid_after' do
      user.update_column(:tokens_valid_after, Time.current + 1.second)

      result = run_mutation
      data = gql_data(result)['refreshToken']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('TOKEN_EXPIRED')
    end
  end

  describe 'token too old' do
    it 'returns error when token expired more than 7 days ago' do
      old_exp = 8.days.ago.to_i
      old_token = JWT.encode(
        { user_id: user.id, exp: old_exp, iat: 9.days.ago.to_i, jti: SecureRandom.uuid },
        JwtService::SECRET_KEY,
        JwtService::ALGORITHM
      )

      result = run_mutation(tok: old_token)
      data = gql_data(result)['refreshToken']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('TOKEN_EXPIRED')
    end
  end
end
