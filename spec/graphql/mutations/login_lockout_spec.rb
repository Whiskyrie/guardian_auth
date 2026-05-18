require 'rails_helper'

RSpec.describe 'LoginUser lockout', type: :graphql do
  let(:password) { 'SecurePassword1@' }
  let(:user) { create(:user) }

  let(:mutation) do
    <<~GQL
      mutation LoginUser($email: String!, $password: String!) {
        loginUser(input: { email: $email, password: $password }) {
          success
          message
          token
          errors { message code }
        }
      }
    GQL
  end

  def run_login(email: user.email, pass: 'wrong-password')
    execute_graphql(
      query: mutation,
      variables: { email: email, password: pass }
    )
  end

  def login_data(result)
    gql_data(result)['loginUser']
  end

  describe 'bloqueio após tentativas falhas' do
    it 'bloqueia após MAX_FAILED_ATTEMPTS tentativas incorretas' do
      User::MAX_FAILED_ATTEMPTS.times { run_login }

      result = run_login
      data = login_data(result)

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('ACCOUNT_LOCKED')
    end

    it 'incrementa failed_login_attempts a cada falha' do
      3.times { run_login }
      expect(user.reload.failed_login_attempts).to eq(3)
    end

    it 'define locked_until ao atingir o limite' do
      User::MAX_FAILED_ATTEMPTS.times { run_login }
      expect(user.reload.locked_until).to be_present
      expect(user.reload.locked_until).to be > Time.current
    end

    it 'inclui o tempo restante na mensagem de bloqueio' do
      User::MAX_FAILED_ATTEMPTS.times { run_login }

      result = run_login
      expect(login_data(result)['message']).to match(/\d+ minuto/)
    end
  end

  describe 'conta bloqueada' do
    before do
      user.update_columns(
        failed_login_attempts: User::MAX_FAILED_ATTEMPTS,
        locked_until: 10.minutes.from_now
      )
    end

    it 'rejeita login mesmo com senha correta' do
      result = run_login(pass: password)
      data = login_data(result)

      expect(data['success']).to be false
      expect(data['errors'].first['code']).to eq('ACCOUNT_LOCKED')
    end

    it 'não incrementa o contador durante o bloqueio' do
      run_login(pass: password)
      expect(user.reload.failed_login_attempts).to eq(User::MAX_FAILED_ATTEMPTS)
    end
  end

  describe 'reset após login bem-sucedido' do
    it 'zera o contador após login com senha correta' do
      2.times { run_login }
      expect(user.reload.failed_login_attempts).to eq(2)

      run_login(pass: password)
      expect(user.reload.failed_login_attempts).to eq(0)
      expect(user.reload.locked_until).to be_nil
    end
  end

  describe 'conta desbloqueada após expirar' do
    it 'permite login quando locked_until está no passado' do
      user.update_columns(
        failed_login_attempts: User::MAX_FAILED_ATTEMPTS,
        locked_until: 1.minute.ago
      )

      result = run_login(pass: password)
      expect(login_data(result)['success']).to be true
    end
  end
end
