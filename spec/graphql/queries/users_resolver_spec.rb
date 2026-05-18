require 'rails_helper'

RSpec.describe 'users query', type: :graphql do
  let(:admin) { create(:user, :admin) }

  let(:query) do
    <<~GRAPHQL
      query Users($role: UserRoleEnum, $search: String) {
        users(role: $role, search: $search) {
          nodes { id email firstName lastName }
          pageInfo { hasNextPage hasPreviousPage }
        }
      }
    GRAPHQL
  end

  def run_query(variables: {}, as: admin)
    execute_graphql(query: query, variables: variables, user: as)
  end

  describe 'admin listing users' do
    it 'returns all users' do
      create_list(:user, 3)

      result = run_query
      data = gql_data(result)['users']

      expect(gql_errors(result)).to be_nil
      expect(data['nodes'].length).to be >= 3
    end

    it 'includes the admin in the result' do
      result = run_query
      emails = gql_data(result)['users']['nodes'].map { |u| u['email'] }

      expect(emails).to include(admin.email)
    end
  end

  describe 'filtering by role' do
    it 'returns only users with the requested role' do
      regular_users = create_list(:user, 2)
      extra_admin = create(:user, :admin)

      result = run_query(variables: { role: 'ADMIN' })
      emails = gql_data(result)['users']['nodes'].map { |u| u['email'] }

      expect(emails).to include(admin.email, extra_admin.email)
      regular_users.each { |u| expect(emails).not_to include(u.email) }
    end
  end

  describe 'searching by name or email' do
    it 'returns users matching the search term' do
      matching = create(:user, first_name: 'Zephyr', last_name: 'Unique')
      non_matching = create(:user, first_name: 'Common', last_name: 'Name')

      result = run_query(variables: { search: 'Zephyr' })
      emails = gql_data(result)['users']['nodes'].map { |u| u['email'] }

      expect(emails).to include(matching.email)
      expect(emails).not_to include(non_matching.email)
    end
  end

  describe 'non-admin user' do
    it 'raises an authorization error' do
      regular_user = create(:user)
      result = run_query(as: regular_user)

      expect(gql_errors(result)).to be_present
    end
  end

  describe 'unauthenticated' do
    it 'raises an authentication error' do
      result = run_query(as: nil)

      expect(gql_errors(result)).to be_present
    end
  end
end
