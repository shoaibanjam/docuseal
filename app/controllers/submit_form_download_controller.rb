# frozen_string_literal: true

class SubmitFormDownloadController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  FILES_TTL = 5.minutes

  def index
    @submitter = Submitter.find_by!(slug: params[:submit_form_slug])

    if @submitter.completed_at?
      return redirect_to submitter_download_index_path(@submitter.slug,
                                                       sig: @submitter.signed_id(expires_in: 40.minutes,
                                                                                 purpose: :download_completed))
    end

    return head :unprocessable_content if @submitter.declined_at? ||
                                          @submitter.submission.archived_at? ||
                                          @submitter.submission.expired? ||
                                          @submitter.submission.template&.archived_at? ||
                                          AccountConfig.exists?(account_id: @submitter.account_id,
                                                                key: AccountConfig::ALLOW_TO_PARTIAL_DOWNLOAD_KEY,
                                                                value: false) ||
                                          !Submitters::AuthorizedForForm.call(@submitter, current_user, request)

    # Always generate files from the active submitter state for in-progress links.
    # This prevents exposing completed files from other submitters.
    submission = @submitter.submission

    fields = submission.template_fields || submission.template.fields

    fields.each do |field|
      next unless field['submitter_uuid'] == @submitter.uuid
      next unless field['type'] == 'stamp'

      next if @submitter.values[field['uuid']].present?

      attachment =
        Submitters::CreateStampAttachment.call(
          @submitter,
          with_logo: field.dig('preferences', 'with_logo') != false
        )

      @submitter.values[field['uuid']] = attachment.uuid
    end

    @submitter.save! if @submitter.changed?

    Submissions::GeneratePreviewAttachments.call(submission, submitter: @submitter)

    attachments = @submitter.preview_documents.preload(:blob)

    urls = attachments.map do |attachment|
      ActiveStorage::Blob.proxy_path(attachment.blob, expires_at: FILES_TTL.from_now.to_i)
    end

    render json: urls
  end
end
