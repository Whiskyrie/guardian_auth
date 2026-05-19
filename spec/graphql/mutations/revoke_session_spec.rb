require 'rails_helper'

RSpec.describe 'RevokeSession mutation', type: :graphql do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  let(:mutation) do
    <<~GRAPHQL
      mutation RevokeSession($sessionId: ID!) {
        revokeSession(input: { sessionId: $sessionId }) {
          success
          message
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(session_id:, as: user)
    execute_graphql(query: mutation, variables: { sessionId: session_id.to_s }, user: as)
  end

  describe 'user revokes own session' do
    let!(:session) { create(:session, user: user) }

    it 'returns success' do
      result = run_mutation(session_id: session.id)
      data = gql_data(result)['revokeSession']

      expect(data['success']).to be true
      expect(gql_errors(result)).to be_nil
    end

    it 'marks the session as revoked in the database' do
      run_mutation(session_id: session.id)
      expect(session.reload.revoked?).to be true
    end

    it 'adds the session jti to the token blacklist' do
      run_mutation(session_id: session.id)
      expect(TokenBlacklist.exists?(jti: session.jti)).to be true
    end
  end

  describe 'user tries to revoke another user session' do
    let(:other_user) { create(:user) }
    let!(:other_session) { create(:session, user: other_user) }

    it 'returns INSUFFICIENT_PERMISSIONS' do
      result = run_mutation(session_id: other_session.id)
      data = gql_data(result)['revokeSession']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('INSUFFICIENT_PERMISSIONS')
      expect(other_session.reload.revoked?).to be false
    end
  end

  describe 'admin revokes any user session' do
    let!(:session) { create(:session, user: user) }

    it 'returns success' do
      result = run_mutation(session_id: session.id, as: admin)
      data = gql_data(result)['revokeSession']

      expect(data['success']).to be true
      expect(session.reload.revoked?).to be true
    end
  end

  describe 'session not found' do
    it 'returns RESOURCE_NOT_FOUND' do
      result = run_mutation(session_id: 0)
      data = gql_data(result)['revokeSession']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end

  describe 'already revoked session (idempotency)' do
    let!(:session) { create(:session, :revoked, user: user) }

    it 'returns success with a specific message' do
      result = run_mutation(session_id: session.id)
      data = gql_data(result)['revokeSession']

      expect(data['success']).to be true
      expect(data['message']).to eq('A sessão já estava revogada')
    end
  end

  describe 'unauthenticated request' do
    let!(:session) { create(:session, user: user) }

    it 'returns an error' do
      result = run_mutation(session_id: session.id, as: nil)
      data = gql_data(result)['revokeSession']

      expect(data['success']).to be false
    end
  end

  describe 'audit log' do
    let!(:session) { create(:session, user: user) }

    it 'creates a session_revoked audit log entry' do
      user; session # force creation before counting
      expect { run_mutation(session_id: session.id) }.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.action).to eq('session_revoked')
    end
  end
end
