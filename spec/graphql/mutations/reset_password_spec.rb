require 'rails_helper'

RSpec.describe 'ResetPassword mutation', type: :graphql do
  let(:user) { create(:user, password: 'SecurePassword1@', password_confirmation: 'SecurePassword1@') }

  let(:mutation) do
    <<~GRAPHQL
      mutation ResetPassword($token: String!, $newPassword: String!) {
        resetPassword(input: { token: $token, newPassword: $newPassword }) {
          success
          message
          errors { message code field }
        }
      }
    GRAPHQL
  end

  def run_mutation(token:, new_password: 'NewSecure1@')
    execute_graphql(
      query: mutation,
      variables: { token: token, newPassword: new_password }
    )
  end

  def generate_reset_token(for_user:)
    raw_token = PasswordResetToken.create_for_user(for_user)
    raw_token
  end

  describe 'valid token resets password' do
    it 'resets the password successfully' do
      raw_token = generate_reset_token(for_user: user)
      result = run_mutation(token: raw_token, new_password: 'NewSecure1@')

      expect(gql_errors(result)).to be_nil
      data = gql_data(result)['resetPassword']
      expect(data['success']).to be true
      expect(data['message']).to include('Password has been reset successfully')
      expect(data['errors']).to be_empty
    end

    it 'allows login with the new password' do
      raw_token = generate_reset_token(for_user: user)
      run_mutation(token: raw_token, new_password: 'NewSecure1@')
      expect(user.reload.authenticate('NewSecure1@')).to be_truthy
    end

    it 'marks the reset token as used' do
      raw_token = generate_reset_token(for_user: user)
      run_mutation(token: raw_token, new_password: 'NewSecure1@')
      token_hash = Digest::SHA256.hexdigest(raw_token)
      token_record = PasswordResetToken.find_by(token_hash: token_hash)
      expect(token_record.used).to be true
    end
  end

  describe 'invalid token' do
    it 'returns error for invalid token' do
      result = run_mutation(token: 'invalid_token_value')

      data = gql_data(result)['resetPassword']
      expect(data['success']).to be false
      expect(data['message']).to include('Invalid or expired reset token')
      expect(data['errors'].first['code']).to eq('PASSWORD_RESET_TOKEN_INVALID')
    end
  end

  describe 'expired token' do
    it 'returns error for expired token' do
      raw_token = generate_reset_token(for_user: user)
      token_hash = Digest::SHA256.hexdigest(raw_token)
      PasswordResetToken.find_by(token_hash: token_hash).update!(expires_at: 2.hours.ago)

      result = run_mutation(token: raw_token)

      data = gql_data(result)['resetPassword']
      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('PASSWORD_RESET_TOKEN_INVALID')
    end
  end

  describe 'weak new password' do
    it 'returns validation error for password without special character' do
      raw_token = generate_reset_token(for_user: user)
      result = run_mutation(token: raw_token, new_password: 'NoSpecial1Ch')

      data = gql_data(result)['resetPassword']
      expect(data['success']).to be false
      expect(data['errors']).to be_present
    end

    it 'returns validation error for short password' do
      raw_token = generate_reset_token(for_user: user)
      result = run_mutation(token: raw_token, new_password: 'Sh1@')

      data = gql_data(result)['resetPassword']
      expect(data['success']).to be false
    end
  end

  describe 'password history enforcement' do
    it 'rejects reuse of the current password' do
      raw_token = generate_reset_token(for_user: user)
      result = run_mutation(token: raw_token, new_password: 'SecurePassword1@')

      data = gql_data(result)['resetPassword']
      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('VALIDATION_FAILED')
      expect(data['errors'].first['message']).to include('was used recently')
    end

    it 'rejects a password that was previously used' do
      # First reset: change away from the original password
      first_token = generate_reset_token(for_user: user)
      run_mutation(token: first_token, new_password: 'Intermediate1@')

      # Second reset: try to reuse the original password
      second_token = generate_reset_token(for_user: user)
      result = run_mutation(token: second_token, new_password: 'SecurePassword1@')

      data = gql_data(result)['resetPassword']
      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('VALIDATION_FAILED')
      expect(data['errors'].first['message']).to include('was used recently')
    end
  end

  describe 'successful reset invalidates existing sessions' do
    it 'updates tokens_valid_after on the user' do
      raw_token = generate_reset_token(for_user: user)
      expect do
        run_mutation(token: raw_token, new_password: 'NewSecure1@')
      end.to change { user.reload.tokens_valid_after }.from(nil)
    end
  end
end
