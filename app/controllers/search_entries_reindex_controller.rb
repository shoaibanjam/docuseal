# frozen_string_literal: true

class SearchEntriesReindexController < ApplicationController
  def create
    authorize!(:manage, EncryptedConfig)

    ReindexAllSearchEntriesJob.perform_async

    AccountConfig.find_or_initialize_by(account_id: Account.minimum(:id), key: :fulltext_search)
                 .update!(value: true)

    Docuseal.instance_variable_set(:@fulltext_search, nil)

    redirect_back(
      fallback_location: settings_account_path,
      notice: I18n.t('search_index_build_started', jobs_url: "#{root_url}jobs/busy")
    )
  end
end
