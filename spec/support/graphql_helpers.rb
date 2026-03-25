# Helper para executar mutations GraphQL nos specs
module GraphqlHelpers
  def execute_graphql(query:, variables: {}, user: nil, token: nil, ip: '127.0.0.1')
    context = {
      current_user: user,
      current_token: token,
      request: double('request', remote_ip: ip, headers: {}, user_agent: 'RSpec'),
      ip_address: ip,
      user_agent: 'RSpec'
    }

    GuardianAuthSchema.execute(
      query,
      variables: variables,
      context: context
    )
  end

  def gql_errors(result)
    result['errors']
  end

  def gql_data(result)
    result['data']
  end
end

RSpec.configure do |config|
  config.include GraphqlHelpers, type: :graphql
end
