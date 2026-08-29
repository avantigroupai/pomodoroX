// PomodoroX Web Interactive Demo & Audio Engine

let currentPhase = 'focus'; // 'focus', 'shortBreak', 'longBreak'
let timerState = 'idle'; // 'idle', 'running', 'paused'
let totalDuration = 25 * 60;
let timeRemaining = 25 * 60;
let completedPomodoros = 0;
let timerInterval = null;

const phaseConfigs = {
  focus: {
    name: 'FOCUS',
    duration: 25 * 60,
    colorStart: '#ff5947',
    colorEnd: '#ff942e',
    tagClass: 'glow-coral'
  },
  shortBreak: {
    name: 'SHORT BREAK',
    duration: 5 * 60,
    colorStart: '#2ed6b8',
    colorEnd: '#38a6f2',
    tagClass: 'glow-cyan'
  },
  longBreak: {
    name: 'LONG BREAK',
    duration: 15 * 60,
    colorStart: '#ad61fa',
    colorEnd: '#eb59d1',
    tagClass: 'glow-purple'
  }
};

// Canvas Ring Setup with HiDPI Retina Crispness
function drawDialOnCanvas(canvasEl, progress) {
  if (!canvasEl) return;
  const ctx = canvasEl.getContext('2d');
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  
  // Set internal resolution for crisp Retina rendering
  const displayWidth = canvasEl.clientWidth || parseInt(canvasEl.getAttribute('width')) || 280;
  const displayHeight = canvasEl.clientHeight || parseInt(canvasEl.getAttribute('height')) || 280;
  
  if (canvasEl.width !== displayWidth * dpr || canvasEl.height !== displayHeight * dpr) {
    canvasEl.width = displayWidth * dpr;
    canvasEl.height = displayHeight * dpr;
  }

  ctx.save();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, displayWidth, displayHeight);

  const size = displayWidth;
  const center = size / 2;
  const radius = size * 0.39;

  const cfg = phaseConfigs[currentPhase];

  // 1. Ambient Radial Glow
  const gradGlow = ctx.createRadialGradient(center, center, center * 0.3, center, center, center * 0.95);
  gradGlow.addColorStop(0, hexToRgba(cfg.colorStart, timerState === 'running' ? 0.25 : 0.08));
  gradGlow.addColorStop(1, 'transparent');
  ctx.fillStyle = gradGlow;
  ctx.beginPath();
  ctx.arc(center, center, center * 0.95, 0, Math.PI * 2);
  ctx.fill();

  // 2. 60 Minute Tick Marks
  ctx.save();
  ctx.translate(center, center);
  for (let i = 0; i < 60; i++) {
    ctx.fillStyle = i % 5 === 0 ? 'rgba(255, 255, 255, 0.32)' : 'rgba(255, 255, 255, 0.09)';
    const tickLen = i % 5 === 0 ? 8 : 4;
    const tickW = i % 5 === 0 ? 1.75 : 1;
    ctx.fillRect(-tickW / 2, -radius - 14, tickW, tickLen);
    ctx.rotate((6 * Math.PI) / 180);
  }
  ctx.restore();

  // 3. Background Track
  ctx.beginPath();
  ctx.arc(center, center, radius, 0, Math.PI * 2);
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.08)';
  ctx.lineWidth = size * 0.05;
  ctx.lineCap = 'round';
  ctx.stroke();

  // 4. Active Progress Arc
  const startAngle = -Math.PI / 2;
  const endAngle = startAngle + Math.max(0.001, progress) * (Math.PI * 2);

  const gradStroke = ctx.createLinearGradient(0, 0, size, size);
  gradStroke.addColorStop(0, cfg.colorStart);
  gradStroke.addColorStop(1, cfg.colorEnd);

  ctx.beginPath();
  ctx.arc(center, center, radius, startAngle, endAngle);
  ctx.strokeStyle = gradStroke;
  ctx.lineWidth = size * 0.05;
  ctx.lineCap = 'round';
  ctx.shadowColor = cfg.colorStart;
  ctx.shadowBlur = timerState === 'running' ? 16 : 6;
  ctx.stroke();
  ctx.shadowBlur = 0;

  // 5. Leading Glowing Arc Cursor Dot
  if (progress > 0.01 && progress < 0.99) {
    const dotX = center + radius * Math.cos(endAngle);
    const dotY = center + radius * Math.sin(endAngle);

    ctx.beginPath();
    ctx.arc(dotX, dotY, size * 0.022, 0, Math.PI * 2);
    ctx.fillStyle = '#ffffff';
    ctx.shadowColor = cfg.colorStart;
    ctx.shadowBlur = 12;
    ctx.fill();
    ctx.shadowBlur = 0;
  }

  ctx.restore();
}

