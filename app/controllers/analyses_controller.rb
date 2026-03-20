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
    @analysis = Analysis.find(params[:id])
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
        @analysis.cv_text = PdfParser.extract(@analysis.file)
        @analysis.save

        # Chamar ClaudeAnalyser
        result = ClaudeAnalyser.new(@analysis.cv_text).call

        @analysis.update!(
          summary: result["summary"],
          skills: result["skills"],
          raw_json: result
        )

        result["roles"].each do |role_data|
          @analysis.roles.create!(
            title: role_data["title"],
            justification: role_data["justification"],
            market_fit: role_data["market_fit"],
            position: role_data["position"]
          )
        end

      rescue PdfParserError => e
        @analysis.errors.add(:file, e.message)
        render :new, status: :unprocessable_entity and return
      end

      redirect_to analysis_path(@analysis), notice: "CV enviado! A IA está a analisar o teu perfil."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def analysis_params
    params.require(:analysis).permit(:cv_text, :file)
  end
end
