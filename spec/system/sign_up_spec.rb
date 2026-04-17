# frozen_string_literal: true

RSpec.describe 'Sign Up' do
  let!(:account) { create(:account) }
  let!(:existing_user) { create(:user, account:, email: 'admin@example.com', password: 'strong_password') }

  before do
    visit new_user_registration_path
  end

  it 'creates a new isolated account for the new user' do
    fill_in 'First name', with: 'Jane'
    fill_in 'Last name', with: 'Doe'
    fill_in 'Email', with: 'jane.doe@example.com'
    fill_in 'Password', with: 'strong_password'
    fill_in 'Confirm new password', with: 'strong_password'
    within("form[action='#{user_registration_path}']") do
      click_button 'Sign up'
    end

    expect(page).to have_content('Document Templates')

    user = User.find_by(email: 'jane.doe@example.com')

    expect(user).to be_present
    expect(Account.count).to eq(2)
    expect(user.account_id).not_to eq(account.id)
    expect(user.account.name).to eq("Jane Doe's Workspace")
    expect(user.first_name).to eq('Jane')
    expect(user.last_name).to eq('Doe')
  end

  it 'creates a new user account with google oauth' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: 'google-user-2',
      info: {
        email: 'google.user@example.com',
        first_name: 'Google',
        last_name: 'User',
        name: 'Google User'
      }
    )

    click_button 'Sign up with Google'

    expect(page).to have_content('Document Templates')

    user = User.find_by(email: 'google.user@example.com')
    expect(user).to be_present
    expect(user.provider).to eq('google_oauth2')
    expect(user.uid).to eq('google-user-2')
    expect(Account.count).to eq(2)
    expect(user.account.name).to eq("Google User's Workspace")
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end
end
