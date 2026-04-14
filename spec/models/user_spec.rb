require 'rails_helper'

RSpec.describe User, type: :model do
  # ---- Validations ----

  describe 'validations' do
    describe 'email' do
      it 'requires email' do
        user = build(:user, email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'requires unique email (case insensitive)' do
        create(:user, email: 'unique@example.com')
        duplicate = build(:user, email: 'unique@example.com')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:email]).to include('has already been taken')
      end

      it 'requires unique email regardless of case' do
        create(:user, email: 'case@example.com')
        duplicate = build(:user, email: 'CASE@EXAMPLE.COM')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:email]).to include('has already been taken')
      end

      it 'validates email format' do
        invalid_emails = ['notanemail', '@example.com', 'user@', 'user@.com', 'user@com']
        invalid_emails.each do |email|
          user = build(:user, email: email)
          expect(user).not_to be_valid
          expect(user.errors[:email]).to include('must be a valid email format')
        end
      end

      it 'accepts valid emails' do
        valid_emails = ['user@example.com', 'user.name@example.com', 'user+tag@example.com']
        valid_emails.each do |email|
          user = build(:user, email: email)
          expect(user).to be_valid
        end
      end

      it 'enforces maximum length' do
        user = build(:user, email: "#{'a' * 244}@example.com")
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is too long (maximum is 255 characters)')
      end
    end

    describe 'password' do
      it 'requires minimum 8 characters' do
        user = build(:user, password: 'Short1@', password_confirmation: 'Short1@')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 8 characters)')
      end

      it 'requires uppercase letter' do
        user = build(:user, password: 'lowercase1@', password_confirmation: 'lowercase1@')
        expect(user).not_to be_valid
      end

      it 'requires lowercase letter' do
        user = build(:user, password: 'UPPERCASE1@', password_confirmation: 'UPPERCASE1@')
        expect(user).not_to be_valid
      end

      it 'requires digit' do
        user = build(:user, password: 'NoDigitHere@', password_confirmation: 'NoDigitHere@')
        expect(user).not_to be_valid
      end

      it 'requires special character' do
        user = build(:user, password: 'NoSpecial1Ch', password_confirmation: 'NoSpecial1Ch')
        expect(user).not_to be_valid
      end

      it 'accepts a strong password' do
        user = build(:user, password: 'SecurePassword1@', password_confirmation: 'SecurePassword1@')
        expect(user).to be_valid
      end

      it 'rejects weak passwords' do
        User::WEAK_PASSWORDS.each do |weak|
          # Append special char and digit if not present to isolate the weak-password check
          pw = weak.match?(/[@$!%*?&]/) ? weak : "#{weak}@"
          pw = pw.match?(/\d/) ? pw : "#{pw}1"
          pw = pw.match?(/[A-Z]/) ? pw : "A#{pw}"
          pw = pw.match?(/[a-z]/) ? pw : "#{pw}a"
          user = build(:user, password: pw, password_confirmation: pw)
          expect(user).not_to be_valid
          expect(user.errors[:password]).to include('is too common and easy to guess. Choose a more secure password.')
        end
      end

      it 'does not validate password on update when password is nil' do
        user = create(:user)
        user.password = nil
        user.password_confirmation = nil
        expect(user).to be_valid
      end
    end

    describe 'first_name and last_name' do
      it 'requires first_name' do
        user = build(:user, first_name: nil)
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include("can't be blank")
      end

      it 'requires last_name' do
        user = build(:user, last_name: nil)
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include("can't be blank")
      end

      it 'requires minimum 2 characters' do
        user = build(:user, first_name: 'A', last_name: 'B')
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include('is too short (minimum is 2 characters)')
        expect(user.errors[:last_name]).to include('is too short (minimum is 2 characters)')
      end

      it 'enforces maximum 50 characters' do
        user = build(:user, first_name: 'A' * 51, last_name: 'B' * 51)
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include('is too long (maximum is 50 characters)')
        expect(user.errors[:last_name]).to include('is too long (maximum is 50 characters)')
      end

      it 'validates format - only letters, spaces, hyphens, apostrophes' do
        user = build(:user, first_name: 'John123', last_name: 'Doe!')
        expect(user).not_to be_valid
      end

      it 'accepts valid names with accents and hyphens' do
        user = build(:user, first_name: "Jean-Pierre", last_name: "O'Brien")
        expect(user).to be_valid
      end
    end

    describe 'password_not_similar_to_user_info' do
      it 'rejects password containing first name' do
        user = build(:user, first_name: 'Jonathan', password: 'Jonathan1@', password_confirmation: 'Jonathan1@')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must not contain personal information such as name or email')
      end

      it 'rejects password containing last name' do
        user = build(:user, last_name: 'Williams', password: 'Williams1@', password_confirmation: 'Williams1@')
        expect(user).not_to be_valid
      end

      it 'rejects password containing email local part' do
        user = build(:user, email: 'myname@example.com', password: 'Myname123@', password_confirmation: 'Myname123@')
        expect(user).not_to be_valid
      end

      it 'skips check for short user info (< 3 chars)' do
        user = build(:user, first_name: 'Al', password: 'AlsonGood1@', password_confirmation: 'AlsonGood1@')
        expect(user).to be_valid
      end
    end
  end

  # ---- Associations ----

  describe 'associations' do
    it { should have_many(:user_roles).dependent(:destroy) }
    it { should have_many(:roles).through(:user_roles) }
    it { should have_many(:permissions).through(:roles) }
    it { should have_many(:password_reset_tokens).dependent(:destroy) }
  end

  # ---- Callbacks ----

  describe 'callbacks' do
    describe 'normalize_email' do
      it 'downcases and strips email before validation' do
        user = create(:user, email: '  UPPER@Example.COM  ')
        expect(user.email).to eq('upper@example.com')
      end
    end

    describe 'assign_default_role' do
      it 'assigns the default user role after creation' do
        user = create(:user)
        expect(user.role_names).to include('user')
      end

      it 'does not override existing roles' do
        admin = create(:user, :admin)
        expect(admin.role_names).to include('admin')
      end
    end

    describe 'sanitize_user_inputs' do
      it 'removes HTML tags from first_name and last_name' do
        user = create(:user, first_name: '<script>alert(1)</script>John', last_name: 'Doe<b>')
        expect(user.first_name).not_to include('<')
        expect(user.last_name).not_to include('<')
      end
    end
  end

  # ---- RBAC Methods ----

  describe 'RBAC methods' do
    let(:user) { create(:user) }
    let(:admin) { create(:user, :admin) }

    describe '#has_role?' do
      it 'returns true when user has the role' do
        expect(admin.has_role?('admin')).to be true
      end

      it 'returns false when user does not have the role' do
        expect(user.has_role?('admin')).to be false
      end

      it 'returns false for unpersisted user' do
        new_user = build(:user)
        expect(new_user.has_role?('user')).to be false
      end
    end

    describe '#has_permission?' do
      it 'returns false for unpersisted user' do
        new_user = build(:user)
        expect(new_user.has_permission?('users', 'read')).to be false
      end

      it 'returns false when user lacks the permission' do
        expect(user.has_permission?('admin', 'manage')).to be false
      end
    end

    describe '#admin?' do
      it 'returns true for admin users' do
        expect(admin.admin?).to be true
      end

      it 'returns false for regular users' do
        expect(user.admin?).to be false
      end
    end

    describe '#user?' do
      it 'returns true for users with user role' do
        expect(user.user?).to be true
      end
    end

    describe '#primary_role' do
      it 'returns admin for admin users' do
        expect(admin.primary_role).to eq('admin')
      end

      it 'returns user for regular users' do
        expect(user.primary_role).to eq('user')
      end

      it 'returns first role name or user when no roles match' do
        user_without_roles = create(:user, :without_roles)
        expect(user_without_roles.primary_role).to eq('user')
      end
    end

    describe '#role_names' do
      it 'returns an array of role names' do
        expect(user.role_names).to include('user')
        expect(admin.role_names).to include('admin', 'user')
      end
    end
  end

  # ---- Authentication ----

  describe '#track_login!' do
    it 'updates last_login_at' do
      user = create(:user)
      expect { user.track_login! }.to change { user.reload.last_login_at }.from(nil)
    end
  end

  describe '#can_update_profile?' do
    it 'returns true for admin users' do
      admin = create(:user, :admin)
      expect(admin.can_update_profile?).to be true
    end

    it 'returns true when profile_updated_at is nil' do
      user = create(:user)
      expect(user.can_update_profile?).to be true
    end

    it 'returns true when profile was updated more than 7 days ago' do
      user = create(:user, profile_updated_at: 8.days.ago)
      expect(user.can_update_profile?).to be true
    end

    it 'returns false when profile was updated recently' do
      user = create(:user, profile_updated_at: 1.day.ago)
      expect(user.can_update_profile?).to be false
    end
  end

  describe '#track_profile_update!' do
    it 'updates profile_updated_at without triggering callbacks' do
      user = create(:user)
      expect { user.track_profile_update! }.to change { user.reload.profile_updated_at }.from(nil)
    end
  end

  # ---- Class Methods ----

  describe '.find_by_email' do
    it 'finds user by case-insensitive email' do
      user = create(:user, email: 'findme@example.com')
      expect(User.find_by_email('FINDME@EXAMPLE.COM')).to eq(user)
    end

    it 'strips whitespace' do
      user = create(:user, email: 'stripped@example.com')
      expect(User.find_by_email('  stripped@example.com  ')).to eq(user)
    end
  end
end
