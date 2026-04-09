# frozen_string_literal: true

describe 'SubmissionsDownloadController' do
  let(:account) { create(:account, :with_testing_account) }
  let(:author) { create(:user, account:) }
  let(:template) { create(:template, account:, author:, submitter_count: 2, only_field_types: %w[text]) }
  let(:submission) { create(:submission, :with_submitters, template:, created_by_user: author) }
  let(:first_submitter) { submission.submitters.order(:id).first }
  let(:second_submitter) { submission.submitters.order(:id).second }

  before do
    first_submitter.update!(completed_at: 2.minutes.ago)
    second_submitter.update!(completed_at: 1.minute.ago)

    allow(Submissions::EnsureResultGenerated).to receive(:call)
    allow(ActiveStorage::Blob).to receive(:proxy_url).and_return('/file/generated.pdf')
  end

  describe 'GET /submitters/:slug/download' do
    it 'returns admin documents with all fields and no redactions for authenticated admin downloads' do
      sign_in(author)

      admin_attachment = instance_double(ActiveStorage::Attachment, blob: instance_double(ActiveStorage::Blob))

      allow(Submissions::GenerateResultAttachments).to receive(:call)
      allow(Submitters).to receive(:select_admin_attachments_for_download).and_return([admin_attachment])

      get "/submitters/#{first_submitter.slug}/download"

      expect(response).to have_http_status(:ok)
      expect(Submissions::GenerateResultAttachments).to have_received(:call).with(
        second_submitter,
        for_admin: true,
        apply_redactions: false
      )
      expect(Submitters).to have_received(:select_admin_attachments_for_download).with(second_submitter)
      expect(response.parsed_body).to eq(['/file/generated.pdf'])
    end

    it 'rejects combined download for signer links' do
      sig = first_submitter.signed_id(expires_in: 40.minutes, purpose: :download_completed)

      get "/submitters/#{first_submitter.slug}/download", params: { sig:, combined: 'true' }

      expect(response).to have_http_status(:not_found)
    end

    it 'keeps signer links scoped to the signer attachments' do
      sig = first_submitter.signed_id(expires_in: 40.minutes, purpose: :download_completed)
      signer_attachment = instance_double(ActiveStorage::Attachment, blob: instance_double(ActiveStorage::Blob))

      allow(Submissions::GenerateResultAttachments).to receive(:call)
      allow(Submitters).to receive(:select_attachments_for_download).and_return([signer_attachment])
      allow(first_submitter.documents).to receive(:preload).and_return([signer_attachment])

      get "/submitters/#{first_submitter.slug}/download", params: { sig: }

      expect(response).to have_http_status(:ok)
      expect(Submissions::GenerateResultAttachments).not_to have_received(:call)
      expect(Submitters).not_to have_received(:select_attachments_for_download)
      expect(response.parsed_body).to eq(['/file/generated.pdf'])
    end
  end
end