function drawDial(progress) {
  const heroCanvas = document.getElementById('timerCanvas');
  const focusCanvas = document.getElementById('focusTimerCanvas');
  if (heroCanvas) drawDialOnCanvas(heroCanvas, progress);
  if (focusCanvas) drawDialOnCanvas(focusCanvas, progress);
}

function syncTaskName(newName) {
  const heroTask = document.getElementById('activeTaskName');
  const focusTask = document.querySelector('.focus-task-title');
  if (heroTask && heroTask.textContent !== newName) heroTask.textContent = newName;
  if (focusTask && focusTask.textContent !== newName) focusTask.textContent = newName;
}

function updateDisplay() {
  const mins = Math.floor(timeRemaining / 60);
  const secs = timeRemaining % 60;
  const timeStr = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  
  const timerTimeEl = document.getElementById('timerTime');
  const focusTimerTimeEl = document.getElementById('focusTimerTime');
  const deviceStatusEl = document.querySelector('.device-status');
  
  if (timerTimeEl) timerTimeEl.textContent = timeStr;
  if (focusTimerTimeEl) focusTimerTimeEl.textContent = timeStr;
  if (deviceStatusEl) deviceStatusEl.textContent = timeStr;

  // Page title dynamic update when running
  if (timerState === 'running') {
    document.title = `(${timeStr}) PomodoroX • ${phaseConfigs[currentPhase].name}`;
  } else {
    document.title = 'PomodoroX — Minimalist Pomodoro Timer & Ambient Soundscapes for Mac & iOS';
  }

  const progress = totalDuration > 0 ? (totalDuration - timeRemaining) / totalDuration : 0;
  drawDial(progress);
}

function setDemoPhase(phase) {
  currentPhase = phase;
  const cfg = phaseConfigs[phase];
  totalDuration = cfg.duration;
  timeRemaining = cfg.duration;
  timerState = 'idle';

  clearInterval(timerInterval);
  timerInterval = null;

  // Update dynamic phase attribute on document and overlay
  document.documentElement.setAttribute('data-phase', phase);
  const focusOverlay = document.getElementById('focusOverlay');
  if (focusOverlay) focusOverlay.setAttribute('data-phase', phase);

  // Update Phase Pills across all scopes
  document.querySelectorAll('.phase-pill, .focus-phase-pill').forEach(pill => pill.classList.remove('active'));
  const idx = phase === 'focus' ? 0 : (phase === 'shortBreak' ? 1 : 2);
  
  document.querySelectorAll('.phase-selector').forEach(selector => {
    const pills = selector.querySelectorAll('button');
    if (pills[idx]) pills[idx].classList.add('active');
  });

  // Update Phase Tags
  const tag = document.getElementById('phaseTag');
  const focusTag = document.getElementById('focusPhaseTag');
  [tag, focusTag].forEach(el => {
    if (el) {
      el.textContent = cfg.name;
      el.style.color = cfg.colorStart;
      el.style.background = hexToRgba(cfg.colorStart, 0.15);
      el.style.borderColor = hexToRgba(cfg.colorStart, 0.3);
    }
  });

  updatePlayIcon();
  updateDisplay();
}

