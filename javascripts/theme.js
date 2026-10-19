/* Redmine shadcn theme - theme.js
 * Redmine が <head> で読み込む。ここでは見た目の補助だけ行う。
 */
(function () {
  'use strict';

  var STORAGE_KEY = 'redmine-shadcn-theme:mode';
  var root = document.documentElement;
  var media = window.matchMedia('(prefers-color-scheme: dark)');

  function getStoredMode() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (e) {
      return null;
    }
  }

  function setStoredMode(mode) {
    try {
      localStorage.setItem(STORAGE_KEY, mode);
    } catch (e) {
      /* プライベートモードなどでは保存しない */
    }
  }

  function isDark() {
    var mode = getStoredMode();
    if (mode === 'dark') return true;
    if (mode === 'light') return false;
    return media.matches;
  }

  function apply() {
    root.classList.toggle('dark', isDark());
  }

  // ちらつき防止のため、DOM 構築前に即適用する
  apply();
  media.addEventListener('change', function () {
    if (!getStoredMode()) apply();
  });

  var ICON_SUN =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/></svg>';
  var ICON_MOON =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/></svg>';

  function renderToggle(button) {
    var dark = root.classList.contains('dark');
    button.innerHTML = dark ? ICON_SUN : ICON_MOON;
    button.title = dark ? 'Light mode' : 'Dark mode';
    button.setAttribute('aria-label', button.title);
  }

  function addToggle() {
    var topMenu = document.getElementById('top-menu');
    if (!topMenu || document.getElementById('shadcn-theme-toggle')) return;

    var button = document.createElement('button');
    button.type = 'button';
    button.id = 'shadcn-theme-toggle';
    renderToggle(button);
    button.addEventListener('click', function () {
      setStoredMode(root.classList.contains('dark') ? 'light' : 'dark');
      apply();
      renderToggle(button);
    });
    topMenu.insertBefore(button, topMenu.firstChild);
  }

  /* ガントチャートの行の高さを広げる
   * Redmine は各要素の top をサーバー側で 20px 刻みにインライン指定しているので、
   * それを GANTT_ROW_HEIGHT 刻みに計算し直す。
   * 折りたたみ（gantt.js の ganttEntryClick）は data-collapse-expand の top_increment を使うので、それも書き換える。
   */
  var GANTT_ROW_HEIGHT = 28;
  var GANTT_ORIGINAL_ROW_HEIGHT = 20;
  // 行の内容（高さ 16px）の上下の余白。1 行目の上端がヘッダーの下端（1 行目の top - 6px）と重なるように、
  // 1 行目の位置は変えずに 2 行目以降を広げる
  var GANTT_ROW_PADDING = (GANTT_ROW_HEIGHT - 16) / 2;

  function expandGanttRows() {
    var table = document.querySelector('table.gantt-table');
    if (!table || table.getAttribute('data-shadcn-rows')) return;

    var rows = table.querySelectorAll('[data-collapse-expand]');
    var subjects = table.querySelectorAll('.gantt_subjects form > div');
    var start = Infinity;
    var i;
    for (i = 0; i < subjects.length; i++) {
      var value = parseFloat(subjects[i].style.top);
      if (!isNaN(value) && value < start) start = value;
    }
    if (start === Infinity) return;

    var scale = GANTT_ROW_HEIGHT / GANTT_ORIGINAL_ROW_HEIGHT;
    for (i = 0; i < rows.length; i++) {
      var el = rows[i];
      var top = parseFloat(el.style.top);
      if (!isNaN(top) && top >= start) {
        el.style.top = (start + (top - start) * scale) + 'px';
      }
      var json = el.getAttribute('data-collapse-expand');
      if (json && json.indexOf('top_increment') !== -1) {
        el.setAttribute(
          'data-collapse-expand',
          json.replace(/"top_increment":\s*\d+/, '"top_increment":' + GANTT_ROW_HEIGHT)
        );
        if (window.jQuery) window.jQuery.removeData(el);
      }
    }

    // 全体の高さを行数ぶん伸ばす（コンテナ・縦の罫線・今日の線・関連線の描画エリア）
    var delta = subjects.length * (GANTT_ROW_HEIGHT - GANTT_ORIGINAL_ROW_HEIGHT);
    var tall = table.querySelectorAll('[style*="height"]');
    for (i = 0; i < tall.length; i++) {
      var height = parseFloat(tall[i].style.height);
      if (height > 100) tall[i].style.height = (height + delta) + 'px';
    }

    table.style.setProperty('--gantt-row-start', start + 'px');
    table.style.setProperty('--gantt-row-height', GANTT_ROW_HEIGHT + 'px');
    table.style.setProperty('--gantt-row-padding', GANTT_ROW_PADDING + 'px');
    table.setAttribute('data-shadcn-rows', '1');
  }

  /* ガントチャートのタイムラインをカードの幅いっぱいに広げる
   * Redmine は「1 日あたり何 px」で left / width をインライン指定しているので、
   * 表示領域より狭いときだけ横方向に拡大する（広いときはスクロールのまま）。
   * 元の値は data 属性に残して、表示領域の幅が変わったら計算し直す。
   */
  function fitGanttWidth() {
    var area = document.getElementById('gantt_area');
    var draw = document.getElementById('gantt_draw_area');
    if (!area || !draw) return;

    var items = area.querySelectorAll('[style*="left"], [style*="width"]');
    var i, el;
    for (i = 0; i < items.length; i++) {
      el = items[i];
      if (el.hasAttribute('data-shadcn-left')) continue;
      el.setAttribute('data-shadcn-left', el.style.left);
      el.setAttribute('data-shadcn-width', el.style.width);
    }

    var contentWidth = parseFloat(draw.getAttribute('data-shadcn-width'));
    if (!contentWidth) return;
    var scale = Math.max(1, (area.clientWidth - 1) / contentWidth);

    for (i = 0; i < items.length; i++) {
      el = items[i];
      var left = parseFloat(el.getAttribute('data-shadcn-left'));
      var width = parseFloat(el.getAttribute('data-shadcn-width'));
      if (!isNaN(left)) el.style.left = (left * scale) + 'px';
      if (!isNaN(width)) el.style.width = (width * scale) + 'px';
    }
  }

  // 関連線・進捗線を新しい位置で描き直す
  function redrawGantt() {
    var draw = document.getElementById('gantt_draw_area');
    if (!draw) return;
    if (window.draw_gantt) window.draw_gantt.setSize(draw.offsetWidth, draw.offsetHeight);
    if (typeof window.drawGanttHandler === 'function') window.drawGanttHandler();
  }

  var fittedWidth = null;

  function refitGantt() {
    var area = document.getElementById('gantt_area');
    if (!area || area.clientWidth === fittedWidth) return;
    fittedWidth = area.clientWidth;
    fitGanttWidth();
    redrawGantt();
  }

  function layoutGantt() {
    var area = document.getElementById('gantt_area');
    if (!area) return;
    expandGanttRows();
    refitGantt();

    // gantt.js の初期化（選択した列の表示切り替え）やサイドバーの開閉・ウィンドウのリサイズで
    // 表示領域の幅が変わるので、そのたびに合わせ直す
    window.addEventListener('load', refitGantt);
    if (window.ResizeObserver) {
      var timer = null;
      new ResizeObserver(function () {
        clearTimeout(timer);
        timer = setTimeout(refitGantt, 100);
      }).observe(area);
    }
  }

  window.RedmineShadcnTheme = { refitGantt: refitGantt };

  function init() {
    addToggle();
    layoutGantt();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
