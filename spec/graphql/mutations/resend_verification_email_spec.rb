require 'rails_helper'

RSpec.describe 'ResendVerificationEmail mutation', type: :graphql do
  let(:user) { create(:user) }
  let(:token) { JwtService.encode(user_id: user.id) }

  let(:mutation) do
    <<~GQL
      mutation ResendVerificationEmail {
        resendVerificationEmail(input: {}) {
          success
          message
          errors { message code }
        }
      }
    GQL
  end

  def run_mutation(as: user, with_token: token)
    execute_graphql(query: mutation, user: as, token: with_token)
  end

  describe 'usuário autenticado com email não verificado' do
    it 'enfileira o job e retorna sucesso' do
      expect(SendVerificationEmailJob).to receive(:perform_later).with(user.id)

      result = run_mutation
      data = gql_data(result)['resendVerificationEmail']

      expect(data['success']).to be true
      expect(data['message']).to include('enviado')
    end
  end

  describe 'usuário com email já verificado' do
    it 'retorna sucesso sem enfileirar job' do
      user.update_column(:email_verified_at, Time.current)
      expect(SendVerificationEmailJob).not_to receive(:perform_later)

      result = run_mutation
      data = gql_data(result)['resendVerificationEmail']

      expect(data['success']).to be true
      expect(data['message']).to include('já está verificado')
    end
  end

  describe 'dentro do cooldown de 15 minutos' do
    it 'retorna erro de rate limit' do
      user.update_column(:email_verification_sent_at, 5.minutes.ago)

      result = run_mutation
      data = gql_data(result)['resendVerificationEmail']

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('RATE_LIMIT_EXCEEDED')
    end
  end

  describe 'sem autenticação' do
    it 'retorna erro de autenticação' do
      result = run_mutation(as: nil, with_token: nil)
      data = gql_data(result)['resendVerificationEmail']

      expect(data['success']).to be false
    end
  end
end
