require 'rails_helper'

RSpec.describe 'LogoutUser mutation', type: :graphql do
  let(:user) { create(:user) }
  let(:token) { JwtService.encode(user_id: user.id) }

  let(:mutation) do
    <<~GRAPHQL
      mutation {
        logoutUser(input: {}) {
          success
          message
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(as: user, with_token: token)
    execute_graphql(query: mutation, user: as, token: with_token)
  end

  describe 'successful logout' do
    it 'returns success' do
      result = run_mutation
      data = gql_data(result)['logoutUser']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['message']).to eq('Successfully logged out')
      expect(data['errors']).to be_empty
    end

    it 'blacklists the token' do
      decoded = JwtService.decode(token)
      jti = decoded['jti']

      run_mutation

      expect(JwtService.blacklisted?(jti)).to be true
    end
  end

  describe 'unauthenticated user' do
    it 'returns error when no user in context' do
      result = run_mutation(as: nil, with_token: nil)
      data = gql_data(result)['logoutUser']

      expect(data['success']).to be false
      expect(data['message']).to eq('User not authenticated')
      expect(data['errors'].first['code']).to eq('AUTHENTICATION_REQUIRED')
    end
  end

  describe 'authenticated user without token' do
    it 'returns error when token is missing' do
      result = run_mutation(with_token: nil)
      data = gql_data(result)['logoutUser']

      expect(data['success']).to be false
      expect(data['message']).to eq('No token found')
      expect(data['errors'].first['code']).to eq('INVALID_TOKEN')
    end
  end
end
