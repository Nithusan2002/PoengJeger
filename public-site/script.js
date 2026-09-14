const year = document.getElementById("year");
if (year) year.textContent = new Date().getFullYear();

document.querySelectorAll(".mobile-menu a").forEach((link) => {
  link.addEventListener("click", () => link.closest("details")?.removeAttribute("open"));
});

const waitlistForm = document.getElementById("waitlist-form");
const waitlistStatus = document.getElementById("waitlist-status");

function setWaitlistStatus(message, state = "") {
  waitlistStatus.textContent = message;
  if (state) waitlistStatus.dataset.state = state;
  else delete waitlistStatus.dataset.state;
}

waitlistForm?.addEventListener("submit", async (event) => {
  event.preventDefault();

  const endpoint = window.POENGJEGER_CONFIG?.waitlistEndpoint;
  const data = new FormData(waitlistForm);
  const email = String(data.get("email") || "").trim();
  const consent = data.get("consent") === "on";
  const company = String(data.get("company") || "");
  const button = waitlistForm.querySelector("button[type='submit']");

  if (!waitlistForm.checkValidity()) {
    waitlistForm.reportValidity();
    return;
  }

  if (!endpoint) {
    setWaitlistStatus("Interesselisten klargjøres fortsatt. Prøv igjen litt senere.", "error");
    return;
  }

  button.disabled = true;
  setWaitlistStatus("Registrerer …");

  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, consent, company, source: "nithusan.no/poengjeger" })
    });

    const result = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(result.error || "Kunne ikke registrere e-postadressen.");

    waitlistForm.reset();
    setWaitlistStatus("Takk! Du får beskjed når Poengjeger er klar.", "success");
  } catch (error) {
    setWaitlistStatus(error.message || "Noe gikk galt. Prøv igjen senere.", "error");
  } finally {
    button.disabled = false;
  }
});
