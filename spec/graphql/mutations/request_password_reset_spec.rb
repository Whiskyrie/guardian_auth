require 'rails_helper'

RSpec.describe 'RequestPasswordReset mutation', type: :graphql do
  let(:user) { create(:user) }

  let(:mutation) do
    <<~GRAPHQL
      mutation RequestPasswordReset($email: String!) {
        requestPasswordReset(input: { email: $email }) {
          success
          message
          errors { message code }
        }
      }
    GRAPHQL
  end

  def run_mutation(email: user.email)
    execute_graphql(
      query: mutation,
      variables: { email: email }
    )
  end

  describe 'existing email' do
    it 'returns success' do
      result = run_mutation

      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['requestPasswordReset']
      expect(data['success']).to be true
      expect(data['message']).to include('password reset token has been generated')
      expect(data['errors']).to be_empty
    end

    it 'creates a password reset token for the user' do
      expect do
        run_mutation
      end.to change { user.password_reset_tokens.count }.by(1)
    end
  end

  describe 'non-existent email' do
    it 'returns the same generic success message (no enumeration)' do
      result = run_mutation(email: 'nonexistent@example.com')

      data = gql_data(result)['requestPasswordReset']
      expect(data['success']).to be true
      expect(data['message']).to include('password reset token has been generated')
    end

    it 'does not create any password reset tokens' do
      expect do
        run_mutation(email: 'nonexistent@example.com')
      end.not_to change(PasswordResetToken, :count)
    end
  end

  describe 'blank email' do
    it 'returns error for blank email' do
      result = run_mutation(email: '')

      data = gql_data(result)['requestPasswordReset']
      expect(data['success']).to be false
      expect(data['message']).to eq('Email is required')
      expect(data['errors'].first['code']).to eq('INVALID_INPUT')
    end
  end
end
