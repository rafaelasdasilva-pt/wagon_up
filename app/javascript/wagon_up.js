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
  if (sidebarToggle && sidebar && !sidebarToggle.dataset.bound) {
    sidebarToggle.dataset.bound = "1";
    sidebarToggle.addEventListener("click", () => {
      sidebar.classList.toggle("collapsed");
      const collapsed = sidebar.classList.contains("collapsed");
      sidebarToggle.textContent = collapsed ? "›" : "‹";
      sidebarToggle.style.left = collapsed ? "8px" : "268px";
    });
  }

  // 11. Chat — handled by chat_controller.js (Stimulus)

}

document.addEventListener("DOMContentLoaded", initWagonUp);
document.addEventListener("turbo:load", initWagonUp);
