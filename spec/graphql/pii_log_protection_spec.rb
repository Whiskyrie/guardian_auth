require 'rails_helper'

RSpec.describe 'PII log protection (NEX-58)', type: :graphql do
  let(:user) { create(:user) }
  let(:log_output) { StringIO.new }
  let(:test_logger) { Logger.new(log_output) }

  before do
    allow(Rails).to receive(:logger).and_return(test_logger)
  end

  def logged_output
    log_output.string
  end

  # -------------------------------------------------------
  # (a) authentication.rb — no token fragment or email in log
  # -------------------------------------------------------
  describe 'Authentication concern logging' do
    let(:token) { JwtService.encode(user_id: user.id, role: user.primary_role) }

    it 'does not log a token fragment when authenticating' do
      allow(JwtService).to receive(:valid_token?).and_return(true)
      allow(JwtService).to receive(:decode).and_return({ 'user_id' => user.id, 'iat' => Time.current.to_i })
      allow(SecurityLogger).to receive(:log_login_attempt)

      {
        current_user: user,
        current_token: token,
        remote_ip: '1.2.3.4',
        user_agent: 'RSpec'
      }

      # Simulate extract_token_from_header path via execute_graphql with an explicit token
      execute_graphql(query: '{ __typename }', user: user, token: token)

      expect(logged_output).not_to match(/Token extracted and stored/)
      expect(logged_output).not_to match(/#{Regexp.escape(token[0..10])}/)
    end

    it 'does not log the Authorization header value' do
      execute_graphql(query: '{ __typename }', user: user, token: token)

      expect(logged_output).not_to match(/Authorization header:/)
    end

    it 'does not log the user email on successful authentication' do
      allow(JwtService).to receive(:valid_token?).and_return(true)
      allow(JwtService).to receive(:decode).and_return({ 'user_id' => user.id, 'iat' => Time.current.to_i })
      allow(SecurityLogger).to receive(:log_login_attempt) do |args|
        expect(args).not_to have_key(:email)
        expect(args[:user_id]).to eq(user.id)
      end

      execute_graphql(query: '{ __typename }', user: user, token: token)
    end
  end

  # -------------------------------------------------------
  # (b) performance_tracer.rb — query literals are redacted
  # -------------------------------------------------------
  describe 'PerformanceTracer#sanitize_query' do
    subject(:sanitize) { Tracers::PerformanceTracer.sanitize_query(query) }

    context 'with a query containing double-quoted string literals' do
      let(:query) { 'mutation { loginUser(input: { email: "user@example.com", password: "secret123" }) { token } }' }

      it 'replaces string literal values with [REDACTED]' do
        expect(sanitize).not_to include('user@example.com')
        expect(sanitize).not_to include('secret123')
        expect(sanitize).to include('[REDACTED]')
      end
    end

    context 'with a query containing no string literals' do
      let(:query) { 'query { users { id } }' }

      it 'returns the query unchanged (no false positives)' do
        expect(sanitize).to eq(query)
      end
    end

    context 'with a nil query' do
      let(:query) { nil }

      it 'returns nil safely' do
        expect(sanitize).to be_nil
      end
    end

    context 'when logging a query with PII' do
      it 'does not log email values in query performance log' do
        query_with_pii = 'mutation { loginUser(input: { email: "victim@example.com" }) { token } }'

        Tracers::PerformanceTracer.send(
          :log_query_performance,
          query: query_with_pii,
          duration: 0.1,
          variables: {},
          operation_name: 'Login'
        )

        expect(logged_output).not_to include('victim@example.com')
        expect(logged_output).to include('[REDACTED]')
      end
    end
  end

  # -------------------------------------------------------
  # (c) graphql_controller context — no Rack request object
  # -------------------------------------------------------
  describe 'GraphQL context' do
    it 'does not expose the full Rack request object in context' do
      captured_context = nil

      allow(GuardianAuthSchema).to receive(:execute) do |_query, opts|
        captured_context = opts[:context]
        { 'data' => {} }
      end

      execute_graphql(query: '{ __typename }', user: user)

      expect(captured_context).not_to have_key(:request)
      expect(captured_context[:remote_ip]).to be_present
      expect(captured_context[:user_agent]).to be_present
    end
  end
end
