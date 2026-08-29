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

function getAudioContext() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
  return audioCtx;
}

function playWebSound(type) {
  stopWebSound();
  if (type === 'none') return;

  const ctx = getAudioContext();
  const bufferSize = 2 * ctx.sampleRate;
  const noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
  const output = noiseBuffer.getChannelData(0);

  let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
  let lastOut = 0.0;

  for (let i = 0; i < bufferSize; i++) {
    const white = Math.random() * 2 - 1;
    if (type === 'rain') {
      b0 = 0.95 * b0 + white * 0.05;
      const drop = Math.random() > 0.996 ? Math.random() * 0.4 : 0;
      output[i] = (b0 * 0.7 + drop * 0.3) * 0.8;
    } else if (type === 'pinkNoise') {
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.96900 * b2 + white * 0.1538520;
      b3 = 0.86650 * b3 + white * 0.3104856;
      b4 = 0.55000 * b4 + white * 0.5329522;
      b5 = -0.7616 * b5 - white * 0.0168980;
      output[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.12;
      b6 = white * 0.115926;
    } else if (type === 'brownNoise') {
      lastOut = (lastOut + 0.02 * white) / 1.02;
      output[i] = lastOut * 3.0;
    } else if (type === 'oceanWaves') {
      const lfo = Math.sin((i / ctx.sampleRate) * 0.15 * Math.PI * 2);
      lastOut = (lastOut + 0.02 * white) / 1.02;
      output[i] = lastOut * (0.3 + (lfo + 1) * 1.2);
    } else if (type === 'stream') {
      b0 = 0.85 * b0 + white * 0.15;
      b1 = 0.90 * b1 + b0 * 0.10;
      output[i] = (b1 * 1.2 + white * 0.03) * 0.6;
    }
  }

  const whiteNoise = ctx.createBufferSource();
  whiteNoise.buffer = noiseBuffer;
  whiteNoise.loop = true;

  gainNode = ctx.createGain();
  const vol = parseFloat(document.getElementById('ambientVol')?.value || 0.5);
  gainNode.gain.setValueAtTime(0.01, ctx.currentTime);
  gainNode.gain.linearRampToValueAtTime(vol * 0.35, ctx.currentTime + 0.5);

  whiteNoise.connect(gainNode);
  gainNode.connect(ctx.destination);
  whiteNoise.start();

  activeNoiseNode = whiteNoise;

  // Update pills active states
  document.querySelectorAll('.sound-btn').forEach(btn => {
    btn.classList.toggle('active', btn.textContent.toLowerCase().includes(type.toLowerCase()));
  });
}

function stopWebSound() {
  if (activeNoiseNode && gainNode && audioCtx) {
    gainNode.gain.linearRampToValueAtTime(0.001, audioCtx.currentTime + 0.3);
    setTimeout(() => {
      try { activeNoiseNode.stop(); } catch(e){}
      activeNoiseNode = null;
    }, 300);
  }
}

function changeAmbientSound(val) {
  if (timerState === 'running') {
    if (val === 'none') stopWebSound();
    else playWebSound(val);
  }
}

function setAmbientVolume(val) {
  if (gainNode && audioCtx) {
    gainNode.gain.setValueAtTime(parseFloat(val) * 0.35, audioCtx.currentTime);
  }
}

// 528Hz Harmonic Solfeggio Bell Chime
function playBellChime() {
  const ctx = getAudioContext();
  const f0 = 528;
  const harmonics = [f0, f0 * 1.503, f0 * 2.001, f0 * 2.756];
  const gains = [0.4, 0.2, 0.12, 0.08];

  harmonics.forEach((freq, idx) => {
    const osc = ctx.createOscillator();
    const g = ctx.createGain();

    osc.frequency.setValueAtTime(freq, ctx.currentTime);
    g.gain.setValueAtTime(gains[idx], ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 3.0);

    osc.connect(g);
    g.connect(ctx.destination);

    osc.start();
    osc.stop(ctx.currentTime + 3.2);
  });
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
