class Users::SettingsController < ApplicationController
  def show; end

  def update_avatar
    if params[:avatar].present?
      current_user.avatar.attach(params[:avatar])
      redirect_to account_settings_path, notice: "Profile photo updated."
    else
      redirect_to account_settings_path, alert: "Please select a photo."
    end
  end

  def update_profile
    if current_user.update_with_password(profile_params)
      bypass_sign_in(current_user)
      redirect_to account_settings_path, notice: "Profile updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    if current_user.update_with_password(password_params)
      bypass_sign_in(current_user)
      redirect_to account_settings_path, notice: "Password updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy_account
    current_user.destroy
    redirect_to root_path, notice: "Your account has been deleted."
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :current_password)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
