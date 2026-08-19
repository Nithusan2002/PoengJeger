(function () {
  "use strict";

  const CONFIG = window.ADMIN_TOOL_CONFIG || {};
  const STORAGE_KEY = "poengjeger_admin_session";
  const SESSION_REFRESH_MARGIN_SECONDS = 60;
  const CAMPAIGN_STATUS_LABELS = {
    draft: "Draft",
    published: "Published",
    archived: "Archived",
    review: "Review",
    expired: "Expired"
  };
  const PROGRAM_GUIDE_STATUS_LABELS = {
    draft: "Draft",
    published: "Published",
    archived: "Archived"
  };
  const STATUS_LABELS = {
    new: "Ny",
    needs_review: "Trenger review",
    approved: "Godkjent",
    rejected: "Avvist",
    promoted: "Promotert"
  };

  const state = {
    session: loadSession(),
    role: null,
    candidates: [],
    campaigns: [],
    programGuides: [],
    categories: [],
    programs: [],
    sources: [],
    selectedCandidateId: null,
    selectedCampaignId: null,
    selectedProgramGuideProgramId: null,
    activePanelId: "queue-panel",
    loading: false,
    sessionRefreshPromise: null
  };

  const elements = {
    authPanel: document.querySelector("#auth-panel"),
    authMessage: document.querySelector("#auth-message"),
    campaignDetailPanel: document.querySelector("#campaign-detail-panel"),
    campaignList: document.querySelector("#campaign-list"),
    campaignMessage: document.querySelector("#campaign-message"),
    campaignPanel: document.querySelector("#campaign-panel"),
    campaignRefreshButton: document.querySelector("#campaign-refresh-button"),
    campaignStatusFilter: document.querySelector("#campaign-status-filter"),
    detailPanel: document.querySelector("#detail-panel"),
    emailInput: document.querySelector("#email-input"),
    ingestButton: document.querySelector("#ingest-button"),
    ingestLimitInput: document.querySelector("#ingest-limit-input"),
    ingestSourceSelect: document.querySelector("#ingest-source-select"),
    loginButton: document.querySelector("#login-button"),
    loginForm: document.querySelector("#login-form"),
    passwordInput: document.querySelector("#password-input"),
    programGuideDetailPanel: document.querySelector("#program-guide-detail-panel"),
    programGuideList: document.querySelector("#program-guide-list"),
    programGuideMessage: document.querySelector("#program-guide-message"),
    programGuidePanel: document.querySelector("#program-guide-panel"),
    programGuideRefreshButton: document.querySelector("#program-guide-refresh-button"),
    queueList: document.querySelector("#queue-list"),
    queueMessage: document.querySelector("#queue-message"),
    queuePanel: document.querySelector("#queue-panel"),
    refreshButton: document.querySelector("#refresh-button"),
    sessionPill: document.querySelector("#session-pill"),
    signOutButton: document.querySelector("#sign-out-button"),
    statusFilter: document.querySelector("#status-filter")
  };
  elements.workspaceNav = document.querySelector("#workspace-nav");
  elements.workspaceNavButtons = Array.from(document.querySelectorAll("[data-panel-target]"));

  elements.loginForm.addEventListener("submit", onLoginSubmit);
  elements.ingestButton.addEventListener("click", runIngestionFromAdmin);
  elements.refreshButton.addEventListener("click", refreshQueue);
  elements.campaignRefreshButton.addEventListener("click", refreshCampaigns);
  elements.programGuideRefreshButton.addEventListener("click", refreshProgramGuides);
  elements.signOutButton.addEventListener("click", signOut);
  elements.statusFilter.addEventListener("change", refreshQueue);
  elements.campaignStatusFilter.addEventListener("change", refreshCampaigns);
  elements.workspaceNavButtons.forEach((button) => {
    button.addEventListener("click", function () {
      setActivePanel(button.getAttribute("data-panel-target"));
    });
  });

  if (!hasConfig()) {
    setMessage(
      elements.authMessage,
      "Mangler lokal konfigurasjon. Opprett admin-tool/config.local.js fra config.example.js og sett SUPABASE-data.",
      "error"
    );
    elements.loginButton.disabled = true;
  } else if (state.session) {
    initializeAuthenticatedFlow();
  } else {
    renderUnauthenticated();
    setMessage(elements.authMessage, "Logg inn med en Supabase-bruker som har admin- eller editorrolle.", "muted");
  }

  function hasConfig() {
    return Boolean(CONFIG.supabaseUrl && CONFIG.supabasePublishableKey);
  }

  async function onLoginSubmit(event) {
    event.preventDefault();

    if (!hasConfig()) {
      return;
    }

    const email = elements.emailInput.value.trim();
    const password = elements.passwordInput.value;

    if (!email || !password) {
      setMessage(elements.authMessage, "E-post og passord må fylles ut.", "error");
      return;
    }

    setAuthLoading(true);
    setMessage(elements.authMessage, "Logger inn...", "muted");

    try {
      const session = await authRequest("/auth/v1/token?grant_type=password", {
        method: "POST",
        body: {
          email,
          password
        }
      });

      state.session = normalizeSessionPayload(session, email);
      persistSession();

      elements.passwordInput.value = "";
      await initializeAuthenticatedFlow();
    } catch (error) {
      clearSession();
      renderUnauthenticated();
      setMessage(elements.authMessage, error.message, "error");
    } finally {
      setAuthLoading(false);
    }
  }

  async function initializeAuthenticatedFlow() {
    if (!state.session) {
      renderUnauthenticated();
      return;
    }

    renderAuthenticatedShell();
    setMessage(elements.queueMessage, "Laster session, rolle og kandidater...", "muted");

    try {
      await ensureSession();
      state.role = await fetchRole();

      if (!state.role || (state.role !== "admin" && state.role !== "editor")) {
        throw new Error("Brukeren mangler intern admin- eller editorrolle.");
      }

      renderSessionPill();
      await fetchReferenceData();
      await Promise.all([refreshQueue(), refreshCampaigns(), refreshProgramGuides()]);
    } catch (error) {
      clearSession();
      renderUnauthenticated();
      setMessage(elements.authMessage, error.message, "error");
    }
  }

  async function fetchReferenceData() {
    const [programs, categories, sources] = await Promise.all([
      fetchPrograms(),
      fetchCategories(),
      fetchSources()
    ]);

    state.programs = programs;
    state.categories = categories;
    state.sources = sources;
  }

  async function refreshQueue() {
    if (!state.session) {
      renderUnauthenticated();
      return;
    }

    state.loading = true;
    elements.refreshButton.disabled = true;
    setMessage(elements.queueMessage, "Laster kandidatkø...", "muted");

    try {
      const status = elements.statusFilter.value;
      state.candidates = await fetchQueue(status);

      if (!state.candidates.length) {
        state.selectedCandidateId = null;
        renderQueue();
        renderEmptyDetail("Ingen kandidater matcher filteret akkurat nå.");
        setMessage(elements.queueMessage, "Ingen kandidater i valgt filter.", "muted");
        return;
      }

      if (!state.candidates.some((candidate) => candidate.id === state.selectedCandidateId)) {
        state.selectedCandidateId = state.candidates[0].id;
      }

      renderQueue();
      renderDetail();
      setMessage(
        elements.queueMessage,
        `Viser ${state.candidates.length} kandidat${state.candidates.length === 1 ? "" : "er"}.`,
        "success"
      );
    } catch (error) {
      setMessage(elements.queueMessage, error.message, "error");
      renderEmptyDetail("Kunne ikke laste kandidatdetaljer.");
    } finally {
      state.loading = false;
      elements.refreshButton.disabled = false;
    }
  }

  async function refreshCampaigns() {
    if (!state.session) {
      renderUnauthenticated();
      return;
    }

    elements.campaignRefreshButton.disabled = true;
    setMessage(elements.campaignMessage, "Laster kampanjer...", "muted");

    try {
      const status = elements.campaignStatusFilter.value;
      state.campaigns = await fetchCampaigns(status);

      if (!state.campaigns.length) {
        state.selectedCampaignId = null;
        renderCampaignList();
        renderEmptyCampaignDetail("Ingen kampanjer matcher filteret ennå.");
        setMessage(elements.campaignMessage, "Ingen kampanjer i valgt filter.", "muted");
        return;
      }

      if (!state.campaigns.some((campaign) => campaign.id === state.selectedCampaignId)) {
        state.selectedCampaignId = state.campaigns[0].id;
      }

      renderCampaignList();
      renderCampaignDetail();
      setMessage(
        elements.campaignMessage,
        `Viser ${state.campaigns.length} kampanje${state.campaigns.length === 1 ? "" : "r"}.`,
        "success"
      );
    } catch (error) {
      setMessage(elements.campaignMessage, error.message, "error");
      renderEmptyCampaignDetail("Kunne ikke laste kampanjer.");
    } finally {
      elements.campaignRefreshButton.disabled = false;
    }
  }

  async function refreshProgramGuides() {
    if (!state.session) {
      renderUnauthenticated();
      return;
    }

    elements.programGuideRefreshButton.disabled = true;
    setMessage(elements.programGuideMessage, "Laster programguider...", "muted");

    try {
      state.programGuides = await fetchProgramGuides();

      if (!state.programs.length) {
        state.selectedProgramGuideProgramId = null;
        renderProgramGuideList();
        renderEmptyProgramGuideDetail("Ingen bonusprogrammer er tilgjengelige.");
        setMessage(elements.programGuideMessage, "Ingen programmer å vise.", "muted");
        return;
      }

      if (!state.programs.some((program) => program.id === state.selectedProgramGuideProgramId)) {
        state.selectedProgramGuideProgramId = state.programs[0].id;
      }

      renderProgramGuideList();
      renderProgramGuideDetail();
      setMessage(
        elements.programGuideMessage,
        `Viser ${state.programs.length} program${state.programs.length === 1 ? "" : "mer"}.`,
        "success"
      );
    } catch (error) {
      setMessage(elements.programGuideMessage, error.message, "error");
      renderEmptyProgramGuideDetail("Kunne ikke laste programguider.");
    } finally {
      elements.programGuideRefreshButton.disabled = false;
    }
  }

  async function runIngestionFromAdmin() {
    if (!state.session) {
      renderUnauthenticated();
      return;
    }

    const source = elements.ingestSourceSelect.value;
    const limit = clampIngestionLimit(elements.ingestLimitInput.value);
    const originalLabel = elements.ingestButton.textContent;

    elements.ingestLimitInput.value = String(limit);
    elements.ingestButton.disabled = true;
    elements.ingestButton.textContent = "Henter...";
    setMessage(elements.queueMessage, `Henter nye kandidater fra ${ingestSourceLabel(source)}...`, "muted");

    try {
      const params = new URLSearchParams({
        source,
        limit: String(limit)
      });
      const result = await functionRequest(`/ingest-campaign-candidates?${params.toString()}`, {
        method: "POST"
      });

      await refreshQueue();
      setMessage(elements.queueMessage, summarizeIngestionResult(result, source), "success");
    } catch (error) {
      setMessage(elements.queueMessage, error.message, "error");
    } finally {
      elements.ingestButton.disabled = false;
      elements.ingestButton.textContent = originalLabel;
    }
  }

  async function fetchQueue(status) {
    const params = new URLSearchParams();
    params.set(
      "select",
      [
        "id",
        "status",
        "detected_at",
        "source_url",
        "title",
        "summary",
        "reviewed_at",
        "review_note",
        "promoted_campaign_id",
        "ingest_kind",
        "source_name",
        "suggested_program_name",
        "suggested_category_name"
      ].join(",")
    );
    params.set("order", "detected_at.desc");

    if (status) {
      params.set("status", `eq.${status}`);
    }

    const response = await apiRequest(`/rest/v1/admin_ingestion_candidate_queue?${params.toString()}`);

    return response.map(normalizeCandidate);
  }

  async function fetchRole() {
    const response = await apiRequest("/rest/v1/rpc/current_editorial_role", {
      method: "POST",
      body: {}
    });

    if (typeof response === "string") {
      return response;
    }

    if (response && typeof response === "object" && typeof response.current_editorial_role === "string") {
      return response.current_editorial_role;
    }

    return null;
  }

  async function fetchPrograms() {
    const params = new URLSearchParams();
    params.set("select", "id,name,slug,is_active");
    params.set("is_active", "eq.true");
    params.set("order", "name.asc");

    return apiRequest(`/rest/v1/bonus_programs?${params.toString()}`);
  }

  async function fetchCategories() {
    const params = new URLSearchParams();
    params.set("select", "id,name,slug");
    params.set("order", "name.asc");

    return apiRequest(`/rest/v1/campaign_categories?${params.toString()}`);
  }

  async function fetchSources() {
    const params = new URLSearchParams();
    params.set("select", "id,name");
    params.set("order", "name.asc");

    return apiRequest(`/rest/v1/campaign_sources?${params.toString()}`);
  }

  async function fetchCampaigns(status) {
    const params = new URLSearchParams();
    params.set(
      "select",
      [
        "id",
        "title",
        "summary",
        "details",
        "status",
        "last_verified_at",
        "primary_program_id",
        "category_id",
        "editorial_summary",
        "updated_at",
        "campaign_editorial_assessments(id,score,decision_label,decision_summary,best_for,not_for,reason_why_it_matters,estimated_value_text,difficulty_level,availability_scope,risk_note)",
        "campaign_source_references(id,source_id,url,title,checked_at,evidence_note)",
        "campaign_requirements(id,text,sort_order)",
        "campaign_programs(program_id)"
      ].join(",")
    );
    params.set("order", "updated_at.desc");

    if (status) {
      params.set("status", `eq.${status}`);
    }

    const response = await apiRequest(`/rest/v1/campaigns?${params.toString()}`);
    return response.map(normalizeCampaign);
  }

  async function fetchProgramGuides() {
    const params = new URLSearchParams();
    params.set(
      "select",
      [
        "id",
        "program_id",
        "status",
        "intro_text",
        "strategy",
        "value_estimate_label",
        "value_estimate_detail",
        "expiration_summary",
        "expiration_detail",
        "earning_tips",
        "redemption_tips",
        "risk_notes",
        "last_reviewed_at",
        "updated_at"
      ].join(",")
    );
    params.set("order", "updated_at.desc");

    const response = await apiRequest(`/rest/v1/program_guides?${params.toString()}`);
    return response.map(normalizeProgramGuide);
  }

  function normalizeCandidate(candidate) {
    return {
      id: candidate.id,
      status: candidate.status,
      detectedAt: candidate.detected_at,
      sourceUrl: candidate.source_url,
      title: candidate.title,
      summary: candidate.summary || "Ingen oppsummering ennå.",
      reviewedAt: candidate.reviewed_at,
      reviewNote: candidate.review_note || "",
      promotedCampaignId: candidate.promoted_campaign_id,
      ingestKind: candidate.ingest_kind,
      sourceName: candidate.source_name,
      suggestedProgramName: candidate.suggested_program_name,
      suggestedCategoryName: candidate.suggested_category_name
    };
  }

  function normalizeCampaign(campaign) {
    const requirements = (campaign.campaign_requirements || [])
      .slice()
      .sort((left, right) => left.sort_order - right.sort_order);
    const editorialAssessment = Array.isArray(campaign.campaign_editorial_assessments)
      ? campaign.campaign_editorial_assessments[0] || null
      : campaign.campaign_editorial_assessments || null;
    const sourceReferences = campaign.campaign_source_references || [];
    const programLinks = campaign.campaign_programs || [];

    return {
      id: campaign.id,
      title: campaign.title || "",
      summary: campaign.summary || "",
      details: campaign.details || "",
      status: campaign.status,
      lastVerifiedAt: campaign.last_verified_at,
      primaryProgramId: campaign.primary_program_id,
      categoryId: campaign.category_id,
      editorialSummary: campaign.editorial_summary || "",
      editorialAssessment: editorialAssessment
        ? {
            id: editorialAssessment.id,
            score: editorialAssessment.score,
            decisionLabel: editorialAssessment.decision_label || "",
            decisionSummary: editorialAssessment.decision_summary || "",
            bestFor: editorialAssessment.best_for || "",
            notFor: editorialAssessment.not_for || "",
            reasonWhyItMatters: editorialAssessment.reason_why_it_matters || "",
            estimatedValueText: editorialAssessment.estimated_value_text || "",
            difficultyLevel: editorialAssessment.difficulty_level || "",
            availabilityScope: editorialAssessment.availability_scope || "",
            riskNote: editorialAssessment.risk_note || ""
          }
        : null,
      updatedAt: campaign.updated_at,
      requirements,
      sourceReferences,
      programLinks
    };
  }

  function normalizeProgramGuide(guide) {
    return {
      id: guide.id,
      programId: guide.program_id,
      status: guide.status,
      introText: guide.intro_text || "",
      strategy: guide.strategy || "",
      valueEstimateLabel: guide.value_estimate_label || "",
      valueEstimateDetail: guide.value_estimate_detail || "",
      expirationSummary: guide.expiration_summary || "",
      expirationDetail: guide.expiration_detail || "",
      earningTips: Array.isArray(guide.earning_tips) ? guide.earning_tips : [],
      redemptionTips: Array.isArray(guide.redemption_tips) ? guide.redemption_tips : [],
      riskNotes: Array.isArray(guide.risk_notes) ? guide.risk_notes : [],
      lastReviewedAt: guide.last_reviewed_at,
      updatedAt: guide.updated_at
    };
  }

  function renderUnauthenticated() {
    elements.authPanel.classList.remove("hidden");
    elements.queuePanel.classList.add("hidden");
    elements.campaignPanel.classList.add("hidden");
    elements.programGuidePanel.classList.add("hidden");
    elements.workspaceNav.classList.add("hidden");
    elements.signOutButton.classList.add("hidden");
    elements.sessionPill.classList.add("hidden");
  }

  function renderAuthenticatedShell() {
    elements.authPanel.classList.add("hidden");
    elements.workspaceNav.classList.remove("hidden");
    elements.signOutButton.classList.remove("hidden");
    elements.sessionPill.classList.remove("hidden");
    setActivePanel(state.activePanelId);
  }

  function setActivePanel(panelId) {
    const validPanelIds = ["queue-panel", "campaign-panel", "program-guide-panel"];
    state.activePanelId = validPanelIds.includes(panelId) ? panelId : "queue-panel";

    [elements.queuePanel, elements.campaignPanel, elements.programGuidePanel].forEach((panel) => {
      panel.classList.toggle("hidden", panel.id !== state.activePanelId);
    });

    elements.workspaceNavButtons.forEach((button) => {
      const isActive = button.getAttribute("data-panel-target") === state.activePanelId;
      button.classList.toggle("active", isActive);
      button.setAttribute("aria-current", isActive ? "page" : "false");
    });
  }

  function renderSessionPill() {
    const email = state.session ? state.session.userEmail : "ukjent";
    const role = state.role ? state.role.toUpperCase() : "UKJENT";
    const expiry = state.session && state.session.expiresAt
      ? ` · utløper ${formatTimeFromUnixSeconds(state.session.expiresAt)}`
      : "";
    elements.sessionPill.textContent = `${email} · ${role}${expiry}`;
  }

  function renderQueue() {
    elements.queueList.innerHTML = "";

    if (!state.candidates.length) {
      return;
    }

    state.candidates.forEach((candidate) => {
      const item = document.createElement("li");
      item.className = "queue-item";
      if (candidate.id === state.selectedCandidateId) {
        item.classList.add("selected");
      }

      item.innerHTML = `
        <div class="badge-row">
          ${renderBadge(candidate.status)}
          ${candidate.suggestedProgramName ? renderMetaBadge(candidate.suggestedProgramName) : ""}
          ${candidate.suggestedCategoryName ? renderMetaBadge(candidate.suggestedCategoryName) : ""}
        </div>
        <h3>${escapeHtml(candidate.title)}</h3>
        <p>${escapeHtml(candidate.summary)}</p>
        <div class="candidate-meta">
          <span>${escapeHtml(candidate.sourceName)}</span>
          <span>•</span>
          <span>${escapeHtml(candidate.ingestKind)}</span>
          <span>•</span>
          <span>${formatDateTime(candidate.detectedAt)}</span>
        </div>
      `;

      item.addEventListener("click", function () {
        state.selectedCandidateId = candidate.id;
        renderQueue();
        renderDetail();
      });

      elements.queueList.appendChild(item);
    });
  }

  function renderCampaignList() {
    elements.campaignList.innerHTML = "";

    if (!state.campaigns.length) {
      return;
    }

    state.campaigns.forEach((campaign) => {
      const item = document.createElement("li");
      item.className = "queue-item";

      if (campaign.id === state.selectedCampaignId) {
        item.classList.add("selected");
      }

      item.innerHTML = `
        <div class="badge-row">
          ${renderCampaignBadge(campaign.status)}
          ${campaign.primaryProgramId ? renderMetaBadge(programName(campaign.primaryProgramId)) : ""}
          ${campaign.categoryId ? renderMetaBadge(categoryName(campaign.categoryId)) : ""}
        </div>
        <h3>${escapeHtml(campaign.title || "Uten tittel")}</h3>
        <p>${escapeHtml(campaign.summary || "Ingen oppsummering ennå.")}</p>
        <div class="candidate-meta">
          <span>Sist oppdatert ${formatDateTime(campaign.updatedAt)}</span>
          <span>•</span>
          <span>${campaign.requirements.length} krav</span>
          <span>•</span>
          <span>${campaign.sourceReferences.length} kilder</span>
        </div>
      `;

      item.addEventListener("click", function () {
        state.selectedCampaignId = campaign.id;
        renderCampaignList();
        renderCampaignDetail();
      });

      elements.campaignList.appendChild(item);
    });
  }

  function renderProgramGuideList() {
    elements.programGuideList.innerHTML = "";

    state.programs.forEach((program) => {
      const guide = guideForProgram(program.id);
      const item = document.createElement("li");
      item.className = "queue-item";

      if (program.id === state.selectedProgramGuideProgramId) {
        item.classList.add("selected");
      }

      item.innerHTML = `
        <div class="badge-row">
          ${renderProgramGuideBadge(guide ? guide.status : "draft")}
          ${renderMetaBadge(program.slug)}
        </div>
        <h3>${escapeHtml(program.name)}</h3>
        <p>${escapeHtml(guide ? firstTextLine(guide.strategy, "Ingen strategi ennå.") : "Ingen guide opprettet ennå.")}</p>
        <div class="candidate-meta">
          <span>${guide ? `Sist oppdatert ${formatDateTime(guide.updatedAt)}` : "Ikke opprettet"}</span>
          <span>•</span>
          <span>${guide && guide.lastReviewedAt ? `Kontrollert ${formatDateTime(guide.lastReviewedAt)}` : "Ikke kontrollert"}</span>
        </div>
      `;

      item.addEventListener("click", function () {
        state.selectedProgramGuideProgramId = program.id;
        renderProgramGuideList();
        renderProgramGuideDetail();
      });

      elements.programGuideList.appendChild(item);
    });
  }

  function renderDetail() {
    const candidate = state.candidates.find((entry) => entry.id === state.selectedCandidateId);

    if (!candidate) {
      renderEmptyDetail("Velg en kandidat for detaljer.");
      return;
    }

    elements.detailPanel.classList.remove("empty");
    elements.detailPanel.innerHTML = `
      <div class="detail-copy">
        <div class="badge-row">
          ${renderBadge(candidate.status)}
          ${candidate.suggestedProgramName ? renderMetaBadge(candidate.suggestedProgramName) : ""}
          ${candidate.suggestedCategoryName ? renderMetaBadge(candidate.suggestedCategoryName) : ""}
        </div>

        <div>
          <h2>${escapeHtml(candidate.title)}</h2>
          <p>${escapeHtml(candidate.summary)}</p>
        </div>

        <section>
          <h3>Metadata</h3>
          <div class="detail-meta">
            <span>Kilde: ${escapeHtml(candidate.sourceName)}</span>
            <span>•</span>
            <span>Ingest: ${escapeHtml(candidate.ingestKind)}</span>
            <span>•</span>
            <span>Oppdaget: ${formatDateTime(candidate.detectedAt)}</span>
          </div>
        </section>

        <section>
          <h3>Kildelenke</h3>
          <a href="${escapeAttribute(candidate.sourceUrl)}" target="_blank" rel="noreferrer">
            ${escapeHtml(candidate.sourceUrl)}
          </a>
        </section>

        <section>
          <h3>Review-notat</h3>
          <textarea id="review-note-input" rows="5" placeholder="Kort note til intern vurdering...">${escapeHtml(
            candidate.reviewNote
          )}</textarea>
        </section>

        ${
          candidate.promotedCampaignId
            ? `<section><h3>Promotert kampanje</h3><p><code>${escapeHtml(candidate.promotedCampaignId)}</code></p><button type="button" class="secondary" data-open-campaign="${escapeAttribute(candidate.promotedCampaignId)}">Åpne draft-editor</button></section>`
            : ""
        }

        <div class="detail-actions">
          <div class="action-row">
            <button type="button" data-action="needs_review">Sett til needs_review</button>
            <button type="button" data-action="approved">Godkjenn</button>
            <button type="button" class="danger" data-action="rejected">Avvis</button>
          </div>
          <div class="action-row">
            <button type="button" class="secondary" data-action="promote">Promoter til draft</button>
          </div>
          <span class="help">Publisering skjer fortsatt separat på kampanjeutkastet.</span>
        </div>
      </div>
    `;

    elements.detailPanel.querySelectorAll("button[data-action]").forEach((button) => {
      button.addEventListener("click", async function () {
        const note = elements.detailPanel.querySelector("#review-note-input").value.trim();
        const action = button.getAttribute("data-action");
        const originalLabel = button.textContent;
        button.disabled = true;
        button.textContent = "Jobber...";

        try {
          if (action === "promote") {
            const campaignId = await apiRequest("/rest/v1/rpc/promote_ingestion_candidate_to_campaign", {
              method: "POST",
              body: {
                p_candidate_id: candidate.id,
                p_review_note: note || null
              }
            });

        state.selectedCampaignId = campaignId;
        await refreshCampaigns();
        setActivePanel("campaign-panel");
          } else {
            await apiRequest("/rest/v1/rpc/set_ingestion_candidate_status", {
              method: "POST",
              body: {
                p_candidate_id: candidate.id,
                p_status: action,
                p_review_note: note || null
              }
            });
          }

          setMessage(elements.queueMessage, "Kandidaten ble oppdatert.", "success");
          await refreshQueue();
        } catch (error) {
          setMessage(elements.queueMessage, error.message, "error");
          button.disabled = false;
          button.textContent = originalLabel;
        }
      });
    });

    const openCampaignButton = elements.detailPanel.querySelector("[data-open-campaign]");
    if (openCampaignButton) {
      openCampaignButton.addEventListener("click", function () {
        state.selectedCampaignId = openCampaignButton.getAttribute("data-open-campaign");
        setActivePanel("campaign-panel");
        renderCampaignList();
        renderCampaignDetail();
      });
    }
  }

  function renderEmptyDetail(message) {
    elements.detailPanel.classList.add("empty");
    elements.detailPanel.innerHTML = `<p>${escapeHtml(message)}</p>`;
  }

  function renderCampaignDetail() {
    const campaign = state.campaigns.find((entry) => entry.id === state.selectedCampaignId);

    if (!campaign) {
      renderEmptyCampaignDetail("Velg en kampanje for å redigere draften.");
      return;
    }

    const primarySource = campaign.sourceReferences[0] || null;
    const sourceId = primarySource ? primarySource.source_id : "";
    const editorialAssessment = campaign.editorialAssessment;

    elements.campaignDetailPanel.classList.remove("empty");
    elements.campaignDetailPanel.innerHTML = `
      <form id="campaign-editor-form" class="detail-form">
        <div class="badge-row">
          ${renderCampaignBadge(campaign.status)}
          ${campaign.primaryProgramId ? renderMetaBadge(programName(campaign.primaryProgramId)) : ""}
          ${campaign.categoryId ? renderMetaBadge(categoryName(campaign.categoryId)) : ""}
        </div>

        <div class="detail-grid">
          <label class="field">
            <span>Tittel</span>
            <input name="title" type="text" value="${escapeAttribute(campaign.title)}" required />
          </label>

          <label class="field">
            <span>Status</span>
            <select name="status">
              ${renderCampaignStatusOptions(campaign.status)}
            </select>
          </label>
        </div>

        <label class="field">
          <span>Kort beskrivelse</span>
          <textarea name="summary" rows="3">${escapeHtml(campaign.summary)}</textarea>
        </label>

        <label class="field">
          <span>Detaljer</span>
          <textarea name="details" rows="7">${escapeHtml(campaign.details)}</textarea>
        </label>

        <div class="detail-grid">
          <label class="field">
            <span>Primærprogram</span>
            <select name="primaryProgramId">
              <option value="">Ingen valgt</option>
              ${renderSelectOptions(state.programs, campaign.primaryProgramId)}
            </select>
            <span class="hint">Første versjon støtter ett primærprogram i editoren.</span>
          </label>

          <label class="field">
            <span>Kategori</span>
            <select name="categoryId">
              <option value="">Ingen valgt</option>
              ${renderSelectOptions(state.categories, campaign.categoryId)}
            </select>
          </label>
        </div>

        <div class="detail-grid">
          <label class="field">
            <span>Sist verifisert</span>
            <input
              name="lastVerifiedAt"
              type="datetime-local"
              value="${escapeAttribute(toDateTimeLocalValue(campaign.lastVerifiedAt))}"
            />
          </label>

          <label class="field">
            <span>Redaksjonell kortvurdering</span>
            <input name="editorialSummary" type="text" value="${escapeAttribute(campaign.editorialSummary)}" />
          </label>
        </div>

        <section class="section-stack">
          <div class="section-heading-row">
            <h3>Redaksjonell vurdering</h3>
            <button type="button" class="secondary compact-button" data-ai-action="suggest-editorial">
              Foreslå med AI
            </button>
          </div>
          <div class="detail-grid">
            <label class="field">
              <span>Beslutning</span>
              <select name="decisionLabel">
                <option value="">Ikke satt</option>
                ${renderEnumOptions(
                  [
                    { value: "worth_checking", label: "Verdt å sjekke" },
                    { value: "niche", label: "Kun relevant for noen" },
                    { value: "low_value", label: "Lav verdi" },
                    { value: "uncertain", label: "Usikker / vent" }
                  ],
                  editorialAssessment ? editorialAssessment.decisionLabel : ""
                )}
              </select>
              <span class="hint">Kort fasit for om brukeren bør bry seg.</span>
            </label>

            <label class="field">
              <span>Kort konklusjon</span>
              <textarea name="decisionSummary" rows="4">${escapeHtml(
                editorialAssessment ? editorialAssessment.decisionSummary : ""
              )}</textarea>
              <span class="hint">Vises høyt i feed og kampanjedetalj.</span>
            </label>
          </div>

          <div class="detail-grid">
            <label class="field">
              <span>Passer for</span>
              <textarea name="bestFor" rows="3">${escapeHtml(
                editorialAssessment ? editorialAssessment.bestFor : ""
              )}</textarea>
            </label>

            <label class="field">
              <span>Passer ikke for</span>
              <textarea name="notFor" rows="3">${escapeHtml(
                editorialAssessment ? editorialAssessment.notFor : ""
              )}</textarea>
            </label>
          </div>

          <div class="detail-grid">
            <label class="field">
              <span>Hvorfor interessant</span>
              <textarea name="reasonWhyItMatters" rows="4">${escapeHtml(
                editorialAssessment ? editorialAssessment.reasonWhyItMatters : ""
              )}</textarea>
            </label>

            <label class="field">
              <span>Estimert verdi</span>
              <textarea name="estimatedValueText" rows="4">${escapeHtml(
                editorialAssessment ? editorialAssessment.estimatedValueText : ""
              )}</textarea>
            </label>
          </div>

          <div class="detail-grid">
            <label class="field">
              <span>Friksjon</span>
              <select name="difficultyLevel">
                <option value="">Ikke satt</option>
                ${renderEnumOptions(
                  [
                    { value: "low", label: "Lav" },
                    { value: "medium", label: "Middels" },
                    { value: "high", label: "Høy" }
                  ],
                  editorialAssessment ? editorialAssessment.difficultyLevel : ""
                )}
              </select>
            </label>

            <label class="field">
              <span>Tilgjengelighet</span>
              <select name="availabilityScope">
                <option value="">Ikke satt</option>
                ${renderEnumOptions(
                  [
                    { value: "narrow", label: "Smal" },
                    { value: "regional", label: "Regional" },
                    { value: "broad", label: "Bred" }
                  ],
                  editorialAssessment ? editorialAssessment.availabilityScope : ""
                )}
              </select>
            </label>
          </div>

          <label class="field">
            <span>Risiko / forbehold</span>
            <textarea name="riskNote" rows="4">${escapeHtml(
              editorialAssessment ? editorialAssessment.riskNote : ""
            )}</textarea>
          </label>
        </section>

        <label class="field">
          <span>Krav, ett per linje</span>
          <textarea name="requirements" rows="6">${escapeHtml(
            campaign.requirements.map((requirement) => requirement.text).join("\n")
          )}</textarea>
        </label>

        <section class="section-stack">
          <h3>Primær kilde</h3>
          <div class="source-card">
            <div class="detail-grid">
              <label class="field">
                <span>Kilde</span>
                <select name="sourceId">
                  <option value="">Velg kilde</option>
                  ${renderSelectOptions(state.sources, sourceId)}
                </select>
              </label>

              <label class="field">
                <span>Kontrolltidspunkt</span>
                <input
                  name="sourceCheckedAt"
                  type="datetime-local"
                  value="${escapeAttribute(toDateTimeLocalValue(primarySource ? primarySource.checked_at : campaign.lastVerifiedAt))}"
                />
              </label>
            </div>

            <label class="field">
              <span>Kildetittel</span>
              <input name="sourceTitle" type="text" value="${escapeAttribute(primarySource ? primarySource.title || "" : campaign.title)}" />
            </label>

            <label class="field">
              <span>Kildelenke</span>
              <input name="sourceUrl" type="url" value="${escapeAttribute(primarySource ? primarySource.url || "" : "")}" />
            </label>

            <label class="field">
              <span>Bevisnotat</span>
              <textarea name="sourceEvidenceNote" rows="3">${escapeHtml(primarySource ? primarySource.evidence_note || "" : "")}</textarea>
            </label>
          </div>
        </section>

        <div class="detail-actions">
          <div class="action-row">
            <button type="submit">Lagre endringer</button>
            <button type="button" class="success" data-publish-action="publish">Lagre og publiser</button>
            <button type="button" class="secondary" data-publish-action="archive">Arkiver</button>
          </div>
          <span class="help">Publisering krever bonusprogram, https-kilde, tittel, beskrivelse, beslutning, kort konklusjon, redaksjonell begrunnelse og <code>last_verified_at</code>.</span>
        </div>
      </form>
    `;

    const form = elements.campaignDetailPanel.querySelector("#campaign-editor-form");
    form.addEventListener("submit", async function (event) {
      event.preventDefault();
      await saveCampaignEditor(form, campaign, null);
    });

    elements.campaignDetailPanel.querySelectorAll("[data-publish-action]").forEach((button) => {
      button.addEventListener("click", async function () {
        const action = button.getAttribute("data-publish-action");
        const targetStatus = action === "publish" ? "published" : "archived";
        await saveCampaignEditor(form, campaign, targetStatus);
      });
    });

    const aiButton = elements.campaignDetailPanel.querySelector('[data-ai-action="suggest-editorial"]');
    if (aiButton) {
      aiButton.addEventListener("click", async function () {
        await suggestEditorialAssessment(form, campaign, aiButton);
      });
    }

    form.addEventListener("input", function () {
      updatePublishButtonState(form);
    });
    form.addEventListener("change", function () {
      updatePublishButtonState(form);
    });
    updatePublishButtonState(form);
  }

  function renderEmptyCampaignDetail(message) {
    elements.campaignDetailPanel.classList.add("empty");
    elements.campaignDetailPanel.innerHTML = `<p>${escapeHtml(message)}</p>`;
  }

  function renderProgramGuideDetail() {
    const program = state.programs.find((entry) => entry.id === state.selectedProgramGuideProgramId);

    if (!program) {
      renderEmptyProgramGuideDetail("Velg et program for å redigere guiden.");
      return;
    }

    const guide = guideForProgram(program.id);
    const draft = guide || emptyProgramGuideDraft(program.id);
    const readiness = programGuideReadiness(draft);

    elements.programGuideDetailPanel.classList.remove("empty");
    elements.programGuideDetailPanel.innerHTML = `
      <form id="program-guide-editor-form" class="detail-form">
        <div class="program-guide-editor-layout">
          <section class="program-guide-edit-pane">
            <div class="badge-row">
              ${renderProgramGuideBadge(draft.status)}
              ${renderMetaBadge(program.name)}
            </div>

            <section class="draft-readiness" aria-live="polite">
              ${renderProgramGuideReadiness(readiness)}
            </section>

            <div class="detail-grid">
              <label class="field">
                <span>Program</span>
                <input type="text" value="${escapeAttribute(program.name)}" disabled />
              </label>

              <label class="field">
                <span>Status</span>
                <select name="status">
                  ${renderProgramGuideStatusOptions(draft.status)}
                </select>
              </label>
            </div>

            <label class="field">
              <span>Intro på programsiden</span>
              <textarea name="introText" rows="4" placeholder="Kort forklaring som vises øverst på programsiden...">${escapeHtml(
                draft.introText
              )}</textarea>
              <span class="hint">Vises både i Lær-listen og øverst på programsiden. Skriv 1-2 konkrete setninger uten bastante verdianslag.</span>
            </label>

            <label class="field">
              <span>Strategi</span>
              <textarea name="strategy" rows="5" placeholder="Når passer dette programmet, og hva bør brukeren vurdere?">${escapeHtml(
                draft.strategy
              )}</textarea>
              <span class="hint">Hold dette som redaksjonell veiledning. Skill estimat og fakta fra generell vurdering.</span>
            </label>

            <div class="detail-grid">
              <label class="field">
                <span>Verdi-kort: tittel</span>
                <input
                  name="valueEstimateLabel"
                  type="text"
                  placeholder="For eksempel: Varierer"
                  value="${escapeAttribute(draft.valueEstimateLabel)}"
                />
              </label>

              <label class="field">
                <span>Utløp-kort: tittel</span>
                <input
                  name="expirationSummary"
                  type="text"
                  placeholder="For eksempel: Sjekk vilkår"
                  value="${escapeAttribute(draft.expirationSummary)}"
                />
              </label>
            </div>

            <label class="field">
              <span>Verdi-kort: forklaring</span>
              <textarea name="valueEstimateDetail" rows="3" placeholder="Hva styrer verdien, og hva bør kontrolleres?">${escapeHtml(draft.valueEstimateDetail)}</textarea>
            </label>

            <label class="field">
              <span>Utløp-kort: forklaring</span>
              <textarea name="expirationDetail" rows="3" placeholder="Forklar utløpsrisiko uten å gjette konkrete regler.">${escapeHtml(draft.expirationDetail)}</textarea>
            </label>

            <label class="field">
              <span>Slik tjener du, ett tips per linje</span>
              <textarea name="earningTips" rows="5" placeholder="Registrer medlemsnummer før kjøp&#10;Aktiver kampanjer før betaling">${escapeHtml(draft.earningTips.join("\n"))}</textarea>
            </label>

            <label class="field">
              <span>Slik bruker du, ett tips per linje</span>
              <textarea name="redemptionTips" rows="5" placeholder="Sammenlign poengbruk med kontantpris&#10;Unngå bruk der alternativverdien er lav">${escapeHtml(draft.redemptionTips.join("\n"))}</textarea>
            </label>

            <label class="field">
              <span>Vanlige feller, ett punkt per linje</span>
              <textarea name="riskNotes" rows="5" placeholder="Kampanjer kan være målrettet&#10;Vilkår kan endres før bruk">${escapeHtml(draft.riskNotes.join("\n"))}</textarea>
            </label>

            <label class="field">
              <span>Sist redaksjonelt kontrollert</span>
              <input
                name="lastReviewedAt"
                type="datetime-local"
                value="${escapeAttribute(toDateTimeLocalValue(draft.lastReviewedAt))}"
              />
            </label>

            <div class="detail-actions">
              <div class="action-row">
                <button type="submit">Lagre draft</button>
                <button type="button" class="success" data-guide-action="publish">Lagre og publiser</button>
                <button type="button" class="secondary" data-guide-action="reviewed">Marker kontrollert</button>
                <button type="button" class="secondary" data-guide-action="archive">Arkiver</button>
              </div>
              <span class="help">Publisering krever intro, strategi og minst ett punkt i hver tipsseksjon. Verdi og utløp bør fylles før publisering.</span>
            </div>
          </section>

          <aside class="program-guide-preview-pane">
            <div class="preview-sticky">
              <div class="preview-heading">
                <span>Forhåndsvisning</span>
                <strong>${escapeHtml(program.name)}</strong>
              </div>
              <div id="program-guide-live-preview">
                ${renderProgramGuidePreview(program, draft)}
              </div>
            </div>
          </aside>
        </div>
      </form>
    `;

    const form = elements.programGuideDetailPanel.querySelector("#program-guide-editor-form");
    form.addEventListener("submit", async function (event) {
      event.preventDefault();
      await saveProgramGuideEditor(form, program, guide, null);
    });

    elements.programGuideDetailPanel.querySelectorAll("[data-guide-action]").forEach((button) => {
      button.addEventListener("click", async function () {
        await saveProgramGuideEditor(form, program, guide, button.getAttribute("data-guide-action"));
      });
    });

    form.addEventListener("input", function () {
      updateProgramGuideDraftAssist(form, program);
    });
    form.addEventListener("change", function () {
      updateProgramGuideDraftAssist(form, program);
    });
  }

  function renderEmptyProgramGuideDetail(message) {
    elements.programGuideDetailPanel.classList.add("empty");
    elements.programGuideDetailPanel.innerHTML = `<p>${escapeHtml(message)}</p>`;
  }

  function emptyProgramGuideDraft(programId) {
    return {
      id: null,
      programId,
      status: "draft",
      introText: "",
      strategy: "",
      valueEstimateLabel: "",
      valueEstimateDetail: "",
      expirationSummary: "",
      expirationDetail: "",
      earningTips: [],
      redemptionTips: [],
      riskNotes: [],
      lastReviewedAt: null,
      updatedAt: null
    };
  }

  function collectProgramGuideDraftFromForm(form, program) {
    const formData = new FormData(form);
    return {
      ...emptyProgramGuideDraft(program.id),
      status: String(formData.get("status") || "draft"),
      introText: String(formData.get("introText") || "").trim(),
      strategy: String(formData.get("strategy") || "").trim(),
      valueEstimateLabel: String(formData.get("valueEstimateLabel") || "").trim(),
      valueEstimateDetail: String(formData.get("valueEstimateDetail") || "").trim(),
      expirationSummary: String(formData.get("expirationSummary") || "").trim(),
      expirationDetail: String(formData.get("expirationDetail") || "").trim(),
      earningTips: splitTextareaLines(formData.get("earningTips")),
      redemptionTips: splitTextareaLines(formData.get("redemptionTips")),
      riskNotes: splitTextareaLines(formData.get("riskNotes")),
      lastReviewedAt: String(formData.get("lastReviewedAt") || "").trim()
    };
  }

  function programGuideReadiness(guide) {
    const checks = [
      {
        label: "Intro",
        complete: Boolean(guide.introText),
        help: "Vises i Lær-listen og på programsiden."
      },
      {
        label: "Strategi",
        complete: Boolean(guide.strategy),
        help: "Forklar når programmet er nyttig."
      },
      {
        label: "Verdi-kort",
        complete: Boolean(guide.valueEstimateLabel && guide.valueEstimateDetail),
        help: "Bruk forsiktig estimat eller forklar variasjon."
      },
      {
        label: "Utløp-kort",
        complete: Boolean(guide.expirationSummary && guide.expirationDetail),
        help: "Forklar risiko uten å gjette vilkår."
      },
      {
        label: "Opptjening",
        complete: guide.earningTips.length > 0,
        help: "Minst ett konkret tips."
      },
      {
        label: "Bruk",
        complete: guide.redemptionTips.length > 0,
        help: "Minst ett råd for innløsning."
      },
      {
        label: "Feller",
        complete: guide.riskNotes.length > 0,
        help: "Minst ett risikopunkt."
      }
    ];

    const completeCount = checks.filter((check) => check.complete).length;
    return {
      checks,
      completeCount,
      totalCount: checks.length,
      isPublishReady: checks.every((check) => check.complete)
    };
  }

  function renderProgramGuideReadiness(readiness) {
    return `
      <div class="readiness-header">
        <div>
          <span class="readiness-kicker">Draft-status</span>
          <strong>${readiness.completeCount}/${readiness.totalCount} felt klare</strong>
        </div>
        <span class="readiness-pill ${readiness.isPublishReady ? "ready" : "draft"}">
          ${readiness.isPublishReady ? "Klar til publisering" : "Mangler innhold"}
        </span>
      </div>
      <div class="readiness-grid">
        ${readiness.checks
          .map(
            (check) => `
              <div class="readiness-item ${check.complete ? "complete" : ""}">
                <span aria-hidden="true">${check.complete ? "✓" : "–"}</span>
                <div>
                  <strong>${escapeHtml(check.label)}</strong>
                  <small>${escapeHtml(check.help)}</small>
                </div>
              </div>
            `
          )
          .join("")}
      </div>
    `;
  }

  function renderProgramGuidePreview(program, guide) {
    const intro = guide.introText || "Intro vises her når du skriver.";
    const strategy = guide.strategy || "Strategiteksten vises her.";
    const valueLabel = guide.valueEstimateLabel || "Verdi";
    const valueDetail = guide.valueEstimateDetail || "Forklaring av verdi vises her.";
    const expirationLabel = guide.expirationSummary || "Utløp";
    const expirationDetail = guide.expirationDetail || "Forklaring av utløpsrisiko vises her.";

    return `
      <div class="program-preview-card">
        <div class="program-preview-hero">
          <div class="program-preview-mark">${escapeHtml(programInitials(program))}</div>
          <div>
            <h3>${escapeHtml(program.name)}</h3>
            <p>${escapeHtml(intro)}</p>
          </div>
        </div>

        <div class="program-preview-metrics">
          <div>
            <span>Verdi per poeng</span>
            <strong>${escapeHtml(valueLabel)}</strong>
            <p>${escapeHtml(valueDetail)}</p>
          </div>
          <div>
            <span>Utløp</span>
            <strong>${escapeHtml(expirationLabel)}</strong>
            <p>${escapeHtml(expirationDetail)}</p>
          </div>
        </div>

        <div class="program-preview-section">
          <span>Slik tjener du raskere</span>
          ${renderPreviewTips(guide.earningTips)}
        </div>

        <div class="program-preview-section">
          <span>Slik får du mest ut av poengene</span>
          ${renderPreviewTips(guide.redemptionTips)}
        </div>

        <div class="program-preview-section">
          <span>Vanlige feller</span>
          ${renderPreviewTips(guide.riskNotes)}
        </div>

        <p class="program-preview-strategy">${escapeHtml(strategy)}</p>
      </div>
    `;
  }

  function renderPreviewTips(items) {
    if (!items.length) {
      return `<p class="program-preview-empty">Ingen punkter ennå.</p>`;
    }

    return `
      <ul>
        ${items
          .slice(0, 3)
          .map((item) => `<li>${escapeHtml(item)}</li>`)
          .join("")}
      </ul>
    `;
  }

  function updateProgramGuideDraftAssist(form, program) {
    const draft = collectProgramGuideDraftFromForm(form, program);
    const readinessContainer = form.querySelector(".draft-readiness");
    const previewContainer = form.querySelector("#program-guide-live-preview");

    if (readinessContainer) {
      readinessContainer.innerHTML = renderProgramGuideReadiness(programGuideReadiness(draft));
    }

    if (previewContainer) {
      previewContainer.innerHTML = renderProgramGuidePreview(program, draft);
    }
  }

  async function saveCampaignEditor(form, originalCampaign, overrideStatus) {
    const formData = new FormData(form);
    const payload = collectCampaignFormData(formData, originalCampaign, overrideStatus);
    const validationErrors = validateCampaignPayload(payload);

    if (validationErrors.length) {
      setMessage(elements.campaignMessage, validationErrors.join(" "), "error");
      return;
    }

    const submitButtons = form.querySelectorAll("button");
    submitButtons.forEach((button) => {
      button.disabled = true;
    });

    try {
      await saveEditorialCampaign(payload);
      setMessage(elements.campaignMessage, "Kampanjen ble lagret.", "success");
      await refreshCampaigns();
    } catch (error) {
      setMessage(elements.campaignMessage, error.message, "error");
    } finally {
      submitButtons.forEach((button) => {
        button.disabled = false;
      });
    }
  }

  async function saveProgramGuideEditor(form, program, originalGuide, action) {
    const formData = new FormData(form);
    const payload = collectProgramGuideFormData(formData, program, originalGuide, action);
    const validationErrors = validateProgramGuidePayload(payload);

    if (validationErrors.length) {
      setMessage(elements.programGuideMessage, validationErrors.join(" "), "error");
      return;
    }

    const submitButtons = form.querySelectorAll("button");
    submitButtons.forEach((button) => {
      button.disabled = true;
    });

    try {
      await upsertProgramGuide(payload);
      setMessage(elements.programGuideMessage, "Programguiden ble lagret.", "success");
      await refreshProgramGuides();
    } catch (error) {
      setMessage(elements.programGuideMessage, error.message, "error");
    } finally {
      submitButtons.forEach((button) => {
        button.disabled = false;
      });
    }
  }

  function collectProgramGuideFormData(formData, program, originalGuide, action) {
    const now = new Date().toISOString();
    let status = String(formData.get("status") || "draft");
    let lastReviewedAt = String(formData.get("lastReviewedAt") || "").trim();

    if (action === "publish") {
      status = "published";
      lastReviewedAt = lastReviewedAt || now;
    } else if (action === "archive") {
      status = "archived";
    } else if (action === "reviewed") {
      lastReviewedAt = now;
    }

    return {
      id: originalGuide ? originalGuide.id : null,
      programId: program.id,
      status,
      introText: String(formData.get("introText") || "").trim(),
      strategy: String(formData.get("strategy") || "").trim(),
      valueEstimateLabel: String(formData.get("valueEstimateLabel") || "").trim(),
      valueEstimateDetail: String(formData.get("valueEstimateDetail") || "").trim(),
      expirationSummary: String(formData.get("expirationSummary") || "").trim(),
      expirationDetail: String(formData.get("expirationDetail") || "").trim(),
      earningTips: splitTextareaLines(formData.get("earningTips")),
      redemptionTips: splitTextareaLines(formData.get("redemptionTips")),
      riskNotes: splitTextareaLines(formData.get("riskNotes")),
      lastReviewedAt: lastReviewedAt ? toISOString(lastReviewedAt) : null
    };
  }

  function validateProgramGuidePayload(payload) {
    const errors = [];

    if (payload.status === "published") {
      if (!payload.strategy) {
        errors.push("Publisering krever strategi.");
      }

      if (!payload.introText) {
        errors.push("Publisering krever intro på programsiden.");
      }

      if (!payload.earningTips.length) {
        errors.push("Publisering krever minst ett opptjeningstips.");
      }

      if (!payload.redemptionTips.length) {
        errors.push("Publisering krever minst ett brukstips.");
      }

      if (!payload.riskNotes.length) {
        errors.push("Publisering krever minst ett risikonotat.");
      }

      if (!payload.lastReviewedAt) {
        errors.push("Publisering krever kontrolltidspunkt.");
      }
    }

    return errors;
  }

  function collectCampaignFormData(formData, originalCampaign, overrideStatus) {
    const requirements = String(formData.get("requirements") || "")
      .split("\n")
      .map((item) => item.trim())
      .filter(Boolean);
    const sourceUrl = String(formData.get("sourceUrl") || "").trim();
    const sourceTitle = String(formData.get("sourceTitle") || "").trim();
    const sourceCheckedAt = String(formData.get("sourceCheckedAt") || "").trim();
    const lastVerifiedAt = String(formData.get("lastVerifiedAt") || "").trim();

    return {
      id: originalCampaign.id,
      title: String(formData.get("title") || "").trim(),
      summary: String(formData.get("summary") || "").trim(),
      details: String(formData.get("details") || "").trim(),
      status: overrideStatus || String(formData.get("status") || "draft"),
      primaryProgramId: emptyToNull(formData.get("primaryProgramId")),
      categoryId: emptyToNull(formData.get("categoryId")),
      editorialSummary: emptyToNull(formData.get("editorialSummary")),
      decisionLabel: emptyToNull(formData.get("decisionLabel")),
      decisionSummary: emptyToNull(formData.get("decisionSummary")),
      bestFor: emptyToNull(formData.get("bestFor")),
      notFor: emptyToNull(formData.get("notFor")),
      reasonWhyItMatters: String(formData.get("reasonWhyItMatters") || "").trim(),
      estimatedValueText: emptyToNull(formData.get("estimatedValueText")),
      difficultyLevel: emptyToNull(formData.get("difficultyLevel")),
      availabilityScope: emptyToNull(formData.get("availabilityScope")),
      riskNote: emptyToNull(formData.get("riskNote")),
      lastVerifiedAt: lastVerifiedAt ? toISOString(lastVerifiedAt) : null,
      requirements,
      sourceId: emptyToNull(formData.get("sourceId")),
      sourceTitle: sourceTitle || null,
      sourceUrl: sourceUrl || null,
      sourceCheckedAt: sourceCheckedAt ? toISOString(sourceCheckedAt) : null,
      sourceEvidenceNote: emptyToNull(formData.get("sourceEvidenceNote"))
    };
  }

  function validateCampaignPayload(payload) {
    const errors = [];

    if (!payload.title) {
      errors.push("Tittel mangler.");
    }

    if (!payload.summary) {
      errors.push("Kort beskrivelse mangler.");
    }

    if (!payload.details) {
      errors.push("Detaljtekst mangler.");
    }

    if (
      payload.reasonWhyItMatters ||
      payload.decisionLabel ||
      payload.decisionSummary ||
      payload.bestFor ||
      payload.notFor ||
      payload.estimatedValueText ||
      payload.difficultyLevel ||
      payload.availabilityScope ||
      payload.riskNote
    ) {
      if (!payload.reasonWhyItMatters) {
        errors.push("Redaksjonell vurdering krever 'Hvorfor interessant'.");
      }
    }

    if (payload.status === "published") {
      if (!payload.primaryProgramId) {
        errors.push("Publisering krever bonusprogram.");
      }

      if (!payload.lastVerifiedAt) {
        errors.push("Publisering krever sist verifisert.");
      }

      if (!payload.sourceUrl || !payload.sourceId) {
        errors.push("Publisering krever minst én gyldig kilde.");
      }

      if (payload.sourceUrl && !isHttpsUrl(payload.sourceUrl)) {
        errors.push("Kildelenke må være en https-URL.");
      }

      if (!payload.reasonWhyItMatters) {
        errors.push("Publisering krever en redaksjonell begrunnelse.");
      }

      if (!payload.decisionLabel) {
        errors.push("Publisering krever en beslutning.");
      }

      if (!payload.decisionSummary) {
        errors.push("Publisering krever en kort konklusjon.");
      }
    }

    return errors;
  }

  async function saveEditorialCampaign(payload) {
    await apiRequest("/rest/v1/rpc/save_editorial_campaign", {
      method: "POST",
      body: {
        p_campaign_id: payload.id,
        p_payload: {
          title: payload.title,
          summary: payload.summary,
          details: payload.details,
          status: payload.status,
          primaryProgramId: payload.primaryProgramId,
          categoryId: payload.categoryId,
          editorialSummary: payload.editorialSummary,
          decisionLabel: payload.decisionLabel,
          decisionSummary: payload.decisionSummary,
          bestFor: payload.bestFor,
          notFor: payload.notFor,
          reasonWhyItMatters: payload.reasonWhyItMatters,
          estimatedValueText: payload.estimatedValueText,
          difficultyLevel: payload.difficultyLevel,
          availabilityScope: payload.availabilityScope,
          riskNote: payload.riskNote,
          lastVerifiedAt: payload.lastVerifiedAt,
          requirements: payload.requirements,
          sourceId: payload.sourceId,
          sourceTitle: payload.sourceTitle,
          sourceUrl: payload.sourceUrl,
          sourceCheckedAt: payload.sourceCheckedAt,
          sourceEvidenceNote: payload.sourceEvidenceNote
        }
      }
    });
  }

  async function suggestEditorialAssessment(form, campaign, button) {
    const originalLabel = button.textContent;
    button.disabled = true;
    button.textContent = "Foreslår...";
    setMessage(elements.campaignMessage, "Lager AI-forslag til redaksjonell vurdering...", "muted");

    try {
      const formData = new FormData(form);
      const suggestion = await functionRequest("/suggest-editorial-assessment", {
        method: "POST",
        body: {
          title: String(formData.get("title") || "").trim(),
          summary: String(formData.get("summary") || "").trim(),
          details: String(formData.get("details") || "").trim(),
          sourceUrl: String(formData.get("sourceUrl") || "").trim(),
          sourceTitle: String(formData.get("sourceTitle") || "").trim(),
          sourceEvidenceNote: String(formData.get("sourceEvidenceNote") || "").trim(),
          programName: programName(String(formData.get("primaryProgramId") || "")),
          categoryName: categoryName(String(formData.get("categoryId") || ""))
        }
      });

      applyEditorialSuggestion(form, suggestion);
      updatePublishButtonState(form);
      setMessage(
        elements.campaignMessage,
        suggestion.generatedBy === "openai"
          ? "AI-forslag er fylt inn. Kontroller teksten før lagring."
          : "Forslag er fylt inn med lokal fallback. Sett OPENAI_API_KEY for ekte AI-forslag.",
        "success"
      );
    } catch (error) {
      setMessage(elements.campaignMessage, error.message, "error");
    } finally {
      button.disabled = false;
      button.textContent = originalLabel;
    }
  }

  function applyEditorialSuggestion(form, suggestion) {
    setFieldValue(form, "editorialSummary", suggestion.editorialSummary);
    setFieldValue(form, "decisionLabel", suggestion.decisionLabel);
    setFieldValue(form, "decisionSummary", suggestion.decisionSummary);
    setFieldValue(form, "bestFor", suggestion.bestFor);
    setFieldValue(form, "notFor", suggestion.notFor);
    setFieldValue(form, "reasonWhyItMatters", suggestion.reasonWhyItMatters);
    setFieldValue(form, "estimatedValueText", suggestion.estimatedValueText);
    setFieldValue(form, "difficultyLevel", suggestion.difficultyLevel);
    setFieldValue(form, "availabilityScope", suggestion.availabilityScope);
    setFieldValue(form, "riskNote", suggestion.riskNote);
  }

  function setFieldValue(form, name, value) {
    const field = form.elements[name];
    if (field && value) {
      field.value = value;
      field.dispatchEvent(new Event("change", { bubbles: true }));
    }
  }

  function updatePublishButtonState(form) {
    const publishButton = form.querySelector('[data-publish-action="publish"]');
    if (!publishButton) {
      return;
    }

    const formData = new FormData(form);
    const canPublish = Boolean(
      String(formData.get("title") || "").trim()
        && String(formData.get("summary") || "").trim()
        && String(formData.get("details") || "").trim()
        && String(formData.get("primaryProgramId") || "").trim()
        && String(formData.get("lastVerifiedAt") || "").trim()
        && String(formData.get("sourceId") || "").trim()
        && isHttpsUrl(String(formData.get("sourceUrl") || "").trim())
        && String(formData.get("decisionLabel") || "").trim()
        && String(formData.get("decisionSummary") || "").trim()
        && String(formData.get("reasonWhyItMatters") || "").trim()
    );

    publishButton.disabled = !canPublish;
    publishButton.title = canPublish
      ? ""
      : "Publisering krever tittel, beskrivelse, detaljer, bonusprogram, sist verifisert, https-kilde, beslutning, kort konklusjon og redaksjonell begrunnelse.";
  }

  async function upsertProgramGuide(payload) {
    const body = {
      program_id: payload.programId,
      status: payload.status,
      intro_text: payload.introText || null,
      strategy: payload.strategy || null,
      value_estimate_label: payload.valueEstimateLabel || null,
      value_estimate_detail: payload.valueEstimateDetail || null,
      expiration_summary: payload.expirationSummary || null,
      expiration_detail: payload.expirationDetail || null,
      earning_tips: payload.earningTips,
      redemption_tips: payload.redemptionTips,
      risk_notes: payload.riskNotes,
      last_reviewed_at: payload.lastReviewedAt
    };

    if (payload.id) {
      await apiRequest(`/rest/v1/program_guides?id=eq.${payload.id}`, {
        method: "PATCH",
        body,
        extraHeaders: {
          Prefer: "return=minimal"
        }
      });
      return;
    }

    await apiRequest("/rest/v1/program_guides", {
      method: "POST",
      body: [body],
      extraHeaders: {
        Prefer: "return=minimal"
      }
    });
  }

  async function signOut() {
    if (state.session) {
      try {
        await apiRequest("/auth/v1/logout", {
          method: "POST",
          useSession: true,
          skipSessionRefresh: true
        });
      } catch (_error) {
        // Logout should still clear the local session even if the remote token is already gone.
      }
    }

    clearSession();
    state.role = null;
    state.candidates = [];
    state.campaigns = [];
    state.programGuides = [];
    state.selectedCandidateId = null;
    state.selectedCampaignId = null;
    state.selectedProgramGuideProgramId = null;
    elements.loginForm.reset();
    renderEmptyDetail("Velg en kandidat for detaljer.");
    renderEmptyCampaignDetail("Velg en kampanje for å redigere draften.");
    renderEmptyProgramGuideDetail("Velg et program for å redigere guiden.");
    renderUnauthenticated();
    setMessage(elements.authMessage, "Du er logget ut.", "success");
  }

  async function apiRequest(path, options) {
    if (!hasConfig()) {
      throw new Error("Adminverktøyet mangler lokal konfigurasjon.");
    }

    const requestOptions = options || {};
    const useSession = requestOptions.useSession !== false;

    if (useSession && !requestOptions.skipSessionRefresh) {
      await ensureSession();
    }

    const response = await fetchSupabase(path, requestOptions, useSession);

    if (response.status === 401 && useSession && !requestOptions.skipSessionRefresh) {
      await ensureSession({ force: true });
      const retryResponse = await fetchSupabase(path, requestOptions, useSession);
      return parseSupabaseResponse(retryResponse);
    }

    return parseSupabaseResponse(response);
  }

  async function fetchSupabase(path, requestOptions, useSession) {
    const headers = {
      apikey: CONFIG.supabasePublishableKey,
      Accept: "application/json"
    };

    if (useSession && state.session && state.session.accessToken) {
      headers.Authorization = `Bearer ${state.session.accessToken}`;
    } else if (requestOptions.method !== "POST" || !path.startsWith("/auth/")) {
      headers.Authorization = `Bearer ${CONFIG.supabasePublishableKey}`;
    }

    if (requestOptions.body) {
      headers["Content-Type"] = "application/json";
    }

    if (requestOptions.extraHeaders) {
      Object.assign(headers, requestOptions.extraHeaders);
    }

    return fetch(`${CONFIG.supabaseUrl}${path}`, {
      method: requestOptions.method || "GET",
      headers,
      body: requestOptions.body ? JSON.stringify(requestOptions.body) : undefined
    });
  }

  async function parseSupabaseResponse(response) {
    const isJson = (response.headers.get("content-type") || "").includes("application/json");
    const payload = isJson ? await response.json() : await response.text();

    if (!response.ok) {
      const message =
        payload && typeof payload === "object" && payload.msg
          ? payload.msg
          : payload && typeof payload === "object" && payload.message
            ? payload.message
            : typeof payload === "string" && payload
              ? payload
              : "Ukjent feil fra Supabase.";

      throw new Error(message);
    }

    return payload;
  }

  async function functionRequest(path, options) {
    if (!hasConfig()) {
      throw new Error("Adminverktøyet mangler lokal konfigurasjon.");
    }

    if (!state.session || !state.session.accessToken) {
      throw new Error("Du må være logget inn for å bruke denne handlingen.");
    }

    await ensureSession();

    const functionsUrl = CONFIG.supabaseUrl.replace(".supabase.co", ".functions.supabase.co");
    const requestOptions = options || {};
    const response = await fetchFunction(functionsUrl, path, requestOptions);

    if (response.status === 401) {
      await ensureSession({ force: true });
      const retryResponse = await fetchFunction(functionsUrl, path, requestOptions);
      return parseFunctionResponse(retryResponse);
    }

    return parseFunctionResponse(response);
  }

  function fetchFunction(functionsUrl, path, requestOptions) {
    const headers = {
      apikey: CONFIG.supabasePublishableKey,
      authorization: `Bearer ${state.session.accessToken}`,
      Accept: "application/json"
    };

    if (requestOptions.body) {
      headers["Content-Type"] = "application/json";
    }

    return fetch(`${functionsUrl}${path}`, {
      method: requestOptions.method || "GET",
      headers,
      body: requestOptions.body ? JSON.stringify(requestOptions.body) : undefined
    });
  }

  async function parseFunctionResponse(response) {
    const isJson = (response.headers.get("content-type") || "").includes("application/json");
    const payload = isJson ? await response.json() : await response.text();

    if (!response.ok) {
      const message =
        payload && typeof payload === "object" && payload.error
          ? payload.error
          : payload && typeof payload === "object" && payload.message
            ? payload.message
            : typeof payload === "string" && payload
              ? payload
              : "Ukjent feil fra Edge Function.";

      throw new Error(message);
    }

    return payload;
  }

  async function ensureSession(options) {
    const shouldForce = Boolean(options && options.force);

    if (!state.session || !state.session.accessToken) {
      throw new Error("Du må være logget inn for å bruke denne handlingen.");
    }

    if (!state.session.refreshToken) {
      handleExpiredSession();
      throw new Error("Sessionen mangler refresh-token. Logg inn på nytt.");
    }

    if (!shouldForce && !isSessionExpiring(state.session)) {
      return state.session;
    }

    if (!state.sessionRefreshPromise) {
      state.sessionRefreshPromise = refreshSession()
        .catch((error) => {
          handleExpiredSession();
          throw error;
        })
        .finally(() => {
          state.sessionRefreshPromise = null;
        });
    }

    return state.sessionRefreshPromise;
  }

  async function refreshSession() {
    const previousEmail = state.session ? state.session.userEmail : null;
    const response = await authRequest("/auth/v1/token?grant_type=refresh_token", {
      method: "POST",
      body: {
        refresh_token: state.session.refreshToken
      }
    });

    state.session = normalizeSessionPayload(response, previousEmail);
    persistSession();
    renderSessionPill();

    return state.session;
  }

  function normalizeSessionPayload(session, fallbackEmail) {
    if (!session || !session.access_token || !session.refresh_token) {
      throw new Error("Supabase returnerte ikke en komplett session.");
    }

    return {
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
      expiresAt: session.expires_at || null,
      userEmail: session.user && session.user.email ? session.user.email : fallbackEmail || "ukjent"
    };
  }

  function isSessionExpiring(session) {
    if (!session.expiresAt) {
      return false;
    }

    const secondsUntilExpiry = Number(session.expiresAt) - Math.floor(Date.now() / 1000);
    return secondsUntilExpiry <= SESSION_REFRESH_MARGIN_SECONDS;
  }

  function handleExpiredSession() {
    clearSession();
    state.role = null;
    renderUnauthenticated();
    setMessage(elements.authMessage, "Sessionen er utløpt. Logg inn på nytt.", "error");
  }

  function clampIngestionLimit(value) {
    const parsed = Number.parseInt(String(value || ""), 10);
    if (!Number.isFinite(parsed)) {
      return 10;
    }

    return Math.min(Math.max(parsed, 1), 50);
  }

  function isHttpsUrl(value) {
    try {
      const url = new URL(value);
      return url.protocol === "https:" && Boolean(url.hostname);
    } catch (_error) {
      return false;
    }
  }

  function ingestSourceLabel(source) {
    const labels = {
      trumf_netthandel: "Trumf Netthandel",
      sas_eurobonus_shopping: "SAS EuroBonus Shopping"
    };

    return labels[source] || source;
  }

  function summarizeIngestionResult(result, requestedSource) {
    if (!result || typeof result !== "object") {
      return "Connectoren svarte uten detaljert resultat.";
    }

    const results = Array.isArray(result.results) ? result.results : [];

    if (Number(result.checked_source_count || 0) === 0 || !results.length) {
      return `${ingestSourceLabel(requestedSource)} er ikke aktivert som kilde ennå. Ingen kandidater ble hentet.`;
    }

    const found = results.reduce((sum, item) => sum + Number(item.found_count || 0), 0);
    const inserted = results.reduce((sum, item) => sum + Number(item.inserted_count || 0), 0);
    const skipped = results.reduce((sum, item) => sum + Number(item.skipped_duplicate_count || 0), 0);
    const failed = results.filter((item) => item.status === "failed");

    if (failed.length) {
      return `Connectoren feilet for ${failed.length} kilde(r): ${failed.map((item) => item.error || item.parser_key).join("; ")}`;
    }

    return `Connectoren fant ${found} kandidat${found === 1 ? "" : "er"}, la inn ${inserted} ny${inserted === 1 ? "" : "e"} og hoppet over ${skipped} duplikat${skipped === 1 ? "" : "er"}.`;
  }

  function authRequest(path, options) {
    return apiRequest(path, {
      method: options.method,
      body: options.body,
      useSession: false
    });
  }

  function setAuthLoading(isLoading) {
    elements.loginButton.disabled = isLoading;
    elements.emailInput.disabled = isLoading;
    elements.passwordInput.disabled = isLoading;
  }

  function setMessage(element, message, kind) {
    element.textContent = message;
    element.className = `message ${kind || "muted"}`;
  }

  function loadSession() {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY);
      const session = raw ? JSON.parse(raw) : null;
      if (!session || !session.accessToken || !session.refreshToken) {
        return null;
      }

      return session;
    } catch (_error) {
      return null;
    }
  }

  function persistSession() {
    if (!state.session) {
      return;
    }

    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state.session));
  }

  function clearSession() {
    state.session = null;
    window.localStorage.removeItem(STORAGE_KEY);
  }

  function formatDateTime(value) {
    if (!value) {
      return "Ukjent";
    }

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
      return value;
    }

    return new Intl.DateTimeFormat("nb-NO", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(date);
  }

  function formatTimeFromUnixSeconds(value) {
    const date = new Date(Number(value) * 1000);

    if (Number.isNaN(date.getTime())) {
      return "ukjent";
    }

    return new Intl.DateTimeFormat("nb-NO", {
      timeStyle: "short"
    }).format(date);
  }

  function toDateTimeLocalValue(value) {
    if (!value) {
      return "";
    }

    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return "";
    }

    const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
    return local.toISOString().slice(0, 16);
  }

  function toISOString(value) {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
  }

  function renderBadge(status) {
    const label = STATUS_LABELS[status] || status;
    return `<span class="badge ${escapeAttribute(status)}">${escapeHtml(label)}</span>`;
  }

  function renderCampaignBadge(status) {
    const label = CAMPAIGN_STATUS_LABELS[status] || status;
    return `<span class="badge ${escapeAttribute(status)}">${escapeHtml(label)}</span>`;
  }

  function renderProgramGuideBadge(status) {
    const label = PROGRAM_GUIDE_STATUS_LABELS[status] || status;
    return `<span class="badge ${escapeAttribute(status)}">${escapeHtml(label)}</span>`;
  }

  function renderMetaBadge(value) {
    return value ? `<span class="badge">${escapeHtml(value)}</span>` : "";
  }

  function renderSelectOptions(options, selectedValue) {
    return options
      .map((option) => {
        const label = option.name || option.slug || option.id;
        const isSelected = option.id === selectedValue ? " selected" : "";
        return `<option value="${escapeAttribute(option.id)}"${isSelected}>${escapeHtml(label)}</option>`;
      })
      .join("");
  }

  function renderCampaignStatusOptions(selectedStatus) {
    return Object.entries(CAMPAIGN_STATUS_LABELS)
      .map(([value, label]) => {
        const isSelected = value === selectedStatus ? " selected" : "";
        return `<option value="${escapeAttribute(value)}"${isSelected}>${escapeHtml(label)}</option>`;
      })
      .join("");
  }

  function renderProgramGuideStatusOptions(selectedStatus) {
    return Object.entries(PROGRAM_GUIDE_STATUS_LABELS)
      .map(([value, label]) => {
        const isSelected = value === selectedStatus ? " selected" : "";
        return `<option value="${escapeAttribute(value)}"${isSelected}>${escapeHtml(label)}</option>`;
      })
      .join("");
  }

  function renderEnumOptions(options, selectedValue) {
    return options
      .map((option) => {
        const isSelected = option.value === selectedValue ? " selected" : "";
        return `<option value="${escapeAttribute(option.value)}"${isSelected}>${escapeHtml(option.label)}</option>`;
      })
      .join("");
  }

  function programName(programId) {
    const program = state.programs.find((item) => item.id === programId);
    return program ? program.name : "";
  }

  function programInitials(program) {
    if (!program || !program.name) {
      return "PJ";
    }

    const specialCases = {
      "sas-eurobonus": "EUR",
      trumf: "TRU",
      spenn: "SPE",
      "norwegian-cashpoints": "CAS",
      "norwegian-reward": "CAS",
      "flying-blue": "FLY",
      avios: "AVI"
    };

    if (specialCases[program.slug]) {
      return specialCases[program.slug];
    }

    const initials = program.name
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((word) => word[0])
      .join("")
      .toUpperCase();

    return initials || program.name.slice(0, 2).toUpperCase();
  }

  function categoryName(categoryId) {
    const category = state.categories.find((item) => item.id === categoryId);
    return category ? category.name : "";
  }

  function guideForProgram(programId) {
    return state.programGuides.find((guide) => guide.programId === programId) || null;
  }

  function splitTextareaLines(value) {
    return String(value || "")
      .split("\n")
      .map((item) => item.trim())
      .filter(Boolean);
  }

  function firstTextLine(value, fallback) {
    const normalized = String(value || "").trim();
    if (!normalized) {
      return fallback;
    }

    return normalized.length > 140 ? `${normalized.slice(0, 137)}...` : normalized;
  }

  function emptyToNull(value) {
    const normalized = String(value || "").trim();
    return normalized || null;
  }

  function escapeHtml(value) {
    return String(value || "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  function escapeAttribute(value) {
    return escapeHtml(value).replaceAll("`", "&#96;");
  }
})();
