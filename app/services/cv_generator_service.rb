require "net/http"
require "json"

class CvGeneratorService
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
  MODEL       = "claude-sonnet-4-5"
  MAX_TOKENS  = 4000
  TEMPERATURE = 0.3

  SYSTEM_PROMPT = <<~SYSTEM
    You are an expert CV writer specialising in tech career transitions for Le Wagon bootcamp graduates.
    You produce tailored, ATS-optimised CVs in JSON format.
    Your COMPLETE response must be a single valid JSON object — starts with { and ends with }.
    No text before or after. Never truncate the JSON.
  SYSTEM

  def initialize(analysis, role)
    @analysis = analysis
    @role     = role
  end

  def call
    raw_text = call_api
    parse_response(raw_text)
  end

  private

  def call_api
    uri  = URI(ANTHROPIC_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl    = true
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"]      = "application/json"
    request["x-api-key"]         = ENV["ANTHROPIC_API_KEY"]
    request["anthropic-version"] = "2023-06-01"

    request.body = {
      model:       MODEL,
      max_tokens:  MAX_TOKENS,
      temperature: TEMPERATURE,
      system:      SYSTEM_PROMPT,
      messages:    [ { role: "user", content: user_prompt } ]
    }.to_json

    response = http.request(request)
    body     = JSON.parse(response.body)
    body.dig("content", 0, "text")
  end

  def user_prompt
    <<~PROMPT
      Create a professional CV for a Le Wagon bootcamp graduate targeting a **#{@role.title}** position.

      ## Original CV (source of truth — extract real data only)
      #{cv_text_excerpt}

      ## Target role context
      - Role: #{@role.title}
      - Why this role fits: #{@role.justification}
      - Confirmed technical skills: #{@analysis.hard_skills_selected.presence || "Ruby on Rails, JavaScript, SQL, HTML/CSS, Git"}
      - Confirmed soft skills: #{@analysis.soft_skills_selected.presence || "Communication, Problem Solving, Adaptability"}

      ## Output schema (return ONLY this JSON — no extra keys, no markdown fences)
      {
        "name": "Full name extracted from CV",
        "headline": "#{@role.title} | Le Wagon Graduate",
        "email": "email if present in CV, else empty string",
        "phone": "phone if present in CV, else empty string",
        "linkedin": "linkedin URL or handle if present, else empty string",
        "location": "City, Country",
        "summary": "3–4 sentence professional summary tailored for #{@role.title}. First person. ATS keywords included. Highlight bootcamp + transferable experience.",
        "skills": {
          "technical": ["up to 10 relevant technical skills"],
          "soft": ["up to 6 relevant soft skills"]
        },
        "experience": [
          {
            "title": "Job title",
            "company": "Company name",
            "period": "Month Year – Month Year (or Present)",
            "highlights": ["3 bullet points reframed to highlight transferable value for #{@role.title}"]
          }
        ],
        "education": [
          {
            "degree": "Programme name",
            "institution": "Institution name",
            "year": "Year or year range",
            "highlights": ["1–2 notable achievements or projects"]
          }
        ],
        "projects": [
          {
            "name": "Project name",
            "description": "1–2 sentences on what it does and impact",
            "tech": ["tech stack used"]
          }
        ]
      }

      ## Rules
      - Extract ONLY real data from the CV text — never invent experience, dates or companies.
      - Reframe past experience bullets to highlight transferable skills for #{@role.title}.
      - Place Le Wagon bootcamp prominently in education (as the most recent entry).
      - All text values in English. Proper names preserved.
      - Return the JSON object only — no commentary, no markdown.
    PROMPT
  end

  def cv_text_excerpt
    return "" if @analysis.cv_text.blank?

    text = @analysis.cv_text
    text.length <= 5000 ? text : "#{text[0..4999]}\n\n[...rest truncated...]"
  end

  def parse_response(raw_text)
    clean = raw_text.to_s.gsub(/```json|```/, "").strip
    JSON.parse(clean)
  rescue JSON::ParserError
    match = clean.match(/\{.*\}/m)
    if match
      JSON.parse(match[0]) rescue fallback_cv
    else
      fallback_cv
    end
  end

  def fallback_cv
    name = @analysis.raw_json&.dig("estudante", "nome") || "Graduate"
    {
      "name"      => name,
      "headline"  => "#{@role.title} | Le Wagon Graduate",
      "email"     => "",
      "phone"     => "",
      "linkedin"  => "",
      "location"  => "",
      "summary"   => "Le Wagon bootcamp graduate transitioning to #{@role.title}.",
      "skills"    => { "technical" => [], "soft" => [] },
      "experience" => [],
      "education" => [
        { "degree" => "Full-Stack Web Development", "institution" => "Le Wagon", "year" => Time.current.year.to_s, "highlights" => [] }
      ],
      "projects"  => []
    }
  end
end
