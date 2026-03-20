// ─── Global functions (via window — required because importmap uses ES modules) ─

window.toggleTag = function(el) {
  el.classList.toggle("active");
};

window.goSetupStep2 = function() {
  document.getElementById("setup-step1").style.display = "none";
  document.getElementById("setup-step2").style.display = "block";
  const s1 = document.getElementById("step1-indicator");
  s1.classList.remove("active");
  s1.classList.add("done");
  s1.querySelector(".ps-circle").innerHTML = "✓";
  document.getElementById("step2-indicator").classList.add("active");
  document.getElementById("ps-line-1").classList.add("done");
};

window.goSetupStep1 = function() {
  document.getElementById("setup-step2").style.display = "none";
  document.getElementById("setup-step1").style.display = "block";
  const s1 = document.getElementById("step1-indicator");
  s1.classList.add("active");
  s1.classList.remove("done");
  s1.querySelector(".ps-circle").innerHTML = "1";
  document.getElementById("step2-indicator").classList.remove("active");
  document.getElementById("ps-line-1").classList.remove("done");
};

window.handleCVUpload = function(input) {
  const file = input.files[0];
  if (file) {
    const fn = document.getElementById("cvFileName");
    fn.textContent = "✓ " + file.name + " uploaded";
    fn.style.display = "block";
  }
};

// ─────────────────────────────────────────────────────────────────────────────

