import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input"]
  static values = { roleId: Number, interviewId: Number }

  connect() {
    this.scrollToBottom()
    console.log("Chat controller connected — roleId:", this.roleIdValue, "interviewId:", this.interviewIdValue)
  }

  // new.html.erb — cria a entrevista e obtém a primeira pergunta
  async start(event) {
    event.preventDefault()
    const text = this.inputTarget.value.trim()
    if (!text) return

    this.clearInput()
    this.disableInput()
    this.appendUser(text)
    const loadingId = this.appendLoading()

    try {
      const data = await this.request("POST", `/roles/${this.roleIdValue}/interviews`, {})
      this.removeLoading(loadingId)

      if (data.first_question) this.appendBot(data.first_question)

      // Actualiza o controller para modo resposta
      this.interviewIdValue = data.interview_id
      this.inputTarget.dataset.action = "keydown.enter->chat#answer:prevent"
      this.element.querySelector("[data-action='click->chat#start']").dataset.action = "click->chat#answer"
      this.enableInput()
    } catch (e) {
      this.removeLoading(loadingId)
      this.appendBot("Sorry, there was an error starting the interview. Please try again.")
      console.error("start() error:", e)
      this.enableInput()
    }
  }

  // show.html.erb — envia resposta e obtém feedback + próxima pergunta
  async answer(event) {
    event.preventDefault()
    const text = this.inputTarget.value.trim()
    if (!text) return

    this.clearInput()
    this.disableInput()
    this.appendUser(text)
    const loadingId = this.appendLoading()

    try {
      const data = await this.request("PATCH", `/interviews/${this.interviewIdValue}`, { answer: text })
      this.removeLoading(loadingId)

      if (data.feedback) this.appendBot(data.feedback, data.score)

      if (data.finished) {
        this.replaceInputWithResults(data.results_url)
      } else if (data.next_question) {
        this.appendBot(data.next_question)
        this.enableInput()
      }
    } catch {
      this.removeLoading(loadingId)
      this.appendBot("Sorry, something went wrong. Please try again.")
      this.enableInput()
    }
  }

  // ── DOM helpers ──────────────────────────────────────────────────────────

  appendBot(content, score = null) {
    const scoreHtml = score
      ? `<span style="display:inline-block;background:var(--brand-pale);color:var(--brand);font-size:.72rem;font-weight:700;padding:2px 8px;border-radius:100px;margin-bottom:.4rem">Score: ${score}/10</span><br>`
      : ""
    this.appendMessage("bot", `
      <div class="wu-chloe-avatar" style="width:56px;height:56px;flex-shrink:0"><img src="/assets/chloe_avatar.png" alt="Chloe" style="width:100%;height:100%;object-fit:cover;border-radius:50%;transform:scale(1.36)"></div>
      <div class="wu-msg-bubble">${scoreHtml}${this.escapeHtml(content)}</div>
    `)
  }

  appendUser(content) {
    this.appendMessage("user", `<div class="wu-msg-bubble">${this.escapeHtml(content)}</div>`)
  }

  appendLoading() {
    const id = `loading-${Date.now()}`
    const div = this.appendMessage("bot", `
      <div class="wu-chloe-avatar" style="width:56px;height:56px;flex-shrink:0"><img src="/assets/chloe_avatar.png" alt="Chloe" style="width:100%;height:100%;object-fit:cover;border-radius:50%;transform:scale(1.36)"></div>
      <div class="wu-msg-bubble" style="opacity:.5;font-style:italic">Chloe is thinking...</div>
    `)
    div.id = id
    return id
  }

  appendMessage(type, innerHtml) {
    const div = document.createElement("div")
    div.className = `wu-msg ${type}`
    div.innerHTML = innerHtml
    this.messagesTarget.appendChild(div)
    this.scrollToBottom()
    return div
  }

  removeLoading(id) {
    document.getElementById(id)?.remove()
  }

  replaceInputWithResults(url) {
    const row = this.element.querySelector(".wu-chat-input-row")
    if (row) {
      row.innerHTML = `<a href="${url}" class="btn-wu btn-wu-primary">See full results →</a>`
      row.style.justifyContent = "center"
    }
  }

  clearInput()   { this.inputTarget.value = ""; this.inputTarget.style.height = "auto" }
  disableInput() { this.inputTarget.disabled = true }
  enableInput()  { this.inputTarget.disabled = false; this.inputTarget.focus() }
  scrollToBottom() { if (this.hasMessagesTarget) this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight }

  escapeHtml(text) {
    const d = document.createElement("div")
    d.textContent = text
    return d.innerHTML
  }

  async request(method, url, body) {
    const res = await fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content ?? "",
        "Accept": "application/json"
      },
      body: JSON.stringify(body)
    })
    if (!res.ok) {
      const text = await res.text().catch(() => "")
      console.error(`Chat fetch error ${res.status}:`, text)
      throw new Error(`HTTP ${res.status}`)
    }
    return res.json()
  }
}