function toggleDemoTimer() {
  if (timerState === 'running') {
    // Pause
    timerState = 'paused';
    clearInterval(timerInterval);
    timerInterval = null;
    stopWebSound();
  } else {
    // Start / Resume
    timerState = 'running';
    timerInterval = setInterval(() => {
      if (timeRemaining > 0) {
        timeRemaining -= 1;
        updateDisplay();
      } else {
        // Complete
        handleSessionEnd();
      }
    }, 1000);

    const soundSelect = document.getElementById('ambientSelect') || document.getElementById('focusAmbientSelect');
    const sound = soundSelect ? soundSelect.value : 'none';
    if (sound !== 'none') {
      playWebSound(sound);
    }
  }
  updatePlayIcon();
  updateDisplay();
}

function resetDemoTimer() {
  clearInterval(timerInterval);
  timerInterval = null;
  timerState = 'idle';
  timeRemaining = totalDuration;
  stopWebSound();
  updatePlayIcon();
  updateDisplay();
}

function skipDemoPhase() {
  if (currentPhase === 'focus') {
    setDemoPhase('shortBreak');
  } else {
    setDemoPhase('focus');
  }
}

function adjustDemoTime(deltaMins) {
  timeRemaining = Math.max(60, Math.min(7200, timeRemaining + deltaMins * 60));
  totalDuration = Math.max(timeRemaining, totalDuration + deltaMins * 60);
  updateDisplay();
}

function handleSessionEnd() {
  resetDemoTimer();
  playBellChime();
  if (currentPhase === 'focus') {
    completedPomodoros += 1;
    const countEl = document.getElementById('pomoCount');
    const focusCountEl = document.getElementById('focusPomoCount');
    if (countEl) countEl.textContent = completedPomodoros;
    if (focusCountEl) focusCountEl.textContent = completedPomodoros;
    setDemoPhase('shortBreak');
  } else {
    setDemoPhase('focus');
  }
}

function updatePlayIcon() {
  const icon = document.getElementById('playIcon');
  const focusIcon = document.getElementById('focusPlayIcon');
  const svgContent = timerState === 'running'
    ? '<rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect>'
    : '<polygon points="5 3 19 12 5 21 5 3"></polygon>';
  
  if (icon) icon.innerHTML = svgContent;
  if (focusIcon) focusIcon.innerHTML = svgContent;
}

function hexToRgba(hex, alpha) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

// Web Audio API Ambient Sound Synthesizer
let audioCtx = null;
let activeNoiseNode = null;
let gainNode = null;
let currentPlayingSound = null;

function getAudioContext() {
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    audioCtx = new AudioContextClass();
  }
  if (audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
  return audioCtx;
}

function toggleSoundButton(type) {
  if (type === 'chime') {
    playBellChime();
    const chimeBtn = document.getElementById('btn-chime');
    if (chimeBtn) {
      chimeBtn.classList.add('pulse-active');
      setTimeout(() => chimeBtn.classList.remove('pulse-active'), 2500);
    }
    return;
  }

  if (currentPlayingSound === type) {
    // If already playing this sound, stop it
    stopWebSound();
    currentPlayingSound = null;
    updateSoundButtonUI(null);
  } else {
    // Play selected sound
    playWebSound(type);
    currentPlayingSound = type;
    updateSoundButtonUI(type);
  }
}

function updateSoundButtonUI(activeType) {
  document.querySelectorAll('.sound-btn').forEach(btn => {
    const soundType = btn.getAttribute('data-sound');
    if (soundType && soundType === activeType) {
      btn.classList.add('active', 'is-playing');
    } else {
      btn.classList.remove('active', 'is-playing');
    }
  });

  // Sync with emulator dropdown if open
  const emulatorSelect = document.getElementById('ambientSelect');
  const ambientIcon = document.getElementById('ambientIcon');
  if (emulatorSelect) {
    emulatorSelect.value = activeType || 'none';
  }
  if (ambientIcon) {
    const iconMap = {
      none: '🔇',
      oceanWaves: '🌊',
      pinkNoise: '〰️',
      brownNoise: '💨',
      stream: '🍃'
    };
    ambientIcon.textContent = iconMap[activeType] || '🌊';
  }
}

