import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "send", "form"]

  connect() {
    this.scrollToBottom()
    if (this.hasMessagesTarget) {
      this.observer = new MutationObserver(() => this.scrollToBottom())
      this.observer.observe(this.messagesTarget, { childList: true })
    }
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  resize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 120) + "px"
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.handleSubmit()
    }
  }

  clickSend() {
    this.handleSubmit()
  }

  handleSubmit() {
    if (!this.hasInputTarget || !this.hasFormTarget) return
    const val = this.inputTarget.value.trim()
    if (!val) return

    this.appendUserMessage(val)
    this.showTyping()
    this.formTarget.requestSubmit()
    this.inputTarget.value = ""
    this.inputTarget.style.height = "auto"
  }

  appendUserMessage(text) {
    const wrap = document.createElement("div")
    wrap.className = "wu-msg user wu-msg-new"
    const bubble = document.createElement("div")
    bubble.className = "wu-msg-bubble"
    bubble.textContent = text
    wrap.appendChild(bubble)
    this.messagesTarget.appendChild(wrap)
    this.scrollToBottom()
  }

  showTyping() {
    const existing = document.getElementById("chloe-typing")
    if (existing) existing.remove()

    const wrap = document.createElement("div")
    wrap.className = "wu-msg bot"
    wrap.id = "chloe-typing"
    wrap.innerHTML = `
      <div class="wu-chloe-avatar" style="width:32px;height:32px;font-size:.85rem;flex-shrink:0">🤖</div>
      <div class="wu-msg-bubble wu-typing"><span></span><span></span><span></span></div>
    `
    this.messagesTarget.appendChild(wrap)
    this.scrollToBottom()
  }
}
