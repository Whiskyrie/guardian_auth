require 'rails_helper'

RSpec.describe Role, type: :model do
  # ---- Validations ----

  describe 'validations' do
    it 'requires name' do
      role = build(:role, name: nil)
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("can't be blank")
    end

    it 'requires unique name' do
      create(:role, name: 'unique_role')
      duplicate = build(:role, name: 'unique_role')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end

    it 'enforces maximum name length' do
      role = build(:role, name: 'a' * 51)
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include('is too long (maximum is 50 characters)')
    end

    it 'enforces maximum description length' do
      role = build(:role, description: 'a' * 256)
      expect(role).not_to be_valid
      expect(role.errors[:description]).to include('is too long (maximum is 255 characters)')
    end
  end

  # ---- Associations ----

  describe 'associations' do
    it { should have_many(:user_roles).dependent(:destroy) }
    it { should have_many(:users).through(:user_roles) }
    it { should have_many(:permissions).through(:role_permissions) }
    it { should have_many(:role_permissions).dependent(:destroy) }
  end

  # ---- Scopes ----

  describe 'scopes' do
    it '.system returns only system roles' do
      system_role = create(:role, :admin)
      custom_role = create(:role, name: 'custom_role', system_role: false)
      expect(Role.system).to include(system_role)
      expect(Role.system).not_to include(custom_role)
    end

    it '.custom returns only non-system roles' do
      system_role = create(:role, :admin)
      custom_role = create(:role, name: 'custom_role2', system_role: false)
      expect(Role.custom).to include(custom_role)
      expect(Role.custom).not_to include(system_role)
    end
  end

  # ---- System Roles ----

  describe 'system roles' do
    it '.default_user_role returns the user role' do
      user_role = create(:role, :user)
      expect(Role.default_user_role).to eq(user_role)
    end

    it '.admin_role returns the admin role' do
      admin_role = create(:role, :admin)
      expect(Role.admin_role).to eq(admin_role)
    end
  end

  # ---- Instance Methods ----

  describe '#system_role?' do
    it 'returns true for system roles' do
      role = create(:role, :admin)
      expect(role.system_role?).to be true
    end

    it 'returns false for custom roles' do
      role = create(:role, name: 'custom', system_role: false)
      expect(role.system_role?).to be false
    end
  end

  describe '#permission_names' do
    it 'returns an array of permission strings' do
      role = create(:role, name: 'perms_test')
      perm = create(:permission, resource: 'users', action: 'read')
      role.role_permissions.create!(permission: perm)
      expect(role.permission_names).to include('users:read')
    end
  end

  describe '#has_permission?' do
    it 'returns true when the role has the permission' do
      role = create(:role, name: 'has_perm_test')
      perm = create(:permission, resource: 'users', action: 'update')
      role.role_permissions.create!(permission: perm)
      expect(role.has_permission?('users', 'update')).to be true
    end

    it 'returns false when the role lacks the permission' do
      role = create(:role, name: 'no_perm_test')
      expect(role.has_permission?('users', 'delete')).to be false
    end
  end

  describe '#to_s' do
    it 'returns the role name' do
      role = build(:role, name: 'editor')
      expect(role.to_s).to eq('editor')
    end
  end
end