function playWebSound(type) {
  stopWebSound();
  if (!type || type === 'none') return;

  try {
    const ctx = getAudioContext();
    const sampleRate = ctx.sampleRate;
    const loopDuration = (type === 'oceanWaves') ? 12 : 4;
    const bufferSize = Math.floor(loopDuration * sampleRate);
    const soundBuffer = ctx.createBuffer(1, bufferSize, sampleRate);
    const output = soundBuffer.getChannelData(0);

    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    let brown = 0.0;

    for (let i = 0; i < bufferSize; i++) {
      const white = Math.random() * 2 - 1;
      const t = i / sampleRate;

      if (type === 'oceanWaves') {
        // 🌊 REAL OCEAN WAVES: Asymmetric 12s tidal surge + crashing crest surf + receding foam hiss
        const wavePeriod = 12.0;
        const phase = (t / wavePeriod) * Math.PI * 2;
        const rawSwell = (Math.sin(phase) + 1.0) * 0.5;
        const swell = Math.pow(rawSwell, 1.8);

        brown = (brown + 0.025 * white) / 1.025;
        const deepBody = brown * 3.0 * (0.25 + swell * 1.8);
        const crash = (swell > 0.58) ? (white * (swell - 0.58) * 2.2 * (0.8 + Math.random() * 0.4)) : 0.0;
        const foam = (swell < 0.42) ? (white * (0.42 - swell) * 0.45) : 0.0;

        output[i] = (deepBody * 0.7) + (crash * 0.28) + (foam * 0.18);

      } else if (type === 'pinkNoise') {
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        output[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.18;
        b6 = white * 0.115926;

      } else if (type === 'brownNoise') {
        brown = (brown + 0.03 * white) / 1.03;
        output[i] = brown * 3.6;

      } else if (type === 'stream') {
        b0 = 0.82 * b0 + white * 0.18;
        b1 = 0.88 * b1 + b0 * 0.12;
        const ripple = Math.sin(t * 8.0) * 0.04;
        output[i] = (b1 * 1.4 + ripple + white * 0.04) * 0.75;
      }
    }

    const soundSource = ctx.createBufferSource();
    soundSource.buffer = soundBuffer;
    soundSource.loop = true;

    gainNode = ctx.createGain();
    const vol = parseFloat(document.getElementById('ambientVol')?.value || 0.7);
    gainNode.gain.setValueAtTime(0.01, ctx.currentTime);
    gainNode.gain.linearRampToValueAtTime(vol * 0.6, ctx.currentTime + 0.25);

    soundSource.connect(gainNode);
    gainNode.connect(ctx.destination);
    soundSource.start(0);

    activeNoiseNode = soundSource;
    currentPlayingSound = type;
  } catch (err) {
    console.error('Audio playback error:', err);
  }
}

function stopWebSound() {
  if (activeNoiseNode && gainNode && audioCtx) {
    const prevNode = activeNoiseNode;
    const prevGain = gainNode;
    try {
      prevGain.gain.linearRampToValueAtTime(0.001, audioCtx.currentTime + 0.2);
      setTimeout(() => {
        try { prevNode.stop(); } catch(e){}
      }, 250);
    } catch(e) {}
    activeNoiseNode = null;
  }
}

function changeAmbientSound(val) {
  if (val === 'none') {
    stopWebSound();
    currentPlayingSound = null;
    updateSoundButtonUI(null);
  } else {
    toggleSoundButton(val);
  }
}

function setAmbientVolume(val) {
  if (gainNode && audioCtx) {
    gainNode.gain.setValueAtTime(parseFloat(val) * 0.5, audioCtx.currentTime);
  }
}

// 528Hz Harmonic Solfeggio Tibetan Singing Bowl Chime
function playBellChime() {
  try {
    const ctx = getAudioContext();
    const f0 = 528;
    const harmonics = [f0, f0 * 1.503, f0 * 2.001, f0 * 2.756, f0 * 3.42];
    const gains = [0.5, 0.25, 0.15, 0.09, 0.04];
    const decays = [3.8, 3.2, 2.5, 1.8, 1.2];

    harmonics.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const g = ctx.createGain();

      osc.type = idx === 0 ? 'sine' : 'triangle';
      osc.frequency.setValueAtTime(freq, ctx.currentTime);

      g.gain.setValueAtTime(0.001, ctx.currentTime);
      g.gain.linearRampToValueAtTime(gains[idx] * 0.6, ctx.currentTime + 0.015);
      g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + decays[idx]);

      osc.connect(g);
      g.connect(ctx.destination);

      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + decays[idx] + 0.1);
    });
  } catch (err) {
    console.error('Chime audio error:', err);
  }
}

