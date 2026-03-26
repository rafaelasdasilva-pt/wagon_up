class RolesController < ApplicationController
  before_action :load_role

  # GET /roles/:id
  def show
  end

  # GET /roles/:id/cv
  # Generates a tailored CV PDF for the role and sends it as a download
  def cv
    cv_data  = CvGeneratorService.new(@analysis, @role).call
    pdf_data = PdfCvBuilder.new(cv_data, @role).build

    name     = cv_data["name"].presence || current_user.name
    filename = "cv-#{@role.title.parameterize}-#{name.parameterize}.pdf"

    send_data pdf_data,
              filename:    filename,
              type:        "application/pdf",
              disposition: "attachment"
  rescue => e
    Rails.logger.error("[RolesController#cv] #{e.class}: #{e.message}")
    redirect_to role_path(@role), alert: "Could not generate CV. Please try again."
  end

  private

  def load_role
    @role     = Role.joins(:analysis).where(analyses: { user_id: current_user.id }, id: params[:id]).first!
    @analysis = @role.analysis
  end
end
