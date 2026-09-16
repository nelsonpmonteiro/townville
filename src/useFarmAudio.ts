import { useAudioPlayer } from "expo-audio";
import { useEffect, useMemo, useRef } from "react";
import { AppState, Platform } from "react-native";
import { SoundGate } from "./sound";
export function useFarmAudio(muted: boolean, completed: number) {
  const music = useAudioPlayer(
    require("../assets/audio/music-farm-ambient.wav"),
  );
  const correct = useAudioPlayer(require("../assets/audio/sfx-correct.wav"));
  const ending = useAudioPlayer(require("../assets/audio/sfx-session-end.wav"));
  const gate = useMemo(
    () =>
      new SoundGate({
        play: () => {
          music.loop = true;
          music.volume = 0.16;
          music.play();
        },
        pause: () => {
          music.pause();
          correct.pause();
          ending.pause();
        },
      }),
    [music, correct, ending],
  );
  const muteRef = useRef(muted);
  muteRef.current = muted;
  const hidden = () =>
    Platform.OS === "web"
      ? document.hidden
      : AppState.currentState !== "active";
  useEffect(() => {
    gate.sync(muted, hidden());
  }, [muted, gate]);
  useEffect(() => {
    const gesture = () => gate.gesture();
    const visibility = () => gate.sync(muteRef.current, hidden());
    if (Platform.OS === "web") {
      window.addEventListener("pointerdown", gesture);
      window.addEventListener("keydown", gesture);
      document.addEventListener("visibilitychange", visibility);
      return () => {
        window.removeEventListener("pointerdown", gesture);
        window.removeEventListener("keydown", gesture);
        document.removeEventListener("visibilitychange", visibility);
      };
    }
    const sub = AppState.addEventListener("change", visibility);
    return () => sub.remove();
  }, [gate]);
  const last = useRef(completed);
  useEffect(() => {
    if (completed > last.current && gate.allowed) {
      const p = completed === 5 ? ending : correct;
      p.volume = 0.35;
      p.seekTo(0);
      p.play();
    }
    last.current = completed;
  }, [completed, gate, correct, ending]);
  return () => gate.gesture();
}
