class AnswersController < ApplicationController
  # POST /interviews/:interview_id/answers
  # Guarda a resposta do user, chama ChloeInterviewer para avaliar e gerar a próxima pergunta
  def create
    @interview = Interview.joins(role: :analysis).where(analyses: { user_id: current_user.id }, id: params[:interview_id]).first!
    @answer = Answer.new(answer_params)
    @answer.interview = @interview

    if @answer.save
      Rails.logger.info("[AnswersController] answer saved id=#{@answer.id}")

      result = ChloeInterviewer.new(@interview).evaluate(@answer)
      Rails.logger.info("[AnswersController] chloe result: #{result.inspect}")

      @answer.update(feedback: result[:feedback], score: result[:score])

      if result[:session_complete]
        scores    = @interview.answers.map(&:score).compact
        avg_score = scores.any? ? (scores.sum.to_f / scores.size).round : nil
        summary = result[:summary].is_a?(Hash) ? result[:summary].to_json : result[:summary].to_s
        @interview.update(overall_score: avg_score, feedback_summary: summary, current_question: nil)
      else
        @interview.update_column(:current_question, result[:next_question])
      end

      respond_to do |format|
        format.turbo_stream do
          streams = [
            turbo_stream.remove("chloe-typing"),
            turbo_stream.append("chat-messages", partial: "interviews/feedback_bubble", locals: { answer: @answer })
          ]
          if result[:session_complete]
            streams << turbo_stream.replace("answer-form", partial: "interviews/answer_form", locals: { interview: @interview })
          else
            streams << turbo_stream.append("chat-messages", partial: "interviews/question_bubble", locals: { question: @interview.current_question })
            streams << turbo_stream.replace("answer-form", partial: "interviews/answer_form", locals: { interview: @interview })
          end
          render turbo_stream: streams
        end
        format.html { redirect_to interview_path(@interview) }
      end
    else
      Rails.logger.error("[AnswersController] save failed: #{@answer.errors.full_messages}")
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove("chloe-typing") }
        format.html { redirect_to interview_path(@interview), alert: @answer.errors.full_messages.join(", ") }
      end
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
