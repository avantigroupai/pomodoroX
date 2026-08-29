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

// Canvas Ring Setup
const canvas = document.getElementById('timerCanvas');
const ctx = canvas.getContext('2d');
const size = 280;
const center = size / 2;
const radius = 110;

function drawDial(progress) {
  ctx.clearRect(0, 0, size, size);

  const cfg = phaseConfigs[currentPhase];

  // 1. Ambient Radial Glow
  const gradGlow = ctx.createRadialGradient(center, center, 40, center, center, 135);
  gradGlow.addColorStop(0, hexToRgba(cfg.colorStart, timerState === 'running' ? 0.25 : 0.08));
  gradGlow.addColorStop(1, 'transparent');
  ctx.fillStyle = gradGlow;
  ctx.beginPath();
  ctx.arc(center, center, 135, 0, Math.PI * 2);
  ctx.fill();

  // 2. 60 Minute Tick Marks
  ctx.save();
  ctx.translate(center, center);
  for (let i = 0; i < 60; i++) {
    const angle = (i * 6 * Math.PI) / 180;
    ctx.rotate(6 * Math.PI / 180);
    ctx.fillStyle = i % 5 === 0 ? 'rgba(255, 255, 255, 0.25)' : 'rgba(255, 255, 255, 0.08)';
    ctx.fillRect(-0.75, -radius - 12, i % 5 === 0 ? 1.5 : 1, i % 5 === 0 ? 7 : 3.5);
  }
  ctx.restore();

  // 3. Background Track
  ctx.beginPath();
  ctx.arc(center, center, radius, 0, Math.PI * 2);
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.08)';
  ctx.lineWidth = 14;
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
  ctx.lineWidth = 14;
  ctx.lineCap = 'round';
  ctx.shadowColor = cfg.colorStart;
  ctx.shadowBlur = timerState === 'running' ? 14 : 6;
  ctx.stroke();
  ctx.shadowBlur = 0;

  // 5. Leading Glowing Arc Cursor Dot
  if (progress > 0.01 && progress < 0.99) {
    const dotX = center + radius * Math.cos(endAngle);
    const dotY = center + radius * Math.sin(endAngle);

    ctx.beginPath();
    ctx.arc(dotX, dotY, 6, 0, Math.PI * 2);
    ctx.fillStyle = '#ffffff';
    ctx.shadowColor = cfg.colorStart;
    ctx.shadowBlur = 10;
    ctx.fill();
    ctx.shadowBlur = 0;
  }
}

function updateDisplay() {
  const mins = Math.floor(timeRemaining / 60);
  const secs = timeRemaining % 60;
  const timeStr = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  
  document.getElementById('timerTime').textContent = timeStr;
  document.querySelector('.device-status').textContent = timeStr;

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

  // Update Buttons
  document.querySelectorAll('.phase-pill').forEach(pill => pill.classList.remove('active'));
  const idx = phase === 'focus' ? 0 : (phase === 'shortBreak' ? 1 : 2);
  document.querySelectorAll('.phase-pill')[idx].classList.add('active');

  const tag = document.getElementById('phaseTag');
  tag.textContent = cfg.name;
  tag.style.color = cfg.colorStart;
  tag.style.background = hexToRgba(cfg.colorStart, 0.15);

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

    const sound = document.getElementById('ambientSelect').value;
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
    document.getElementById('pomoCount').textContent = completedPomodoros;
    setDemoPhase('shortBreak');
  } else {
    setDemoPhase('focus');
  }
}

function updatePlayIcon() {
  const icon = document.getElementById('playIcon');
  if (timerState === 'running') {
    icon.innerHTML = '<rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect>';
  } else {
    icon.innerHTML = '<polygon points="5 3 19 12 5 21 5 3"></polygon>';
  }
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
  if (emulatorSelect) {
    emulatorSelect.value = activeType || 'none';
  }
}

