require 'rails_helper'

feature 'managing email address' do
  context 'show one email address if only one is configured' do
    scenario 'shows one email address for a user with only one' do
      user = create(:user, :signed_up, :with_multiple_emails)
      sign_in_and_2fa_user(user)

      expect(page).to have_content(user.email_addresses.first.email)
    end

    scenario 'shows all email address for a user with multiple emails' do
      user = create(:user, :signed_up, :with_multiple_emails)
      email1, email2 = user.reload.email_addresses.map(&:email)
      sign_in_and_2fa_user(user)

      expect(page).to have_content(email1)
      expect(page).to have_content(email2)
    end
  end

  context 'when adding emails is disabled' do
    before do
      allow(FeatureManagement).to receive(:email_addition_enabled?).and_return(false)
    end

    it 'displays the links for allowing the user to manage their email addresses' do
      user = create(:user, :signed_up)
      sign_in_and_2fa_user(user)

      manage_link_path = manage_email_url(id: user.email_addresses.first.id)
      expect(page).to have_link(t('forms.buttons.manage'), href: manage_link_path)
    end
  end

  context 'when adding emails is enabled' do
    before do
      allow(FeatureManagement).to receive(:email_addition_enabled?).and_return(true)
      Rails.application.reload_routes!
    end

    it 'does not display the links for allowing the user to manage their email addresses' do
      user = create(:user, :signed_up)
      sign_in_and_2fa_user(user)

      expect(page).to have_content("#{user.email_addresses.first.email}\nPassword")
    end
  end

  context 'allows deletion of email address' do
    before do
      allow(FeatureManagement).to receive(:email_deletion_enabled?).and_return(true)
    end

    it 'does not allow last confirmed email to be deleted' do
      user = create(:user, :signed_up, :with_email, email: 'test@example.com ')
      confirmed_email = user.confirmed_email_addresses.first
      unconfirmed_email = create(:email_address, user: user, confirmed_at: nil)
      user.email_addresses.reload

      sign_in_and_2fa_user(user)
      expect(page).to have_current_path(account_path)

      delete_link_not_displayed(confirmed_email)
      delete_link_is_displayed(unconfirmed_email)

      delete_email_should_fail(confirmed_email)
      delete_email_should_not_fail(unconfirmed_email)
    end

    it 'Allows delete when more than one confirmed email exists' do
      user = create(:user, :signed_up, :with_email, email: 'test@example.com ')
      confirmed_email1 = user.confirmed_email_addresses.first
      confirmed_email2 = create(:email_address, user: user,
                                                confirmed_at: Time.zone.now)
      user.email_addresses.reload

      sign_in_and_2fa_user(user)
      expect(page).to have_current_path(account_path)

      delete_link_is_displayed(confirmed_email1)
      delete_link_is_displayed(confirmed_email2)

      delete_email_should_not_fail(confirmed_email1)
    end

    it 'sends notification to all confirmed emails when email address is deleted' do
      allow(UserMailer).to receive(:email_deleted).and_call_original
      user = create(:user, :signed_up, :with_email, email: 'test@example.com ')
      confirmed_email1 = user.confirmed_email_addresses.first
      create(:email_address, user: user, confirmed_at: Time.zone.now)
      user.email_addresses.reload

      sign_in_and_2fa_user(user)
      expect(page).to have_current_path(account_path)

      delete_email_should_not_fail(confirmed_email1)
      expect(UserMailer).to have_received(:email_deleted).twice
    end

    def delete_link_not_displayed(email)
      delete_link_path = manage_email_confirm_delete_url(id: email.id)
      expect(page).to_not have_link(t('forms.buttons.delete'), href: delete_link_path)
    end

    def delete_link_is_displayed(email)
      delete_link_path = manage_email_confirm_delete_url(id: email.id)
      expect(page).to have_link(t('forms.buttons.delete'), href: delete_link_path)
    end

    def delete_email_should_fail(email)
      visit manage_email_confirm_delete_url(id: email.id)
      expect(page).to have_content t('email_addresses.delete.confirm',
                                     email: email.email)
      click_button t('forms.email.buttons.delete')

      expect(page).to have_current_path(account_path)
      expect(page).to have_content t('email_addresses.delete.failure')
    end

    def delete_email_should_not_fail(email)
      visit manage_email_confirm_delete_url(id: email.id)
      expect(page).to have_content t('email_addresses.delete.confirm',
                                     email: email.email)
      click_button t('forms.email.buttons.delete')

      expect(page).to have_current_path(account_path)
      expect(page).to have_content t('email_addresses.delete.success')
    end
  end
end
