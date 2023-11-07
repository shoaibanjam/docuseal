# frozen_string_literal: true

ActiveSupport.on_load(:active_storage_attachment) do
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  has_many_attached :preview_images
  has_many_attached :preview_secured_images
end

ActiveStorage::LogSubscriber.detach_from(:active_storage) if Rails.env.production?

Rails.configuration.to_prepare do
  ActiveStorage::DiskController.after_action do
    response.set_header('Cache-Control', 'public, max-age=31536000') if action_name == 'show'
  end

  ActiveStorage::Blobs::ProxyController.before_action do
    response.set_header('Access-Control-Allow-Origin', '*')
    response.set_header('Access-Control-Allow-Methods', 'GET')
    response.set_header('Access-Control-Allow-Headers', '*')
    response.set_header('Access-Control-Max-Age', '1728000')
  end

  ActiveStorage::Blobs::RedirectController.before_action do
    response.set_header('Access-Control-Allow-Origin', '*')
    response.set_header('Access-Control-Allow-Methods', 'GET')
    response.set_header('Access-Control-Allow-Headers', '*')
    response.set_header('Access-Control-Max-Age', '1728000')
  end

  ActiveStorage::DirectUploadsController.before_action do
    next if current_user
    next if Submitter.find_signed(cookies[:submitter_sid])

    head :forbidden
  end

  LoadActiveStorageConfigs.call
rescue StandardError => e
  Rails.logger.error(e)

  nil
end
