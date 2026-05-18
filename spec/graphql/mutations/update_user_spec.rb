require 'rails_helper'

RSpec.describe 'UpdateUser mutation', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user, first_name: 'Alice', last_name: 'Smith') }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateUser($id: ID!, $input: UserInput!) {
        updateUser(input: { id: $id, input: $input }) {
          success
          message
          user { id email firstName lastName }
          errors { message code field }
        }
      }
    GRAPHQL
  end

  def run_mutation(id: target_user.to_gid_param, input: {}, as: admin)
    execute_graphql(query: mutation, variables: { id: id, input: input }, user: as)
  end

  describe 'admin updating another user' do
    it 'updates user fields successfully' do
      result = run_mutation(input: { firstName: 'Bob', lastName: 'Jones' })
      data = gql_data(result)['updateUser']

      expect(gql_errors(result)).to be_nil
      expect(data['success']).to be true
      expect(data['message']).to eq('User updated successfully')
      expect(data['user']['firstName']).to eq('Bob')
    end

    it 'changes user role when requested' do
      result = run_mutation(input: { role: 'ADMIN' })
      data = gql_data(result)['updateUser']

      expect(data['success']).to be true
      expect(target_user.reload.admin?).to be true
    end
  end

  describe 'regular user updating own profile' do
    it 'allows updating own name fields' do
      result = run_mutation(id: target_user.to_gid_param, input: { firstName: 'Bob' }, as: target_user)
      data = gql_data(result)['updateUser']

      expect(data['success']).to be true
      expect(target_user.reload.first_name).to eq('Bob')
    end

    it 'rejects role change attempt' do
      result = run_mutation(id: target_user.to_gid_param, input: { role: 'ADMIN' }, as: target_user)
      data = gql_data(result)['updateUser']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('INSUFFICIENT_PERMISSIONS')
    end

    it 'rejects update of another user' do
      other_user = create(:user)
      result = run_mutation(id: other_user.to_gid_param, input: { firstName: 'Hacked' }, as: target_user)

      # authorize! raises GraphQL::ExecutionError which propagates (no rescue in mutation)
      expect(gql_errors(result)).to be_present
      expect(gql_data(result)['updateUser']).to be_nil
    end
  end

  describe 'user not found' do
    it 'returns not found error' do
      result = run_mutation(id: 'invalid-id-0')
      data = gql_data(result)['updateUser']

      expect(data['success']).to be false
      expect(data['message']).to eq('User not found')
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end

  describe 'profile update cooldown' do
    it 'rejects update when cooldown is active for non-admin' do
      target_user.update_column(:profile_updated_at, 1.day.ago)

      result = run_mutation(id: target_user.to_gid_param, input: { firstName: 'Bob' }, as: target_user)
      data = gql_data(result)['updateUser']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('VALIDATION_FAILED')
    end

    it 'allows admin to bypass cooldown' do
      target_user.update_column(:profile_updated_at, 1.day.ago)

      result = run_mutation(input: { firstName: 'Bob' })
      data = gql_data(result)['updateUser']

      expect(data['success']).to be true
    end
  end
end
