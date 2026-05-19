# frozen_string_literal: true

class LocalesController < ApplicationController
  SUPPORTED_SWITCHER_LOCALES = %w[en-US ar].freeze

  skip_authorization_check
  skip_before_action :authenticate_user!
  skip_before_action :maybe_redirect_to_setup

  def update
    locale = params[:locale].to_s
    locale = 'en-US' unless SUPPORTED_SWITCHER_LOCALES.include?(locale) && I18n.locale_available?(locale)

    if current_account
      current_account.update!(locale:)
    else
      cookies.permanent[:locale] = { value: locale, same_site: :lax }
    end

    redirect_back fallback_location: root_path, status: :see_other
  end
end
