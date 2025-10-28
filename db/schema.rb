# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 20_251_028_155_216) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'

  create_table 'audit_logs', force: :cascade do |t|
    t.bigint 'user_id'
    t.string 'action', null: false, comment: 'login, logout, register, etc'
    t.string 'resource', null: false, comment: 'User, Token, etc'
    t.string 'resource_id'
    t.json 'metadata', comment: 'IP, user_agent, changes, request_id'
    t.string 'result', null: false, comment: 'success, failure, blocked'
    t.datetime 'created_at', null: false
    t.index %w[action created_at], name: 'index_audit_logs_on_action_and_created_at'
    t.index %w[resource resource_id], name: 'index_audit_logs_on_resource_and_resource_id'
    t.index %w[result created_at], name: 'index_audit_logs_on_result_and_created_at'
    t.index %w[user_id created_at], name: 'index_audit_logs_on_user_id_and_created_at'
    t.index ['user_id'], name: 'index_audit_logs_on_user_id'
    t.check_constraint 'action IS NOT NULL', name: 'audit_action_not_null'
    t.check_constraint 'resource IS NOT NULL', name: 'audit_resource_not_null'
    t.check_constraint "result::text = ANY (ARRAY['success'::character varying, 'failure'::character varying, 'blocked'::character varying]::text[])",
                       name: 'valid_audit_result'
  end

  create_table 'password_reset_tokens', force: :cascade do |t|
    t.bigint 'user_id', null: false
    t.string 'token_hash', limit: 64, null: false
    t.string 'ip_address', limit: 45
    t.string 'user_agent', limit: 255
    t.datetime 'expires_at', null: false
    t.boolean 'used', default: false, null: false
    t.datetime 'used_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['expires_at'], name: 'index_password_reset_tokens_on_expires_at'
    t.index ['token_hash'], name: 'index_password_reset_tokens_on_token_hash', unique: true
    t.index %w[user_id used expires_at], name: 'index_reset_tokens_on_user_status'
    t.index ['user_id'], name: 'index_password_reset_tokens_on_user_id'
  end

  create_table 'permissions', force: :cascade do |t|
    t.string 'resource', null: false
    t.string 'action', null: false
    t.text 'description'
    t.jsonb 'metadata', default: {}
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[resource action], name: 'index_permissions_on_resource_and_action', unique: true
  end

  create_table 'role_permissions', force: :cascade do |t|
    t.bigint 'role_id', null: false
    t.bigint 'permission_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['permission_id'], name: 'index_role_permissions_on_permission_id'
    t.index %w[role_id permission_id], name: 'index_role_permissions_on_role_id_and_permission_id', unique: true
    t.index ['role_id'], name: 'index_role_permissions_on_role_id'
  end

  create_table 'roles', force: :cascade do |t|
    t.string 'name', null: false
    t.text 'description'
    t.boolean 'system_role', default: false
    t.jsonb 'metadata', default: {}
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['name'], name: 'index_roles_on_name', unique: true
  end

  create_table 'token_blacklists', force: :cascade do |t|
    t.string 'jti', null: false
    t.datetime 'expires_at', null: false
    t.bigint 'user_id'
    t.string 'reason'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['expires_at'], name: 'index_token_blacklists_on_expires_at'
    t.index ['jti'], name: 'index_token_blacklists_on_jti', unique: true
    t.index ['user_id'], name: 'index_token_blacklists_on_user_id'
  end

  create_table 'user_roles', force: :cascade do |t|
    t.bigint 'user_id', null: false
    t.bigint 'role_id', null: false
    t.datetime 'granted_at', default: -> { 'CURRENT_TIMESTAMP' }
    t.bigint 'granted_by_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['granted_by_id'], name: 'index_user_roles_on_granted_by_id'
    t.index ['role_id'], name: 'index_user_roles_on_role_id'
    t.index %w[user_id role_id], name: 'index_user_roles_on_user_id_and_role_id', unique: true
    t.index ['user_id'], name: 'index_user_roles_on_user_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email'
    t.string 'password_digest'
    t.string 'first_name'
    t.string 'last_name'
    t.string 'role'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.datetime 'last_login_at'
    t.integer 'password_reset_attempts', default: 0, null: false
    t.datetime 'last_password_reset_at'
    t.datetime 'password_reset_locked_until'
    t.datetime 'tokens_valid_after'
    t.datetime 'profile_updated_at'
    t.index ['created_at'], name: 'index_users_on_created_at'
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['last_login_at'], name: 'index_users_on_last_login_at'
    t.index ['password_reset_locked_until'], name: 'index_users_on_password_reset_locked_until'
    t.index ['profile_updated_at'], name: 'index_users_on_profile_updated_at'
    t.index ['role'], name: 'index_users_on_role'
  end

  add_foreign_key 'audit_logs', 'users', on_delete: :nullify
  add_foreign_key 'password_reset_tokens', 'users'
  add_foreign_key 'role_permissions', 'permissions'
  add_foreign_key 'role_permissions', 'roles'
  add_foreign_key 'token_blacklists', 'users'
  add_foreign_key 'user_roles', 'roles'
  add_foreign_key 'user_roles', 'users'
  add_foreign_key 'user_roles', 'users', column: 'granted_by_id'
end
