# frozen_string_literal: true

RSpec.describe 'Sign In' do
  let(:account) { create(:account) }
  let!(:user) { create(:user, account:, email: 'john.dou@example.com', password: 'strong_password') }

  before do
    ActionMailer::Base.deliveries.clear
    visit new_user_session_path
  end

  context 'when only with email and password' do
    it 'signs in successfully with valid email and password' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'

      expect(page).to have_content('Signed in successfully')
      expect(page).to have_content('Document Templates')
    end

    it "doesn't sign in if the email or password are incorrect" do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'wrong_password'
      click_button 'Sign In'

      expect(page).to have_content('Invalid email or password')
      expect(page).not_to have_content('Document Templates')
    end
  end

  context 'when resetting password' do
    it "shows validation error for blank email on forgot password form" do
      click_link 'Forgot your password?'
      expect(page).to have_css('.auth-card')
      click_forgot_password_submit

      expect(page).to have_content("Email can't be blank")
      expect(page).to have_current_path(new_user_password_path)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'shows a signup hint when email is not registered on forgot password form' do
      click_link 'Forgot your password?'
      expect(page).to have_css('.auth-card')

      fill_in 'Email', with: 'unregistered@example.com'
      click_forgot_password_submit

      expect(page).to have_content('This email is not registered')
      expect(page).to have_content('try signup')
      expect(page).to have_current_path(new_user_password_path)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'resets password and allows signing in with a new password' do
      click_link 'Forgot your password?'
      fill_in 'Email', with: user.email
      click_forgot_password_submit

      expect(page).to have_content('You will receive an email with instructions on how to reset your password in a few minutes')
      expect(page).to have_current_path(new_user_session_path)

      reset_password_email = ActionMailer::Base.deliveries.last
      expect(reset_password_email).to be_present
      expect(reset_password_email.to).to include(user.email)

      reset_password_path = extract_reset_password_path(reset_password_email)
      expect(reset_password_path).to be_present

      # Use local request URI to avoid host mismatch in system tests.
      visit reset_password_path
      fill_in 'user_password', with: 'new_strong_password'
      fill_in 'user_password_confirmation', with: 'new_strong_password'
      click_reset_password_submit

      expect(page).to have_content('Your password has been changed successfully')
      expect(user.reload.valid_password?('new_strong_password')).to be(true)
      expect(user.valid_password?('strong_password')).to be(false)
    end
  end

  context 'when 2FA is required' do
    before do
      user.update(otp_required_for_login: true, otp_secret: User.generate_otp_secret)
    end

    it 'signs in successfully with valid OTP code' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'
      fill_in 'Two-Factor Code from Authenticator App', with: user.current_otp
      click_button 'Sign In'

      expect(page).to have_content('Signed in successfully')
      expect(page).to have_content('Document Templates')
    end

    it 'fails to sign in with invalid OTP code' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'
      fill_in 'Two-Factor Code from Authenticator App', with: '123456'
      click_button 'Sign In'

      expect(page).to have_content('Invalid email or password')
      expect(page).not_to have_content('Document Templates')
    end
  end

  context 'when signing in with Google' do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: 'google-user-1',
        info: {
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          name: "#{user.first_name} #{user.last_name}"
        }
      )
    end

    after do
      OmniAuth.config.mock_auth[:google_oauth2] = nil
      OmniAuth.config.test_mode = false
    end

    it 'signs in an existing user with google oauth' do
      click_button 'Sign in with Google'

      expect(page).to have_content('Document Templates')
      expect(user.reload.provider).to eq('google_oauth2')
      expect(user.uid).to eq('google-user-1')
    end
  end

  def click_forgot_password_submit
    within("form[action='#{user_password_path}']") do
      find("button[type='submit']").click
    end
  end

  def click_reset_password_submit
    within("form[action='#{user_password_path}']") do
      find("button[type='submit']").click
    end
  end

  def extract_reset_password_path(email)
    doc = Nokogiri::HTML(email.body.encoded)
    reset_password_link = doc.at_css('a')&.[]('href')
    return if reset_password_link.blank?

    URI.parse(CGI.unescapeHTML(reset_password_link)).request_uri
  end
end
