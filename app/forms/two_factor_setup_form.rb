class TwoFactorSetupForm
  include ActiveModel::Model
  include FormPhoneValidator

  attr_accessor :phone

  def initialize(user)
    @user = user
  end

  def submit(params)
    formatted_phone = params[:phone].phony_formatted(
      format: :international, normalize: :US, spaces: ' '
    )
    self.phone = formatted_phone

    valid?
  end
end
