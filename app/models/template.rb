# frozen_string_literal: true

# == Schema Information
#
# Table name: templates
#
#  id              :bigint           not null, primary key
#  application_key :string
#  deleted_at      :datetime
#  fields          :text             not null
#  name            :string           not null
#  schema          :text             not null
#  slug            :string           not null
#  source          :text             not null
#  submitters      :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  author_id       :bigint           not null
#  folder_id       :bigint           not null
#
# Indexes
#
#  index_templates_on_account_id  (account_id)
#  index_templates_on_author_id   (author_id)
#  index_templates_on_folder_id   (folder_id)
#  index_templates_on_slug        (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (folder_id => template_folders.id)
#
class Template < ApplicationRecord
  DEFAULT_SUBMITTER_NAME = 'First Submitter'

  belongs_to :author, class_name: 'User'
  belongs_to :account
  belongs_to :folder, class_name: 'TemplateFolder'

  before_validation :maybe_set_default_folder, on: :create

  attribute :fields, :string, default: -> { [] }
  attribute :schema, :string, default: -> { [] }
  attribute :submitters, :string, default: -> { [{ name: DEFAULT_SUBMITTER_NAME, uuid: SecureRandom.uuid }] }
  attribute :slug, :string, default: -> { SecureRandom.base58(14) }
  attribute :source, :string, default: 'native'

  serialize :fields, JSON
  serialize :schema, JSON
  serialize :submitters, JSON

  has_many_attached :documents

  has_many :schema_documents, ->(e) { where(uuid: e.schema.pluck('attachment_uuid')) },
           class_name: 'ActiveStorage::Attachment', dependent: :destroy, as: :record, inverse_of: :record

  has_many :submissions, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }
  scope :archived, -> { where.not(deleted_at: nil) }

  after_save :create_secure_images

  def create_secure_images
      documents.each do |doc|
        document_data = doc.blob.download
        Templates::ProcessDocument.generate_pdf_secured_preview_images(self, doc, document_data)
      end
  end

  private

  def maybe_set_default_folder
    self.folder ||= account.default_template_folder
  end
end
