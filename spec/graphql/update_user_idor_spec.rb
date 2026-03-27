require 'rails_helper'

RSpec.describe 'UpdateUser IDOR protection', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateUser($id: ID!, $input: UserInput!) {
        updateUser(input: { id: $id, input: $input }) {
          user { id email }
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_update(id:, input: { firstName: 'Changed' }, as: admin)
    execute_graphql(
      query: mutation,
      variables: { id: id, input: input },
      user: as
    )
  end

  describe 'with a valid User GlobalID' do
    it 'updates the user successfully' do
      result = run_update(id: target_user.to_gid_param, input: { firstName: 'Updated' })

      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['updateUser']
      expect(data['errors']).to be_empty
      expect(target_user.reload.first_name).to eq('Updated')
    end
  end

  describe 'with a GlobalID pointing to a non-User model (IDOR attempt)' do
    it 'returns not-found error and does not expose data from the other model' do
      role = Role.find_or_create_by!(name: 'admin') do |r|
        r.description = 'Administrator'
        r.system_role = true
      end

      result = run_update(id: role.to_gid_param)

      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['updateUser']
      expect(data['user']).to be_nil
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
      # The error message must not reveal which model was attempted
      expect(data['errors'].first['message']).to eq('User not found')
    end
  end

  describe 'with a GlobalID for a non-existent User' do
    it 'returns not-found error' do
      non_existent_gid = User.new(id: 999_999_999).to_gid_param

      result = run_update(id: non_existent_gid)

      data = gql_data(result)['updateUser']
      expect(data['user']).to be_nil
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end

  describe 'with a malformed / non-GlobalID string' do
    it 'returns not-found error without raising' do
      result = run_update(id: 'not-a-valid-gid-at-all')

      data = gql_data(result)['updateUser']
      expect(data['user']).to be_nil
      expect(data['errors'].first['code']).to eq('RESOURCE_NOT_FOUND')
    end
  end
end
