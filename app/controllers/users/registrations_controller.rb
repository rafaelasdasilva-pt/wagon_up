class Users::RegistrationsController < Devise::RegistrationsController
  private

  def after_sign_up_path_for(resource)
    new_analysis_path
  end
end
