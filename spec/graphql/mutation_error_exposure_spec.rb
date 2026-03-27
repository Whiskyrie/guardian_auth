require 'rails_helper'

RSpec.describe 'Mutation internal error exposure', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  describe 'LogoutUser' do
    before do
      allow(JwtService).to receive(:blacklist_token!).and_raise(StandardError, 'internal db error')
      allow(Rails.logger).to receive(:error)
    end

    let(:result) do
      execute_graphql(
        query: <<~GRAPHQL,
          mutation {
            logoutUser(input: {}) {
              success
              message
            }
          }
        GRAPHQL
        user: target_user,
        token: 'some.jwt.token'
      )
    end

    it 'does not expose internal exception message to client' do
      expect(gql_errors(result)).to be_nil
      expect(gql_data(result)['logoutUser']['message']).not_to include('internal db error')
    end

    it 'returns a safe generic message' do
      data = gql_data(result)['logoutUser']
      expect(data['success']).to be false
      expect(data['message']).to eq('Logout failed due to an internal error. Please try again.')
    end

    it 'logs the full exception internally' do
      result
      expect(Rails.logger).to have_received(:error).with(match(/internal db error/i))
    end
  end

  describe 'DeleteUser' do
    before do
      allow_any_instance_of(User).to receive(:destroy).and_raise(StandardError, 'internal db error')
      allow(Rails.logger).to receive(:error)
    end

    let(:result) do
      execute_graphql(
        query: <<~GRAPHQL,
          mutation DeleteUser($id: ID!) {
            deleteUser(input: { id: $id }) {
              success
              message
              errors { message code }
            }
          }
        GRAPHQL
        variables: { id: target_user.id.to_s },
        user: admin
      )
    end

    it 'does not expose internal exception message to client' do
      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['deleteUser']
      all_messages = [data['message']] + Array(data['errors']).map { |e| e['message'] }
      expect(all_messages).not_to include(match(/internal db error/i))
    end

    it 'returns a safe generic error message' do
      data = gql_data(result)['deleteUser']
      expect(data['success']).to be false
      expect(data['errors'].first['message']).to eq('An internal error occurred while deleting the user')
    end

    it 'logs the full exception internally' do
      result
      expect(Rails.logger).to have_received(:error).with(match(/internal db error/i))
    end
  end

  describe 'ChangePassword' do
    before do
      allow_any_instance_of(User).to receive(:save).and_raise(StandardError, 'internal db error')
      allow(Rails.logger).to receive(:error)
    end

    let(:result) do
      execute_graphql(
        query: <<~GRAPHQL,
          mutation ChangePassword($currentPassword: String!, $newPassword: String!) {
            changePassword(input: { currentPassword: $currentPassword, newPassword: $newPassword }) {
              user { id }
              errors { message code }
            }
          }
        GRAPHQL
        variables: { currentPassword: 'SecurePassword1@', newPassword: 'NewSecure2@!' },
        user: target_user
      )
    end

    it 'does not expose internal exception message to client' do
      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['changePassword']
      error_messages = Array(data['errors']).map { |e| e['message'] }
      expect(error_messages).not_to include(match(/internal db error/i))
    end

    it 'returns a safe generic error message' do
      data = gql_data(result)['changePassword']
      expect(data['errors'].first['message']).to eq('Password change failed. Please try again.')
    end

    it 'logs the full exception internally' do
      result
      expect(Rails.logger).to have_received(:error).with(match(/internal db error/i))
    end
  end
end
