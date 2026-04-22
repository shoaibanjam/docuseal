# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  around_action :with_browser_locale

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
    elsif already_confirmed_error?(resource)
      flash[:notice] = I18n.t('devise.confirmations.already_confirmed')
      redirect_to new_user_session_path(
        { user: { email: resource.email.presence } }.compact_blank.merge(redir: params[:redir], lang: params[:lang]).compact_blank
      )
    else
      respond_with_navigational(resource.errors, status: :unprocessable_content) { render :new }
    end
  end

  def create
    email = params.dig(resource_name, :email).to_s.downcase
    user = resource_class.find_by(email:)

    if user.blank?
      flash[:notice] = I18n.t(
        'devise.confirmations.send_instructions'
      )
      return redirect_to new_user_session_path(redir: params[:redir], lang: params[:lang])
    end

    if user.confirmed?
      flash[:notice] = I18n.t(
        'devise.confirmations.already_confirmed'
      )
      return redirect_to new_user_session_path(user: { email: email }, redir: params[:redir], lang: params[:lang])
    end

    resend_result = user.resend_confirmation_with_limit!

    if resend_result[:status] == :sent_expired
      flash[:notice] = I18n.t(
        'confirmation_link_expired_resend_automatically',
        default: 'Your previous confirmation link expired. We sent a new confirmation email.'
      )
    elsif resend_result[:status] == :sent
      flash[:notice] = I18n.t(
        'confirmation_link_resent_with_limit',
        default: "Confirmation email sent. You can resend %{remaining_count} more time(s) in this 10-minute window.",
        remaining_count: resend_result[:remaining_count]
      )
    else
      flash[:alert] = I18n.t(
        'confirmation_resend_limit_reached',
        default: 'You can resend confirmation at most 2 times every 10 minutes. Please wait a bit and try again.'
      )
    end

    redirect_to new_user_session_path(user: { email: email }, redir: params[:redir], lang: params[:lang])
  end

  private

  def already_confirmed_error?(resource)
    resource.errors.details.fetch(:email, []).any? { |error| error[:error] == :already_confirmed }
  end
end
