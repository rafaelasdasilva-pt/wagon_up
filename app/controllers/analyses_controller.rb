class AnalysesController < ApplicationController
  # GET /analyses → redireciona para a última análise ou para new
  def index
    analysis = current_user.analyses.last
    if analysis
      redirect_to analysis_path(analysis)
    else
      redirect_to new_analysis_path
    end
  end

  # GET /analyses/new
  def new
    @analysis = Analysis.new
  end

  # GET /analyses/:id
  def show
    @analysis = current_user.analyses.find(params[:id])
  end

  # POST /analyses
  def create
    @analysis = current_user.analyses.new

    if params[:analysis][:file].blank?
      @analysis.errors.add(:file, "É obrigatório anexar um CV em PDF")
      render :new, status: :unprocessable_entity and return
    end

    if @analysis.save
      @analysis.file.attach(params[:analysis][:file])

      begin
        @analysis.update!(cv_text: PdfParser.extract(@analysis.file))
      rescue PdfParserError => e
        @analysis.errors.add(:file, e.message)
        render :new, status: :unprocessable_entity and return
      end

      AnalysisJob.perform_later(@analysis.id)

      redirect_to analysis_path(@analysis), notice: "CV enviado! A Chloe está a analisar o teu perfil..."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def analysis_params
    params.require(:analysis).permit(:cv_text, :file)
  end
end
