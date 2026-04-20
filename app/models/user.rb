# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  archived_at            :datetime
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  consumed_timestep      :integer
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           not null
#  encrypted_password     :string           not null
#  failed_attempts        :integer          default(0), not null
#  first_name             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  otp_required_for_login :boolean          default(FALSE), not null
#  otp_secret             :string
#  provider               :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           not null
#  sign_in_count          :integer          default(0), not null
#  uid                    :string
#  unconfirmed_email      :string
#  unlock_token           :string
#  uuid                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#
# Indexes
#
#  index_users_on_account_id            (account_id)
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_provider_and_uid      (provider,uid) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_uuid                  (uuid) UNIQUE
#
# Foreign Keys
#
#  account_id  (account_id => accounts.id)
#
class User < ApplicationRecord
  OAUTH_PROVIDER_GOOGLE = 'google_oauth2'

  ROLES = [
    ADMIN_ROLE = 'admin'
  ].freeze

  EMAIL_REGEXP = /[^@;,<>\s]+@[^@;,<>\s]+/

  FULL_EMAIL_REGEXP =
    /\A[a-z0-9][.']?(?:(?:[a-z0-9_-]+[.+'])*[a-z0-9_-]+)*@(?:[a-z0-9]+[.-])*[a-z0-9]+\.[a-z]{2,}\z/i

  has_one_attached :signature
  has_one_attached :initials

  belongs_to :account
  has_one :access_token, dependent: :destroy
  has_many :access_tokens, dependent: :destroy
  has_many :mcp_tokens, dependent: :destroy
  has_many :templates, dependent: :destroy, foreign_key: :author_id, inverse_of: :author
  has_many :template_folders, dependent: :destroy, foreign_key: :author_id, inverse_of: :author
  has_many :user_configs, dependent: :destroy
  has_many :encrypted_configs, dependent: :destroy, class_name: 'EncryptedUserConfig'
  has_many :email_messages, dependent: :destroy, foreign_key: :author_id, inverse_of: :author

  devise :two_factor_authenticatable,
         :registerable,
         :confirmable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable,
         :lockable,
         :omniauthable,
         omniauth_providers: [OAUTH_PROVIDER_GOOGLE.to_sym]

  attribute :role, :string, default: ADMIN_ROLE
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :admins, -> { where(role: ADMIN_ROLE) }

  validates :email, format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\z/ }
  validates :uid, uniqueness: { scope: :provider }, allow_blank: true

  def self.from_omniauth(auth)
    provider = auth.provider.to_s
    uid = auth.uid.to_s
    email = auth.info.email.to_s.downcase

    return User.new.tap { |user| user.errors.add(:email, :blank) } if email.blank?

    user = find_by(provider:, uid:) || find_or_initialize_by(email:)
    return user if user.persisted? && user.provider == provider && user.uid == uid

    user.provider = provider
    user.uid = uid
    user.first_name ||= auth.info.first_name.presence || auth.info.name.to_s.split.first.presence
    user.last_name ||= auth.info.last_name.presence || auth.info.name.to_s.split.drop(1).join(' ').presence
    user.password = Devise.friendly_token.first(32) if user.encrypted_password.blank?

    if user.new_record?
      account = Account.new(name: registration_account_name(user.first_name, user.last_name, email))
      user.account = account
      user.skip_confirmation!

      ActiveRecord::Base.transaction do
        account.save!
        user.save!
      end
    else
      user.save! if user.changed?
    end

    user
  rescue ActiveRecord::RecordInvalid
    user
  end

  def access_token
    token_record = super || build_access_token.tap(&:save!)
    token_record.token
    token_record
  rescue ActiveRecord::Encryption::Errors::Decryption, OpenSSL::Cipher::CipherError
    token_record&.destroy! if token_record&.persisted?
    build_access_token.tap(&:save!)
  end

  def active_for_authentication?
    super && !archived_at? && !account.archived_at?
  end

  def remember_me
    true
  end

  def sidekiq?
    return true if Rails.env.development?

    role == 'admin'
  end

  def self.sign_in_after_reset_password
    if PasswordsController::Current.user.present?
      !PasswordsController::Current.user.otp_required_for_login
    else
      true
    end
  end

  def initials
    [first_name&.first, last_name&.first].compact_blank.join.upcase
  end

  def full_name
    [first_name, last_name].compact_blank.join(' ')
  end

  def friendly_name
    if full_name.present?
      %("#{full_name.delete('"')}" <#{email}>)
    else
      email
    end
  end

  def self.registration_account_name(first_name, last_name, email)
    full_name = [first_name, last_name].compact_blank.join(' ')
    return "#{full_name}'s Workspace" if full_name.present?

    email_prefix = email.to_s.downcase.split('@').first.to_s
    sanitized_prefix = email_prefix.gsub(/[^a-z0-9]+/i, ' ').squish

    return "#{sanitized_prefix.titleize}'s Workspace" if sanitized_prefix.present?

    'Workspace'
  end
end
