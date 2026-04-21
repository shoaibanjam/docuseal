# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  before_action :configure_permitted_parameters
  skip_before_action :verify_authenticity_token, only: :destroy

  around_action :with_browser_locale

  def new
    prepare_resend_option_from_unconfirmed_alert
    super
  end

  def create
    email = sign_in_params[:email].to_s.downcase

    user = User.find_by(email:)
    session[:pending_confirmation_email] = email if user.present? && !user.confirmed?

    if handle_unconfirmed_sign_in(user, email)
      return
    end

    if Docuseal.multitenant? && !User.exists?(email:)
      Rollbar.warning('Sign in new user') if defined?(Rollbar)

      return redirect_to new_registration_path(sign_up: true, user: sign_in_params.slice(:email)),
                         notice: I18n.t('create_a_new_account')
    end

    if User.exists?(email:, otp_required_for_login: true) && sign_in_params[:otp_attempt].blank?
      return render :otp, locals: { resource: User.new(sign_in_params) }, status: :unprocessable_content
    end

    super
  end

  def destroy
    signed_out =
      if Devise.sign_out_all_scopes
        sign_out
      else
        sign_out(resource_name)
      end

    # Ensure the underlying Rails session is fully rotated after logout.
    reset_session
    set_flash_message!(:notice, :signed_out) if signed_out

    redirect_to after_sign_out_path_for(resource_name), status: :see_other
  end

  private

  def prepare_resend_option_from_unconfirmed_alert
    return if @show_confirmation_resend_option
    email = params.dig(:user, :email).to_s.downcase
    email = session[:pending_confirmation_email].to_s.downcase if email.blank?
    should_show_from_failure = session.delete(:show_confirmation_resend)
    should_show_from_alert = flash[:alert].to_s.include?(I18n.t('devise.failure.unconfirmed'))
    should_show = should_show_from_failure || should_show_from_alert
    return unless should_show

    if email.present?
      user = User.find_by(email:)
      return if user.blank? || user.confirmed?
    end

    @show_confirmation_resend_option = true
    @confirmation_resend_email = email
    session.delete(:pending_confirmation_email) if email.present?
  end

  def handle_unconfirmed_sign_in(user, email)
    return false unless user.present? && !user.confirmed?
    return false unless user.valid_password?(sign_in_params[:password].to_s)

    if user.confirmation_link_expired?
      user.resend_confirmation_with_limit!

      redirect_to new_user_session_path(
        user: { email: email },
        redir: params[:redir],
        lang: params[:lang]
      ),
                  notice: I18n.t(
                    'confirmation_link_expired_resend_automatically',
                    default: 'Your previous confirmation link expired. We sent a new confirmation email.'
                  )
    else
      @show_confirmation_resend_option = true
      @confirmation_resend_email = email
      self.resource = resource_class.new(email:)
      clean_up_passwords(resource)

      flash.now[:alert] = I18n.t(
        'account_not_confirmed_resend_available',
        default: 'Your account is not confirmed yet. Check your email or request a new confirmation link.'
      )
      render :new, status: :unprocessable_content
    end

    true
  end

  def after_sign_in_path_for(...)
    if params[:redir].present?
      return console_redirect_index_path(redir: params[:redir]) if params[:redir].starts_with?(Docuseal::CONSOLE_URL)

      return params[:redir]
    end

    super
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  def set_flash_message(key, kind, options = {})
    return if key == :alert && kind == 'already_authenticated'

    super
  end
end
