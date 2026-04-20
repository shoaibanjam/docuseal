# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  around_action :with_browser_locale

  before_action :configure_permitted_parameters

  def new
    super

    resource.email ||= params.dig(:user, :email).to_s.downcase.presence
  end

  def create
    account = build_registration_account
    build_resource(sign_up_params.merge(account: account))
    resource.email = resource.email.to_s.downcase

    ActiveRecord::Base.transaction do
      account.save!
      resource.save!
    end

    if resource.persisted?
      yield resource if block_given?

      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        redirect_to after_sign_up_path_for(resource), status: :see_other
      else
        set_flash_message! :notice, :signed_up_but_unconfirmed, email: resource.email
        expire_data_after_sign_in!
        redirect_to after_inactive_sign_up_path_for(resource), status: :see_other
      end
    end
  rescue ActiveRecord::RecordInvalid
    clean_up_passwords(resource)
    set_minimum_password_length
    render :new, status: :unprocessable_content
  end

  protected

  def after_sign_up_path_for(resource)
    return root_path if resource.active_for_authentication?

    after_inactive_sign_up_path_for(resource)
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
  end

  def build_registration_account
    Account.new(name: registration_account_name)
  end

  def registration_account_name
    User.registration_account_name(sign_up_params[:first_name], sign_up_params[:last_name], sign_up_params[:email])
  end
end
