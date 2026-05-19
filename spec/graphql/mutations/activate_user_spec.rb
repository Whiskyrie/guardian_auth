require 'rails_helper'

RSpec.describe 'ActivateUser mutation', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target) { create(:user, deactivated_at: 1.day.ago) }

  let(:mutation) do
    <<~GRAPHQL
      mutation ActivateUser($userId: ID!) {
        activateUser(input: { userId: $userId }) {
          success
          message
          user { id active deactivatedAt }
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(user_id: target.id.to_s, as: admin)
    execute_graphql(query: mutation, variables: { userId: user_id }, user: as)
  end

  describe 'admin activates a deactivated user' do
    it 'returns success and marks the user as active' do
      result = run_mutation
      data = gql_data(result)['activateUser']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['user']['active']).to be true
      expect(data['user']['deactivatedAt']).to be_nil
    end

    it 'clears deactivation columns in the database' do
      run_mutation
      target.reload
      expect(target.deactivated_at).to be_nil
      expect(target.deactivated_by_id).to be_nil
      expect(target.deactivation_reason).to be_nil
    end

    it 'creates an audit log entry' do
      admin; target # force creation before counting
      expect { run_mutation }.to change(AuditLog, :count).by(1)
      log = AuditLog.last
      expect(log.action).to eq('user_activation')
      expect(log.resource_id).to eq(target.id.to_s)
    end
  end

  describe 'idempotency — user already active' do
    it 'returns success with a specific message' do
      active_user = create(:user)
      result = run_mutation(user_id: active_user.id.to_s)
      data = gql_data(result)['activateUser']

      expect(data['success']).to be true
      expect(data['message']).to eq('A conta já está ativa')
      expect(active_user.reload.deactivated?).to be false
    end
  end

  describe 'non-admin user' do
    it 'rejects activation with INSUFFICIENT_PERMISSIONS' do
      regular_user = create(:user)
      result = run_mutation(as: regular_user)
      data = gql_data(result)['activateUser']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('INSUFFICIENT_PERMISSIONS')
      expect(target.reload.deactivated?).to be true
    end
  end

  describe 'unauthenticated request' do
    it 'returns an authentication error' do
      result = run_mutation(as: nil)
      data = gql_data(result)['activateUser']

      expect(data['success']).to be false
    end
  end

  describe 'user not found' do
    it 'returns RESOURCE_NOT_FOUND' do
      result = run_mutation(user_id: '0')
      data = gql_data(result)['activateUser']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end
end
