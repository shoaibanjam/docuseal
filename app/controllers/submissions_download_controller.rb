# frozen_string_literal: true

class SubmissionsDownloadController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def default_url_options
    Docuseal.default_url_options.merge(url_options_for_current_request)
  end

  TTL = 40.minutes
  FILES_TTL = 5.minutes

  def index
    @submitter = Submitter.find_signed(params[:sig], purpose: :download_completed) if params[:sig].present?

    @signature_valid =
      if @submitter&.slug == params[:submitter_slug]
        true
      else
        @submitter = nil
        false
      end

    @submitter ||= Submitter.find_by!(slug: params[:submitter_slug])

    return head :not_found unless @submitter.completed_at?

    Submissions::EnsureResultGenerated.call(@submitter)

    if !@signature_valid && !current_user_submitter?(@submitter)
      return head :not_found unless Submitters::AuthorizedForForm.call(@submitter, current_user, request)

      if @submitter.completed_at < TTL.ago
        Rollbar.info("TTL: #{@submitter.id}") if defined?(Rollbar)

        return head :not_found
      end
    end

    if params[:combined] == 'true'
      return head :not_found if @signature_valid

      respond_with_combined(@submitter)
    else
      render json: build_urls(@submitter, admin_download: admin_download_request?)
    end
  end

  def signed_download_url
    @submitter = Submitter.find_by!(slug: params[:slug])

    return head :not_found unless @submitter.completed_at?

    Submissions::EnsureResultGenerated.call(@submitter)

    return head :not_found if @submitter.completed_at < TTL.ago && !current_user_submitter?(@submitter)

    url = submitter_download_index_url(
      @submitter.slug,
      sig: @submitter.signed_id(expires_in: TTL, purpose: :download_completed)
    )
    render json: { url: url }
  end

  private

  def current_user_submitter?(submitter)
    current_user && current_ability.can?(:read, submitter)
  end

  def build_urls(submitter, admin_download: false)
    filename_format = AccountConfig.find_or_initialize_by(account_id: submitter.account_id,
                                                          key: AccountConfig::DOCUMENT_FILENAME_FORMAT_KEY)&.value

    attachments, filename_submitter =
      if admin_download
        all_completed_submitter = submitter.submission.submitters.where.not(completed_at: nil).order(:completed_at).last || submitter

        # Admin downloads should include all parties' values while excluding redact overlays.
        Submissions::GenerateResultAttachments.call(
          all_completed_submitter,
          for_admin: true,
          apply_redactions: false
        )

        [Submitters.select_admin_attachments_for_download(all_completed_submitter), all_completed_submitter]
      else
        [Submitters.select_attachments_for_download(submitter), submitter]
      end

    attachments.map do |attachment|
      ActiveStorage::Blob.proxy_url(
        attachment.blob,
        expires_at: FILES_TTL.from_now.to_i,
        filename: Submitters.build_document_filename(filename_submitter, attachment.blob, filename_format),
        url_options: url_options_for_current_request
      )
    end
  end

  def admin_download_request?
    !@signature_valid && current_user.present? && current_ability.can?(:read, @submitter.submission)
  end

  def build_combined_url(submitter)
    return if submitter.submission.submitters.exists?(completed_at: nil)
    return if submitter.submission.submitters.order(:completed_at).last != submitter

    attachment = submitter.submission.combined_document_attachment
    attachment ||= Submissions::EnsureCombinedGenerated.call(submitter)

    filename_format = AccountConfig.find_or_initialize_by(account_id: submitter.account_id,
                                                          key: AccountConfig::DOCUMENT_FILENAME_FORMAT_KEY)&.value

    ActiveStorage::Blob.proxy_path(
      attachment.blob,
      expires_at: FILES_TTL.from_now.to_i,
      filename: Submitters.build_document_filename(submitter, attachment.blob, filename_format)
    )
  end
end
