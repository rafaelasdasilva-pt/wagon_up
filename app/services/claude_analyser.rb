require "net/http"
require "json"

class ClaudeAnalyser
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
  MODEL       = "claude-sonnet-4-5"
  MAX_TOKENS  = 10_000  # JSON 3 cargos × 3 mercados + margem de segurança
  TEMPERATURE = 0.2     # Mais determinístico → JSON mais estável

  SYSTEM_PROMPT = <<~SYSTEM
    You are Chloe, Global Tech Recruitment Specialist at the Wagon Up platform.
    Your sole function: analyse CVs of Le Wagon Brasil bootcamp graduates and
    produce precise, personalised career diagnoses in JSON format.

    ## Your core philosophy
    You believe that a career-changer's previous experience is a competitive
    advantage — not an obstacle. Your analysis always finds the bridge between
    past and future, with concrete data and direct language.

    ## Bootcamp context
    The student completed 9 intensive weeks of AI Software Development. Stack:
    Ruby, Ruby on Rails, JavaScript, HTML, CSS, SQL, Git, GitHub, Heroku,
    Active Storage, WebSocket, Figma, OpenAI API, Claude Code.

    ## Absolute constraints (violation = invalid response)
    1. Your COMPLETE response must be a single valid JSON object.
       Starts with { and ends with }. No text before or after.
    2. NEVER invent experiences or skills not mentioned in the CV.
    3. NEVER use placeholders like [insert skill] or [X years].
       ALWAYS use real data extracted from the provided CV.
    4. NEVER truncate the JSON. All schema fields must be present.
    5. ALL output text values MUST be in English. Proper names preserved.
    6. Currency convention: use the local currency of each analysed country.
       Examples: Brazil → BRL monthly (e.g. "R$ 6,000 – R$ 9,000"),
       Portugal/Europe → EUR annual (e.g. "€ 28,000 – € 40,000"),
       USA/International → USD annual (e.g. "$ 55,000 – $ 80,000"),
       UK → GBP annual, Canada → CAD annual, Australia → AUD annual.
       Adapt the period (monthly/annual) to the local standard of each country.
  SYSTEM

  USER_PROMPT_TEMPLATE = <<~PROMPT
    ## STUDENT CV

    <cv_texto>
    {{CV_TEXT}}
    </cv_texto>

    ## SKILLS SELECTED BY THE STUDENT

    The student confirmed the following skills. Treat them as true and use them ACTIVELY in the analysis:

    Confirmed technical skills: {{HARD_SKILLS}}
    Confirmed behavioural skills: {{SOFT_SKILLS}}

    Mandatory rules for these skills:
    - Include ALL confirmed technical skills in `analise_lacunas.tenho` for each role (in addition to those extracted from the CV).
    - NEVER list in `analise_lacunas.falta` any skill the student has already confirmed having.
    - Mention confirmed behavioural skills in `prompt_curriculo` for each role as ATS keywords (e.g. "Problem Solving", "Communication", "Adaptability").
    - When relevant, reflect behavioural skills in `breakdown` (e.g. "Communicates with stakeholders" for Communication, "Solves blockers independently" for Problem Solving, "Adapts to change" for Adaptability).

    Markets to analyse: {{TARGET_MARKETS}}

    Student first name to use in all text (resumo_chloe, mensagem_chloe): {{USER_NAME}}

    ## QUALITY RULES

    - `breakdown.passado`: short, specific label — MAXIMUM 4 words. Examples: "5 yrs data L'Oréal", "Rails bootcamp Le Wagon", "Team management". NEVER a full sentence.
    - `breakdown.futuro`: outcome in a short phrase — MAXIMUM 5 words. Examples: "Fullstack ready day one", "Data-driven decisions", "Communicates with stakeholders". NEVER more than one phrase.
    - `mercados.insight`: 2 sentences — Sentence 1: sector trend + numerical data. Sentence 2: why THIS student specifically.
    - `analise_lacunas.falta`: NEVER list a skill the student already has. REAL resource with platform + cost + duration.
    - `mensagem_chloe`: exactly 2 sentences, use <strong> on one keyword, use the first name provided in {{USER_NAME}}.
    - `resumo_chloe`: ALWAYS start with the first name provided in {{USER_NAME}}, never use a name extracted from the CV.
    - `prompt_curriculo`: 150–200 words, first person, ≥5 ATS keywords, confident tone.
    - Percentages: Role 1 = 82–92%, Role 2 = 73–83%, Role 3 = 64–76%. Never multiples of 5.
    - `rotulo_compatibilidade`: use EXACTLY — 82–92% = "Excellent Fit", 73–83% = "Good Fit", 64–76% = "Solid Fit".
    - Career axes: Axis A (prior experience) < 3 yrs = Entry-level, 3–5 = Mid-level, > 5 = Senior. Axis B (tech maturity) bootcamp = Junior, bootcamp + tech exp = Mid.

    ## REFERENCE EXAMPLE

    <exemplo>
    {
      "estudante": { "nome": "Madalena Da Cruz", "iniciais": "MD", "headline": "Full Stack Developer & Product Strategist", "resumo_chloe": "Madalena combines 5 years of data analysis at L'Oréal with a complete Rails stack — a rare profile that unites business instinct and technical capability." },
      "cargos_sugeridos": [{
        "id": "junior-web-developer", "titulo": "Junior Web Developer", "axis_a": "Senior", "axis_b": "Junior",
        "percentual_compatibilidade": 87, "rotulo_compatibilidade": "Excellent Fit",
        "descricao": "Rails + L'Oréal product vision = a dev who ships features users actually want.",
        "mensagem_chloe": "<strong>Madalena, this is your strongest path.</strong> 5 years reading user behaviour at L'Oréal is worth more than any UX course.",
        "justificativa": "Le Wagon fullstack stack combined with 5 years of real-world data analysis experience.",
        "breakdown": [
          { "icone": "📊", "passado": "5 yrs data L'Oréal", "futuro": "Data-driven product decisions" },
          { "icone": "💻", "passado": "Rails + React Le Wagon", "futuro": "Fullstack ready day one" },
          { "icone": "🤝", "passado": "Led teams at L'Oréal", "futuro": "Communicates with stakeholders" },
          { "icone": "🎯", "passado": "A/B testing 3 years", "futuro": "Ships features fast" }
        ],
        "mercados": {
          "Brazil": { "salario": "R$ 3,500 – R$ 6,000", "periodo": "per month", "demanda": "High", "percentual_demanda": 76, "tendencia": "↑ +23% junior dev roles in SP in 2025", "tempo_contratacao": "3 – 5 weeks", "insight": "Fintechs in SP grew headcount 34% in 2025, seeking profiles that bridge business and tech stack. <strong>Madalena's L'Oréal background and English fluency</strong> eliminate the two most common objections to bootcamp graduates." }
        },
        "analise_lacunas": {
          "tenho": ["Ruby on Rails — fullstack (Le Wagon SP, 2 projects)", "React + JavaScript", "SQL & PostgreSQL", "Git & GitHub", "Data analysis — 5 yrs L'Oréal"],
          "falta": [
            { "habilidade": "TypeScript", "recurso": "TypeScript Handbook — Microsoft Learn (free, ~6h)" },
            { "habilidade": "Automated testing (RSpec)", "recurso": "Kitt Le Wagon — testing module (free, ~4h)" }
          ]
        },
        "prompt_curriculo": "I am Madalena Da Cruz, transitioning from 5 years as a Marketing Manager at L'Oréal to Junior Web Developer after the Le Wagon SP bootcamp. Proficient in Ruby on Rails, React, JavaScript, PostgreSQL and Git — two published apps. Keywords: Rails, REST API, Agile, MVC, CI/CD. My background in data analysis and project management is a direct advantage in product-driven development."
      }]
    }
    </exemplo>

    Reply ONLY with valid JSON following exactly the structure of the example. Start with { and end with }. Exactly 3 objects in cargos_sugeridos, each with the markets indicated in {{TARGET_MARKETS}}. The keys of the "mercados" object MUST be exactly the country names provided in {{TARGET_MARKETS}}, without translation or alteration. ALL text values must be in English.
  PROMPT

  def initialize(cv_text, hard_skills: nil, soft_skills: nil, target_markets: nil, user_name: nil)
    @cv_text = cv_text
    @hard_skills = hard_skills.presence || ""
    @soft_skills = soft_skills.presence || ""
    @target_markets = target_markets.presence || "Brazil, Portugal, United States"
    @user_name = user_name.presence || ""
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
      .gsub("{{HARD_SKILLS}}", @hard_skills)
      .gsub("{{SOFT_SKILLS}}", @soft_skills)
      .gsub("{{TARGET_MARKETS}}", @target_markets)
      .gsub("{{USER_NAME}}", @user_name)
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
      "estudante" => { "resumo_chloe" => "Error processing profile. Please try again.", "nome" => "", "iniciais" => "", "headline" => "" },
      "cargos_sugeridos" => []
    }
  end
end
