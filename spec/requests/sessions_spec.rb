# frozen_string_literal: true

describe 'Sessions' do
  let(:user) { create(:user) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  describe 'DELETE /sign_out' do
    it 'sets no-store cache headers for authenticated pages' do
      sign_in(user)

      get templates_path

      expect(response).to have_http_status(:ok)
      expect(response.headers['Cache-Control']).to include('no-store')
      expect(response.headers['Pragma']).to eq('no-cache')
      expect(response.headers['Expires']).to eq('0')
    end

    it 'signs out and blocks protected routes after logout' do
      sign_in(user)

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)

      get templates_path

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be_present
    end

    it 'invalidates the authenticated session even without a CSRF token' do
      sign_in(user)

      expect do
        delete destroy_user_session_path
      end.not_to raise_error

      get templates_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
