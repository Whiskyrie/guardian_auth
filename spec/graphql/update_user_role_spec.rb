require 'rails_helper'

RSpec.describe 'UpdateUserRole mutation', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateUserRole($userId: ID!, $roleNames: [UserRoleEnum!]!) {
        updateUserRole(input: { userId: $userId, roleNames: $roleNames }) {
          success
          message
          user { id roles }
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(user_id: target_user.id.to_s, role_names: ['USER'], as: admin)
    execute_graphql(
      query: mutation,
      variables: { userId: user_id, roleNames: role_names },
      user: as
    )
  end

  describe 'successful role assignment' do
    it 'assigns the requested roles to the user' do
      result = run_mutation(role_names: ['USER'])

      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['updateUserRole']
      expect(data['success']).to be true
      expect(data['user']['roles']).to include('USER')
    end

    it 'replaces existing roles with the new set' do
      # ensure target_user starts with only 'user' role
      result = run_mutation(role_names: ['ADMIN'])

      expect(gql_errors(result)).to be_nil
      expect(target_user.reload.role_names).to contain_exactly('admin')
    end
  end

  describe 'invalid role name' do
    it 'returns an error without persisting any changes' do
      original_roles = target_user.reload.role_names.dup

      # GraphQL enum validation will reject unknown enum values at the schema level
      result = execute_graphql(
        query: mutation,
        variables: { userId: target_user.id.to_s, roleNames: ['NOT_A_ROLE'] },
        user: admin
      )

      # Invalid enum value rejected by GraphQL schema before reaching resolver
      expect(gql_errors(result)).to be_present
      expect(target_user.reload.role_names).to match_array(original_roles)
    end
  end

  describe 'atomic rollback on partial failure' do
    it 'rolls back all role assignments if persistence fails mid-way' do
      # Materialize both users before the stub to avoid triggering it during factory creation
      admin_user = admin
      initial_role_names = target_user.reload.role_names.dup

      call_count = 0
      allow_any_instance_of(UserRole).to receive(:save!).and_wrap_original do |method|
        call_count += 1
        raise ActiveRecord::RecordInvalid, method.receiver if call_count >= 2

        method.call
      end

      result = execute_graphql(
        query: mutation,
        variables: { userId: target_user.id.to_s, roleNames: %w[ADMIN USER] },
        user: admin_user
      )

      data = gql_data(result)['updateUserRole']
      expect(data['success']).to be false
      # No partial state: original roles restored by rollback
      expect(target_user.reload.role_names).to match_array(initial_role_names)
    end
  end

  describe 'authorization' do
    it 'rejects non-admin users' do
      regular_user = create(:user)

      result = execute_graphql(
        query: mutation,
        variables: { userId: target_user.id.to_s, roleNames: ['ADMIN'] },
        user: regular_user
      )

      data = gql_data(result)['updateUserRole']
      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('INSUFFICIENT_PERMISSIONS')
    end

    it 'returns not found for non-existent user' do
      result = run_mutation(user_id: '00000000')

      data = gql_data(result)['updateUserRole']
      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end
end
