require 'rails_helper'

describe RequestPasswordReset do
  describe '#perform' do
    context 'when the user is not found' do
      it 'sends the account registration email' do
        email = 'nonexistent@example.com'

        send_sign_up_email_confirmation = instance_double(SendSignUpEmailConfirmation)
        expect(send_sign_up_email_confirmation).to receive(:call).with(
          hash_including(
            instructions: I18n.t(
              'user_mailer.email_confirmation_instructions.first_sentence.forgot_password',
            ),
          ),
        )
        expect(SendSignUpEmailConfirmation).to receive(:new).and_return(
          send_sign_up_email_confirmation,
        )

        RequestPasswordReset.new(email).perform
        expect(User.find_with_email(email)).to be_present
      end
    end

    context 'when the user is found, not privileged, and confirmed' do
      it 'sends password reset instructions' do
        user = build_stubbed(:user)

        allow(User).to receive(:find_with_email).with(user.email).and_return(user)

        expect(user).to receive(:send_reset_password_instructions)

        RequestPasswordReset.new(user.email).perform
      end
    end

    context 'when the user is found, not privileged, and not yet confirmed' do
      it 'sends password reset instructions' do
        user = build_stubbed(:user, :unconfirmed)

        allow(User).to receive(:find_with_email).with(user.email).and_return(user)

        expect(user).to receive(:send_reset_password_instructions)

        RequestPasswordReset.new(user.email).perform
      end
    end
  end
end
