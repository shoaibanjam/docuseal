# frozen_string_literal: true

module Submissions
  module EnsureCombinedGenerated
    WAIT_FOR_RETRY = 2.seconds
    CHECK_EVENT_INTERVAL = 1.second
    CHECK_COMPLETE_TIMEOUT = 90.seconds
    KEY_PREFIX = 'combined_document'

    WaitForCompleteTimeout = Class.new(StandardError)
    NotCompletedYet = Class.new(StandardError)

    module_function

    def redaction_logic_version_matches?(submission)
      current_version = Submissions::GenerateResultAttachments::REDACTION_LOGIC_VERSION
      attachment = submission.combined_document_attachment
      return false unless attachment

      version =
        attachment.metadata&.[]('redaction_logic_version') || attachment.metadata&.[](:redaction_logic_version)

      version == current_version
    end

    def call(submitter)
      return nil unless submitter

      raise NotCompletedYet unless submitter.completed_at?

      total_wait_time ||= 0
      key = [KEY_PREFIX, submitter.id].join(':')

      if ApplicationRecord.uncached { LockEvent.exists?(key:, event_name: :complete) }
        return submitter.submission.combined_document_attachment if redaction_logic_version_matches?(submitter.submission)

        submitter.submission.combined_document_attachment&.purge
      end

      events = ApplicationRecord.uncached { LockEvent.where(key:).order(:id).to_a }

      if events.present? && events.last.event_name.in?(%w[start retry])
        wait_for_complete_or_fail(submitter)
      else
        LockEvent.create!(key:, event_name: events.present? ? :retry : :start)

        result = Submissions::GenerateCombinedAttachment.call(submitter)

        LockEvent.create!(key:, event_name: :complete)

        result
      end
    rescue ActiveRecord::RecordNotUnique
      sleep WAIT_FOR_RETRY
      total_wait_time += WAIT_FOR_RETRY

      total_wait_time > CHECK_COMPLETE_TIMEOUT ? raise : retry
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
      Rails.logger.error(e)

      LockEvent.create!(key:, event_name: :fail)

      raise
    end

    def wait_for_complete_or_fail(submitter)
      total_wait_time = 0

      loop do
        sleep CHECK_EVENT_INTERVAL
        total_wait_time += CHECK_EVENT_INTERVAL

        last_event =
          ApplicationRecord.uncached do
            LockEvent.where(key: [KEY_PREFIX, submitter.id].join(':')).order(:id).last
          end

        if last_event.event_name.in?(%w[complete fail])
          return ApplicationRecord.uncached do
            if last_event.event_name == 'complete' && !redaction_logic_version_matches?(submitter.submission)
              submitter.submission.combined_document_attachment&.purge
              result = Submissions::GenerateCombinedAttachment.call(submitter)
              result
            else
              ActiveStorage::Attachment.find_by(record: submitter.submission, name: 'combined_document')
            end
          end
        end

        raise WaitForCompleteTimeout if total_wait_time > CHECK_COMPLETE_TIMEOUT
      end
    end
  end
end
