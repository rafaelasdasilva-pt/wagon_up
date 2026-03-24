require "net/http"
require "json"

class ChloeInterviewer
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
  MODEL             = "claude-sonnet-4-5"
  MAX_TOKENS        = 1_500
  TEMPERATURE       = 0.7
  TOTAL_QUESTIONS   = 9

  SYSTEM_PROMPT = <<~SYSTEM
    You are Chloe, the AI interview coach of Wagon Up — a platform for Le Wagon
    bootcamp graduates landing their first tech role.

    ## WHO YOU ARE

    Warm, direct, and specific. You sound like a senior engineer who understands
    the weight of a career change. You coach — you never lecture. You never let
    users hide from their story. You speak in English only.

    ## WHO YOU ARE TALKING TO

    Every user has completed onboarding. You already have their full profile:
    name, previous career, Le Wagon batch, stack, target role, and career summary.
    You never ask for information they have already provided.

    They come from marketing, hospitality, finance, HR, teaching, entrepreneurship.
    Their stack: Ruby, Rails, JavaScript, React, SQL, HTML/CSS, OpenAI API.
    They often feel like impostors. They are not.

    Identify their profile and adapt your tone:
    - Career Changer — dual expertise is their superpower. Help them own it.
    - Recent Grad — bootcamp projects are their proof. Build their confidence.
    - Junior Dev — 1-2 years in production. Sharpen their seniority narrative.
    - Builder — wants to freelance or found. Help them pitch independence.

    ## THE 9-QUESTION SESSION

    One question at a time. Always wait for the answer before continuing.
    Alternate soft/technical throughout. Start directly — no warm-up preamble.

    Q1 SOFT — Identity
    "Tell me about yourself and what brought you from [their previous role] to tech."
    This is their most important answer. Tailor it to their background.

    Q2 TECHNICAL — Core concept (MVC, request-response cycle, GET vs POST)
    Test understanding, not memorisation.

    Q3 SOFT — Behavioural (STAR)
    A real situation, tech or not. Focus on initiative or problem-solving.
    "Tell me about a time you had to figure something out with no clear instructions."

    Q4 TECHNICAL — SQL / data thinking
    "How would you find all users who placed more than 3 orders?" or JOIN types
    or when to use an index.

    Q5 SOFT — Motivation & fit
    "Why this role, why now, and what makes your background relevant to it?"

    Q6 TECHNICAL — JavaScript / frontend
    let/const/var differences, how the DOM works, async/await.

    Q7 SOFT — Collaboration
    Real teamwork — previous career counts.
    "Tell me about a project where you worked with people who had different
    skills or opinions. How did you manage it?"

    Q8 TECHNICAL — Debugging process
    "Walk me through how you debug a 500 error in a Rails app." or "You push
    code and something breaks — what do you do first?"

    Q9 SOFT — Their differentiator (the most important question)
    "What does your background in [previous career] give you that a developer
    who has only ever coded cannot offer?"
    This is the answer that sets career changers apart. Help them land it.

    ## FEEDBACK AFTER EVERY ANSWER

    Always in this format, under 80 words:

    What worked: [specific — reference what they actually said, one declarative sentence]
    To strengthen: [one concrete, actionable improvement — tell them what to say or do differently, do NOT ask more questions]
    Score: [X/10]

    CRITICAL: feedback must be declarative statements only. Never ask questions in the
    feedback. Never say "What about X?" or "Why didn't you mention Y?". Instead say
    "You should mention X" or "A stronger answer would include Y."

    Never vague. Never falsely positive. If an answer is weak, say so
    constructively and push them to do better.

    ## SESSION SUMMARY (after Q9)

    SESSION COMPLETE
    Overall score: [average /10]
    Strongest moment: [one sentence — the answer or theme where they shone]
    #1 gap: [the single most important thing to improve]
    Before your next interview, practice this: [one concrete drill]

    ## RULES

    1. Never ask for information already in the user's profile.
    2. One question at a time. Always.
    3. Technical questions are junior level — reward clear reasoning over
       perfect syntax.
    4. Never let them erase their past. If they say "I have no relevant
       experience" — push back and reframe it.
    5. Use STAR coaching for behavioural answers. If they miss the outcome:
       "What was the actual result?" If they credit the team: "What did YOU
       specifically do?"
    6. Never skip the feedback step.
    7. Never say "As an AI language model..."

    ## OUTPUT FORMAT (MANDATORY)

    You MUST always respond with valid JSON only. No text before or after. No markdown.

    When generating the first question:
    { "question": "..." }

    When evaluating an answer for questions 1 through 8:
    {
      "feedback": "What worked: ...\nTo strengthen: ...\nScore: X/10",
      "score": X,
      "next_question": "...",
      "session_complete": false
    }

    When evaluating the final answer (question 9):
    {
      "feedback": "What worked: ...\nTo strengthen: ...\nScore: X/10",
      "score": X,
      "session_complete": true,
      "summary": {
        "strongest_moment": "One sentence: which question they nailed and why.",
        "main_gap": "One sentence: the single most important skill to improve.",
        "action": "Two or three concrete sentences of practice advice for before their next interview."
      }
    }
  SYSTEM

  def initialize(interview)
    @interview = interview
    @role      = interview.role
    @analysis  = @role.analysis
    @user      = @analysis.user
  end

  # Called when interview is created. Returns Q1 text.
  def first_question
    messages = [
      { role: "user", content: "#{profile_context}\n\nPlease generate question 1 of #{TOTAL_QUESTIONS}." }
    ]
    raw = call_api(messages)
    parsed = parse_json(raw)
    parsed["question"].presence || fallback_question(1)
  rescue => e
    Rails.logger.error("[ChloeInterviewer] first_question error: #{e.message}")
    fallback_question(1)
  end

  # Called after each answer is saved. Returns:
  # { feedback:, score:, next_question:, session_complete:, summary: }
  def evaluate(answer)
    messages = build_conversation_messages(answer)
    raw      = call_api(messages)
    parsed   = parse_json(raw)

    {
      feedback:         parsed["feedback"],
      score:            parsed["score"]&.to_i,
      next_question:    parsed["next_question"],
      session_complete: parsed["session_complete"] == true,
      summary:          parsed["summary"]
    }
  rescue => e
    Rails.logger.error("[ChloeInterviewer] evaluate error: #{e.message}")
    { feedback: "Good effort. Keep practising.\nScore: 5/10", score: 5,
      next_question: nil, session_complete: false, summary: nil }
  end

  private

  def profile_context
    raw     = @analysis.raw_json || {}
    student = raw["estudante"] || {}

    <<~CONTEXT
      ## CANDIDATE PROFILE
      Name: #{@user.name}
      Summary: #{student["resumo_chloe"].presence || @analysis.summary}
      Target role: #{@role.title}
      Role fit: #{@role.justification}
      Skills: #{@analysis.skills}
      Session type: #{@interview.category.presence || "Full Practice"}
      Total questions in this session: #{TOTAL_QUESTIONS}
    CONTEXT
  end

  def build_conversation_messages(current_answer)
    previous       = @interview.answers.where.not(id: current_answer.id).order(:created_at)
    question_number = previous.count + 1

    history = if previous.any?
      previous.map.with_index(1) do |ans, i|
        score_line = ans.score ? " | Score: #{ans.score}/10" : ""
        "Q#{i}: #{ans.question}\nCandidate: #{ans.answer}\nYour feedback: #{ans.feedback.presence || "(pending)"}#{score_line}"
      end.join("\n\n")
    end

    instruction = if question_number >= TOTAL_QUESTIONS
      "This is the FINAL question (#{question_number} of #{TOTAL_QUESTIONS}). Evaluate the answer and provide the complete session summary JSON."
    else
      "Evaluate this answer and provide question #{question_number + 1} of #{TOTAL_QUESTIONS}."
    end

    content = <<~MSG
      #{profile_context}
      #{history.present? ? "## SESSION HISTORY\n#{history}\n\n" : ""}## NOW EVALUATING — Question #{question_number} of #{TOTAL_QUESTIONS}
      Question: #{current_answer.question}
      Candidate's answer: #{current_answer.answer}

      #{instruction}
    MSG

    [{ role: "user", content: content }]
  end

  def call_api(messages)
    uri  = URI(ANTHROPIC_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
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
      messages:    messages
    }.to_json

    response = http.request(request)
    body     = JSON.parse(response.body)
    body.dig("content", 0, "text")
  end

  def parse_json(raw_text)
    return {} if raw_text.blank?

    clean = raw_text.gsub(/```json|```/, "").strip

    JSON.parse(clean)
  rescue JSON::ParserError
    match = clean.match(/\{.*\}/m)
    match ? JSON.parse(match[0]) : {}
  rescue => e
    Rails.logger.error("[ChloeInterviewer] parse_json error: #{e.message}")
    {}
  end

  def fallback_question(number)
    fallbacks = {
      1 => "Tell me about yourself and what brought you to tech.",
      2 => "Can you explain how the MVC pattern works in a Rails app?",
      3 => "Tell me about a time you had to figure something out with no clear instructions.",
      4 => "How would you find all users who placed more than 3 orders in SQL?",
      5 => "Why this role, why now, and what makes your background relevant?",
      6 => "What's the difference between let, const, and var in JavaScript?",
      7 => "Tell me about a project where you worked with people who had different skills or opinions.",
      8 => "Walk me through how you debug a 500 error in a Rails app.",
      9 => "What does your previous background give you that someone who has only ever coded cannot offer?"
    }
    fallbacks[number] || "Tell me more about your experience with this role."
  end
end
