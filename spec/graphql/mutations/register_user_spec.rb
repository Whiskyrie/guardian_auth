require 'rails_helper'

RSpec.describe 'RegisterUser mutation', type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation RegisterUser($email: String!, $password: String!, $firstName: String!, $lastName: String!) {
        registerUser(input: { email: $email, password: $password, firstName: $firstName, lastName: $lastName }) {
          success
          message
          token
          user { id email firstName lastName }
          errors { message code field }
        }
      }
    GRAPHQL
  end

  def run_mutation(email: 'newuser@example.com', password: 'SecurePassword1@', first_name: 'John', last_name: 'Doe')
    execute_graphql(
      query: mutation,
      variables: { email: email, password: password, firstName: first_name, lastName: last_name }
    )
  end

  describe 'successful registration' do
    it 'creates a new user and returns token' do
      result = run_mutation

      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['registerUser']
      expect(data['success']).to be true
      expect(data['message']).to include('Registro realizado')
      expect(data['token']).to be_present
      expect(data['user']['email']).to eq('newuser@example.com')
      expect(data['user']['firstName']).to eq('John')
      expect(data['user']['lastName']).to eq('Doe')
      expect(data['errors']).to be_empty
    end

    it 'assigns the default user role' do
      run_mutation
      new_user = User.find_by(email: 'newuser@example.com')
      expect(new_user.role_names).to include('user')
    end
  end

  describe 'duplicate email' do
    it 'returns failure for already taken email' do
      create(:user, email: 'taken@example.com')
      result = run_mutation(email: 'taken@example.com')

      data = gql_data(result)['registerUser']
      expect(data['success']).to be false
      expect(data['message']).to eq('Registration failed')
      expect(data['token']).to be_nil
      expect(data['errors']).to be_present
    end
  end

  describe 'weak password' do
    it 'returns failure for password without special character' do
      result = run_mutation(password: 'NoSpecial1Ch')

      data = gql_data(result)['registerUser']
      expect(data['success']).to be false
      expect(data['errors']).to be_present
    end

    it 'returns failure for common weak password' do
      result = run_mutation(password: 'password123@')

      data = gql_data(result)['registerUser']
      expect(data['success']).to be false
    end
  end

  describe 'invalid email format' do
    it 'returns failure for malformed email' do
      result = run_mutation(email: 'not-an-email')

      data = gql_data(result)['registerUser']
      expect(data['success']).to be false
      expect(data['errors']).to be_present
    end
  end

  describe 'missing fields' do
    it 'returns failure for missing first_name (too short)' do
      result = run_mutation(first_name: 'A')

      data = gql_data(result)['registerUser']
      expect(data['success']).to be false
    end

    it 'returns failure for missing last_name (too short)' do
      result = run_mutation(last_name: 'B')

      data = gql_data(result)['registerUser']
      expect(data['success']).to be false
    end
  end
end