function playWebSound(type) {
  stopWebSound();
  if (!type || type === 'none') return;

  try {
    const ctx = getAudioContext();
    const sampleRate = ctx.sampleRate;
    const loopDuration = (type === 'oceanWaves') ? 12 : (type === 'omChant' ? 9 : 4);
    const bufferSize = Math.floor(loopDuration * sampleRate);
    const soundBuffer = ctx.createBuffer(1, bufferSize, sampleRate);
    const output = soundBuffer.getChannelData(0);

    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    let brown = 0.0;
    let dropletDecay = 0;
    let dropletFreq = 3200;

    for (let i = 0; i < bufferSize; i++) {
      const white = Math.random() * 2 - 1;
      const t = i / sampleRate;

      if (type === 'rain') {
        // 🌧 REAL RAIN: Diffuse rainfall bed + Poisson individual raindrop impacts + soft wind swell
        b0 = 0.96 * b0 + white * 0.04;
        b1 = 0.92 * b1 + b0 * 0.08;
        const rainBed = (b1 * 2.0) * 0.7;

        if (Math.random() > 0.995) {
          dropletDecay = 0.5 + Math.random() * 0.4;
          dropletFreq = 2400 + Math.random() * 2200;
        } else {
          dropletDecay *= 0.992;
        }
        const droplet = dropletDecay > 0.001 ? Math.sin(dropletFreq * dropletDecay) * dropletDecay * 0.4 : 0.0;
        output[i] = rainBed + droplet;

      } else if (type === 'oceanWaves') {
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

      } else if (type === 'omChant') {
        // 🕉 AUTHENTIC OM CHANTING: Sacred 136.1 Hz fundamental + harmonic throat resonance + meditative 9s breath cycle
        const breathPeriod = 9.0;
        const breathPhase = (t / breathPeriod) * Math.PI * 2;
        const breathEnv = Math.max(0.08, Math.pow((Math.sin(breathPhase) + 1.0) * 0.5, 1.25));

        const vibrato = Math.sin(t * 5.2 * Math.PI * 2) * 0.8;
        const f0 = 136.1 + vibrato;

        const h0 = Math.sin(t * f0 * Math.PI * 2) * 0.55;
        const h1 = Math.sin(t * f0 * 2.0 * Math.PI * 2) * 0.26;
        const h2 = Math.sin(t * f0 * 3.0 * Math.PI * 2) * 0.15;
        const h3 = Math.sin(t * f0 * 4.0 * Math.PI * 2) * 0.08;
        const subBass = Math.sin(t * (f0 * 0.5) * Math.PI * 2) * 0.22;

        const rawVocal = (h0 + h1 + h2 + h3 + subBass) * breathEnv;
        b0 = 0.88 * b0 + rawVocal * 0.12;
        b1 = 0.84 * b1 + b0 * 0.16;
        output[i] = b1 * 1.6;

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
function toggleFaq(button) {
  const item = button.closest('.faq-item');
  const isExpanded = button.getAttribute('aria-expanded') === 'true';
  
  // Close all other FAQ items for a clean single-open accordion behavior
  document.querySelectorAll('.faq-item').forEach(faq => {
    if (faq !== item) {
      faq.classList.remove('active');
      const btn = faq.querySelector('.faq-question');
      if (btn) btn.setAttribute('aria-expanded', 'false');
    }
  });

  if (isExpanded) {
    item.classList.remove('active');
    button.setAttribute('aria-expanded', 'false');
  } else {
    item.classList.add('active');
    button.setAttribute('aria-expanded', 'true');
  }
}

// Ensure the first FAQ is active on load
document.addEventListener('DOMContentLoaded', () => {
  const firstFaq = document.querySelector('.faq-item');
  if (firstFaq) {
    firstFaq.classList.add('active');
    const firstBtn = firstFaq.querySelector('.faq-question');
    if (firstBtn) firstBtn.setAttribute('aria-expanded', 'true');
  }
});
