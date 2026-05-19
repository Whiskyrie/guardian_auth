require 'rails_helper'

RSpec.describe 'userSessions query', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target) { create(:user) }

  let(:query) do
    <<~GRAPHQL
      query UserSessions($userId: ID!) {
        userSessions(userId: $userId) {
          id
          ipAddress
          userAgent
          createdAt
          expiresAt
          current
        }
      }
    GRAPHQL
  end

  def run_query(user_id: target.id, as: admin)
    execute_graphql(query: query, variables: { userId: user_id.to_s }, user: as)
  end

  describe 'admin lists another user sessions' do
    it 'returns the active sessions of the target user' do
      active = create(:session, user: target)
      create(:session, :revoked, user: target)

      result = run_query
      data = gql_data(result)['userSessions']

      expect(data.map { |s| s['id'] }).to contain_exactly(active.id.to_s)
    end

    it 'does not return sessions from other users' do
      create(:session, user: target)
      create(:session, user: create(:user))

      result = run_query
      expect(gql_data(result)['userSessions'].length).to eq(1)
    end
  end

  describe 'non-admin user' do
    it 'raises an error' do
      regular_user = create(:user)
      result = run_query(as: regular_user)

      expect(gql_errors(result)).to be_present
    end
  end

  describe 'user not found' do
    it 'raises an error' do
      result = run_query(user_id: 0)
      expect(gql_errors(result)).to be_present
    end
  end

  describe 'unauthenticated request' do
    it 'raises an error' do
      result = run_query(as: nil)
      expect(gql_errors(result)).to be_present
    end
  end
end
