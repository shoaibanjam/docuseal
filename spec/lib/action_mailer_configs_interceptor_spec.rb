# frozen_string_literal: true

RSpec.describe ActionMailerConfigsInterceptor do
  describe '.delivering_email' do
    let(:account_a) { create(:account, name: 'Alpha Inc') }
    let(:account_b) { create(:account, name: 'Beta Co') }

    let!(:smtp_a) do
      create(:encrypted_config, account: account_a, key: EncryptedConfig::EMAIL_SMTP_KEY, value: {
               'host' => 'smtp.alpha.test',
               'port' => '587',
               'username' => 'ua',
               'password' => 'pa',
               'domain' => 'alpha.test',
               'authentication' => 'plain',
               'security' => 'tls',
               'from_email' => 'sign@alpha.test'
             })
    end

    let!(:smtp_b) do
      create(:encrypted_config, account: account_b, key: EncryptedConfig::EMAIL_SMTP_KEY, value: {
               'host' => 'smtp.beta.test',
               'port' => '465',
               'username' => 'ub',
               'password' => 'pb',
               'domain' => 'beta.test',
               'authentication' => 'plain',
               'security' => 'ssl',
               'from_email' => 'sign@beta.test'
             })
    end

    def message_with_account(account_id)
      Mail.new(from: 'App <app@app.test>', to: 'x@test', subject: 's', body: 'b').tap do |m|
        m[described_class::ACCOUNT_SMTP_HEADER] = account_id.to_s
      end
    end

    before do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Docuseal).to receive(:demo?).and_return(false)
      allow(Docuseal).to receive(:multitenant?).and_return(false)
      allow(Rails.application.config.action_mailer).to receive(:delivery_method).and_return(nil)
    end

    it 'uses EncryptedConfig for the account in the routing header' do
      msg = message_with_account(account_b.id)
      described_class.delivering_email(msg)

      expect(msg.delivery_method).to be_a(Mail::SMTP)
      smtp_settings = msg.delivery_method.settings
      expect(smtp_settings[:address]).to eq('smtp.beta.test')
      expect(msg.from).to include('sign@beta.test')
      expect(msg[described_class::ACCOUNT_SMTP_HEADER]).to be_blank
    end

    it 'selects a different row when the header matches another account' do
      msg = message_with_account(account_a.id)
      described_class.delivering_email(msg)

      expect(msg.delivery_method.settings[:address]).to eq('smtp.alpha.test')
      expect(msg.from).to include('sign@alpha.test')
    end
  end
end
