require "net/http"
require "json"

class ClaudeAnalyser
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
  MODEL       = "claude-sonnet-4-5"
  MAX_TOKENS  = 10_000  # JSON 3 cargos × 3 mercados + margem de segurança
  TEMPERATURE = 0.2     # Mais determinístico → JSON mais estável

  SYSTEM_PROMPT = <<~SYSTEM
    Você é Chloe, especialista em Recrutamento Tech Global da plataforma Wagon Up.
    Sua função exclusiva: analisar currículos de alunos do Le Wagon Brasil e
    produzir diagnósticos de carreira precisos e personalizados em formato JSON.

    ## Sua filosofia central
    Você acredita que a experiência anterior de um profissional em transição é
    uma vantagem competitiva — não um obstáculo. Sua análise sempre encontra
    a ponte entre o passado e o futuro, com dados concretos e linguagem direta.

    ## Contexto do bootcamp
    O aluno concluiu 9 semanas intensivas de AI Software Development. Stack:
    Ruby, Ruby on Rails, JavaScript, HTML, CSS, SQL, Git, GitHub, Heroku,
    Active Storage, WebSocket, Figma, OpenAI API, Claude Code.

    ## Restrições absolutas (violação = resposta inválida)
    1. Sua resposta COMPLETA deve ser um único objeto JSON válido.
       Começa com { e termina com }. Nenhum texto antes ou depois.
    2. NUNCA invente experiências ou habilidades não mencionadas no CV.
    3. NUNCA use placeholders como [inserir habilidade] ou [X anos].
       Use SEMPRE os dados reais extraídos do CV fornecido.
    4. NUNCA trunque o JSON. Todos os campos do esquema devem estar presentes.
    5. Output SEMPRE em português do Brasil. Nomes próprios preservados.
    6. Convenção de moeda por mercado (use EXATAMENTE este formato):
       - Brasil        → "R$ 6.000 – R$ 9.000"  (mensal, BRL)
       - Portugal      → "€ 28.000 – € 38.000"  (anual, EUR)
       - Internacional → "$ 55.000 – $ 80.000"  (anual, USD)
  SYSTEM

  USER_PROMPT_TEMPLATE = <<~PROMPT
    ## CV DO ESTUDANTE

    <cv_texto>
    {{CV_TEXT}}
    </cv_texto>

    Mercados a analisar: {{TARGET_MARKETS}}

    ## REGRAS DE QUALIDADE

    - `breakdown.passado`: referência ESPECÍFICA ao CV — empresa, cargo, anos, projecto
    - `breakdown.futuro`: valor concreto e mensurável para o cargo-alvo
    - `mercados.insight`: 2 frases — Frase 1: tendência do sector + dado numérico. Frase 2: por que ESTE estudante especificamente.
    - `analise_lacunas.falta`: NUNCA listar habilidade que o estudante já tem. Recurso REAL com plataforma + custo + duração.
    - `mensagem_chloe`: exactamente 2 frases, use <strong> numa palavra-chave, use o primeiro nome.
    - `prompt_curriculo`: 150–200 palavras, primeira pessoa, ≥5 palavras-chave ATS, tom confiante.
    - Percentuais: Cargo 1 = 82–92%, Cargo 2 = 73–83%, Cargo 3 = 64–76%. Nunca múltiplos de 5.
    - `rotulo_compatibilidade`: use EXACTAMENTE — 82–92% = "Encaixe Excelente", 73–83% = "Bom Encaixe", 64–76% = "Encaixe Sólido".
    - Eixos de carreira: Eixo A (exp. anterior) < 3 anos = Entry-level, 3–5 = Intermediário, > 5 = Sênior. Eixo B (maturidade tech) bootcamp = Júnior, bootcamp + exp. tech = Pleno.

    ## EXEMPLO DE REFERÊNCIA

    <exemplo>
    {
      "estudante": { "nome": "Madalena Da Cruz", "iniciais": "MD", "headline": "Dev Full Stack & Estrategista de Produto", "resumo_chloe": "Madalena combina 5 anos de análise de dados na L'Oréal com stack Rails completa — um perfil raro que une instinto de negócio e capacidade técnica." },
      "cargos_sugeridos": [{
        "id": "desenvolvedor-web-junior", "titulo": "Desenvolvedor Web Júnior", "axis_a": "Sênior", "axis_b": "Júnior",
        "percentual_compatibilidade": 87, "rotulo_compatibilidade": "Encaixe Excelente",
        "descricao": "Rails + visão de produto da L'Oréal = dev que entrega funcionalidades que os utilizadores realmente querem.",
        "mensagem_chloe": "<strong>Madalena, este é o seu caminho mais sólido.</strong> 5 anos lendo comportamento de utilizadores na L'Oréal valem mais do que qualquer curso de UX.",
        "justificativa": "Stack fullstack do Le Wagon combinada com 5 anos de experiência real em análise de dados.",
        "breakdown": [
          { "icone": "📊", "passado": "5 anos analisando dados de campanhas na L'Oréal", "futuro": "Decisões de produto baseadas em dados desde o 1º sprint" },
          { "icone": "💻", "passado": "Ruby on Rails + React — Le Wagon SP, 2 projectos publicados", "futuro": "Capacidade fullstack independente" },
          { "icone": "🤝", "passado": "Liderou projectos com design, vendas e engenharia na L'Oréal", "futuro": "Comunicação clara com stakeholders não-técnicos" },
          { "icone": "🎯", "passado": "Testes A/B em campanhas digitais — 3 anos de prática", "futuro": "Mentalidade de experimentação aplicada a features de produto" }
        ],
        "mercados": {
          "Brasil": { "salario": "R$ 3.500 – R$ 6.000", "periodo": "por mês", "demanda": "Alta", "percentual_demanda": 76, "tendencia": "↑ +23% vagas dev júnior em SP em 2025", "tempo_contratacao": "3 – 5 semanas", "insight": "Fintechs em SP cresceram 34% em headcount em 2025, procurando perfis que unem negócio e stack técnica. <strong>O histórico da Madalena na L'Oréal e fluência em inglês</strong> eliminam as duas objeções mais comuns a formandos de bootcamp." }
        },
        "analise_lacunas": {
          "tenho": ["Ruby on Rails — fullstack (Le Wagon SP, 2 projectos)", "React + JavaScript", "SQL & PostgreSQL", "Git & GitHub", "Análise de dados — 5 anos L'Oréal"],
          "falta": [
            { "habilidade": "TypeScript", "recurso": "TypeScript Handbook — Microsoft Learn (gratuito, ~6h)" },
            { "habilidade": "Testes automatizados (RSpec)", "recurso": "Kitt Le Wagon — módulo de testes (gratuito, ~4h)" }
          ]
        },
        "prompt_curriculo": "Sou Madalena Da Cruz, transitando de 5 anos como Gerente de Marketing na L'Oréal para Desenvolvedor Web Júnior após o bootcamp Le Wagon SP. Proficiência em Ruby on Rails, React, JavaScript, PostgreSQL e Git — dois apps publicados. Palavras-chave: Rails, REST API, Agile, MVC, CI/CD. A minha experiência em dados e gestão de projectos é uma vantagem directa no desenvolvimento orientado a produto."
      }]
    }
    </exemplo>

    Responde APENAS com JSON válido seguindo exactamente a estrutura do exemplo. Começa com { e termina com }. Exactamente 3 objectos em cargos_sugeridos, cada um com os mercados: Brasil, Portugal, Internacional.
  PROMPT

  def initialize(cv_text)
    @cv_text = cv_text
  end

  def call
    raw_text = call_api
    parse_response(raw_text)
  end

  private

  def call_api
    uri = URI(ANTHROPIC_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 120  # 2 minutos

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = ENV["ANTHROPIC_API_KEY"]
    request["anthropic-version"] = "2023-06-01"

    request.body = {
      model: MODEL,
      max_tokens: MAX_TOKENS,
      temperature: TEMPERATURE,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: user_prompt }]
    }.to_json

    response = http.request(request)
    body = JSON.parse(response.body)
    body.dig("content", 0, "text")
  end

  def user_prompt
    USER_PROMPT_TEMPLATE
      .gsub("{{CV_TEXT}}", truncate_cv(@cv_text))
      .gsub("{{HARD_SKILLS}}", "")
      .gsub("{{PREVIOUS_ROLE}}", "")
      .gsub("{{TARGET_MARKETS}}", "Brasil, Portugal, Internacional")
      .gsub("{{BATCH}}", "")
  end

  def truncate_cv(text)
    return "" if text.blank?
    return text if text.length <= 8000

    inicio = text[0..5499]
    fim    = text[-2499..]
    "#{inicio}\n\n[...trecho central omitido para reduzir tokens...]\n\n#{fim}"
  end

  def parse_response(raw_text)
    # Remove o bloco <raciocinio> antes de parsear
    clean = raw_text.gsub(/<raciocinio>.*?<\/raciocinio>/m, "").strip
    clean = clean.gsub(/```json|```/, "").strip

    begin
      JSON.parse(clean)
    rescue JSON::ParserError
      match = clean.match(/\{.*\}/m)
      if match
        begin
          JSON.parse(match[0])
        rescue JSON::ParserError => e
          Rails.logger.error("[ClaudeAnalyser] JSON parse error após extracção: #{e.message}")
          fallback_response
        end
      else
        Rails.logger.error("[ClaudeAnalyser] Nenhum JSON encontrado na resposta")
        fallback_response
      end
    end
  end

  def fallback_response
    {
      "estudante" => { "resumo_chloe" => "Erro ao processar o perfil. Tente novamente.", "nome" => "", "iniciais" => "", "headline" => "" },
      "cargos_sugeridos" => []
    }
  end
end
