# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  around_action :with_browser_locale
end
