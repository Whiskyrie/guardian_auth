require 'rails_helper'

RSpec.describe 'DeactivateUser mutation', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target) { create(:user) }

  let(:mutation) do
    <<~GRAPHQL
      mutation DeactivateUser($userId: ID!, $reason: String) {
        deactivateUser(input: { userId: $userId, reason: $reason }) {
          success
          message
          user { id active deactivatedAt }
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(user_id: target.id.to_s, reason: nil, as: admin)
    execute_graphql(query: mutation, variables: { userId: user_id, reason: reason }, user: as)
  end

  describe 'admin deactivates a user' do
    it 'returns success and marks the user as deactivated' do
      result = run_mutation
      data = gql_data(result)['deactivateUser']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['user']['active']).to be false
      expect(data['user']['deactivatedAt']).to be_present
    end

    it 'persists deactivation to the database' do
      run_mutation(reason: 'Policy violation')
      expect(target.reload.deactivated?).to be true
      expect(target.reload.deactivation_reason).to eq('Policy violation')
      expect(target.reload.deactivated_by_id).to eq(admin.id)
    end

    it 'bumps tokens_valid_after to invalidate existing sessions' do
      before = Time.current
      run_mutation
      expect(target.reload.tokens_valid_after).to be >= before
    end

    it 'creates an audit log entry' do
      admin; target # force creation before counting
      expect { run_mutation }.to change(AuditLog, :count).by(1)
      log = AuditLog.last
      expect(log.action).to eq('user_deactivation')
      expect(log.resource).to eq('User')
      expect(log.resource_id).to eq(target.id.to_s)
    end
  end

  describe 'idempotency — user already deactivated' do
    it 'returns success with a specific message and does not overwrite deactivated_at' do
      original_time = 1.day.ago
      target.update_columns(deactivated_at: original_time)

      result = run_mutation
      data = gql_data(result)['deactivateUser']

      expect(data['success']).to be true
      expect(data['message']).to eq('A conta já está desativada')
      expect(target.reload.deactivated_at).to be_within(1.second).of(original_time)
    end
  end

  describe 'admin tries to deactivate themselves' do
    it 'rejects the attempt with BUSINESS_RULE_VIOLATION' do
      result = run_mutation(user_id: admin.id.to_s)
      data = gql_data(result)['deactivateUser']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('BUSINESS_RULE_VIOLATION')
      expect(admin.reload.deactivated?).to be false
    end
  end

  describe 'non-admin user' do
    it 'rejects deactivation with INSUFFICIENT_PERMISSIONS' do
      regular_user = create(:user)
      result = run_mutation(as: regular_user)
      data = gql_data(result)['deactivateUser']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('INSUFFICIENT_PERMISSIONS')
      expect(target.reload.deactivated?).to be false
    end
  end

  describe 'unauthenticated request' do
    it 'returns an authentication error' do
      result = run_mutation(as: nil)
      data = gql_data(result)['deactivateUser']

      expect(data['success']).to be false
    end
  end

  describe 'user not found' do
    it 'returns RESOURCE_NOT_FOUND' do
      result = run_mutation(user_id: '0')
      data = gql_data(result)['deactivateUser']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end
end
