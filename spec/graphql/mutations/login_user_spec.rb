require 'rails_helper'

RSpec.describe 'LoginUser mutation', type: :graphql do
  let(:user) { create(:user, password: 'SecurePassword1@', password_confirmation: 'SecurePassword1@') }

  let(:mutation) do
    <<~GRAPHQL
      mutation LoginUser($email: String!, $password: String!) {
        loginUser(input: { email: $email, password: $password }) {
          success
          message
          token
          user { id email }
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(email: user.email, password: 'SecurePassword1@')
    execute_graphql(
      query: mutation,
      variables: { email: email, password: password }
    )
  end

  describe 'successful login' do
    it 'returns success with token and user' do
      result = run_mutation

      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['loginUser']
      expect(data['success']).to be true
      expect(data['message']).to eq('Login successful')
      expect(data['token']).to be_present
      expect(data['user']['email']).to eq(user.email)
      expect(data['errors']).to be_empty
    end

    it 'updates last_login_at' do
      expect {
        run_mutation
      }.to change { user.reload.last_login_at }.from(nil)
    end
  end

  describe 'invalid credentials' do
    it 'returns failure for wrong password' do
      result = run_mutation(password: 'WrongPassword1@')

      data = gql_data(result)['loginUser']
      expect(data['success']).to be false
      expect(data['message']).to eq('Invalid credentials')
      expect(data['token']).to be_nil
      expect(data['user']).to be_nil
      expect(data['errors'].first['code']).to eq('INVALID_CREDENTIALS')
    end

    it 'returns failure for non-existent email' do
      result = run_mutation(email: 'nonexistent@example.com')

      data = gql_data(result)['loginUser']
      expect(data['success']).to be false
      expect(data['message']).to eq('Invalid credentials')
      expect(data['errors'].first['code']).to eq('INVALID_CREDENTIALS')
    end
  end

  describe 'empty email/password' do
    it 'returns error for empty email' do
      result = run_mutation(email: '')

      data = gql_data(result)['loginUser']
      expect(data['success']).to be false
      expect(data['message']).to eq('Email and password are required')
      expect(data['errors'].first['code']).to eq('INVALID_INPUT')
    end

    it 'returns error for empty password' do
      result = run_mutation(password: '')

      data = gql_data(result)['loginUser']
      expect(data['success']).to be false
      expect(data['message']).to eq('Email and password are required')
      expect(data['errors'].first['code']).to eq('INVALID_INPUT')
    end
  end
end
