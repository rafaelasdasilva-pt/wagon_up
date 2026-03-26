class AnalysisJob < ApplicationJob
  queue_as :default

  def perform(analysis_id)
    analysis = Analysis.find(analysis_id)

    result = ClaudeAnalyser.new(
      analysis.cv_text,
      hard_skills: analysis.hard_skills_selected,
      soft_skills: analysis.soft_skills_selected,
      target_markets: analysis.target_markets,
      user_name: analysis.user.name.split.first
    ).call

    skills = result.dig("cargos_sugeridos", 0, "analise_lacunas", "tenho") || []

    analysis.update!(
      summary: result.dig("estudante", "resumo_chloe"),
      skills: skills.to_json,
      raw_json: result,
      status: "done"
    )

    result["cargos_sugeridos"].each_with_index do |cargo, i|
      analysis.roles.create!(
        title: cargo["titulo"],
        justification: cargo["justificativa"],
        market_fit: cargo["mercados"],
        position: i + 1
      )
    end
  rescue => e
    analysis&.update!(status: "failed")
    raise e
  end
end
