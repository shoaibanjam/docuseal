# frozen_string_literal: true

class EmailSmtpSettingsController < ApplicationController
  before_action :load_encrypted_config
  authorize_resource :encrypted_config, only: :index
  authorize_resource :encrypted_config, parent: false, only: :create

  def index; end

  def create
    configs = email_configs
    replace_undecryptable_smtp_encrypted_config_row! if @smtp_config_had_undecryptable_ciphertext

    if @encrypted_config.update(configs)
      unless Docuseal.multitenant?
        from = smtp_from_email_for_success_mail
        SettingsMailer.smtp_successful_setup(from, account: current_account).deliver_now!
      end

      redirect_to settings_email_index_path, notice: I18n.t('changes_have_been_saved')
    else
      render :index, status: :unprocessable_content
    end
  rescue StandardError => e
    flash[:alert] = e.message

    render :index, status: :unprocessable_content
  end

  private

  def load_encrypted_config
    @smtp_config_had_undecryptable_ciphertext = false
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: EncryptedConfig::EMAIL_SMTP_KEY)

    @email_smtp_form_value = safe_email_smtp_form_value(@encrypted_config)
  end

  def safe_email_smtp_form_value(config)
    return {} unless config.persisted?

    config.value || {}
  rescue ActiveRecord::Encryption::Errors::Decryption, OpenSSL::Cipher::CipherError => e
    @smtp_config_had_undecryptable_ciphertext = true
    Rails.logger.error(
      "[EmailSmtpSettingsController] SMTP EncryptedConfig could not be decrypted for " \
      "account_id=#{config.account_id} (#{e.class}): #{e.message}"
    )
    flash.now[:alert] = I18n.t('email_smtp_settings_could_not_be_decrypted') if flash[:alert].blank?
    {}
  end

  # When ciphertext in DB was written with different keys, ActiveRecord::Encryption still tries to
  # deserialize the old payload during #update. Remove the row with delete_all (no decrypt) and
  # insert a fresh one from the submitted form.
  def replace_undecryptable_smtp_encrypted_config_row!
    return unless @encrypted_config.persisted?

    EncryptedConfig.where(
      account_id: current_account.id,
      key: EncryptedConfig::EMAIL_SMTP_KEY
    ).delete_all

    @encrypted_config = EncryptedConfig.new(
      account: current_account,
      key: EncryptedConfig::EMAIL_SMTP_KEY
    )
    @smtp_config_had_undecryptable_ciphertext = false
  end

  def smtp_from_email_for_success_mail
    raw = email_configs[:value]
    return current_user.email if raw.blank?

    hash = raw.is_a?(ActionController::Parameters) ? raw.to_unsafe_h : raw.to_h
    hash.stringify_keys['from_email'].presence || current_user.email
  end

  def email_configs
    params.require(:encrypted_config).permit(value: {}).tap do |e|
      e[:value] ||= {}
      e[:value].compact_blank!
    end
  end
end