function initWagonUp() {

  // 1. Navbar scroll shadow
  const nav = document.getElementById("wuNav");
  if (nav) {
    window.addEventListener("scroll", () => {
      nav.classList.toggle("scrolled", window.scrollY > 30);
    }, { passive: true });
  }

  // 2. Mobile burger
  const burger = document.getElementById("wuBurger");
  const mobileNav = document.getElementById("wuMobileNav");
  if (burger && mobileNav) {
    burger.addEventListener("click", () => mobileNav.classList.toggle("open"));
    mobileNav.querySelectorAll("a").forEach(a =>
      a.addEventListener("click", () => mobileNav.classList.remove("open"))
    );
  }

  // 3. Avatar dropdown
  const avatarBtn = document.getElementById("wuAvatarBtn");
  const avatarDrop = document.getElementById("wuAvatarDrop");
  if (avatarBtn && avatarDrop) {
    avatarBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      avatarDrop.classList.toggle("open");
    });
    document.addEventListener("click", () => avatarDrop.classList.remove("open"));
  }

  // 4. Scroll reveal
  const srEls = document.querySelectorAll(".sr");
  if (srEls.length) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(e => { if (e.isIntersecting) e.target.classList.add("up"); });
    }, { threshold: 0.1 });
    srEls.forEach(el => observer.observe(el));
  }

  // 6. CV drop zone — drag support (click handled by onclick in HTML)
  const dropZone = document.querySelector(".drop-zone");
  if (dropZone) {
    dropZone.addEventListener("dragover", (e) => {
      e.preventDefault();
      dropZone.style.borderColor = "#6C3EF4";
    });
    dropZone.addEventListener("dragleave", () => {
      dropZone.style.borderColor = "";
    });
    dropZone.addEventListener("drop", (e) => {
      e.preventDefault();
      dropZone.style.borderColor = "";
      const file = e.dataTransfer.files[0];
      if (file && file.type === "application/pdf") {
        const cvInput = document.getElementById("cvInput");
        const fn = document.getElementById("cvFileName");
        if (cvInput) {
          const dt = new DataTransfer();
          dt.items.add(file);
          cvInput.files = dt.files;
        }
        if (fn) { fn.textContent = "✓ " + file.name + " uploaded"; fn.style.display = "block"; }
      }
    });
  }

  // 8. Progress bars
  setTimeout(() => {
    document.querySelectorAll(".wu-progress-fill[data-width]").forEach(bar => {
      bar.style.width = bar.dataset.width;
    });
  }, 400);

  // 9. Copy prompt
  const copyBtn = document.getElementById("copyPromptBtn");
  const promptText = document.getElementById("promptText");
  if (copyBtn && promptText) {
    copyBtn.addEventListener("click", () => {
      navigator.clipboard.writeText(promptText.innerText).then(() => {
        const orig = copyBtn.textContent;
        copyBtn.textContent = "Copied! ✓";
        setTimeout(() => { copyBtn.textContent = orig; }, 2000);
      });
    });
  }

  // 10. Sidebar toggle
  const sidebarToggle = document.getElementById("wuSidebarToggle");
  const sidebar = document.getElementById("wuSidebar");
  if (sidebarToggle && sidebar) {
    sidebarToggle.addEventListener("click", () => {
      sidebar.classList.toggle("collapsed");
      const collapsed = sidebar.classList.contains("collapsed");
      sidebarToggle.textContent = collapsed ? "›" : "‹";
      sidebarToggle.style.left = collapsed ? "8px" : "268px";
    });
  }

  // 11. Chat
  const chatMessages = document.getElementById("wuChatMessages");
  const chatInput = document.getElementById("wuChatInput");
  const sendBtn = document.getElementById("wuSendBtn");
  const qCount = document.getElementById("wuQCount");

  const chloeReplies = [
    "Great start! Can you tell me more about how you applied that in a real project?",
    "Interesting — I like that you're drawing on your previous experience. Let me push a bit further: what was the hardest part of that transition?",
    "Good answer! For a technical interview, try to quantify the impact where possible. What metrics did you have?",
    "That's a solid response. One tip: use the STAR method to structure it — Situation, Task, Action, Result. Want to try again with that framework?"
  ];
  let replyIndex = 0;
  let questionCount = 0;

  function appendMessage(role, html) {
    const wrap = document.createElement("div");
    wrap.className = "wu-msg " + role;

    if (role === "bot") {
      const avatar = document.createElement("div");
      avatar.className = "wu-chloe-avatar";
      avatar.style.cssText = "width:32px;height:32px;font-size:.85rem;flex-shrink:0";
      avatar.textContent = "🤖";
      wrap.appendChild(avatar);
    }

    const bubble = document.createElement("div");
    bubble.className = "wu-msg-bubble";
    bubble.innerHTML = html;
    wrap.appendChild(bubble);

    chatMessages.appendChild(wrap);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    return wrap;
  }

  function sendMessage() {
    if (!chatInput || !chatMessages) return;
    const val = chatInput.value.trim();
    if (!val) return;
    chatInput.value = "";
    chatInput.style.height = "auto";

    appendMessage("user", val);

    const typing = appendMessage("bot", "<em style='color:var(--ink-3)'>Chloe is thinking…</em>");

    setTimeout(() => {
      typing.querySelector(".wu-msg-bubble").innerHTML = chloeReplies[replyIndex % chloeReplies.length];
      replyIndex++;
      questionCount = Math.min(questionCount + 1, 5);
      if (qCount) qCount.textContent = questionCount + "/5";
      chatMessages.scrollTop = chatMessages.scrollHeight;
    }, 1200);
  }

  if (sendBtn) sendBtn.addEventListener("click", sendMessage);
  if (chatInput) {
    chatInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); sendMessage(); }
    });
    chatInput.addEventListener("input", () => {
      chatInput.style.height = "auto";
      chatInput.style.height = Math.min(chatInput.scrollHeight, 120) + "px";
    });
  }

  // 12. New session
  document.querySelectorAll(".wu-new-session").forEach(btn => {
    btn.addEventListener("click", () => {
      if (!chatMessages) return;
      chatMessages.innerHTML = "";
      replyIndex = 0;
      questionCount = 0;
      if (qCount) qCount.textContent = "0/5";

      appendMessage("bot", "Hi! I'm Chloe, your AI interview coach. Ready to start a new session?");
    });
  });

}

document.addEventListener("DOMContentLoaded", initWagonUp);
document.addEventListener("turbo:load", initWagonUp);
