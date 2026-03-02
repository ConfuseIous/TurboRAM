
// Intersection Observer — stagger-animate feature cards into view
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry, i) => {
      if (entry.isIntersecting) {
        const card = entry.target;
        card.style.animationDelay = `${i * 0.06}s`;
        card.classList.add("visible");
        observer.unobserve(card);
      }
    });
  },
  { threshold: 0.12 }
);

document.querySelectorAll(".feature-card").forEach((card) => {
  observer.observe(card);
});

// Add subtle background particles
function addParticles() {
  const container = document.querySelector(".particles");
  if (!container) return;
  for (let i = 0; i < 20; i++) {
    const p = document.createElement("div");
    p.className = "particle";
    p.style.left = Math.random() * 100 + "%";
    p.style.top = Math.random() * 100 + "%";
    p.style.animationDelay = Math.random() * 6 + "s";
    p.style.animationDuration = Math.random() * 3 + 3 + "s";
    container.appendChild(p);
  }
}
addParticles();

// Dynamic footer year
const yearEl = document.getElementById("footer-year");
if (yearEl) yearEl.textContent = new Date().getFullYear();
