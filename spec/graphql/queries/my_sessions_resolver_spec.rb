require 'rails_helper'

RSpec.describe 'mySessions query', type: :graphql do
  let(:user) { create(:user) }

  let(:query) do
    <<~GRAPHQL
      query MySessions {
        mySessions {
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

  def run_query(as: user, token: nil)
    execute_graphql(query: query, user: as, token: token)
  end

  describe 'authenticated user lists own sessions' do
    it 'returns only active sessions' do
      active = create(:session, user: user)
      create(:session, :revoked, user: user)
      create(:session, :expired, user: user)

      result = run_query
      data = gql_data(result)['mySessions']

      expect(data.map { |s| s['id'] }).to contain_exactly(active.id.to_s)
    end

    it 'does not return sessions from other users' do
      create(:session, user: user)
      other_user = create(:user)
      create(:session, user: other_user)

      result = run_query
      data = gql_data(result)['mySessions']

      expect(data.length).to eq(1)
    end

    it 'returns session metadata' do
      session = create(:session, user: user, ip_address: '10.0.0.1', user_agent: 'Chrome/1.0')

      result = run_query
      entry = gql_data(result)['mySessions'].first

      expect(entry['ipAddress']).to eq('10.0.0.1')
      expect(entry['userAgent']).to eq('Chrome/1.0')
      expect(entry['expiresAt']).to be_present
    end

    it 'marks the current session as current: true' do
      token, session = Session.issue!(user: user, ip: '127.0.0.1', user_agent: 'RSpec')
      create(:session, user: user) # another session that should not be current

      result = execute_graphql(query: query, user: user, token: token)
      data = gql_data(result)['mySessions']

      current_entry = data.find { |s| s['id'] == session.id.to_s }
      other_entries = data.reject { |s| s['id'] == session.id.to_s }

      expect(current_entry['current']).to be true
      expect(other_entries.map { |s| s['current'] }).to all(be false)
    end
  end

  describe 'sessions issued before tokens_valid_after are excluded' do
    it 'excludes pre-invalidation sessions' do
      old_session = create(:session, user: user, created_at: 2.days.ago)
      user.update_columns(tokens_valid_after: 1.day.ago)
      new_session = create(:session, user: user)

      result = run_query
      ids = gql_data(result)['mySessions'].map { |s| s['id'] }

      expect(ids).to include(new_session.id.to_s)
      expect(ids).not_to include(old_session.id.to_s)
    end
  end

  describe 'unauthenticated request' do
    it 'returns an error' do
      result = run_query(as: nil)
      expect(gql_errors(result)).to be_present
    end
  end
end