// Shortcuts Auto-Fadeout (after 5 seconds for distraction-free focus)
let shortcutsFadeTimeout = null;

function scheduleShortcutsFade() {
  const pills = document.querySelectorAll('.focus-shortcuts-pill');
  pills.forEach(p => p.classList.remove('faded'));
  clearTimeout(shortcutsFadeTimeout);
  shortcutsFadeTimeout = setTimeout(() => {
    pills.forEach(p => p.classList.add('faded'));
  }, 5000);
}

// Focus Mode Controller
function openFocusMode() {
  const overlay = document.getElementById('focusOverlay');
  if (overlay) {
    overlay.classList.add('open');
    overlay.setAttribute('data-phase', currentPhase);
    document.documentElement.setAttribute('data-phase', currentPhase);
    document.body.style.overflow = 'hidden';
    
    // Sync UI elements
    updateDisplay();
    scheduleShortcutsFade();
    
    // Update URL hash smoothly to #focus
    if (window.location.hash !== '#focus') {
      history.replaceState(null, '', '#focus');
    }
  }
}

function closeFocusMode() {
  const overlay = document.getElementById('focusOverlay');
  if (overlay) {
    overlay.classList.remove('open');
    document.body.style.overflow = '';
    clearTimeout(shortcutsFadeTimeout);
    if (window.location.hash === '#focus' || window.location.hash === '#webTimer') {
      history.replaceState(null, '', window.location.pathname + window.location.search);
    }
  }
}

function toggleBrowserFullscreen() {
  if (!document.fullscreenElement) {
    const docEl = document.documentElement;
    if (docEl.requestFullscreen) docEl.requestFullscreen();
    else if (docEl.webkitRequestFullscreen) docEl.webkitRequestFullscreen();
  } else {
    if (document.exitFullscreen) document.exitFullscreen();
    else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
  }
}

async function shareWebTimerLink(e) {
  const targetUrl = 'https://avantigroupai.github.io/pomodoroX/#focus';
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(targetUrl);
  }
  const btn = e ? e.currentTarget : null;
  if (btn) {
    const originalText = btn.innerHTML;
    btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg> Copied!';
    setTimeout(() => { btn.innerHTML = originalText; }, 2000);
  }
}

