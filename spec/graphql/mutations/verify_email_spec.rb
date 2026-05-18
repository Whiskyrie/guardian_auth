require 'rails_helper'

RSpec.describe 'VerifyEmail mutation', type: :graphql do
  let(:user) { create(:user) }

  let(:mutation) do
    <<~GQL
      mutation VerifyEmail($token: String!) {
        verifyEmail(input: { token: $token }) {
          success
          message
          user { id emailVerified }
          errors { message code }
        }
      }
    GQL
  end

  def run_mutation(token:)
    execute_graphql(query: mutation, variables: { token: token })
  end

  describe 'com token válido' do
    let(:raw_token) { user.generate_email_verification_token! }

    it 'verifica o email e limpa o digest' do
      result = run_mutation(token: raw_token)
      data = gql_data(result)['verifyEmail']

      expect(data['success']).to be true
      expect(data['user']['emailVerified']).to be true
      expect(user.reload.email_verified_at).to be_present
      expect(user.reload.email_verification_digest).to be_nil
    end

    it 'retorna mensagem de sucesso' do
      result = run_mutation(token: raw_token)
      expect(gql_data(result)['verifyEmail']['message']).to include('sucesso')
    end
  end

  describe 'com token inválido' do
    it 'retorna erro' do
      result = run_mutation(token: 'token-invalido')
      data = gql_data(result)['verifyEmail']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('INVALID_INPUT')
    end
  end

  describe 'com token expirado' do
    it 'retorna erro de token expirado' do
      user.update_columns(
        email_verification_digest: Digest::SHA256.hexdigest('old-token'),
        email_verification_sent_at: 25.hours.ago
      )

      result = run_mutation(token: 'old-token')
      data = gql_data(result)['verifyEmail']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('TOKEN_EXPIRED')
    end
  end

  describe 'com email já verificado' do
    it 'retorna sucesso indicando que já estava verificado' do
      raw_token = user.generate_email_verification_token!
      user.update_column(:email_verified_at, Time.current)

      result = run_mutation(token: raw_token)
      data = gql_data(result)['verifyEmail']

      expect(data['success']).to be true
      expect(data['message']).to include('já estava verificado')
    end
  end

  describe 'com token em branco' do
    it 'retorna erro' do
      result = run_mutation(token: '')
      data = gql_data(result)['verifyEmail']

      expect(data['success']).to be false
    end
  end
end
