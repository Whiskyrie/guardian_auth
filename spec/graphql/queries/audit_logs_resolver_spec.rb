require 'rails_helper'

RSpec.describe 'auditLogs query', type: :graphql do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  # The admin factory creates the role but not the permissions (those come from migrations).
  # We set up the required permission here so the resolver's permission check passes.
  before do
    permission = Permission.find_or_create_by!(resource: 'audit_logs', action: 'read') do |p|
      p.description = 'View audit logs'
    end
    admin_role = admin.roles.find_by(name: 'admin')
    admin_role.permissions << permission unless admin_role.permissions.include?(permission)
  end

  let(:query) do
    <<~GRAPHQL
      query AuditLogs($userId: ID, $action: String, $resource: String, $result: String) {
        auditLogs(userId: $userId, action: $action, resource: $resource, result: $result) {
          nodes {
            id
            action
            resource
            result
            user { id }
          }
        }
      }
    GRAPHQL
  end

  def run_query(variables: {}, as: admin)
    execute_graphql(query: query, variables: variables, user: as)
  end

  def create_log(user: target_user, action: 'login', resource: 'User', result: 'success')
    AuditLog.create!(user: user, action: action, resource: resource, result: result, metadata: {})
  end

  describe 'admin querying audit logs' do
    it 'returns audit logs' do
      create_log
      create_log(action: 'logout')

      result = run_query
      data = gql_data(result)['auditLogs']

      expect(gql_errors(result)).to be_nil
      expect(data['nodes'].length).to be >= 2
    end
  end

  describe 'filtering' do
    it 'filters by user_id' do
      create_log(user: target_user)
      other_user = create(:user)
      create_log(user: other_user)

      result = run_query(variables: { userId: target_user.id.to_s })
      nodes = gql_data(result)['auditLogs']['nodes']

      expect(nodes).to be_present
      nodes.each { |log| expect(log['user']['id'].to_i).to eq(target_user.id) }
    end

    it 'filters by action' do
      create_log(action: 'login')
      create_log(action: 'logout')

      result = run_query(variables: { action: 'login' })
      actions = gql_data(result)['auditLogs']['nodes'].map { |l| l['action'] }

      expect(actions).to all(eq('login'))
    end

    it 'filters by resource' do
      create_log(resource: 'User')
      create_log(resource: 'Token')

      result = run_query(variables: { resource: 'Token' })
      resources = gql_data(result)['auditLogs']['nodes'].map { |l| l['resource'] }

      expect(resources).to all(eq('Token'))
    end

    it 'filters by result' do
      create_log(result: 'success')
      create_log(result: 'failure')

      result = run_query(variables: { result: 'failure' })
      results = gql_data(result)['auditLogs']['nodes'].map { |l| l['result'] }

      expect(results).to all(eq('failure'))
    end
  end

  describe 'non-admin user' do
    it 'raises an authorization error' do
      result = run_query(as: target_user)

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
