class AnswersController < ApplicationController
  # POST /interviews/:interview_id/answers
  # Guarda a resposta do user a uma pergunta da entrevista
  # interview_id vem da URL (nested route) — sabemos a que entrevista pertence
  # Após guardar, redireciona de volta para a entrevista em curso (show)
  # TODO: chamar ChloeInterviewer.evaluate(@answer) para avaliar a resposta via API Anthropic
  #       e preencher automaticamente :feedback e :score
  def create
    @interview = Interview.joins(role: :analysis).where(analyses: { user_id: current_user.id }, id: params[:interview_id]).first!
    @answer = Answer.new(answer_params)
    @answer.interview = @interview

    if @answer.save
      redirect_to interview_path(@interview), notice: "Resposta guardada!"
    else
      redirect_to interview_path(@interview), alert: "Erro ao guardar a resposta."
    end
  end

  private

  # Filtra os parâmetros permitidos vindos do formulário
  # :question — a pergunta feita pela IA (ChloeInterviewer)
  # :answer   — a resposta escrita pelo user
  # :feedback — avaliação da resposta gerada pela IA (preenchida depois)
  # :score    — pontuação da resposta (0-10), gerada pela IA (preenchida depois)
  def answer_params
    params.require(:answer).permit(:question, :answer, :feedback, :score)
  end
end
