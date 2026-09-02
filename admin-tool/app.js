(function () {
  "use strict";

  const CONFIG = window.ADMIN_TOOL_CONFIG || {};
  const STORAGE_KEY = "poengjeger_admin_session";
  const SIDEBAR_STORAGE_KEY = "poengjeger_admin_sidebar_collapsed";
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
  const STORE_STATUS_LABELS = {
    draft: "Draft",
    review: "Review",
    published: "Published",
    archived: "Archived"
  };
  const STORE_EARNING_STATUS_LABELS = {
    draft: "Draft",
    published: "Published",
    expired: "Expired",
    archived: "Archived"
  };
  const STATUS_LABELS = {
    new: "Ny",
    needs_review: "Trenger review",
    approved: "Godkjent",
    rejected: "Avvist",
    promoted: "Promotert"
  };
  const PROGRAM_GUIDE_BASE_COLUMNS = [
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
  ];
  const PROGRAM_GUIDE_MANUAL_COPY_COLUMNS = [
    "guide_kicker",
    "reading_time_label",
    "strategy_section_title",
    "decision_section_title",
    "earning_decision_label",
    "redemption_decision_label",
    "risk_decision_label",
    "earning_section_title",
    "earning_section_intro",
    "redemption_section_title",
    "redemption_section_intro",
    "risk_section_title",
    "risk_section_intro",
    "campaigns_section_title",
    "campaigns_section_intro"
  ];
  const PROGRAM_GUIDE_MARKDOWN_COLUMNS = ["body_markdown"];
  const PROGRAM_GUIDE_COLUMNS = [
    ...PROGRAM_GUIDE_BASE_COLUMNS.slice(0, 2),
    "title",
    ...PROGRAM_GUIDE_BASE_COLUMNS.slice(2, 9),
    ...PROGRAM_GUIDE_MARKDOWN_COLUMNS,
    ...PROGRAM_GUIDE_MANUAL_COPY_COLUMNS,
    ...PROGRAM_GUIDE_BASE_COLUMNS.slice(9)
  ];

  const state = {
    session: loadSession(),
    role: null,
    candidates: [],
    campaigns: [],
    storeEarningRates: [],
    programGuides: [],
    categories: [],
    programs: [],
    sources: [],
    earningMethods: [],
    selectedCandidateId: null,
    selectedCampaignId: null,
    selectedStoreEarningRateId: null,
    selectedProgramGuideProgramId: null,
    selectedProgramGuideId: null,
    newProgramGuideDraft: null,
    programGuidePreviewExpanded: false,
    sidebarCollapsed: loadSidebarCollapsed(),
    activePanelId: "queue-panel",
    loading: false,
    programGuideManualCopyAvailable: true,
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
    opsCampaignCount: document.querySelector("#ops-campaign-count"),
    opsCampaignNote: document.querySelector("#ops-campaign-note"),
    opsFocusLabel: document.querySelector("#ops-focus-label"),
    opsFocusNote: document.querySelector("#ops-focus-note"),
    opsOverview: document.querySelector("#ops-overview"),
    opsQueueCount: document.querySelector("#ops-queue-count"),
    opsQueueNote: document.querySelector("#ops-queue-note"),
    opsStoreCount: document.querySelector("#ops-store-count"),
    opsStoreNote: document.querySelector("#ops-store-note"),
    passwordInput: document.querySelector("#password-input"),
    personalCampaignCount: document.querySelector("#personal-campaign-count"),
    personalDashboard: document.querySelector("#personal-dashboard"),
    personalIngestButton: document.querySelector("#personal-ingest-button"),
    personalQueueCount: document.querySelector("#personal-queue-count"),
    personalStoreCount: document.querySelector("#personal-store-count"),
    personalSummary: document.querySelector("#personal-summary"),
    programGuideDetailPanel: document.querySelector("#program-guide-detail-panel"),
    programGuideList: document.querySelector("#program-guide-list"),
    programGuideMessage: document.querySelector("#program-guide-message"),
    programGuideNewButton: document.querySelector("#program-guide-new-button"),
    programGuidePanel: document.querySelector("#program-guide-panel"),
    programGuideRefreshButton: document.querySelector("#program-guide-refresh-button"),
    queueList: document.querySelector("#queue-list"),
    queueMessage: document.querySelector("#queue-message"),
    queuePanel: document.querySelector("#queue-panel"),
    queueWorkbar: document.querySelector("#queue-workbar"),
    refreshButton: document.querySelector("#refresh-button"),
    sessionPill: document.querySelector("#session-pill"),
    signOutButton: document.querySelector("#sign-out-button"),
    storeEarningDetailPanel: document.querySelector("#store-earning-detail-panel"),
    storeEarningList: document.querySelector("#store-earning-list"),
    storeEarningMessage: document.querySelector("#store-earning-message"),
    storeEarningPanel: document.querySelector("#store-earning-panel"),
    storeEarningRefreshButton: document.querySelector("#store-earning-refresh-button"),
    storeEarningStatusFilter: document.querySelector("#store-earning-status-filter"),
    storeEarningWorkbar: document.querySelector("#store-earning-workbar"),
    statusFilter: document.querySelector("#status-filter")
  };
  elements.campaignWorkbar = document.querySelector("#campaign-workbar");
  elements.workspaceFrame = document.querySelector("#workspace-frame");
  elements.workspaceNav = document.querySelector("#workspace-nav");
  elements.workspaceNavButtons = Array.from(document.querySelectorAll("[data-panel-target]"));
  elements.workspaceNavToggle = document.querySelector("#workspace-nav-toggle");
  elements.workspaceSidebar = document.querySelector("#workspace-sidebar");

  elements.loginForm.addEventListener("submit", onLoginSubmit);
  elements.ingestButton.addEventListener("click", runIngestionFromAdmin);
  elements.personalIngestButton.addEventListener("click", runPersonalIngestion);
  elements.refreshButton.addEventListener("click", refreshQueue);
  elements.campaignRefreshButton.addEventListener("click", refreshCampaigns);
  elements.storeEarningRefreshButton.addEventListener("click", refreshStoreEarningRates);
  elements.programGuideRefreshButton.addEventListener("click", refreshProgramGuides);
  elements.programGuideNewButton.addEventListener("click", startNewProgramGuide);
  elements.signOutButton.addEventListener("click", signOut);
  elements.statusFilter.addEventListener("change", refreshQueue);
  elements.campaignStatusFilter.addEventListener("change", refreshCampaigns);
  elements.storeEarningStatusFilter.addEventListener("change", refreshStoreEarningRates);
  elements.workspaceNavButtons.forEach((button) => {
    button.addEventListener("click", function () {
      setActivePanel(button.getAttribute("data-panel-target"));
    });
  });
  elements.workspaceNavToggle.addEventListener("click", function () {
    setSidebarCollapsed(!state.sidebarCollapsed);
  });
  Array.from(document.querySelectorAll("[data-personal-target]")).forEach((button) => {
    button.addEventListener("click", function () {
      openPersonalTarget(button.getAttribute("data-personal-target"));
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
      await Promise.all([refreshQueue(), refreshCampaigns(), refreshStoreEarningRates(), refreshProgramGuides()]);
      updatePersonalDashboard();
    } catch (error) {
      clearSession();
      renderUnauthenticated();
      setMessage(elements.authMessage, error.message, "error");
    }
  }

  async function fetchReferenceData() {
    const [programs, categories, sources, earningMethods] = await Promise.all([
      fetchPrograms(),
      fetchCategories(),
      fetchSources(),
      fetchEarningMethods()
    ]);

    state.programs = programs;
    state.categories = categories;
    state.sources = sources;
    state.earningMethods = earningMethods;
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
        updatePersonalDashboard();
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
      updatePersonalDashboard();
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
        updatePersonalDashboard();
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
      updatePersonalDashboard();
    } catch (error) {
      setMessage(elements.campaignMessage, error.message, "error");
      renderEmptyCampaignDetail("Kunne ikke laste kampanjer.");
    } finally {
      elements.campaignRefreshButton.disabled = false;
    }
  }

  async function refreshStoreEarningRates() {
    if (!state.session) {
      renderUnauthenticated();
      return;
    }

    elements.storeEarningRefreshButton.disabled = true;
    setMessage(elements.storeEarningMessage, "Laster butikkopptjening...", "muted");

    try {
      const status = elements.storeEarningStatusFilter.value;
      state.storeEarningRates = await fetchStoreEarningRates(status);

      if (!state.storeEarningRates.length) {
        state.selectedStoreEarningRateId = null;
        renderStoreEarningList();
        renderEmptyStoreEarningDetail("Ingen satser matcher filteret ennå.");
        setMessage(elements.storeEarningMessage, "Ingen butikkopptjening i valgt filter.", "muted");
        updatePersonalDashboard();
        return;
      }

      if (!state.storeEarningRates.some((rate) => rate.id === state.selectedStoreEarningRateId)) {
        state.selectedStoreEarningRateId = state.storeEarningRates[0].id;
      }

      renderStoreEarningList();
      renderStoreEarningDetail();
      setMessage(
        elements.storeEarningMessage,
        `Viser ${state.storeEarningRates.length} sats${state.storeEarningRates.length === 1 ? "" : "er"}.`,
        "success"
      );
      updatePersonalDashboard();
    } catch (error) {
      setMessage(elements.storeEarningMessage, error.message, "error");
      renderEmptyStoreEarningDetail("Kunne ikke laste butikkopptjening.");
    } finally {
      elements.storeEarningRefreshButton.disabled = false;
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
        state.selectedProgramGuideId = null;
        state.newProgramGuideDraft = null;
        renderProgramGuideList();
        renderEmptyProgramGuideDetail("Ingen bonusprogrammer er tilgjengelige.");
        setMessage(elements.programGuideMessage, "Ingen programmer å vise.", "muted");
        return;
      }

      if (state.selectedProgramGuideId && !state.programGuides.some((guide) => guide.id === state.selectedProgramGuideId)) {
        state.selectedProgramGuideId = null;
      }

      if (!state.selectedProgramGuideId && !state.newProgramGuideDraft && state.programGuides.length) {
        state.selectedProgramGuideId = state.programGuides[0].id;
        state.selectedProgramGuideProgramId = state.programGuides[0].programId;
      }

      renderProgramGuideList();
      renderProgramGuideDetail();
      if (state.programGuideManualCopyAvailable) {
        setMessage(
          elements.programGuideMessage,
          `Viser ${state.programGuides.length} guide${state.programGuides.length === 1 ? "" : "r"}.`,
          "success"
        );
      } else {
        setMessage(
          elements.programGuideMessage,
          "Databasen mangler de nye guidefeltene. Kjør siste Supabase-migrasjon før hele guiden kan lagres.",
          "error"
        );
      }
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

  async function runPersonalIngestion() {
    setActivePanel("queue-panel");
    elements.statusFilter.value = "new";
    elements.ingestLimitInput.value = "10";
    await runIngestionFromAdmin();
  }

  async function openPersonalTarget(panelId) {
    if (panelId === "queue-panel") {
      elements.statusFilter.value = "new";
      await refreshQueue();
    } else if (panelId === "campaign-panel") {
      elements.campaignStatusFilter.value = "draft";
      await refreshCampaigns();
    } else if (panelId === "store-earning-panel") {
      elements.storeEarningStatusFilter.value = "draft";
      await refreshStoreEarningRates();
    }

    setActivePanel(panelId);
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
        "promoted_store_earning_rate_id",
        "ingest_kind",
        "parser_key",
        "shop_slug",
        "missing_bonus_value",
        "suggested_category_slug",
        "suggested_category_source",
        "is_store_earning_candidate",
        "suggested_method_slug",
        "matched_store_id",
        "matched_store_name",
        "matched_store_status",
        "matches_existing_store",
        "has_existing_store_method_rate",
        "needs_category_review",
        "is_ready_for_store_earning",
        "review_signal_label",
        "source_name",
        "suggested_program_name",
        "suggested_category_id",
        "suggested_category_name"
      ].join(",")
    );
    params.set("order", "detected_at.desc");

    if (status) {
      params.set("status", `eq.${status}`);
    }

    const response = await apiRequest(`/rest/v1/admin_ingestion_candidate_queue?${params.toString()}`);

    return response.map(normalizeCandidate).sort(compareCandidatesForReview);
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

  async function fetchEarningMethods() {
    const params = new URLSearchParams();
    params.set("select", "id,name,slug,program_id,status");
    params.set("status", "neq.archived");
    params.set("order", "name.asc");

    return apiRequest(`/rest/v1/earning_methods?${params.toString()}`);
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

  async function fetchStoreEarningRates(status) {
    const params = new URLSearchParams();
    params.set(
      "select",
      [
        "id",
        "store_id",
        "earning_method_id",
        "status",
        "rate_label",
        "normal_rate_label",
        "value_summary",
        "requirement_summary",
        "warning_text",
        "handoff_url",
        "source_url",
        "source_title",
        "checked_at",
        "starts_at",
        "ends_at",
        "sort_order",
        "is_base_rate",
        "updated_at",
        "stores(id,slug,name,category_id,status,website_url,search_keywords,last_verified_at)",
        "earning_methods(id,slug,name,program_id,status)"
      ].join(",")
    );
    params.set("order", "updated_at.desc");

    if (status) {
      params.set("status", `eq.${status}`);
    }

    const response = await apiRequest(`/rest/v1/store_earning_rates?${params.toString()}`);
    return response.map(normalizeStoreEarningRate);
  }

  async function fetchProgramGuides() {
    try {
      const response = await fetchProgramGuidesWithColumns(PROGRAM_GUIDE_COLUMNS);
      state.programGuideManualCopyAvailable = true;
      return response.map(normalizeProgramGuide);
    } catch (error) {
      if (!isMissingProgramGuideManualCopyColumn(error)) {
        throw error;
      }

      await sleep(500);
      try {
        const response = await fetchProgramGuidesWithColumns(PROGRAM_GUIDE_COLUMNS);
        state.programGuideManualCopyAvailable = true;
        return response.map(normalizeProgramGuide);
      } catch (retryError) {
        if (!isMissingProgramGuideManualCopyColumn(retryError)) {
          throw retryError;
        }
      }

      const response = await fetchProgramGuidesWithColumns(PROGRAM_GUIDE_BASE_COLUMNS);
      state.programGuideManualCopyAvailable = false;
      return response.map(normalizeProgramGuide);
    }
  }

  async function fetchProgramGuidesWithColumns(columns) {
    const params = new URLSearchParams();
    params.set("select", columns.join(","));
    params.set("order", "updated_at.desc");

    return apiRequest(`/rest/v1/program_guides?${params.toString()}`);
  }

  function isMissingProgramGuideManualCopyColumn(error) {
    const message = String(error && error.message ? error.message : error);
    return ["title", ...PROGRAM_GUIDE_MARKDOWN_COLUMNS, ...PROGRAM_GUIDE_MANUAL_COPY_COLUMNS].some((column) => message.includes(`program_guides.${column}`));
  }

  function sleep(milliseconds) {
    return new Promise((resolve) => {
      window.setTimeout(resolve, milliseconds);
    });
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
      promotedStoreEarningRateId: candidate.promoted_store_earning_rate_id,
      ingestKind: candidate.ingest_kind,
      parserKey: candidate.parser_key,
      shopSlug: candidate.shop_slug,
      missingBonusValue: Boolean(candidate.missing_bonus_value),
      suggestedCategorySlug: candidate.suggested_category_slug,
      suggestedCategorySource: candidate.suggested_category_source,
      isStoreEarningCandidate: Boolean(candidate.is_store_earning_candidate),
      suggestedMethodSlug: candidate.suggested_method_slug,
      matchedStoreId: candidate.matched_store_id,
      matchedStoreName: candidate.matched_store_name,
      matchedStoreStatus: candidate.matched_store_status,
      matchesExistingStore: Boolean(candidate.matches_existing_store),
      hasExistingStoreMethodRate: Boolean(candidate.has_existing_store_method_rate),
      needsCategoryReview: Boolean(candidate.needs_category_review),
      isReadyForStoreEarning: Boolean(candidate.is_ready_for_store_earning),
      reviewSignalLabel: candidate.review_signal_label || "Trenger review",
      sourceName: candidate.source_name,
      suggestedProgramName: candidate.suggested_program_name,
      suggestedCategoryId: candidate.suggested_category_id,
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

  function normalizeStoreEarningRate(rate) {
    const store = Array.isArray(rate.stores) ? rate.stores[0] || null : rate.stores || null;
    const method = Array.isArray(rate.earning_methods)
      ? rate.earning_methods[0] || null
      : rate.earning_methods || null;

    return {
      id: rate.id,
      storeId: rate.store_id,
      earningMethodId: rate.earning_method_id,
      status: rate.status,
      rateLabel: rate.rate_label || "",
      normalRateLabel: rate.normal_rate_label || "",
      valueSummary: rate.value_summary || "",
      requirementSummary: rate.requirement_summary || "",
      warningText: rate.warning_text || "",
      handoffUrl: rate.handoff_url || "",
      sourceUrl: rate.source_url || "",
      sourceTitle: rate.source_title || "",
      checkedAt: rate.checked_at,
      startsAt: rate.starts_at,
      endsAt: rate.ends_at,
      sortOrder: Number(rate.sort_order || 0),
      isBaseRate: Boolean(rate.is_base_rate),
      updatedAt: rate.updated_at,
      store: store
        ? {
            id: store.id,
            slug: store.slug || "",
            name: store.name || "",
            categoryId: store.category_id,
            status: store.status,
            websiteUrl: store.website_url || "",
            searchKeywords: Array.isArray(store.search_keywords) ? store.search_keywords : [],
            lastVerifiedAt: store.last_verified_at
          }
        : null,
      method: method
        ? {
            id: method.id,
            slug: method.slug || "",
            name: method.name || "",
            programId: method.program_id,
            status: method.status
          }
        : null
    };
  }

  function normalizeProgramGuide(guide) {
    return {
      id: guide.id,
      programId: guide.program_id,
      status: guide.status,
      title: guide.title || "",
      introText: guide.intro_text || "",
      bodyMarkdown: guide.body_markdown || "",
      strategy: guide.strategy || "",
      valueEstimateLabel: guide.value_estimate_label || "",
      valueEstimateDetail: guide.value_estimate_detail || "",
      expirationSummary: guide.expiration_summary || "",
      expirationDetail: guide.expiration_detail || "",
      guideKicker: guide.guide_kicker || "",
      readingTimeLabel: guide.reading_time_label || "",
      strategySectionTitle: guide.strategy_section_title || "",
      decisionSectionTitle: guide.decision_section_title || "",
      earningDecisionLabel: guide.earning_decision_label || "",
      redemptionDecisionLabel: guide.redemption_decision_label || "",
      riskDecisionLabel: guide.risk_decision_label || "",
      earningSectionTitle: guide.earning_section_title || "",
      earningSectionIntro: guide.earning_section_intro || "",
      redemptionSectionTitle: guide.redemption_section_title || "",
      redemptionSectionIntro: guide.redemption_section_intro || "",
      riskSectionTitle: guide.risk_section_title || "",
      riskSectionIntro: guide.risk_section_intro || "",
      campaignsSectionTitle: guide.campaigns_section_title || "",
      campaignsSectionIntro: guide.campaigns_section_intro || "",
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
    elements.storeEarningPanel.classList.add("hidden");
    elements.programGuidePanel.classList.add("hidden");
    elements.personalDashboard.classList.add("hidden");
    elements.opsOverview.classList.add("hidden");
    elements.workspaceNav.classList.add("hidden");
    elements.workspaceSidebar.classList.add("hidden");
    elements.signOutButton.classList.add("hidden");
    elements.sessionPill.classList.add("hidden");
  }

  function renderAuthenticatedShell() {
    elements.authPanel.classList.add("hidden");
    elements.personalDashboard.classList.remove("hidden");
    elements.opsOverview.classList.remove("hidden");
    elements.workspaceNav.classList.remove("hidden");
    elements.workspaceSidebar.classList.remove("hidden");
    elements.signOutButton.classList.remove("hidden");
    elements.sessionPill.classList.remove("hidden");
    setSidebarCollapsed(state.sidebarCollapsed);
    setActivePanel(state.activePanelId);
  }

  function updatePersonalDashboard() {
    if (!state.session) {
      return;
    }

    const queueCount = elements.statusFilter.value === "new" ? state.candidates.length : 0;
    const storeCount = elements.storeEarningStatusFilter.value === "draft" ? state.storeEarningRates.length : 0;
    const campaignCount = elements.campaignStatusFilter.value === "draft" ? state.campaigns.length : 0;
    const totalCount = queueCount + storeCount + campaignCount;

    elements.personalQueueCount.textContent = String(queueCount);
    elements.personalStoreCount.textContent = String(storeCount);
    elements.personalCampaignCount.textContent = String(campaignCount);
    elements.personalSummary.textContent = totalCount
      ? `${totalCount} ting ligger klare for behandling. Start med nye funn eller fortsett på drafts.`
      : "Ingen nye funn eller drafts i standardfiltrene akkurat nå.";
    renderOpsOverview(queueCount, storeCount, campaignCount);
    renderWorkbars();
  }

  function renderOpsOverview(queueCount, storeCount, campaignCount) {
    elements.opsQueueCount.textContent = String(queueCount);
    elements.opsStoreCount.textContent = String(storeCount);
    elements.opsCampaignCount.textContent = String(campaignCount);

    elements.opsQueueNote.textContent = queueCount
      ? "Sorter nyttig fra støy."
      : "Ingen nye i filteret.";
    elements.opsStoreNote.textContent = storeCount
      ? "Publiser etter kontroll."
      : "Ingen draft-satser.";
    elements.opsCampaignNote.textContent = campaignCount
      ? "Fyll beslutning og kilde."
      : "Ingen kampanjeutkast.";

    const focus = nextAdminFocus(queueCount, storeCount, campaignCount);
    elements.opsFocusLabel.textContent = focus.label;
    elements.opsFocusNote.textContent = focus.note;
  }

  function nextAdminFocus(queueCount, storeCount, campaignCount) {
    if (queueCount) {
      return { label: "Kø", note: "Lag butikkdraft eller avvis." };
    }

    if (storeCount) {
      return { label: "Butikker", note: "Kontroller sats og handoff." };
    }

    if (campaignCount) {
      return { label: "Kampanjer", note: "Sjekk beslutning og kilde." };
    }

    return { label: "Vedlikehold", note: "Se etter utdaterte publiserte rader." };
  }

  function renderWorkbars() {
    renderQueueWorkbar();
    renderCampaignWorkbar();
    renderStoreEarningWorkbar();
  }

  function renderQueueWorkbar() {
    if (!elements.queueWorkbar) {
      return;
    }

    const total = state.candidates.length;
    const storeCandidates = state.candidates.filter(isStoreEarningCandidate).length;
    const ready = state.candidates.filter((candidate) => candidate.isReadyForStoreEarning).length;
    const categoryReview = state.candidates.filter((candidate) => candidate.needsCategoryReview).length;
    const promoted = state.candidates.filter((candidate) => (
      candidate.promotedCampaignId || candidate.promotedStoreEarningRateId
    )).length;

    elements.queueWorkbar.innerHTML = `
      ${renderWorkbarMetric("I filteret", total)}
      ${renderWorkbarMetric("Klar", ready)}
      ${renderWorkbarMetric("Butikkfunn", storeCandidates)}
      ${renderWorkbarMetric("Kategori usikker", categoryReview)}
      ${renderWorkbarMetric("Promotert", promoted)}
      <span class="workbar-hint">Sorter automatisk: klare butikkfunn først, usikre kategorier bak.</span>
    `;
  }

  function renderCampaignWorkbar() {
    if (!elements.campaignWorkbar) {
      return;
    }

    const readyCount = state.campaigns.filter((campaign) => (
      campaignReadiness(campaignDraftFromCampaign(campaign)).isPublishReady
    )).length;
    const missingSourceCount = state.campaigns.filter((campaign) => !campaign.sourceReferences.length).length;

    elements.campaignWorkbar.innerHTML = `
      ${renderWorkbarMetric("I filteret", state.campaigns.length)}
      ${renderWorkbarMetric("Publiserbare", readyCount)}
      ${renderWorkbarMetric("Mangler kilde", missingSourceCount)}
      <span class="workbar-hint">Fyll konklusjon, hvorfor interessant og verifisert https-kilde.</span>
    `;
  }

  function renderStoreEarningWorkbar() {
    if (!elements.storeEarningWorkbar) {
      return;
    }

    const readinessList = state.storeEarningRates.map((rate) => storeEarningReadiness(storeEarningDraftFromRate(rate)));
    const readyCount = readinessList.filter((readiness) => readiness.level === "ready").length;
    const warningCount = readinessList.filter((readiness) => readiness.level === "warning").length;
    const blockedCount = readinessList.filter((readiness) => readiness.level === "blocked").length;

    elements.storeEarningWorkbar.innerHTML = `
      ${renderWorkbarMetric("Klar", readyCount)}
      ${renderWorkbarMetric("Bør sjekkes", warningCount)}
      ${renderWorkbarMetric("Mangler", blockedCount)}
      <span class="workbar-hint">Publiser og neste draft holder flyten rask.</span>
    `;
  }

  function renderWorkbarMetric(label, value) {
    return `
      <span class="workbar-metric">
        <strong>${escapeHtml(String(value))}</strong>
        <span>${escapeHtml(label)}</span>
      </span>
    `;
  }

  function setActivePanel(panelId) {
    const validPanelIds = ["queue-panel", "campaign-panel", "store-earning-panel", "program-guide-panel"];
    state.activePanelId = validPanelIds.includes(panelId) ? panelId : "queue-panel";

    [elements.queuePanel, elements.campaignPanel, elements.storeEarningPanel, elements.programGuidePanel].forEach((panel) => {
      panel.classList.toggle("hidden", panel.id !== state.activePanelId);
    });

    elements.workspaceNavButtons.forEach((button) => {
      const isActive = button.getAttribute("data-panel-target") === state.activePanelId;
      button.classList.toggle("active", isActive);
      button.setAttribute("aria-current", isActive ? "page" : "false");
    });
    updateActivePanelDensity();
  }

  function setSidebarCollapsed(isCollapsed) {
    state.sidebarCollapsed = Boolean(isCollapsed);
    elements.workspaceFrame.classList.toggle("sidebar-collapsed", state.sidebarCollapsed);
    elements.workspaceNavToggle.textContent = state.sidebarCollapsed ? "Vis meny" : "Skjul meny";
    elements.workspaceNavToggle.setAttribute("aria-expanded", state.sidebarCollapsed ? "false" : "true");
    window.localStorage.setItem(SIDEBAR_STORAGE_KEY, state.sidebarCollapsed ? "true" : "false");
  }

  function updateActivePanelDensity() {
    elements.opsOverview.classList.toggle("compact", state.activePanelId === "program-guide-panel");
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
          ${renderCandidateSignalBadge(candidate)}
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
      const readiness = campaignReadiness(campaignDraftFromCampaign(campaign));
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
          ${renderReadinessBadge(readiness)}
        </div>
        <h3>${escapeHtml(campaign.title || "Uten tittel")}</h3>
        <p>${escapeHtml(campaign.editorialAssessment && campaign.editorialAssessment.decisionSummary
          ? campaign.editorialAssessment.decisionSummary
          : campaign.summary || "Ingen oppsummering ennå.")}</p>
        <div class="candidate-meta">
          <span>Sist oppdatert ${formatDateTime(campaign.updatedAt)}</span>
          <span>•</span>
          <span>${readiness.blockers.length ? `${readiness.blockers.length} mangler` : "Ingen blokkere"}</span>
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

  function renderStoreEarningList() {
    elements.storeEarningList.innerHTML = "";

    if (!state.storeEarningRates.length) {
      return;
    }

    state.storeEarningRates.forEach((rate) => {
      const readiness = storeEarningReadiness(storeEarningDraftFromRate(rate));
      const item = document.createElement("li");
      item.className = "queue-item";

      if (rate.id === state.selectedStoreEarningRateId) {
        item.classList.add("selected");
      }

      item.innerHTML = `
        <div class="badge-row">
          ${renderStoreEarningBadge(rate.status)}
          ${rate.store ? renderStoreBadge(rate.store.status) : ""}
          ${rate.method ? renderMetaBadge(rate.method.name) : ""}
          ${renderReadinessBadge(readiness)}
        </div>
        <h3>${escapeHtml(rate.store ? rate.store.name : "Ukjent butikk")}</h3>
        <p>${escapeHtml(rate.rateLabel || "Ingen sats ennå.")}</p>
        <div class="candidate-meta">
          <span>${escapeHtml(rate.sourceTitle || "Ukjent kilde")}</span>
          <span>•</span>
          <span>${rate.checkedAt ? `Kontrollert ${formatDateTime(rate.checkedAt)}` : "Ikke kontrollert"}</span>
        </div>
      `;

      item.addEventListener("click", function () {
        state.selectedStoreEarningRateId = rate.id;
        renderStoreEarningList();
        renderStoreEarningDetail();
      });

      elements.storeEarningList.appendChild(item);
    });
  }

  function renderProgramGuideList() {
    elements.programGuideList.innerHTML = "";

    const guides = [...state.programGuides];

    if (state.newProgramGuideDraft) {
      guides.unshift(state.newProgramGuideDraft);
    }

    if (!guides.length) {
      const item = document.createElement("li");
      item.className = "queue-item";
      item.innerHTML = `
        <h3>Ingen guider ennå</h3>
        <p>Trykk Ny guide for å opprette første guide.</p>
      `;
      elements.programGuideList.appendChild(item);
      return;
    }

    guides.forEach((guide) => {
      const program = programForGuide(guide);
      const item = document.createElement("li");
      item.className = "queue-item";

      if ((guide.isNewDraft && state.selectedProgramGuideId === "new") || guide.id === state.selectedProgramGuideId) {
        item.classList.add("selected");
      }

      item.innerHTML = `
        <div class="badge-row">
          ${renderProgramGuideBadge(guide.status)}
          ${renderMetaBadge(program ? program.slug : "uten-program")}
        </div>
        <h3>${escapeHtml(programGuideTitle(guide, program))}</h3>
        <p>${escapeHtml(firstTextLine(markdownExcerpt(programGuideEditorMarkdown(guide, program)), "Ingen guideinnhold ennå."))}</p>
        <div class="candidate-meta">
          <span>${guide.updatedAt ? `Sist oppdatert ${formatDateTime(guide.updatedAt)}` : "Ikke lagret"}</span>
          <span>•</span>
          <span>${guide.lastReviewedAt ? `Kontrollert ${formatDateTime(guide.lastReviewedAt)}` : "Ikke kontrollert"}</span>
        </div>
      `;

      item.addEventListener("click", function () {
        state.selectedProgramGuideId = guide.isNewDraft ? "new" : guide.id;
        state.selectedProgramGuideProgramId = guide.programId;
        if (!guide.isNewDraft) {
          state.newProgramGuideDraft = null;
        }
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
    const isStoreEarning = isStoreEarningCandidate(candidate);
    const canPromote = !candidate.promotedCampaignId && !candidate.promotedStoreEarningRateId;
    const canReject = canPromote && candidate.status !== "rejected";
    const promotionAction = isStoreEarning
      ? `<button type="button" data-action="promote_store_earning">Lag butikkdraft</button>`
      : `<button type="button" data-action="promote">Lag kampanjedraft</button>`;
    const promotionHelp = isStoreEarning
      ? "Draften åpnes i Butikker før publisering."
      : "Draften åpnes i Kampanjer før publisering.";
    const categoryControl = isStoreEarning && canPromote
      ? `
        <section>
          <h3>Kategori</h3>
          <label class="field">
            <span>Velg før butikkdraft lages</span>
            <select id="candidate-store-category-input">
              <option value="">Ingen valgt</option>
              ${renderSelectOptions(state.categories, candidate.suggestedCategoryId)}
            </select>
          </label>
        </section>
      `
      : "";
    elements.detailPanel.innerHTML = `
      <div class="detail-copy">
        <div class="badge-row">
          ${renderBadge(candidate.status)}
          ${renderCandidateSignalBadge(candidate)}
          ${candidate.suggestedProgramName ? renderMetaBadge(candidate.suggestedProgramName) : ""}
          ${candidate.suggestedCategoryName ? renderMetaBadge(candidate.suggestedCategoryName) : ""}
        </div>

        <div>
          <h2>${escapeHtml(candidate.title)}</h2>
          <p>${escapeHtml(candidate.summary)}</p>
          <div class="candidate-source-line">
            <span>${escapeHtml(candidate.sourceName)}</span>
            <span>•</span>
            <span>Oppdaget ${formatDateTime(candidate.detectedAt)}</span>
          </div>
        </div>

        <section>
          <h3>Review-signal</h3>
          <div class="signal-grid">
            ${renderSignalItem("Shop slug", candidate.shopSlug || "Mangler", Boolean(candidate.shopSlug))}
            ${renderSignalItem("Klar sats", candidate.missingBonusValue ? "Mangler verdi" : "Har verdi", !candidate.missingBonusValue)}
            ${renderSignalItem("Kategori", candidate.needsCategoryReview ? "Usikker" : "Tydelig", !candidate.needsCategoryReview)}
            ${renderSignalItem("Butikkmatch", candidate.matchesExistingStore ? candidate.matchedStoreName || "Matcher" : "Ny butikk", candidate.matchesExistingStore)}
            ${renderSignalItem("Metode", candidate.hasExistingStoreMethodRate ? "Mulig duplikat" : candidate.suggestedMethodSlug || "Ikke butikk", !candidate.hasExistingStoreMethodRate)}
          </div>
        </section>

        <section>
          <h3>Kildelenke</h3>
          <a href="${escapeAttribute(candidate.sourceUrl)}" target="_blank" rel="noreferrer">
            ${escapeHtml(candidate.sourceUrl)}
          </a>
        </section>

        ${categoryControl}

        <details class="optional-detail">
          <summary>Mer</summary>
          <section>
            <h3>Intern note</h3>
            <textarea id="review-note-input" rows="4" placeholder="Valgfritt notat...">${escapeHtml(
              candidate.reviewNote
            )}</textarea>
          </section>
          <div class="detail-meta">
            <span>Status: ${escapeHtml(STATUS_LABELS[candidate.status] || candidate.status)}</span>
            <span>•</span>
            <span>Ingest: ${escapeHtml(candidate.ingestKind)}</span>
          </div>
        </details>

        ${
          candidate.promotedCampaignId
            ? `<section><h3>Promotert kampanje</h3><p><code>${escapeHtml(candidate.promotedCampaignId)}</code></p><button type="button" class="secondary" data-open-campaign="${escapeAttribute(candidate.promotedCampaignId)}">Åpne draft-editor</button></section>`
            : ""
        }
        ${
          candidate.promotedStoreEarningRateId
            ? `<section><h3>Promotert butikkopptjening</h3><p><code>${escapeHtml(candidate.promotedStoreEarningRateId)}</code></p><p class="help">Satsen er opprettet som draft og må kontrolleres før publisering.</p></section>`
            : ""
        }

        <div class="detail-actions">
          <div class="action-row">
            ${canPromote ? promotionAction : ""}
            ${canReject ? `<button type="button" class="danger" data-action="rejected">Avvis</button>` : ""}
          </div>
          <span class="help">${escapeHtml(promotionHelp)} Publisering skjer fortsatt separat.</span>
        </div>
      </div>
    `;

    elements.detailPanel.querySelectorAll("button[data-action]").forEach((button) => {
      button.addEventListener("click", async function () {
        const noteInput = elements.detailPanel.querySelector("#review-note-input");
        const note = noteInput ? noteInput.value.trim() : "";
        const action = button.getAttribute("data-action");
        const originalLabel = button.textContent;
        button.disabled = true;
        button.textContent = "Jobber...";

        try {
          let successMessage = "Kandidaten ble oppdatert.";

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
          } else if (action === "promote_store_earning") {
            const categoryInput = elements.detailPanel.querySelector("#candidate-store-category-input");
            const storeEarningRateId = await apiRequest("/rest/v1/rpc/promote_ingestion_candidate_to_store_earning", {
              method: "POST",
              body: {
                p_candidate_id: candidate.id,
                p_category_id: categoryInput ? emptyToNull(categoryInput.value) : null,
                p_review_note: note || null
              }
            });

            state.selectedStoreEarningRateId = storeEarningRateId;
            elements.storeEarningStatusFilter.value = "draft";
            await refreshStoreEarningRates();
            setActivePanel("store-earning-panel");
            successMessage = "Butikkopptjening ble opprettet som draft. Kontroller og publiser i Butikker.";
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

          setMessage(elements.queueMessage, successMessage, "success");
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
    const readiness = campaignReadiness(campaignDraftFromCampaign(campaign));

    elements.campaignDetailPanel.classList.remove("empty");
    elements.campaignDetailPanel.innerHTML = `
      <form id="campaign-editor-form" class="detail-form">
        <div class="badge-row">
          ${renderCampaignBadge(campaign.status)}
          ${campaign.primaryProgramId ? renderMetaBadge(programName(campaign.primaryProgramId)) : ""}
          ${campaign.categoryId ? renderMetaBadge(categoryName(campaign.categoryId)) : ""}
          ${renderReadinessBadge(readiness)}
        </div>

        <div id="campaign-readiness" class="draft-readiness campaign-readiness">
          ${renderCampaignReadiness(readiness)}
        </div>

        <section class="section-stack priority-section">
          <div class="section-heading-row">
            <div>
              <h3>Beslutning først</h3>
              <p class="section-help">Dette er teksten brukeren skal forstå raskest i appen.</p>
            </div>
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
        </section>

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
            <div>
              <h3>Redaksjonell vurdering</h3>
              <p class="section-help">Skill vurderingen fra dokumenterte fakta og vilkår.</p>
            </div>
            <button type="button" class="secondary compact-button" data-ai-action="suggest-editorial">
              Foreslå med AI
            </button>
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
      updateCampaignDraftAssist(form);
    });
    form.addEventListener("change", function () {
      updateCampaignDraftAssist(form);
    });
    updateCampaignDraftAssist(form);
  }

  function renderStoreEarningDetail() {
    const rate = state.storeEarningRates.find((entry) => entry.id === state.selectedStoreEarningRateId);

    if (!rate) {
      renderEmptyStoreEarningDetail("Velg en sats for å redigere butikkopptjening.");
      return;
    }

    const store = rate.store || {
      id: rate.storeId,
      slug: "",
      name: "",
      categoryId: null,
      status: "draft",
      websiteUrl: "",
      searchKeywords: [],
      lastVerifiedAt: null
    };
    const draft = storeEarningDraftFromRate(rate);
    const readiness = storeEarningReadiness(draft);

    elements.storeEarningDetailPanel.classList.remove("empty");
    elements.storeEarningDetailPanel.innerHTML = `
      <form id="store-earning-editor-form" class="detail-form">
        <div class="badge-row">
          ${renderStoreEarningBadge(rate.status)}
          ${renderStoreBadge(store.status)}
          ${rate.method ? renderMetaBadge(rate.method.name) : ""}
          ${store.categoryId ? renderMetaBadge(categoryName(store.categoryId)) : ""}
          ${renderReadinessBadge(readiness)}
        </div>

        <div id="store-earning-readiness" class="draft-readiness store-readiness">
          ${renderStoreEarningReadiness(readiness)}
        </div>

        <section class="section-stack">
          <h3>Butikk</h3>
          <div class="detail-grid">
            <label class="field">
              <span>Butikknavn</span>
              <input name="storeName" type="text" value="${escapeAttribute(store.name)}" required />
            </label>

            <label class="field">
              <span>Butikkstatus</span>
              <select name="storeStatus">
                ${renderStoreStatusOptions(store.status)}
              </select>
            </label>
          </div>

          <div class="detail-grid">
            <label class="field">
              <span>Kategori</span>
              <select name="storeCategoryId">
                <option value="">Ingen valgt</option>
                ${renderSelectOptions(state.categories, store.categoryId)}
              </select>
            </label>

            <label class="field">
              <span>Butikk-URL</span>
              <input name="storeWebsiteUrl" type="url" value="${escapeAttribute(store.websiteUrl)}" />
            </label>
          </div>

          <label class="field">
            <span>Søkeord, ett per linje</span>
            <textarea name="storeSearchKeywords" rows="4">${escapeHtml(store.searchKeywords.join("\n"))}</textarea>
          </label>
        </section>

        <section class="section-stack">
          <h3>Sats</h3>
          <div class="detail-grid">
            <label class="field">
              <span>Satsstatus</span>
              <select name="rateStatus">
                ${renderStoreEarningStatusOptions(rate.status)}
              </select>
            </label>

            <label class="field">
              <span>Metode</span>
              <select name="earningMethodId">
                ${renderSelectOptions(storeEarningMethods(), rate.earningMethodId)}
              </select>
            </label>
          </div>

          <div class="detail-grid">
            <label class="field">
              <span>Rate-label</span>
              <input name="rateLabel" type="text" value="${escapeAttribute(rate.rateLabel)}" required />
            </label>

            <label class="field">
              <span>Normal sats</span>
              <input name="normalRateLabel" type="text" value="${escapeAttribute(rate.normalRateLabel)}" />
            </label>
          </div>

          <label class="field">
            <span>Verdiforklaring</span>
            <textarea name="valueSummary" rows="3">${escapeHtml(rate.valueSummary)}</textarea>
          </label>

          <label class="field">
            <span>Krav</span>
            <textarea name="requirementSummary" rows="3">${escapeHtml(rate.requirementSummary)}</textarea>
          </label>

          <label class="field">
            <span>Varsel / forbehold</span>
            <textarea name="warningText" rows="3">${escapeHtml(rate.warningText)}</textarea>
          </label>

          <div class="detail-grid">
            <label class="field">
              <span>Handoff-URL</span>
              <input name="handoffUrl" type="url" value="${escapeAttribute(rate.handoffUrl)}" />
            </label>

            <label class="field">
              <span>Kilde-URL</span>
              <input name="sourceUrl" type="url" value="${escapeAttribute(rate.sourceUrl)}" />
            </label>
          </div>

          <div class="detail-grid">
            <label class="field">
              <span>Kildetittel</span>
              <input name="sourceTitle" type="text" value="${escapeAttribute(rate.sourceTitle)}" />
            </label>

            <label class="field">
              <span>Kontrolltidspunkt</span>
              <input name="checkedAt" type="datetime-local" value="${escapeAttribute(toDateTimeLocalValue(rate.checkedAt))}" />
            </label>
          </div>

          <div class="detail-grid">
            <label class="field">
              <span>Starter</span>
              <input name="startsAt" type="datetime-local" value="${escapeAttribute(toDateTimeLocalValue(rate.startsAt))}" />
            </label>

            <label class="field">
              <span>Slutter</span>
              <input name="endsAt" type="datetime-local" value="${escapeAttribute(toDateTimeLocalValue(rate.endsAt))}" />
            </label>
          </div>

          <div class="detail-grid">
            <label class="field">
              <span>Sortering</span>
              <input name="sortOrder" type="number" step="1" value="${escapeAttribute(rate.sortOrder)}" />
            </label>

            <label class="field checkbox-field">
              <span>Grunnsats</span>
              <label class="checkbox-row">
                <input name="isBaseRate" type="checkbox" ${rate.isBaseRate ? "checked" : ""} />
                <span>Vis som vanlig opptjening</span>
              </label>
            </label>
          </div>
        </section>

        <div class="detail-actions">
          <div class="action-row">
            <button type="submit">Lagre endringer</button>
            <button type="button" class="success" data-store-earning-action="publish">Publiser kontrollert</button>
            <button type="button" class="success" data-store-earning-action="publish_next">Publiser og neste draft</button>
            <button type="button" class="secondary" data-store-earning-action="archive">Arkiver sats</button>
          </div>
          <span class="help">Publisering setter både butikk og sats til published. Røde punkter blokkerer publisering; gule punkter bør kontrolleres før du trykker.</span>
        </div>
      </form>
    `;

    const form = elements.storeEarningDetailPanel.querySelector("#store-earning-editor-form");
    form.addEventListener("submit", async function (event) {
      event.preventDefault();
      await saveStoreEarningEditor(form, rate, null);
    });

    elements.storeEarningDetailPanel.querySelectorAll("[data-store-earning-action]").forEach((button) => {
      button.addEventListener("click", async function () {
        const action = button.getAttribute("data-store-earning-action");
        if (action === "publish" || action === "publish_next") {
          await saveStoreEarningEditor(form, rate, "published", { selectNextDraft: action === "publish_next" });
          return;
        }

        await saveStoreEarningEditor(form, rate, "archived");
      });
    });

    form.addEventListener("input", function () {
      updateStoreEarningDraftAssist(form, rate);
    });
    form.addEventListener("change", function () {
      updateStoreEarningDraftAssist(form, rate);
    });
    updateStoreEarningDraftAssist(form, rate);
  }

  function renderEmptyStoreEarningDetail(message) {
    elements.storeEarningDetailPanel.classList.add("empty");
    elements.storeEarningDetailPanel.innerHTML = `<p>${escapeHtml(message)}</p>`;
  }

  function renderEmptyCampaignDetail(message) {
    elements.campaignDetailPanel.classList.add("empty");
    elements.campaignDetailPanel.innerHTML = `<p>${escapeHtml(message)}</p>`;
  }

  function renderProgramGuideDetail() {
    const guide = selectedProgramGuide();
    const draft = guide || state.newProgramGuideDraft;
    const program = draft ? programForGuide(draft) : null;

    if (!draft || !program) {
      renderEmptyProgramGuideDetail("Velg eller opprett en guide.");
      return;
    }

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

            <div class="detail-grid">
              <label class="field">
                <span>Program</span>
                <select name="programId">
                  ${renderSelectOptions(state.programs, draft.programId)}
                </select>
              </label>

              <label class="field">
                <span>Status</span>
                <select name="status">
                  ${renderProgramGuideStatusOptions(draft.status)}
                </select>
              </label>
            </div>

            <label class="field">
              <span>Tittel</span>
              <input
                name="title"
                type="text"
                placeholder="For eksempel: Slik fungerer ${escapeAttribute(program ? program.name : "programmet")}"
                value="${escapeAttribute(programGuideTitle(draft, program))}"
              />
            </label>

            <label class="field">
              <span>Guideinnhold</span>
              <textarea name="bodyMarkdown" rows="24" class="markdown-editor" placeholder="# ${escapeAttribute(programGuideTitle(draft, program))}&#10;&#10;Kort intro til programmet.&#10;&#10;## Slik tjener du poeng&#10;- Punkt én&#10;- Punkt to">${escapeHtml(
                programGuideEditorMarkdown(draft, program)
              )}</textarea>
              <span class="hint">Skriv Markdown: # overskrift, ## seksjon, vanlige avsnitt og punktlister med -. Rå HTML lagres som tekst og rendres ikke som HTML i appen.</span>
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
              <span class="help">Publisering krever guideinnhold og kontrolltidspunkt. Hold innholdet redaksjonelt og uten kampanjelenker.</span>
            </div>
          </section>

          <aside class="program-guide-preview-pane${state.programGuidePreviewExpanded ? " preview-expanded" : ""}">
            <div class="preview-sticky">
              <section class="program-guide-side-section">
                <div class="preview-heading">
                  <div>
                    <span>Review</span>
                    <strong>Publiseringssjekk</strong>
                  </div>
                </div>
                <div class="draft-readiness" aria-live="polite">
                  ${renderProgramGuideReadiness(readiness)}
                </div>
                ${renderProgramGuideSchemaNotice()}
              </section>

              <section class="program-guide-side-section">
                <div class="preview-heading">
                  <div>
                    <span>Forhåndsvisning</span>
                    <strong>${escapeHtml(programGuideTitle(draft, program))}</strong>
                  </div>
                  <div class="preview-tools">
                    <div class="preview-mode-tabs" aria-label="Preview mode">
                      <span class="active">Mobil</span>
                      <span>Artikkel</span>
                    </div>
                    <button type="button" class="secondary compact-button" data-guide-preview-toggle>
                      ${state.programGuidePreviewExpanded ? "Kort preview" : "Full preview"}
                    </button>
                  </div>
                </div>
                <div id="program-guide-live-preview">
                  ${renderProgramGuidePreview(program, draft)}
                </div>
              </section>
            </div>
          </aside>
        </div>
      </form>
    `;

    const form = elements.programGuideDetailPanel.querySelector("#program-guide-editor-form");
    form.addEventListener("submit", async function (event) {
      event.preventDefault();
      await saveProgramGuideEditor(form, guide, null);
    });

    elements.programGuideDetailPanel.querySelectorAll("[data-guide-action]").forEach((button) => {
      button.addEventListener("click", async function () {
        await saveProgramGuideEditor(form, guide, button.getAttribute("data-guide-action"));
      });
    });

    const previewToggleButton = elements.programGuideDetailPanel.querySelector("[data-guide-preview-toggle]");
    if (previewToggleButton) {
      previewToggleButton.addEventListener("click", function () {
        state.programGuidePreviewExpanded = !state.programGuidePreviewExpanded;
        renderProgramGuideDetail();
      });
    }

    form.addEventListener("input", function () {
      updateProgramGuideDraftAssist(form);
    });
    form.addEventListener("change", function () {
      updateProgramGuideDraftAssist(form);
    });
    updateProgramGuideDraftAssist(form);
  }

  function renderEmptyProgramGuideDetail(message) {
    elements.programGuideDetailPanel.classList.add("empty");
    elements.programGuideDetailPanel.innerHTML = `<p>${escapeHtml(message)}</p>`;
  }

  function emptyProgramGuideDraft(programId, title = "") {
    return {
      id: null,
      isNewDraft: true,
      programId,
      status: "draft",
      title,
      introText: "",
      bodyMarkdown: "",
      strategy: "",
      valueEstimateLabel: "",
      valueEstimateDetail: "",
      expirationSummary: "",
      expirationDetail: "",
      guideKicker: "PROGRAMGUIDE",
      readingTimeLabel: "4 min lesing",
      strategySectionTitle: "Slik bør du bruke det",
      decisionSectionTitle: "Før du går videre",
      earningDecisionLabel: "Tjen poeng når",
      redemptionDecisionLabel: "Bruk poeng når",
      riskDecisionLabel: "Stopp opp hvis",
      earningSectionTitle: "Slik tjener du poeng",
      earningSectionIntro: "Start med det du allerede skal kjøpe eller bruke.",
      redemptionSectionTitle: "Slik bruker du poengene smart",
      redemptionSectionIntro: "Bruk poengene der du ser hva du får igjen.",
      riskSectionTitle: "Vanlige feller",
      riskSectionIntro: "Ting som kan gjøre en god kampanje mindre god.",
      campaignsSectionTitle: "",
      campaignsSectionIntro: "",
      earningTips: [],
      redemptionTips: [],
      riskNotes: [],
      lastReviewedAt: null,
      updatedAt: null
    };
  }

  function collectProgramGuideDraftFromForm(form) {
    const formData = new FormData(form);
    const programId = String(formData.get("programId") || state.programs[0]?.id || "").trim();
    return {
      ...emptyProgramGuideDraft(programId),
      id: state.selectedProgramGuideId === "new" ? null : state.selectedProgramGuideId,
      isNewDraft: state.selectedProgramGuideId === "new",
      programId,
      status: String(formData.get("status") || "draft"),
      title: String(formData.get("title") || "").trim(),
      bodyMarkdown: String(formData.get("bodyMarkdown") || "").trim(),
      campaignsSectionTitle: "",
      campaignsSectionIntro: "",
      lastReviewedAt: String(formData.get("lastReviewedAt") || "").trim()
    };
  }

  function programGuideReadiness(guide) {
    const bodyMarkdown = guide.bodyMarkdown || "";
    const checks = [
      {
        label: "Tittel",
        complete: Boolean(guide.title),
        help: "Gi guiden en tydelig tittel."
      },
      {
        label: "Guideinnhold",
        complete: Boolean(bodyMarkdown),
        help: "Hele guiden skrives i Markdown-feltet."
      },
      {
        label: "Overskrift",
        complete: /^#{1,3}\s+\S/m.test(bodyMarkdown),
        help: "Bruk minst én # eller ## overskrift."
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

  function programGuideEditorMarkdown(guide, program) {
    if (guide.bodyMarkdown) {
      return guide.bodyMarkdown;
    }

    const sections = [];
    const intro = guide.introText || "";
    const strategy = guide.strategy || "";

    sections.push(`# ${programGuideTitle(guide, program)}`);

    if (intro) {
      sections.push(intro);
    }

    if (strategy) {
      sections.push(`## ${guide.strategySectionTitle || "Slik bør du bruke det"}\n\n${strategy}`);
    }

    appendMarkdownList(sections, guide.earningSectionTitle || "Slik tjener du poeng", guide.earningTips);
    appendMarkdownList(sections, guide.redemptionSectionTitle || "Slik bruker du poengene smart", guide.redemptionTips);
    appendMarkdownList(sections, guide.riskSectionTitle || "Vanlige feller", guide.riskNotes);

    return sections.join("\n\n");
  }

  function appendMarkdownList(sections, title, items) {
    if (!Array.isArray(items) || !items.length) {
      return;
    }

    sections.push(`## ${title}\n\n${items.map((item) => `- ${item}`).join("\n")}`);
  }

  function markdownExcerpt(markdown) {
    const blocks = markdownBlocks(markdown);
    const firstText = blocks.find((block) => block.type === "paragraph" || block.type === "bullet");
    return firstText ? firstText.text : "";
  }

  function renderMarkdownPreview(markdown) {
    const blocks = markdownBlocks(markdown);

    if (!blocks.length) {
      return `<p class="program-preview-empty">Guiden vises her når du skriver.</p>`;
    }

    return blocks
      .map((block) => {
        if (block.type === "heading") {
          const tag = block.level === 1 ? "h4" : "h5";
          return `<${tag}>${escapeHtml(block.text)}</${tag}>`;
        }

        if (block.type === "bullet") {
          return `<p class="program-preview-bullet"><span aria-hidden="true"></span>${escapeHtml(block.text)}</p>`;
        }

        return `<p>${escapeHtml(block.text)}</p>`;
      })
      .join("");
  }

  function markdownBlocks(markdown) {
    const blocks = [];
    let paragraph = [];

    function flushParagraph() {
      const text = paragraph.join(" ").trim();
      if (text) {
        blocks.push({ type: "paragraph", text });
      }
      paragraph = [];
    }

    String(markdown || "")
      .split(/\r?\n/)
      .forEach((rawLine) => {
        const line = rawLine.trim();

        if (!line) {
          flushParagraph();
          return;
        }

        const headingMatch = /^(#{1,3})\s+(.+)$/.exec(line);
        if (headingMatch) {
          flushParagraph();
          blocks.push({ type: "heading", level: headingMatch[1].length, text: headingMatch[2].trim() });
          return;
        }

        const bulletMatch = /^[-*]\s+(.+)$/.exec(line);
        if (bulletMatch) {
          flushParagraph();
          blocks.push({ type: "bullet", text: bulletMatch[1].trim() });
          return;
        }

        paragraph.push(line);
      });

    flushParagraph();
    return blocks;
  }

  function renderProgramGuidePreview(program, guide) {
    const markdown = programGuideEditorMarkdown(guide, program);
    const title = programGuideTitle(guide, program);

    return `
      <div class="program-preview-device">
        <div class="program-preview-device-bar">
          <span></span>
          <strong>${escapeHtml(title)}</strong>
          <span></span>
        </div>

        <article class="program-preview-card">
          <header class="program-preview-hero">
            <div class="program-preview-mark">${escapeHtml(programInitials(program))}</div>
            <div>
              <span>PROGRAMGUIDE</span>
              <h3>${escapeHtml(title)}</h3>
            </div>
          </header>

          <section class="program-preview-markdown">
            ${renderMarkdownPreview(markdown)}
          </section>

        </article>
      </div>
    `;
  }

  function updateProgramGuideDraftAssist(form) {
    const draft = collectProgramGuideDraftFromForm(form);
    const program = programForGuide(draft);
    const readinessContainer = form.querySelector(".draft-readiness");
    const previewContainer = form.querySelector("#program-guide-live-preview");

    if (readinessContainer) {
      readinessContainer.innerHTML = renderProgramGuideReadiness(programGuideReadiness(draft));
    }

    if (previewContainer) {
      previewContainer.innerHTML = renderProgramGuidePreview(program, draft);
    }

    updateProgramGuidePublishButtonState(form, programGuideReadiness(draft));
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

  async function saveProgramGuideEditor(form, originalGuide, action) {
    if (!state.programGuideManualCopyAvailable) {
      setMessage(
        elements.programGuideMessage,
        "Kan ikke lagre hele guiden før Supabase-migrasjonen for nye guidefelter er kjørt.",
        "error"
      );
      return;
    }

    const formData = new FormData(form);
    const payload = collectProgramGuideFormData(formData, originalGuide, action);
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
      const savedGuideId = await upsertProgramGuide(payload);
      state.newProgramGuideDraft = null;
      state.selectedProgramGuideId = savedGuideId || payload.id;
      state.selectedProgramGuideProgramId = payload.programId;
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

  function renderProgramGuideSchemaNotice() {
    if (state.programGuideManualCopyAvailable) {
      return "";
    }

    return `
      <div class="schema-notice">
        Databasen mangler nye guidefelter. Admin viser eksisterende innhold, men Markdown-redigering krever migrasjonen
        <code>20260902083000_allow_multiple_program_guides.sql</code>.
      </div>
    `;
  }

  async function saveStoreEarningEditor(form, originalRate, overrideRateStatus, options = {}) {
    const formData = new FormData(form);
    const payload = collectStoreEarningFormData(formData, originalRate, overrideRateStatus);
    const validationErrors = validateStoreEarningPayload(payload);

    if (validationErrors.length) {
      setMessage(elements.storeEarningMessage, validationErrors.join(" "), "error");
      return;
    }

    const submitButtons = form.querySelectorAll("button");
    submitButtons.forEach((button) => {
      button.disabled = true;
    });

    try {
      await saveStoreEarningRate(payload);
      if (options.selectNextDraft) {
        elements.storeEarningStatusFilter.value = "draft";
      }
      await refreshStoreEarningRates();
      if (options.selectNextDraft) {
        const message = state.storeEarningRates.length
          ? "Publisert. Neste draft er valgt."
          : "Publisert. Ingen flere draft-satser i filteret.";
        setMessage(elements.storeEarningMessage, message, "success");
      } else {
        setMessage(elements.storeEarningMessage, "Butikkopptjeningen ble lagret.", "success");
      }
    } catch (error) {
      setMessage(elements.storeEarningMessage, error.message, "error");
    } finally {
      submitButtons.forEach((button) => {
        button.disabled = false;
      });
    }
  }

  function collectStoreEarningFormData(formData, originalRate, overrideRateStatus) {
    const storeWebsiteUrl = String(formData.get("storeWebsiteUrl") || "").trim();
    const handoffUrl = String(formData.get("handoffUrl") || "").trim();
    const sourceUrl = String(formData.get("sourceUrl") || "").trim();
    const checkedAt = String(formData.get("checkedAt") || "").trim();
    const startsAt = String(formData.get("startsAt") || "").trim();
    const endsAt = String(formData.get("endsAt") || "").trim();
    const rateStatus = overrideRateStatus || String(formData.get("rateStatus") || "draft");

    return {
      id: originalRate.id,
      storeId: originalRate.storeId,
      storeName: String(formData.get("storeName") || "").trim(),
      storeStatus: rateStatus === "published"
        ? "published"
        : String(formData.get("storeStatus") || "draft"),
      storeCategoryId: emptyToNull(formData.get("storeCategoryId")),
      storeWebsiteUrl: storeWebsiteUrl || null,
      storeSearchKeywords: splitTextareaLines(formData.get("storeSearchKeywords")),
      earningMethodId: emptyToNull(formData.get("earningMethodId")),
      rateStatus,
      rateLabel: String(formData.get("rateLabel") || "").trim(),
      normalRateLabel: emptyToNull(formData.get("normalRateLabel")),
      valueSummary: emptyToNull(formData.get("valueSummary")),
      requirementSummary: emptyToNull(formData.get("requirementSummary")),
      warningText: emptyToNull(formData.get("warningText")),
      handoffUrl: handoffUrl || null,
      sourceUrl: sourceUrl || null,
      sourceTitle: emptyToNull(formData.get("sourceTitle")),
      checkedAt: checkedAt ? toISOString(checkedAt) : null,
      startsAt: startsAt ? toISOString(startsAt) : null,
      endsAt: endsAt ? toISOString(endsAt) : null,
      sortOrder: parseIntegerOrDefault(formData.get("sortOrder"), 0),
      isBaseRate: formData.get("isBaseRate") === "on"
    };
  }

  function storeEarningDraftFromRate(rate) {
    const store = rate.store || {};

    return {
      storeName: store.name || "",
      storeStatus: store.status || "draft",
      storeCategoryId: store.categoryId || null,
      storeWebsiteUrl: store.websiteUrl || null,
      storeSearchKeywords: Array.isArray(store.searchKeywords) ? store.searchKeywords : [],
      earningMethodId: rate.earningMethodId || "",
      rateStatus: rate.status || "draft",
      rateLabel: rate.rateLabel || "",
      normalRateLabel: rate.normalRateLabel || null,
      valueSummary: rate.valueSummary || null,
      requirementSummary: rate.requirementSummary || null,
      warningText: rate.warningText || null,
      handoffUrl: rate.handoffUrl || null,
      sourceUrl: rate.sourceUrl || null,
      sourceTitle: rate.sourceTitle || null,
      checkedAt: rate.checkedAt || null,
      startsAt: rate.startsAt || null,
      endsAt: rate.endsAt || null,
      sortOrder: rate.sortOrder || 0,
      isBaseRate: Boolean(rate.isBaseRate)
    };
  }

  function storeEarningReadiness(payload) {
    const checks = [
      {
        label: "Butikk",
        complete: Boolean(payload.storeName),
        severity: "blocker",
        help: "Butikknavn må være tydelig før publisering."
      },
      {
        label: "Metode",
        complete: Boolean(payload.earningMethodId),
        severity: "blocker",
        help: "Velg SAS Shopping, Trumf eller annen relevant opptjeningsmetode."
      },
      {
        label: "Sats",
        complete: Boolean(payload.rateLabel),
        severity: "blocker",
        help: "Satsen må være synlig, for eksempel poeng per 100 kr eller prosent."
      },
      {
        label: "Kilde",
        complete: Boolean(payload.sourceUrl && isHttpsUrl(payload.sourceUrl)),
        severity: "blocker",
        help: "Kilde må være en https-URL."
      },
      {
        label: "Kontrollert",
        complete: Boolean(payload.checkedAt),
        severity: "blocker",
        help: "Sett tidspunktet satsen ble kontrollert."
      },
      {
        label: "Handoff",
        complete: Boolean(payload.handoffUrl && isHttpsUrl(payload.handoffUrl)),
        severity: "warning",
        help: "Anbefalt for trygg videresending fra appen."
      },
      {
        label: "Krav",
        complete: Boolean(payload.requirementSummary),
        severity: "warning",
        help: "Forklar hvordan handelen må startes for sporing."
      },
      {
        label: "Forbehold",
        complete: !requiresManualStoreReview(payload),
        severity: "warning",
        help: "Sjekk ekstra hvis teksten sier opptil, kampanje, må kontrolleres eller mangler sluttdato."
      }
    ];
    const blockers = checks.filter((check) => check.severity === "blocker" && !check.complete);
    const warnings = checks.filter((check) => check.severity === "warning" && !check.complete);
    const completeCount = checks.filter((check) => check.complete).length;

    return {
      checks,
      blockers,
      warnings,
      completeCount,
      totalCount: checks.length,
      isPublishReady: blockers.length === 0,
      level: blockers.length ? "blocked" : warnings.length ? "warning" : "ready"
    };
  }

  function requiresManualStoreReview(payload) {
    const text = [
      payload.rateLabel,
      payload.normalRateLabel,
      payload.valueSummary,
      payload.requirementSummary,
      payload.warningText
    ]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();

    return (
      text.includes("må kontrolleres")
      || text.includes("opptil")
      || text.includes("kampanje")
      || (text.includes("til ") && !payload.endsAt)
    );
  }

  function renderStoreEarningReadiness(readiness) {
    const heading = readiness.blockers.length
      ? `${readiness.blockers.length} blokkerende mangler`
      : readiness.warnings.length
        ? `${readiness.warnings.length} punkter bør sjekkes`
        : "Klar til publisering";

    return `
      <div class="readiness-header">
        <div>
          <span class="readiness-kicker">Review-status</span>
          <strong>${escapeHtml(heading)}</strong>
        </div>
        <span class="readiness-pill ${escapeAttribute(readiness.level)}">
          ${escapeHtml(readinessLabel(readiness))}
        </span>
      </div>
      <div class="readiness-grid">
        ${readiness.checks
          .map(
            (check) => `
              <div class="readiness-item ${check.complete ? "complete" : check.severity}">
                <span aria-hidden="true">${check.complete ? "✓" : check.severity === "blocker" ? "!" : "?"}</span>
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

  function updateStoreEarningDraftAssist(form, originalRate) {
    const payload = collectStoreEarningFormData(new FormData(form), originalRate, null);
    const readiness = storeEarningReadiness(payload);
    const readinessContainer = form.querySelector("#store-earning-readiness");

    if (readinessContainer) {
      readinessContainer.innerHTML = renderStoreEarningReadiness(readiness);
    }

    updateStoreEarningPublishButtonState(form, readiness);
  }

  function validateStoreEarningPayload(payload) {
    const errors = [];

    if (!payload.storeName) {
      errors.push("Butikknavn mangler.");
    }

    if (!payload.earningMethodId) {
      errors.push("Opptjeningsmetode mangler.");
    }

    if (!payload.rateLabel) {
      errors.push("Rate-label mangler.");
    }

    if (payload.storeWebsiteUrl && !isHttpsUrl(payload.storeWebsiteUrl)) {
      errors.push("Butikk-URL må være en https-URL.");
    }

    if (payload.handoffUrl && !isHttpsUrl(payload.handoffUrl)) {
      errors.push("Handoff-URL må være en https-URL.");
    }

    if (payload.sourceUrl && !isHttpsUrl(payload.sourceUrl)) {
      errors.push("Kilde-URL må være en https-URL.");
    }

    if (payload.startsAt && payload.endsAt && new Date(payload.endsAt) < new Date(payload.startsAt)) {
      errors.push("Sluttdato kan ikke være før startdato.");
    }

    if (payload.rateStatus === "published") {
      if (payload.storeStatus !== "published") {
        errors.push("Publisering krever publisert butikk.");
      }

      if (!payload.sourceUrl) {
        errors.push("Publisering krever kilde-URL.");
      }

      if (!payload.checkedAt) {
        errors.push("Publisering krever kontrolltidspunkt.");
      }
    }

    return errors;
  }

  function collectProgramGuideFormData(formData, originalGuide, action) {
    const now = new Date().toISOString();
    const programId = String(formData.get("programId") || state.programs[0]?.id || "").trim();
    const program = state.programs.find((entry) => entry.id === programId) || null;
    let status = String(formData.get("status") || "draft");
    let lastReviewedAt = String(formData.get("lastReviewedAt") || "").trim();
    const bodyMarkdown = String(formData.get("bodyMarkdown") || "").trim();
    const title = String(formData.get("title") || "").trim() || programGuideTitle({ title: "" }, program);
    const introText = markdownExcerpt(bodyMarkdown);

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
      programId,
      status,
      title,
      introText,
      bodyMarkdown,
      strategy: bodyMarkdown,
      valueEstimateLabel: "",
      valueEstimateDetail: "",
      expirationSummary: "",
      expirationDetail: "",
      guideKicker: "PROGRAMGUIDE",
      readingTimeLabel: "",
      strategySectionTitle: "",
      decisionSectionTitle: "",
      earningDecisionLabel: "",
      redemptionDecisionLabel: "",
      riskDecisionLabel: "",
      earningSectionTitle: "",
      earningSectionIntro: "",
      redemptionSectionTitle: "",
      redemptionSectionIntro: "",
      riskSectionTitle: "",
      riskSectionIntro: "",
      campaignsSectionTitle: "",
      campaignsSectionIntro: "",
      earningTips: [],
      redemptionTips: [],
      riskNotes: [],
      lastReviewedAt: lastReviewedAt ? toISOString(lastReviewedAt) : null
    };
  }

  function validateProgramGuidePayload(payload) {
    const errors = [];

    if (!payload.programId) {
      errors.push("Program mangler.");
    }

    if (!payload.title) {
      errors.push("Guidetittel mangler.");
    }

    if (payload.status === "published") {
      if (!payload.bodyMarkdown) {
        errors.push("Publisering krever guideinnhold.");
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

  function campaignDraftFromCampaign(campaign) {
    const primarySource = campaign.sourceReferences[0] || null;
    const editorialAssessment = campaign.editorialAssessment || {};

    return {
      title: campaign.title || "",
      summary: campaign.summary || "",
      details: campaign.details || "",
      status: campaign.status || "draft",
      primaryProgramId: campaign.primaryProgramId || null,
      categoryId: campaign.categoryId || null,
      editorialSummary: campaign.editorialSummary || null,
      decisionLabel: editorialAssessment.decisionLabel || null,
      decisionSummary: editorialAssessment.decisionSummary || null,
      bestFor: editorialAssessment.bestFor || null,
      notFor: editorialAssessment.notFor || null,
      reasonWhyItMatters: editorialAssessment.reasonWhyItMatters || "",
      estimatedValueText: editorialAssessment.estimatedValueText || null,
      difficultyLevel: editorialAssessment.difficultyLevel || null,
      availabilityScope: editorialAssessment.availabilityScope || null,
      riskNote: editorialAssessment.riskNote || null,
      lastVerifiedAt: campaign.lastVerifiedAt || null,
      requirements: campaign.requirements.map((requirement) => requirement.text),
      sourceId: primarySource ? primarySource.source_id : null,
      sourceTitle: primarySource ? primarySource.title || null : null,
      sourceUrl: primarySource ? primarySource.url || null : null,
      sourceCheckedAt: primarySource ? primarySource.checked_at || null : null,
      sourceEvidenceNote: primarySource ? primarySource.evidence_note || null : null
    };
  }

  function campaignDraftFromForm(form) {
    return collectCampaignFormData(new FormData(form), { id: "" }, null);
  }

  function campaignReadiness(payload) {
    const checks = [
      {
        label: "Tittel",
        complete: Boolean(payload.title),
        severity: "blocker",
        help: "Må være konkret nok til å forstå tilbudet."
      },
      {
        label: "Kort beskrivelse",
        complete: Boolean(payload.summary),
        severity: "blocker",
        help: "Brukes i liste og detalj."
      },
      {
        label: "Detaljer",
        complete: Boolean(payload.details),
        severity: "blocker",
        help: "Forklar vilkår og hvordan tilbudet fungerer."
      },
      {
        label: "Program",
        complete: Boolean(payload.primaryProgramId),
        severity: "blocker",
        help: "EuroBonus eller Trumf må være valgt."
      },
      {
        label: "Kilde",
        complete: Boolean(payload.sourceId && payload.sourceUrl && isHttpsUrl(payload.sourceUrl)),
        severity: "blocker",
        help: "Publisering krever valgt kilde og https-lenke."
      },
      {
        label: "Kontrollert",
        complete: Boolean(payload.lastVerifiedAt),
        severity: "blocker",
        help: "Sett når kampanjen sist ble verifisert."
      },
      {
        label: "Beslutning",
        complete: Boolean(payload.decisionLabel && payload.decisionSummary),
        severity: "blocker",
        help: "Brukeren trenger en kort konklusjon."
      },
      {
        label: "Hvorfor",
        complete: Boolean(payload.reasonWhyItMatters),
        severity: "blocker",
        help: "Redaksjonell begrunnelse må være tydelig."
      },
      {
        label: "Krav",
        complete: payload.requirements.length > 0,
        severity: "warning",
        help: "Anbefalt før publisering, særlig for sporingsvilkår."
      },
      {
        label: "Passer for",
        complete: Boolean(payload.bestFor && payload.notFor),
        severity: "warning",
        help: "Gjør vurderingen lettere å bruke."
      }
    ];
    const blockers = checks.filter((check) => check.severity === "blocker" && !check.complete);
    const warnings = checks.filter((check) => check.severity === "warning" && !check.complete);
    const completeCount = checks.filter((check) => check.complete).length;

    return {
      checks,
      blockers,
      warnings,
      completeCount,
      totalCount: checks.length,
      isPublishReady: blockers.length === 0,
      level: blockers.length ? "blocked" : warnings.length ? "warning" : "ready"
    };
  }

  function renderCampaignReadiness(readiness) {
    const heading = readiness.blockers.length
      ? `${readiness.blockers.length} blokkerende mangler`
      : readiness.warnings.length
        ? `${readiness.warnings.length} punkter bør sjekkes`
        : "Klar til publisering";

    return `
      <div class="readiness-header">
        <div>
          <span class="readiness-kicker">Publiseringssjekk</span>
          <strong>${escapeHtml(heading)}</strong>
        </div>
        <span class="readiness-pill ${escapeAttribute(readiness.level)}">
          ${escapeHtml(readinessLabel(readiness))}
        </span>
      </div>
      <div class="readiness-grid">
        ${readiness.checks
          .map(
            (check) => `
              <div class="readiness-item ${check.complete ? "complete" : check.severity}">
                <span aria-hidden="true">${check.complete ? "✓" : check.severity === "blocker" ? "!" : "?"}</span>
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

  function updateCampaignDraftAssist(form) {
    const readiness = campaignReadiness(campaignDraftFromForm(form));
    const readinessContainer = form.querySelector("#campaign-readiness");

    if (readinessContainer) {
      readinessContainer.innerHTML = renderCampaignReadiness(readiness);
    }

    updatePublishButtonState(form, readiness);
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
      updateCampaignDraftAssist(form);
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

  function updatePublishButtonState(form, readiness) {
    const publishButton = form.querySelector('[data-publish-action="publish"]');
    if (!publishButton) {
      return;
    }

    const resolvedReadiness = readiness || campaignReadiness(campaignDraftFromForm(form));
    const canPublish = resolvedReadiness.isPublishReady;

    publishButton.disabled = !canPublish;
    publishButton.title = canPublish
      ? resolvedReadiness.warnings.length
        ? "Kan publiseres, men gule punkter bør være kontrollert manuelt først."
        : ""
      : `Publisering blokkert: ${resolvedReadiness.blockers.map((check) => check.label).join(", ")}.`;
  }

  function updateStoreEarningPublishButtonState(form, readiness) {
    const publishButtons = form.querySelectorAll(
      '[data-store-earning-action="publish"], [data-store-earning-action="publish_next"]'
    );
    if (!publishButtons.length) {
      return;
    }

    const resolvedReadiness = readiness || storeEarningReadiness(
      collectStoreEarningFormData(new FormData(form), { id: "", storeId: "" }, null)
    );
    const canPublish = resolvedReadiness.isPublishReady;

    publishButtons.forEach((publishButton) => {
      publishButton.disabled = !canPublish;
      publishButton.title = canPublish
        ? resolvedReadiness.warnings.length
          ? "Kan publiseres, men gule punkter bør være kontrollert manuelt først."
          : ""
        : `Publisering blokkert: ${resolvedReadiness.blockers.map((check) => check.label).join(", ")}.`;
    });
  }

  function updateProgramGuidePublishButtonState(form, readiness) {
    const publishButton = form.querySelector('[data-guide-action="publish"]');
    if (!publishButton) {
      return;
    }

    const canPublish = readiness.isPublishReady;
    publishButton.disabled = !canPublish;
    publishButton.title = canPublish
      ? ""
      : `Publisering blokkert: ${readiness.checks
        .filter((check) => !check.complete)
        .map((check) => check.label)
        .join(", ")}.`;
  }

  async function upsertProgramGuide(payload) {
    const body = {
      program_id: payload.programId,
      title: payload.title || null,
      status: payload.status,
      intro_text: payload.introText || null,
      body_markdown: payload.bodyMarkdown || null,
      strategy: payload.strategy || null,
      value_estimate_label: payload.valueEstimateLabel || null,
      value_estimate_detail: payload.valueEstimateDetail || null,
      expiration_summary: payload.expirationSummary || null,
      expiration_detail: payload.expirationDetail || null,
      guide_kicker: payload.guideKicker || null,
      reading_time_label: payload.readingTimeLabel || null,
      strategy_section_title: payload.strategySectionTitle || null,
      decision_section_title: payload.decisionSectionTitle || null,
      earning_decision_label: payload.earningDecisionLabel || null,
      redemption_decision_label: payload.redemptionDecisionLabel || null,
      risk_decision_label: payload.riskDecisionLabel || null,
      earning_section_title: payload.earningSectionTitle || null,
      earning_section_intro: payload.earningSectionIntro || null,
      redemption_section_title: payload.redemptionSectionTitle || null,
      redemption_section_intro: payload.redemptionSectionIntro || null,
      risk_section_title: payload.riskSectionTitle || null,
      risk_section_intro: payload.riskSectionIntro || null,
      campaigns_section_title: payload.campaignsSectionTitle || null,
      campaigns_section_intro: payload.campaignsSectionIntro || null,
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
      return payload.id;
    }

    const created = await apiRequest("/rest/v1/program_guides", {
      method: "POST",
      body: [body],
      extraHeaders: {
        Prefer: "return=representation"
      }
    });
    return created[0]?.id || null;
  }

  async function saveStoreEarningRate(payload) {
    const storeBody = {
      name: payload.storeName,
      category_id: payload.storeCategoryId,
      status: payload.storeStatus,
      website_url: payload.storeWebsiteUrl,
      search_keywords: payload.storeSearchKeywords
    };
    if (payload.rateStatus === "published") {
      storeBody.last_verified_at = payload.checkedAt;
    }

    await apiRequest(`/rest/v1/stores?id=eq.${payload.storeId}`, {
      method: "PATCH",
      body: storeBody,
      extraHeaders: {
        Prefer: "return=minimal"
      }
    });

    await apiRequest(`/rest/v1/store_earning_rates?id=eq.${payload.id}`, {
      method: "PATCH",
      body: {
        earning_method_id: payload.earningMethodId,
        status: payload.rateStatus,
        rate_label: payload.rateLabel,
        normal_rate_label: payload.normalRateLabel,
        value_summary: payload.valueSummary,
        requirement_summary: payload.requirementSummary,
        warning_text: payload.warningText,
        handoff_url: payload.handoffUrl,
        source_url: payload.sourceUrl,
        source_title: payload.sourceTitle,
        checked_at: payload.checkedAt,
        starts_at: payload.startsAt,
        ends_at: payload.endsAt,
        sort_order: payload.sortOrder,
        is_base_rate: payload.isBaseRate
      },
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
    state.storeEarningRates = [];
    state.programGuides = [];
    state.earningMethods = [];
    state.selectedCandidateId = null;
    state.selectedCampaignId = null;
    state.selectedStoreEarningRateId = null;
    state.selectedProgramGuideProgramId = null;
    state.selectedProgramGuideId = null;
    state.newProgramGuideDraft = null;
    elements.loginForm.reset();
    renderEmptyDetail("Velg en kandidat for detaljer.");
    renderEmptyCampaignDetail("Velg en kampanje for å redigere draften.");
    renderEmptyStoreEarningDetail("Velg en sats for å redigere butikkopptjening.");
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

    return Math.min(Math.max(parsed, 1), 1000);
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

  function isStoreEarningCandidate(candidate) {
    return candidate && (
      candidate.isStoreEarningCandidate ||
      ["trumf_netthandel", "sas_eurobonus_shopping"].includes(candidate.parserKey)
    );
  }

  function compareCandidatesForReview(left, right) {
    return candidateReviewRank(left) - candidateReviewRank(right) ||
      new Date(right.detectedAt || 0).getTime() - new Date(left.detectedAt || 0).getTime() ||
      left.title.localeCompare(right.title, "nb");
  }

  function candidateReviewRank(candidate) {
    if (candidate.isReadyForStoreEarning && candidate.matchesExistingStore) {
      return 0;
    }

    if (candidate.isReadyForStoreEarning) {
      return 1;
    }

    if (candidate.needsCategoryReview || candidate.missingBonusValue) {
      return 3;
    }

    if (candidate.hasExistingStoreMethodRate) {
      return 4;
    }

    if (candidate.promotedCampaignId || candidate.promotedStoreEarningRateId) {
      return 5;
    }

    return 2;
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

  function loadSidebarCollapsed() {
    try {
      return window.localStorage.getItem(SIDEBAR_STORAGE_KEY) === "true";
    } catch (_error) {
      return false;
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

  function renderStoreBadge(status) {
    const label = STORE_STATUS_LABELS[status] || status;
    return `<span class="badge ${escapeAttribute(status)}">${escapeHtml(`Butikk: ${label}`)}</span>`;
  }

  function renderReadinessBadge(readiness) {
    return `<span class="badge ${escapeAttribute(readiness.level)}">${escapeHtml(readinessLabel(readiness))}</span>`;
  }

  function renderCandidateSignalBadge(candidate) {
    const level = candidateSignalLevel(candidate);
    return `<span class="badge ${escapeAttribute(level)}">${escapeHtml(candidate.reviewSignalLabel || "Trenger review")}</span>`;
  }

  function candidateSignalLevel(candidate) {
    if (candidate.isReadyForStoreEarning) {
      return "ready";
    }

    if (candidate.needsCategoryReview || candidate.missingBonusValue || candidate.hasExistingStoreMethodRate) {
      return "warning";
    }

    if (candidate.promotedCampaignId || candidate.promotedStoreEarningRateId) {
      return "promoted";
    }

    return "review";
  }

  function renderSignalItem(label, value, isPositive) {
    return `
      <span class="signal-item ${isPositive ? "positive" : "attention"}">
        <strong>${escapeHtml(label)}</strong>
        <span>${escapeHtml(value)}</span>
      </span>
    `;
  }

  function readinessLabel(readiness) {
    if (readiness.level === "ready") {
      return "Klar";
    }

    if (readiness.level === "warning") {
      return "Bør sjekkes";
    }

    return "Mangler";
  }

  function renderStoreEarningBadge(status) {
    const label = STORE_EARNING_STATUS_LABELS[status] || status;
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

  function renderStoreStatusOptions(selectedStatus) {
    return Object.entries(STORE_STATUS_LABELS)
      .map(([value, label]) => {
        const isSelected = value === selectedStatus ? " selected" : "";
        return `<option value="${escapeAttribute(value)}"${isSelected}>${escapeHtml(label)}</option>`;
      })
      .join("");
  }

  function renderStoreEarningStatusOptions(selectedStatus) {
    return Object.entries(STORE_EARNING_STATUS_LABELS)
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

  function storeEarningMethods() {
    return state.earningMethods;
  }

  function selectedProgramGuide() {
    if (state.selectedProgramGuideId === "new") {
      return state.newProgramGuideDraft;
    }

    return state.programGuides.find((guide) => guide.id === state.selectedProgramGuideId) || null;
  }

  function programForGuide(guide) {
    return state.programs.find((program) => program.id === guide?.programId) || null;
  }

  function programGuideTitle(guide, program) {
    return guide?.title || (program ? `Slik fungerer ${program.name}` : "Ny guide");
  }

  function startNewProgramGuide() {
    const program = state.programs[0];
    if (!program) {
      setMessage(elements.programGuideMessage, "Opprett et bonusprogram før du lager en guide.", "error");
      return;
    }

    state.selectedProgramGuideId = "new";
    state.selectedProgramGuideProgramId = program.id;
    state.newProgramGuideDraft = emptyProgramGuideDraft(program.id, `Slik fungerer ${program.name}`);
    renderProgramGuideList();
    renderProgramGuideDetail();
  }

  function guideForProgram(programId) {
    return state.programGuides.find((guide) => guide.programId === programId && guide.status === "published") || null;
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

  function parseIntegerOrDefault(value, fallback) {
    const parsed = Number.parseInt(String(value || ""), 10);
    return Number.isFinite(parsed) ? parsed : fallback;
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