// Global Keyboard Shortcuts
window.addEventListener('keydown', (e) => {
  // Avoid capturing when user is typing in input or select
  if (['INPUT', 'SELECT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;

  scheduleShortcutsFade();

  if (e.code === 'Space') {
    e.preventDefault();
    toggleDemoTimer();
  } else if (e.code === 'Escape') {
    closeFocusMode();
    closeIOSModal();
  } else if (e.key === 'f' || e.key === 'F') {
    // Only toggle fullscreen if in focus mode
    if (document.getElementById('focusOverlay')?.classList.contains('open')) {
      toggleBrowserFullscreen();
    }
  } else if (e.key === 'r' || e.key === 'R') {
    resetDemoTimer();
  } else if (e.key === 's' || e.key === 'S') {
    skipDemoPhase();
  }
});

// Show shortcuts briefly on user mouse movement in focus mode
window.addEventListener('mousemove', () => {
  if (document.getElementById('focusOverlay')?.classList.contains('open')) {
    const pills = document.querySelectorAll('.focus-shortcuts-pill.faded');
    if (pills.length > 0) {
      scheduleShortcutsFade();
    }
  }
}, { passive: true });

// Sync ambient selectors & volume between hero and focus mode
function syncAmbientSound(val) {
  const heroSelect = document.getElementById('ambientSelect');
  const focusSelect = document.getElementById('focusAmbientSelect');
  if (heroSelect) heroSelect.value = val;
  if (focusSelect) focusSelect.value = val;
  changeAmbientSound(val);
}

function syncAmbientVolume(val) {
  const heroVol = document.getElementById('ambientVol');
  const focusVol = document.getElementById('focusAmbientVol');
  if (heroVol) heroVol.value = val;
  if (focusVol) focusVol.value = val;
  setAmbientVolume(val);
}

// Hash Detection on Load & Hash Changes
window.addEventListener('DOMContentLoaded', () => {
  if (window.location.hash === '#focus' || window.location.hash === '#webTimer') {
    openFocusMode();
  }
});

window.addEventListener('hashchange', () => {
  if (window.location.hash === '#focus' || window.location.hash === '#webTimer') {
    openFocusMode();
  } else if (document.getElementById('focusOverlay')?.classList.contains('open')) {
    closeFocusMode();
  }
});

// Modal handling
function openIOSModal() {
  document.getElementById('iosModal').classList.add('open');
}

function closeIOSModal(e) {
  document.getElementById('iosModal').classList.remove('open');
}

// Initial draw
drawDial(0);

// FAQ Accordion Handler
function toggleFaqCard(card) {
  const isAlreadyActive = card.classList.contains('active');

  // Close all cards
  document.querySelectorAll('.faq-card').forEach(el => {
    el.classList.remove('active');
  });

  // Toggle current card
  if (!isAlreadyActive) {
    card.classList.add('active');
  }
}

(function initCopySurfaces() {
  const pill = document.getElementById('copyPill');
  let hideTimer;
  let hideComplete;

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text);
    }
    return new Promise((resolve, reject) => {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.setAttribute('readonly', '');
      ta.style.position = 'fixed';
      ta.style.left = '-9999px';
      document.body.appendChild(ta);
      ta.select();
      try {
        document.execCommand('copy') ? resolve() : reject(new Error('copy failed'));
      } catch (err) {
        reject(err);
      } finally {
        document.body.removeChild(ta);
      }
    });
  }

  function showPill(x, y, label) {
    if (!pill) return;
    pill.textContent = label;
    pill.hidden = false;
    pill.style.left = `${x}px`;
    pill.style.top = `${y}px`;
    requestAnimationFrame(() => pill.classList.add('is-on'));
    clearTimeout(hideTimer);
    clearTimeout(hideComplete);
    hideTimer = setTimeout(() => {
      pill.classList.remove('is-on');
      hideComplete = setTimeout(() => {
        pill.hidden = true;
      }, 200);
    }, 1000);
  }

  document.querySelectorAll('[data-copy-surface]').forEach((surface) => {
    surface.addEventListener('click', async (event) => {
      const unit = event.target.closest('td, th');
      if (!unit || event.target.closest('a, button, input, select, textarea')) return;
      const selection = window.getSelection();
      if (selection && String(selection).trim()) return;
      const text = (unit.innerText || '')
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean)
        .join('\n');
      if (!text || text === '—' || text === '-') return;
      try {
        await copyText(text);
        unit.classList.add('copied-flash');
        setTimeout(() => unit.classList.remove('copied-flash'), 850);
        showPill(event.clientX, event.clientY, 'Copied');
      } catch (err) {
        showPill(event.clientX, event.clientY, 'Copy failed');
      }
    });
  });
})();

