class RolesController < ApplicationController
  # GET /roles/:id
  # Mostra os detalhes de um role sugerido pela IA
  # Inclui título, justificação, market_fit e botão para iniciar entrevista
  # @analysis é carregado para mostrar contexto (de qual análise veio este role)
  def show
    @role = Role.joins(:analysis).where(analyses: { user_id: current_user.id }, id: params[:id]).first!
    @analysis = @role.analysis
  end
end
