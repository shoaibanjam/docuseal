# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'Trustseal <info@docuseal.com>'
  layout 'mailer'

  register_interceptor ActionMailerConfigsInterceptor
  register_interceptor HtmlToPlainTextInterceptor
  register_preview_interceptor HtmlToPlainTextInterceptor

  register_observer ActionMailerEventsObserver

  before_action do
    ActiveStorage::Current.url_options = Docuseal.default_url_options
  end

  after_action :set_message_metadata
  after_action :set_message_uuid

  def default_url_options
    options = (Current.url_options.presence || Docuseal.default_url_options).dup
    email_host = ENV['EMAIL_HOST'].to_s.strip
    return options if email_host.empty?

    begin
      raw_value = email_host.include?('://') ? email_host : "//#{email_host}"
      uri = Addressable::URI.parse(raw_value)

      options[:host] = uri.host if uri.host.present?
      options[:port] = uri.port if uri.port
      options[:protocol] = uri.scheme if uri.scheme.present?
    rescue StandardError
      options[:host] = email_host
    end

    if (options[:protocol] == 'https' && options[:port] == 443) ||
       (options[:protocol] == 'http' && options[:port] == 80)
      options.delete(:port)
    end

    options
  end

  def set_message_metadata
    message.instance_variable_set(:@message_metadata, @message_metadata || {})
  end

  def set_message_uuid
    message['X-Message-Uuid'] = SecureRandom.uuid
  end

  def assign_message_metadata(tag, record)
    @message_metadata = (@message_metadata || {}).merge(
      'tag' => tag,
      'record_id' => record.id,
      'record_type' => record.class.name
    )
  end

  def put_metadata(attrs)
    @message_metadata = (@message_metadata || {}).merge(attrs)
  end
end
