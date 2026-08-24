(() => {
  'use strict';

  const $ = (id) => document.getElementById(id);
  const elements = {
    loginView: $('login-view'), dashboardView: $('dashboard-view'), loginForm: $('login-form'),
    token: $('admin-token'), toggleToken: $('toggle-token'), loginError: $('login-error'),
    refresh: $('refresh-button'), logout: $('logout-button'), dashboardError: $('dashboard-error'),
    dashboardMessage: $('dashboard-message'), queueLoading: $('queue-loading'), queueEmpty: $('queue-empty'),
    queueList: $('queue-list'), queueCount: $('queue-count'), reviewEmpty: $('review-empty'),
    reviewPanel: $('review-panel'), pendingCount: $('pending-count'), publishedCount: $('published-count'),
    rejectedCount: $('rejected-count'), latestSync: $('latest-sync'), syncIndicator: $('sync-indicator'),
    confidenceBadge: $('confidence-badge'), ruleId: $('rule-id'), qualificationName: $('qualification-name'),
    sourceTitle: $('source-title'), sourceLink: $('source-link'), warnings: $('warnings'),
    warningList: $('warning-list'), systemType: $('system-type'), yearFrom: $('year-from'),
    yearTo: $('year-to'), cycleYears: $('cycle-years'), totalCredits: $('total-credits'),
    requirementsList: $('requirements-list'), requirementsEmpty: $('requirements-empty'),
    requirementTemplate: $('requirement-template'), addRequirement: $('add-requirement'),
    mandatoryNotes: $('mandatory-notes'), otherConditions: $('other-conditions'), reviewNote: $('review-note'),
    checkedAt: $('checked-at'), contentType: $('content-type'), extractionMethod: $('extraction-method'),
    evidenceSearch: $('evidence-search'), sourceExcerpt: $('source-excerpt'), publish: $('publish-button'),
    reject: $('reject-button'), ruleForm: $('rule-form'), dialog: $('confirm-dialog'),
    dialogIcon: $('dialog-icon'), dialogTitle: $('dialog-title'), dialogMessage: $('dialog-message'),
    dialogConfirm: $('dialog-confirm'),
  };

  const state = {
    token: sessionStorage.getItem('medlicense_admin_token') || '',
    rules: [], selectedId: null, busy: false, sourceExcerpt: '',
  };

  const numberOrNull = (value) => {
    const trimmed = String(value ?? '').trim();
    if (!trimmed) return null;
    const parsed = Number(trimmed);
    return Number.isFinite(parsed) ? parsed : null;
  };

  const textLines = (value) => String(value || '').split('\n').map((line) => line.trim()).filter(Boolean);

  const formatDate = (value, withTime = false) => {
    if (!value) return '未確認';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return String(value);
    return new Intl.DateTimeFormat('ja-JP', {
      timeZone: 'Asia/Tokyo', year: 'numeric', month: 'numeric', day: 'numeric',
      ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}),
    }).format(date);
  };

  const escapeHtml = (value) => String(value)
    .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;').replaceAll("'", '&#039;');

  const showBanner = (kind, message) => {
    const target = kind === 'error' ? elements.dashboardError : elements.dashboardMessage;
    const other = kind === 'error' ? elements.dashboardMessage : elements.dashboardError;
    other.hidden = true;
    target.textContent = message;
    target.hidden = false;
    window.setTimeout(() => { if (target.textContent === message) target.hidden = true; }, kind === 'error' ? 10000 : 5000);
  };

  const setBusy = (busy) => {
    state.busy = busy;
    elements.refresh.disabled = busy;
    elements.publish.disabled = busy;
    elements.reject.disabled = busy;
    elements.publish.textContent = busy ? '処理中…' : '確認して公開';
  };

  const apiRequest = async (options = {}) => {
    const response = await fetch('/api/admin/rules', {
      cache: 'no-store', ...options,
      headers: { Authorization: `Bearer ${state.token}`, 'Content-Type': 'application/json', ...(options.headers || {}) },
    });
    const payload = await response.json().catch(() => ({}));
    if (response.status === 401) throw new Error('管理用トークンが違います。');
    if (!response.ok) {
      const detail = payload.message || payload.error || `HTTP ${response.status}`;
      throw new Error(`サーバーで処理できませんでした（${detail}）`);
    }
    return payload;
  };

  const showLogin = (message = '') => {
    sessionStorage.removeItem('medlicense_admin_token');
    state.token = ''; state.rules = []; state.selectedId = null;
    elements.dashboardView.hidden = true; elements.loginView.hidden = false;
    elements.loginError.textContent = message; elements.loginError.hidden = !message;
    elements.token.value = ''; elements.token.focus();
  };

  const updateStats = (payload) => {
    const summary = payload.summary || {};
    elements.pendingCount.textContent = summary.pendingReview ?? 0;
    elements.publishedCount.textContent = summary.published ?? 0;
    elements.rejectedCount.textContent = summary.rejected ?? 0;
    const sync = payload.latestSync;
    elements.latestSync.textContent = sync?.finished_at ? formatDate(sync.finished_at, true) : '未実行';
    if (sync?.status === 'succeeded') {
      elements.syncIndicator.textContent = `公式資料の取得成功・${formatDate(sync.finished_at, true)}`;
    } else if (sync) elements.syncIndicator.textContent = `公式資料の取得：${sync.status}`;
    else elements.syncIndicator.textContent = '同期履歴なし';
  };

  const warningCount = (rule) => rule.structured_data?.warnings?.length || 0;

  const renderQueue = () => {
    elements.queueList.replaceChildren(); elements.queueLoading.hidden = true;
    elements.queueEmpty.hidden = state.rules.length > 0;
    elements.queueCount.textContent = `${state.rules.length}件`;
    state.rules.forEach((rule) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `queue-item${String(rule.id) === String(state.selectedId) ? ' selected' : ''}`;
      const top = document.createElement('div'); top.className = 'queue-item-top';
      const title = document.createElement('h3'); title.textContent = rule.qualification_name; top.append(title);
      if (warningCount(rule)) {
        const warning = document.createElement('span'); warning.className = 'mini-warning';
        warning.textContent = `⚠ ${warningCount(rule)}`; top.append(warning);
      }
      const source = document.createElement('p'); source.textContent = rule.source_title;
      const meta = document.createElement('p');
      meta.textContent = `信頼度 ${Math.round(Number(rule.confidence || 0) * 100)}% ・ ${formatDate(rule.checked_at)}`;
      button.append(top, source, meta);
      button.addEventListener('click', () => selectRule(rule.id));
      elements.queueList.append(button);
    });
  };

  const renumberRequirements = () => {
    const rows = [...elements.requirementsList.querySelectorAll('.requirement-row')];
    rows.forEach((row, index) => { row.querySelector('.requirement-number').textContent = `条件 ${index + 1}`; });
    elements.requirementsEmpty.hidden = rows.length > 0;
  };

  const addRequirementRow = (item = {}) => {
    const fragment = elements.requirementTemplate.content.cloneNode(true);
    const row = fragment.querySelector('.requirement-row');
    row.querySelector('.requirement-label').value = item.label || '';
    row.querySelector('.requirement-minimum').value = item.minimum ?? '';
    row.querySelector('.requirement-value').value = item.requiredValue ?? '';
    row.querySelector('.requirement-maximum').value = item.maximum ?? '';
    row.querySelector('.requirement-unit').value = item.unit || '単位';
    row.querySelector('.requirement-mandatory').checked = item.mandatory === true;
    row.querySelector('.requirement-evidence').textContent = item.evidence || '抽出根拠はありません。';
    row.dataset.evidence = item.evidence || '';
    row.querySelector('.remove-requirement').addEventListener('click', () => { row.remove(); renumberRequirements(); });
    elements.requirementsList.append(fragment); renumberRequirements();
  };

  const confidenceClass = (confidence) => confidence >= 0.75
    ? 'confidence-high' : confidence >= 0.5 ? 'confidence-medium' : 'confidence-low';

  const selectRule = (id) => {
    const rule = state.rules.find((item) => String(item.id) === String(id));
    if (!rule) return;
    state.selectedId = rule.id; renderQueue();
    elements.reviewEmpty.hidden = true; elements.reviewPanel.hidden = false;
    const data = rule.structured_data || {};
    const confidence = Number(rule.confidence || 0);
    elements.confidenceBadge.className = `confidence-badge ${confidenceClass(confidence)}`;
    elements.confidenceBadge.textContent = `抽出信頼度 ${Math.round(confidence * 100)}%`;
    elements.ruleId.textContent = `候補 #${rule.id}`;
    elements.qualificationName.textContent = rule.qualification_name;
    elements.sourceTitle.textContent = rule.source_title;
    elements.sourceLink.href = rule.source_url;
    const warnings = Array.isArray(data.warnings) ? data.warnings : [];
    elements.warnings.hidden = warnings.length === 0; elements.warningList.replaceChildren();
    warnings.forEach((warning) => { const item = document.createElement('li'); item.textContent = warning; elements.warningList.append(item); });
    elements.systemType.value = rule.system_type || '';
    elements.yearFrom.value = rule.acquired_year_from ?? ''; elements.yearTo.value = rule.acquired_year_to ?? '';
    elements.cycleYears.value = rule.renewal_cycle_years ?? data.renewalCycleYears ?? '';
    elements.totalCredits.value = rule.required_total_credits ?? data.requiredTotalCredits ?? '';
    elements.mandatoryNotes.value = (data.mandatoryNotes || []).join('\n');
    elements.otherConditions.value = (data.otherConditions || []).join('\n'); elements.reviewNote.value = '';
    elements.requirementsList.replaceChildren(); (data.requirements || []).forEach(addRequirementRow); renumberRequirements();
    elements.checkedAt.textContent = formatDate(rule.checked_at, true);
    elements.contentType.textContent = String(rule.content_type || '').includes('pdf') ? 'PDF' : 'Webページ';
    elements.extractionMethod.textContent = rule.extraction_method || '—'; elements.evidenceSearch.value = '';
    state.sourceExcerpt = rule.source_excerpt || (data.evidence || []).join('\n'); renderEvidence();
    if (window.innerWidth < 821) elements.reviewPanel.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  const renderEvidence = () => {
    const source = state.sourceExcerpt || '抽出本文がありません。公式資料を開いて確認してください。';
    const query = elements.evidenceSearch.value.trim();
    if (!query) { elements.sourceExcerpt.textContent = source; return; }
    const escapedSource = escapeHtml(source); const escapedQuery = escapeHtml(query);
    const pattern = new RegExp(escapedQuery.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');
    elements.sourceExcerpt.innerHTML = escapedSource.replace(pattern, (match) => `<mark>${match}</mark>`);
    elements.sourceExcerpt.querySelector('mark')?.scrollIntoView({ block: 'center' });
  };

  const loadRules = async ({ preserveSelection = true } = {}) => {
    setBusy(true); elements.queueLoading.hidden = false; elements.dashboardError.hidden = true;
    try {
      const payload = await apiRequest(); state.rules = Array.isArray(payload.data) ? payload.data : [];
      updateStats(payload);
      if (!preserveSelection || !state.rules.some((rule) => String(rule.id) === String(state.selectedId))) {
        state.selectedId = state.rules[0]?.id ?? null;
      }
      renderQueue();
      if (state.selectedId !== null) selectRule(state.selectedId);
      else { elements.reviewPanel.hidden = true; elements.reviewEmpty.hidden = false; }
    } catch (error) {
      elements.queueLoading.hidden = true;
      if (String(error.message).includes('トークン')) showLogin(error.message);
      else showBanner('error', error.message);
      throw error;
    } finally { setBusy(false); }
  };

  const collectRequirements = () => [...elements.requirementsList.querySelectorAll('.requirement-row')]
    .map((row, index) => {
      const minimum = numberOrNull(row.querySelector('.requirement-minimum').value);
      const requiredValue = numberOrNull(row.querySelector('.requirement-value').value);
      const maximum = numberOrNull(row.querySelector('.requirement-maximum').value);
      if (minimum === null && requiredValue === null && maximum === null) {
        throw new Error(`条件${index + 1}には最低・固定値・上限のいずれかを入力してください。`);
      }
      if (minimum !== null && maximum !== null && minimum > maximum) {
        throw new Error(`条件${index + 1}の最低値が上限を超えています。`);
      }
      return {
        label: row.querySelector('.requirement-label').value.trim(), minimum, requiredValue, maximum,
        unit: row.querySelector('.requirement-unit').value,
        mandatory: row.querySelector('.requirement-mandatory').checked,
        evidence: row.dataset.evidence || undefined,
      };
    });

  const collectRule = () => {
    if (!elements.ruleForm.reportValidity()) throw new Error('未入力の項目があります。');
    const acquiredYearFrom = numberOrNull(elements.yearFrom.value);
    const acquiredYearTo = numberOrNull(elements.yearTo.value);
    if (acquiredYearFrom !== null && acquiredYearTo !== null && acquiredYearFrom > acquiredYearTo) {
      throw new Error('取得年度の開始が終了より後になっています。');
    }
    return {
      systemType: elements.systemType.value.trim(), acquiredYearFrom, acquiredYearTo,
      renewalCycleYears: numberOrNull(elements.cycleYears.value),
      requiredTotalCredits: numberOrNull(elements.totalCredits.value), requirements: collectRequirements(),
      mandatoryNotes: textLines(elements.mandatoryNotes.value), otherConditions: textLines(elements.otherConditions.value),
    };
  };

  const confirmAction = (action) => new Promise((resolve) => {
    const publish = action === 'publish';
    elements.dialogIcon.textContent = publish ? '✓' : '×';
    elements.dialogTitle.textContent = publish ? 'この条件を公開しますか？' : 'この候補を却下しますか？';
    elements.dialogMessage.textContent = publish
        ? '承認後は公開APIから取得できるようになります。利用者アプリとの条件同期は別途必要です。'
      : '却下した候補は確認待ち一覧から外れます。公式資料そのものは保存されます。';
    elements.dialogConfirm.textContent = publish ? '公開する' : '却下する';
    elements.dialogConfirm.className = publish ? 'button primary' : 'button danger';
    const onClose = () => { elements.dialog.removeEventListener('close', onClose); resolve(elements.dialog.returnValue === 'confirm'); };
    elements.dialog.addEventListener('close', onClose); elements.dialog.showModal();
  });

  const runReviewAction = async (action) => {
    if (state.busy || state.selectedId === null) return;
    let rule;
    try { if (action === 'publish') rule = collectRule(); }
    catch (error) { showBanner('error', error.message); return; }
    if (!(await confirmAction(action))) return;
    setBusy(true);
    try {
      await apiRequest({ method: 'POST', body: JSON.stringify({
        ruleId: Number(state.selectedId), action, note: elements.reviewNote.value.trim(),
        ...(action === 'publish' ? { rule } : {}),
      }) });
      const message = action === 'publish'
        ? '承認した条件を公開APIへ反映しました。' : '候補を却下しました。';
      state.selectedId = null; await loadRules({ preserveSelection: false }); showBanner('success', message);
    } catch (error) {
      if (String(error.message).includes('トークン')) showLogin(error.message);
      else showBanner('error', error.message);
    } finally { setBusy(false); }
  };

  elements.loginForm.addEventListener('submit', async (event) => {
    event.preventDefault(); elements.loginError.hidden = true; state.token = elements.token.value.trim();
    if (!state.token) return; sessionStorage.setItem('medlicense_admin_token', state.token);
    try {
      await loadRules({ preserveSelection: false });
      elements.loginView.hidden = true; elements.dashboardView.hidden = false;
    } catch (error) {
      if (!String(error.message).includes('トークン')) {
        elements.loginError.textContent = error.message; elements.loginError.hidden = false;
      }
    }
  });

  elements.toggleToken.addEventListener('click', () => {
    const reveal = elements.token.type === 'password'; elements.token.type = reveal ? 'text' : 'password';
    elements.toggleToken.textContent = reveal ? '隠す' : '表示';
  });
  elements.refresh.addEventListener('click', () => loadRules().catch(() => {}));
  elements.logout.addEventListener('click', () => showLogin());
  elements.addRequirement.addEventListener('click', () => addRequirementRow());
  elements.evidenceSearch.addEventListener('input', renderEvidence);
  elements.publish.addEventListener('click', () => runReviewAction('publish'));
  elements.reject.addEventListener('click', () => runReviewAction('reject'));

  if (state.token) {
    loadRules({ preserveSelection: false }).then(() => {
      elements.loginView.hidden = true; elements.dashboardView.hidden = false;
    }).catch(() => {});
  }
})();
