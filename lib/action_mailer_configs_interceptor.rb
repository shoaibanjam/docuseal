# frozen_string_literal: true

module ActionMailerConfigsInterceptor
  ACCOUNT_SMTP_HEADER = 'X-Docuseal-Account-Smtp'

  OPEN_TIMEOUT = ENV.fetch('SMTP_OPEN_TIMEOUT', '15').to_i
  READ_TIMEOUT = ENV.fetch('SMTP_READ_TIMEOUT', '25').to_i

  module_function

  def delivering_email(message)
    return message if Rails.env.test?

    if Docuseal.demo?
      message.delivery_method(:test)

      return message
    end

    account_id = message[ACCOUNT_SMTP_HEADER].to_s.presence&.to_i
    if account_id&.positive?
      begin
        email_configs =
          EncryptedConfig.find_by(account_id:, key: EncryptedConfig::EMAIL_SMTP_KEY)

        if email_configs
          apply_encrypted_smtp!(message, email_configs)

          return message
        end
      ensure
        remove_account_smtp_header(message)
      end
    end

    if Rails.env.production? && Rails.application.config.action_mailer.delivery_method
      from_candidates = ENV['SMTP_FROM'].to_s.split(',').map(&:strip).compact_blank
      from = from_candidates.sample.presence || Array(message.from).first

      if from.present? && from.match?(User::FULL_EMAIL_REGEXP)
        message[:from] = message[:from].to_s.sub(User::EMAIL_REGEXP, from)
      elsif from.present?
        message.from = from
      end

      return message
    end

    unless Docuseal.multitenant?
      email_configs = EncryptedConfig.order(:account_id).find_by(key: EncryptedConfig::EMAIL_SMTP_KEY)

      if email_configs
        apply_encrypted_smtp!(message, email_configs)
      else
        message.delivery_method(:test)
      end
    end

    message
  end

  def remove_account_smtp_header(message)
    message.header[ACCOUNT_SMTP_HEADER] = nil
  rescue StandardError
    message[ACCOUNT_SMTP_HEADER] = nil
  end

  def apply_encrypted_smtp!(message, email_configs)
    value = email_configs.value

    message.delivery_method(:smtp, build_smtp_configs_hash(value))

    message.from = %("#{email_configs.account.name.to_s.delete('"')}" <#{value['from_email']}>)
  rescue ActiveRecord::Encryption::Errors::Decryption, OpenSSL::Cipher::CipherError => e
    # Ciphertext in DB was encrypted with different keys than this process (e.g. Docker env
    # missing or changed ENCRYPTION_SECRET / SECRET_KEY_BASE vs where settings were saved).
    Rails.logger.error(
      '[ActionMailerConfigsInterceptor] SMTP settings exist in the database but could not be ' \
      "decrypted (#{e.class}). Use the same ENCRYPTION_SECRET (or SECRET_KEY_BASE) as when email " \
      'settings were saved, set SMTP_ADDRESS (and related SMTP_* env vars) in production, or ' \
      'clear and re-save Email / SMTP in Settings. Falling back to :test delivery for this message.'
    )

    message.delivery_method(:test)
  end

  def build_smtp_configs_hash(value)

    is_tls = value['security'] == 'tls' || (value['security'].blank? && value['port'].to_s == '465')
    is_ssl = value['security'] == 'ssl'
    is_noverify = value['security'] == 'noverify'

    enable_starttls = is_noverify ? :enable_starttls_auto : :enable_starttls

    {
      user_name: value['username'],
      password: value['password'],
      address: value['host'],
      port: value['port'],
      domain: value['domain'],
      openssl_verify_mode: is_noverify ? OpenSSL::SSL::VERIFY_NONE : nil,
      authentication: value['password'].present? ? value.fetch('authentication', 'plain') : nil,
      enable_starttls => !is_tls && !is_ssl,
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT,
      ssl: is_ssl,
      tls: is_tls
    }.compact_blank
  end
end
