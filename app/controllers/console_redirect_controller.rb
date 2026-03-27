# frozen_string_literal: true

class ConsoleRedirectController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def index
    if request.path == '/upgrade'
      params[:redir] = Docuseal.multitenant? ? "#{Docuseal::CONSOLE_URL}/plans" : "#{Docuseal::CONSOLE_URL}/on_premises"
    end

    params[:redir] = "#{Docuseal::CONSOLE_URL}/manage" if request.path == '/manage'

    if request.path == '/sign_up'
      params[:redir] = Docuseal.multitenant? ? "#{Docuseal::CONSOLE_URL}/plans" : "#{Docuseal::CONSOLE_URL}/on_premises"
    end

    if (url = development_console_redirect_url(params[:redir].to_s))
      return redirect_to url, allow_other_host: true
    end

    return redirect_to(new_user_session_path({ redir: params[:redir] }.compact)) if true_user.blank?

    auth = JsonWebToken.encode(uuid: true_user.uuid,
                               scope: :console,
                               exp: 1.minute.from_now.to_i)

    redir_uri = Addressable::URI.parse(params[:redir])
    path = redir_uri.path if params[:redir].to_s.starts_with?(Docuseal::CONSOLE_URL)

    query_values = redir_uri&.query_values || {}
    # Console auth handoff endpoint intermittently returns 500 for on-premises pages.
    # In self-hosted mode, redirect directly and let Console use existing session.
    if !Docuseal.multitenant? && path.to_s.starts_with?('/on_premises')
      return redirect_to "#{Docuseal::CONSOLE_URL}#{path}?#{{ **query_values }.to_query}",
                         allow_other_host: true
    end

    redirect_to "#{Docuseal::CONSOLE_URL}#{path}?#{{ **query_values, 'auth' => auth }.to_query}",
                allow_other_host: true
  end

  private

  def development_console_redirect_url(redir)
    return unless Rails.env.development?
    return if Docuseal.multitenant?
    return unless Docuseal::CONSOLE_URL.include?('localhost')

    return 'https://console.docuseal.com/on_premises' if redir.include?('/on_premises')
    return 'https://console.docuseal.com/plans' if redir.include?('/plans')
    return 'https://console.docuseal.com/api' if redir.include?('/api')

    nil
  end
end
