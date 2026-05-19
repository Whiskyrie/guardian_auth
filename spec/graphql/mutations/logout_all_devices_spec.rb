require 'rails_helper'

RSpec.describe 'LogoutAllDevices mutation', type: :graphql do
  let(:password) { 'SecurePassword1@' }
  let(:user) { create(:user, password: password, password_confirmation: password) }

  let(:mutation) do
    <<~GRAPHQL
      mutation LogoutAllDevices($password: String!) {
        logoutAllDevices(input: { password: $password }) {
          success
          message
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(pwd: password, as: user)
    execute_graphql(query: mutation, variables: { password: pwd }, user: as)
  end

  describe 'successful logout from all devices' do
    it 'returns success' do
      result = run_mutation
      data = gql_data(result)['logoutAllDevices']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['message']).to eq('Successfully logged out from all devices')
      expect(data['errors']).to be_empty
    end

    it 'updates tokens_valid_after to invalidate all existing tokens' do
      expect { run_mutation }.to change { user.reload.tokens_valid_after }
    end

    it 'marks all active sessions as revoked' do
      s1 = create(:session, user: user)
      s2 = create(:session, user: user)

      run_mutation

      expect(s1.reload.revoked?).to be true
      expect(s2.reload.revoked?).to be true
      expect(s1.revoked_reason).to eq('logout_all_devices')
    end
  end

  describe 'wrong password' do
    it 'returns error for incorrect password' do
      result = run_mutation(pwd: 'WrongPassword1@')
      data = gql_data(result)['logoutAllDevices']

      expect(data['success']).to be false
      expect(data['message']).to eq('Invalid password')
      expect(data['errors'].first['code']).to eq('INVALID_CREDENTIALS')
    end
  end

  describe 'unauthenticated user' do
    it 'returns error when not authenticated' do
      result = run_mutation(as: nil)
      data = gql_data(result)['logoutAllDevices']

      expect(data['success']).to be false
      expect(data['message']).to eq('User not authenticated')
      expect(data['errors'].first['code']).to eq('AUTHENTICATION_REQUIRED')
    end
  end
end
