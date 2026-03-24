class InterviewsController < ApplicationController
  # GET /roles/:role_id/interviews/new
  # Mostra o formulário para iniciar uma entrevista para um role específico
  # role_id vem da URL (nested route) — sabemos para qual role é a entrevista
  def new
    @role = current_user_role(params[:role_id])
    @interview = Interview.new
  end

  # POST /roles/:role_id/interviews
  # Cria a entrevista ligada ao role escolhido pelo user
  # role_id vem da URL (nested route)
  # Após criar, redireciona para a entrevista em curso (show)
  def create
    @role = current_user_role(params[:role_id])
    @interview = Interview.new(interview_params)
    @interview.role = @role

    if @interview.save
      question = ChloeInterviewer.new(@interview).first_question
      @interview.update_column(:current_question, question)
      redirect_to interview_path(@interview), notice: "Entrevista iniciada! Boa sorte."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /interviews/:id
  # Página principal da entrevista em curso
  # Mostra as perguntas e o formulário para submeter respostas
  # @answers ordenadas por created_at — mostra a conversa em ordem cronológica
  def show
    @interview  = current_user_interview(params[:id])
    @answers    = @interview.answers.order(:created_at)
    @role       = @interview.role
    @interviews = @role.interviews.order(created_at: :desc)
  end

  # DELETE /interviews/:id
  def destroy
    @interview = current_user_interview(params[:id])
    @role = @interview.role
    @interview.destroy
    last = @role.interviews.order(created_at: :desc).first
    if last
      redirect_to interview_path(last)
    else
      redirect_to role_path(@role)
    end
  end

  # PATCH /interviews/:id
  # Actualiza a entrevista com o score final e feedback da IA
  # Chamado quando a ChloeInterviewer termina de avaliar todas as respostas
  # Redireciona para a página de resultados
  def update
    @interview = current_user_interview(params[:id])

    if @interview.update(interview_params)
      redirect_to results_interview_path(@interview)
    else
      render :show, status: :unprocessable_entity
    end
  end

  # GET /interviews/:id/results
  # Página final da entrevista com score global e feedback detalhado
  # Mostra todas as respostas com a avaliação da IA para cada uma
  def results
    @interview = current_user_interview(params[:id])
    @answers = @interview.answers.order(:created_at)
    @role = @interview.role
  end

  private

  # Filtra os parâmetros permitidos vindos do formulário
  # :category        — tipo de entrevista (ex: "técnica", "comportamental")
  # :overall_score   — score final gerado pela IA (0-100)
  # :feedback_summary — resumo do feedback da IA sobre a entrevista completa
  def interview_params
    params.require(:interview).permit(:category, :overall_score, :feedback_summary)
  end

  def current_user_role(role_id)
    Role.joins(:analysis).where(analyses: { user_id: current_user.id }, id: role_id).first!
  end

  def current_user_interview(interview_id)
    Interview.joins(role: :analysis).where(analyses: { user_id: current_user.id }, id: interview_id).first!
  end
end
