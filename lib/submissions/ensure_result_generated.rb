# frozen_string_literal: true

module Submissions
  module EnsureResultGenerated
    WAIT_FOR_RETRY = 2.seconds
    CHECK_EVENT_INTERVAL = 1.second
    CHECK_COMPLETE_TIMEOUT = 90.seconds

    WaitForCompleteTimeout = Class.new(StandardError)
    NotCompletedYet = Class.new(StandardError)

    module_function

    def redaction_logic_version_matches?(submitter, apply_redactions:)
      current_version = Submissions::GenerateResultAttachments::REDACTION_LOGIC_VERSION

      return false if submitter.documents.empty?

      submitter.documents.each do |attachment|
        version =
          attachment.metadata&.[]('redaction_logic_version') || attachment.metadata&.[](:redaction_logic_version)

        return false if version != current_version

        stored_apply_redactions =
          attachment.metadata&.[]('apply_redactions') || attachment.metadata&.[](:apply_redactions)

        return false if stored_apply_redactions != apply_redactions
      end

      true
    end

    def call(submitter, apply_redactions: true)
      return [] unless submitter

      raise NotCompletedYet unless submitter.completed_at?

      total_wait_time ||= 0
      key = ['result_attachments', submitter.id, apply_redactions ? 'with_redactions' : 'without_redactions'].join(':')

      if ApplicationRecord.uncached { LockEvent.exists?(key:, event_name: :complete) }
        return submitter.documents.reload if redaction_logic_version_matches?(submitter, apply_redactions:)

        submitter.documents.purge
      end

      events = ApplicationRecord.uncached { LockEvent.where(key:).order(:id).to_a }

      if events.present? && events.last.event_name.in?(%w[start retry])
        wait_for_complete_or_fail(submitter, apply_redactions:)
      else
        LockEvent.create!(key:, event_name: events.present? ? :retry : :start)

        documents = GenerateResultAttachments.call(submitter, apply_redactions:)

        LockEvent.create!(key:, event_name: :complete)

        submitter.documents.reset

        documents
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

    def wait_for_complete_or_fail(submitter, apply_redactions:)
      total_wait_time = 0
      key = ['result_attachments', submitter.id, apply_redactions ? 'with_redactions' : 'without_redactions'].join(':')

      loop do
        sleep CHECK_EVENT_INTERVAL
        total_wait_time += CHECK_EVENT_INTERVAL

        last_event =
          ApplicationRecord.uncached do
            LockEvent.where(key:).order(:id).last
          end

        break submitter.documents.reload if last_event.event_name == 'fail'

        if last_event.event_name == 'complete'
          return submitter.documents.reload if redaction_logic_version_matches?(submitter, apply_redactions:)

          submitter.documents.purge
          documents = GenerateResultAttachments.call(submitter, apply_redactions:)
          submitter.documents.reset
          return documents
        end

        raise WaitForCompleteTimeout if total_wait_time > CHECK_COMPLETE_TIMEOUT
      end
    end
  end
end
