# frozen_string_literal: true

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  around_action :with_browser_locale

  def google_oauth2
    user = User.from_omniauth(request.env['omniauth.auth'])

    if user.persisted? && user.active_for_authentication?
      sign_in(user, event: :authentication)
      redirect_to after_sign_in_path
    else
      alert = user.errors.full_messages.to_sentence.presence || I18n.t("devise.failure.#{user.inactive_message}")
      redirect_to new_user_registration_path(redir: parsed_state['redir']), alert: alert
    end
  end

  def failure
    redirect_to new_user_session_path(redir: parsed_state['redir']),
                alert: I18n.t('devise.omniauth_callbacks.failure', kind: 'Google', reason: params[:message].to_s.humanize)
  end

  private

  def after_sign_in_path
    redir = parsed_state['redir'].to_s

    if redir.starts_with?(Docuseal::CONSOLE_URL)
      console_redirect_index_path(redir:)
    else
      redir.presence || root_path
    end
  end

  def parsed_state
    Rack::Utils.parse_nested_query(params[:state].to_s)
  end
end
