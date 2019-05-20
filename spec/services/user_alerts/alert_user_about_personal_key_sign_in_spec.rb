require 'rails_helper'

describe UserAlerts::AlertUserAboutPersonalKeySignIn do
  describe '#call' do
    it 'sends sms and emails to confirmed addresses' do
      user = create(:user)
      disavowal_token = 'asdf1234'
      confirmed_email_addresses = create_list(:email_address, 2, user: user)
      create(:email_address, user: user, confirmed_at: nil)
      phone_configurations = [
        create(:phone_configuration, user: user, phone: '(202) 111-1111'),
        create(:phone_configuration, user: user, phone: '(202) 222-2222'),
      ]

      allow(UserMailer).to receive(:personal_key_sign_in).and_call_original
      allow(SmsPersonalKeySignInNotifierJob).to receive(:perform_now)

      described_class.call(user, disavowal_token)

      expect(UserMailer).to have_received(:personal_key_sign_in).exactly(3).times
      expect(UserMailer).to have_received(:personal_key_sign_in).
        with(confirmed_email_addresses[0].email, disavowal_token: disavowal_token)
      expect(UserMailer).to have_received(:personal_key_sign_in).
        with(confirmed_email_addresses[1].email, disavowal_token: disavowal_token)
      expect(SmsPersonalKeySignInNotifierJob).to have_received(:perform_now).
        with(phone: phone_configurations[0].phone)
      expect(SmsPersonalKeySignInNotifierJob).to have_received(:perform_now).
        with(phone: phone_configurations[1].phone)
    end
  end
end
