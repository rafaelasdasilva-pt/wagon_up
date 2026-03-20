class Users::SessionsController < Devise::SessionsController
  private

  def after_sign_in_path_for(resource)
    analysis = resource.analyses.last
    if analysis
      analysis_path(analysis)
    else
      new_analysis_path
    end
  end
end
