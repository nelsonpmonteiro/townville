// Audio engine for Townville MVP
// Based on HERMES-audio-spec.md (pasted_content_2026-09-16_19-04-13-355_5ada39.txt)

import AsyncStorage from '@react-native-async-storage/async-storage';

let sharedCtx: AudioContext | null = null;

function getCtx() {
  if (!sharedCtx) {
    sharedCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
  }
  return sharedCtx;
}

// Mute state management
let isMuted = false;

export async function loadMuteState() {
  const saved = await AsyncStorage.getItem('townville-muted');
  isMuted = saved === 'true';
  return isMuted;
}

export async function setMuted(value: boolean) {
  isMuted = value;
  await AsyncStorage.setItem('townville-muted', String(value));
}

export function getMuted() {
  return isMuted;
}

export function playSfx(fn: () => void) {
  if (isMuted) return;
  fn();
}

// Generated sound effects (Web Audio API)

export function playCorrect() {
  const ctx = getCtx();
  [[523, 0], [659, 0.1], [784, 0.2], [1047, 0.3]].forEach(([freq, delay]) => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = freq;
    osc.type = 'sine';
    gain.gain.setValueAtTime(0.25, ctx.currentTime + delay);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + delay + 0.25);
    osc.start(ctx.currentTime + delay);
    osc.stop(ctx.currentTime + delay + 0.3);
  });
}

export function playPhaseProgress() {
  const ctx = getCtx();
  [[659, 0], [880, 0.1]].forEach(([freq, delay]) => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = freq;
    osc.type = 'sine';
    gain.gain.setValueAtTime(0.22, ctx.currentTime + delay);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + delay + 0.2);
    osc.start(ctx.currentTime + delay);
    osc.stop(ctx.currentTime + delay + 0.25);
  });
}

export function playWrong(volumeScale = 1) {
  const ctx = getCtx();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.type = 'sawtooth';
  osc.frequency.setValueAtTime(300, ctx.currentTime);
  osc.frequency.exponentialRampToValueAtTime(150, ctx.currentTime + 0.3);
  gain.gain.setValueAtTime(0.18 * volumeScale, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.3);
  osc.start();
  osc.stop(ctx.currentTime + 0.35);
}

export function playUnlock() {
  const ctx = getCtx();
  [[392, 0], [493.88, 0.12], [587.33, 0.24], [783.99, 0.36]].forEach(([freq, delay]) => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = freq;
    osc.type = 'sine';
    gain.gain.setValueAtTime(0.3, ctx.currentTime + delay);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + delay + 0.4);
    osc.start(ctx.currentTime + delay);
    osc.stop(ctx.currentTime + delay + 0.5);
  });
}

export function playTap() {
  const ctx = getCtx();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.frequency.value = 900;
  osc.type = 'sine';
  gain.gain.setValueAtTime(0.15, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.06);
  osc.start();
  osc.stop(ctx.currentTime + 0.08);
}

export function playHint() {
  const ctx = getCtx();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.frequency.value = 1100;
  osc.type = 'sine';
  gain.gain.setValueAtTime(0.12, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15);
  osc.start();
  osc.stop(ctx.currentTime + 0.18);
}

export function playSessionEnd() {
  const ctx = getCtx();
  [261.63, 329.63, 392, 523.25].forEach((freq, i) => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = freq;
    osc.type = 'sine';
    const t = ctx.currentTime + i * 0.1;
    gain.gain.setValueAtTime(0.25, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.5);
    osc.start(t);
    osc.stop(t + 0.6);
  });
}

export function playDrag() {
  const ctx = getCtx();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.frequency.setValueAtTime(200, ctx.currentTime);
  osc.frequency.linearRampToValueAtTime(320, ctx.currentTime + 0.1);
  osc.type = 'triangle';
  gain.gain.setValueAtTime(0.08, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.12);
  osc.start();
  osc.stop(ctx.currentTime + 0.14);
}

export function playDrop() {
  const ctx = getCtx();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.frequency.setValueAtTime(180, ctx.currentTime);
  osc.frequency.exponentialRampToValueAtTime(90, ctx.currentTime + 0.1);
  osc.type = 'sine';
  gain.gain.setValueAtTime(0.2, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15);
  osc.start();
  osc.stop(ctx.currentTime + 0.18);
}
