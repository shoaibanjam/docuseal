# frozen_string_literal: true

RSpec.describe ProcessSubmitterCompletionJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:submission) { create(:submission, template:, created_by_user: user) }
  let(:submitter) { create(:submitter, submission:, uuid: SecureRandom.uuid, completed_at: Time.current) }

  before do
    create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                              value: GenerateCertificate.call.transform_values(&:to_pem))
  end

  describe '#perform' do
    it 'creates a completed submitter' do
      expect do
        described_class.new.perform('submitter_id' => submitter.id)
      end.to change(CompletedSubmitter, :count).by(1)

      completed_submitter = CompletedSubmitter.last
      submitter.reload

      expect(completed_submitter.submitter_id).to eq(submitter.id)
      expect(completed_submitter.submission_id).to eq(submitter.submission_id)
      expect(completed_submitter.account_id).to eq(submitter.submission.account_id)
      expect(completed_submitter.template_id).to eq(submitter.submission.template_id)
      expect(completed_submitter.source).to eq(submitter.submission.source)
    end

    it 'creates a completed document' do
      expect do
        described_class.new.perform('submitter_id' => submitter.id)
      end.to change(CompletedDocument, :count).by(1)

      completed_document = CompletedDocument.last

      expect(completed_document.submitter_id).to eq(submitter.id)
      expect(completed_document.sha256).to be_present
      expect(completed_document.sha256).to eq(submitter.documents.first.metadata['sha256'])
    end

    it 'raises an error if the submitter is not found' do
      expect do
        described_class.new.perform('submitter_id' => 'invalid_id')
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'sends submitter copy emails using each recipient submitter context' do
      template = create(:template, account:, author: user, submitter_count: 2, only_field_types: %w[text])
      submission = create(:submission, :with_submitters, template:, created_by_user: user)
      first_submitter = submission.submitters.order(:id).first
      second_submitter = submission.submitters.order(:id).second
      first_submitter.update!(completed_at: 2.minutes.ago)
      second_submitter.update!(completed_at: 1.minute.ago)

      email_delivery = instance_double(ActionMailer::MessageDelivery, deliver_later!: true)

      allow(SubmitterMailer).to receive(:documents_copy_email).and_return(email_delivery)

      described_class.new.perform('submitter_id' => second_submitter.id)

      expect(SubmitterMailer).to have_received(:documents_copy_email).with(
        first_submitter,
        to: first_submitter.friendly_name
      )
      expect(SubmitterMailer).to have_received(:documents_copy_email).with(
        second_submitter,
        to: second_submitter.friendly_name
      )
    end
  end
end
