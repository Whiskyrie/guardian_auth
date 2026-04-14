require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  # ---- Validations ----

  describe 'validations' do
    it 'requires action' do
      log = build(:audit_log, action: nil)
      expect(log).not_to be_valid
      expect(log.errors[:action]).to include("can't be blank")
    end

    it 'requires resource' do
      log = build(:audit_log, resource: nil)
      expect(log).not_to be_valid
      expect(log.errors[:resource]).to include("can't be blank")
    end

    it 'requires result to be in the allowed list' do
      log = build(:audit_log, result: 'unknown')
      expect(log).not_to be_valid
      expect(log.errors[:result]).to include('is not included in the list')
    end

    %w[success failure blocked].each do |result|
      it "accepts result: #{result}" do
        log = build(:audit_log, result: result)
        expect(log).to be_valid
      end
    end
  end

  # ---- Associations ----

  describe 'associations' do
    it 'belongs to user (optional)' do
      log = build(:audit_log, user: nil)
      expect(log).to be_valid
    end

    it 'can belong to a user' do
      user = create(:user)
      log = build(:audit_log, user: user)
      expect(log).to be_valid
      expect(log.user).to eq(user)
    end
  end

  # ---- Scopes ----

  describe 'scopes' do
    let(:user) { create(:user) }

    let!(:success_log) { create(:audit_log, user: user, action: 'login', resource: 'User', result: 'success') }
    let!(:failure_log) { create(:audit_log, user: user, action: 'login', resource: 'Token', result: 'failure') }
    let!(:blocked_log) { create(:audit_log, user: user, action: 'access_denied', resource: 'User', result: 'blocked') }

    describe '.for_user' do
      it 'returns logs for the specified user' do
        expect(AuditLog.for_user(user)).to include(success_log, failure_log, blocked_log)
      end
    end

    describe '.by_action' do
      it 'filters by action' do
        expect(AuditLog.by_action('login')).to include(success_log, failure_log)
        expect(AuditLog.by_action('login')).not_to include(blocked_log)
      end
    end

    describe '.by_resource' do
      it 'filters by resource' do
        expect(AuditLog.by_resource('User')).to include(success_log, blocked_log)
        expect(AuditLog.by_resource('User')).not_to include(failure_log)
      end
    end

    describe '.by_result' do
      it 'filters by result' do
        expect(AuditLog.by_result('success')).to include(success_log)
        expect(AuditLog.by_result('success')).not_to include(failure_log, blocked_log)
      end
    end

    describe '.successful' do
      it 'returns only success logs' do
        expect(AuditLog.successful).to include(success_log)
        expect(AuditLog.successful).not_to include(failure_log, blocked_log)
      end
    end

    describe '.failed' do
      it 'returns only failure logs' do
        expect(AuditLog.failed).to include(failure_log)
        expect(AuditLog.failed).not_to include(success_log, blocked_log)
      end
    end

    describe '.blocked' do
      it 'returns only blocked logs' do
        expect(AuditLog.blocked).to include(blocked_log)
        expect(AuditLog.blocked).not_to include(success_log, failure_log)
      end
    end
  end

  # ---- Class Methods ----

  describe '.log_action' do
    it 'creates an audit log entry' do
      user = create(:user)
      expect {
        AuditLog.log_action(action: 'register', resource: 'User', user: user, result: 'success')
      }.to change(AuditLog, :count).by(1)
    end
  end
end
