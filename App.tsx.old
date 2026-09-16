import React, { useEffect, useRef, useState } from "react";
import {
  View,
  Text,
  Pressable,
  ScrollView,
  StyleSheet,
  useWindowDimensions,
  Platform,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  NPCS,
  QUESTS,
  BUILDINGS,
  move,
  fresh,
  complete,
  restore,
  serialize,
  available,
  sessionDone,
  Save,
} from "./src/core";
import { FarmArt, Person } from "./src/Art";
import Collection from "./src/Collection";
import { useFarmAudio } from "./src/useFarmAudio";
const KEY = "townville.save.v1";
function Button({
  label,
  onPress,
  subtle = false,
}: {
  label: string;
  onPress: () => void;
  subtle?: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={[s.button, subtle && s.subtle]}
    >
      <Text style={[s.buttonText, subtle && { color: "#566285" }]}>
        {label}
      </Text>
    </Pressable>
  );
}
export default function App() {
  const { width } = useWindowDimensions();
  const narrow = width < 900;
  const [save, setSave] = useState<Save>(fresh),
    [ready, setReady] = useState(false),
    [pos, setPos] = useState({ x: 8, y: 9 }),
    [open, setOpen] = useState(false),
    [success, setSuccess] = useState(false),
    [summary, setSummary] = useState(false),
    [collected, setCollected] = useState<number[]>([]),
    [selected, setSelected] = useState<number | null>(null),
    [message, setMessage] = useState(""),
    [storageMessage, setStorageMessage] = useState("");
  const unlockAudio = useFarmAudio(save.muted, save.completed.length);
  const scrollX = useRef<ScrollView>(null),
    scrollY = useRef<ScrollView>(null);
  const fieldWidth = Math.min(narrow ? width - 32 : width - 354, 960);
  const fieldHeight = narrow ? 430 : 580;
  const quest = QUESTS[save.completed.length];
  const active = useRef(quest);
  if (!open && !success) active.current = quest;
  const q = open || success ? active.current : quest;
  useEffect(() => {
    AsyncStorage.getItem(KEY)
      .then((raw) => {
        setSave(restore(raw));
        setReady(true);
      })
      .catch(() => {
        setStorageMessage("Storage unavailable. This visit will not be saved.");
        setReady(true);
      });
  }, []);
  useEffect(() => {
    if (ready)
      AsyncStorage.setItem(KEY, serialize(save)).catch(() =>
        setStorageMessage("Storage unavailable. This visit will not be saved."),
      );
  }, [save, ready]);
  useEffect(() => {
    scrollX.current?.scrollTo({
      x: Math.max(0, pos.x * 48 - fieldWidth / 2 + 24),
      animated: false,
    });
    scrollY.current?.scrollTo({
      y: Math.max(0, pos.y * 48 - fieldHeight / 2 + 24),
      animated: false,
    });
  }, [pos, fieldWidth, ready]);
  const near = (n: (typeof NPCS)[number]) =>
    Math.abs(n.x - pos.x) + Math.abs(n.y - pos.y) <= 1;
  const talk = (name: string) => {
    const n = NPCS.find((n) => n.name === name)!;
    if (!near(n)) {
      setMessage(`Walk closer to ${name} to say hello.`);
      return;
    }
    if (!available(save, name)) {
      setMessage(
        ["Mae", "Chester", "Lily"].includes(name)
          ? `Let's help ${quest?.npc ?? "the farm"} first.`
          : `${name}'s activities are still being planted. Come back another day.`,
      );
      return;
    }
    setMessage("");
    setCollected([]);
    setSelected(null);
    active.current = quest;
    setOpen(true);
  };
  const walk = (dx: number, dy: number) => {
    if (!open && !success && !summary) setPos((p) => move(p, dx, dy));
  };
  useEffect(() => {
    if (Platform.OS !== "web") return;
    const handler = (e: KeyboardEvent) => {
      if (
        (e.target as HTMLElement)?.tagName === "BUTTON" &&
        (e.key === " " || e.key === "Enter")
      )
        return;
      const dirs: Record<string, number[]> = {
        ArrowUp: [0, -1],
        w: [0, -1],
        ArrowDown: [0, 1],
        s: [0, 1],
        ArrowLeft: [-1, 0],
        a: [-1, 0],
        ArrowRight: [1, 0],
        d: [1, 0],
      };
      if (dirs[e.key]) {
        e.preventDefault();
        walk(dirs[e.key][0], dirs[e.key][1]);
      } else if ((e.key === "Enter" || e.key === " ") && !open && !success) {
        e.preventDefault();
        const n = NPCS.find(near);
        if (n) talk(n.name);
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  });
  const transfer = (id: number) => {
    setCollected((c) => (c.includes(id) ? c : [...c, id]));
    setSelected(null);
    setMessage("");
  };
  const check = () => {
    if (!q) return;
    if (collected.length !== q.count) {
      setMessage("Not quite yet. Count together and try again.");
      return;
    }
    setSave((s) => complete(s, q.id, collected.length));
    setOpen(false);
    setSuccess(true);
    setMessage("");
  };
  if (!ready)
    return (
      <View style={s.shell}>
        <Text>Opening the farm…</Text>
      </View>
    );
  return (
    <ScrollView
      onTouchStart={unlockAudio}
      style={s.shell}
      contentContainerStyle={{ padding: narrow ? 16 : 28, paddingBottom: 30 }}
    >
      <View style={[s.header, narrow && { flexWrap: "wrap" }]}>
        <View>
          <Text style={s.logo}>
            townville<Text style={{ color: "#86ac77" }}>✦</Text>
          </Text>
          <Text style={s.tagline}>Little steps. A growing town.</Text>
        </View>
        <View style={s.row}>
          <View style={s.pill}>
            <Text style={s.pillText}>{save.score} stars</Text>
          </View>
          <Button
            label={save.muted ? "Sound off" : "Sound on"}
            subtle
            onPress={() => setSave((v) => ({ ...v, muted: !v.muted }))}
          />
        </View>
      </View>
      <View
        style={[
          s.row,
          {
            alignItems: "flex-start",
            marginTop: 24,
            flexDirection: narrow ? "column" : "row",
            gap: 22,
          },
        ]}
      >
        <View style={[s.sidebar, narrow && { display: "none" }]}>
          <Text style={s.eyebrow}>YOUR LITTLE WORLD</Text>
          <Text style={s.heading}>A day on the farm</Text>
          <Text style={s.body}>
            A little counting. A little kindness. A place that grows with you.
          </Text>
          <View style={s.divider} />
          <Text style={s.eyebrow}>TODAY'S ADVENTURE</Text>
          <Text style={s.task}>
            {sessionDone(save)
              ? "A lovely day of helping"
              : `Say hello to ${quest?.npc}`}
          </Text>
          <Text style={s.body}>
            {sessionDone(save)
              ? "Your farm is brighter because of you."
              : `Help with ${quest?.kind === "hay" ? "hay bales" : quest?.kind + "s"} and make something wonderful.`}
          </Text>
          <View style={s.progress}>
            {[0, 1, 2, 3, 4].map((i) => (
              <View
                key={i}
                style={[
                  s.progressPart,
                  {
                    backgroundColor:
                      i < save.completed.length ? "#83a96e" : "#e4e4ee",
                  },
                ]}
              />
            ))}
          </View>
          <Text style={s.small}>{save.completed.length} / 5 helping hands</Text>
          <Text style={[s.small, { marginTop: 7 }]}>
            {save.streak} kind helps in a row · never lost by mistakes
          </Text>
          {sessionDone(save) && (
            <Button label="View my day" onPress={() => setSummary(true)} />
          )}
          <View style={s.divider} />
          <Text style={s.eyebrow}>YOUR NEIGHBOURHOODS</Text>
          <View style={s.world}>
            <Text style={s.worldText}>01 The Farm</Text>
            <Text style={s.small}>You are here</Text>
          </View>
          {[
            "02   The Market",
            "03   The Harbour",
            "04   The Workshop",
            "05   The Observatory",
          ].map((t) => (
            <View
              key={t}
              accessibilityState={{ disabled: true }}
              style={s.roadmap}
            >
              <Text style={s.small}>{t}</Text>
              <Text style={[s.small, { fontSize: 10 }]}>COMING LATER</Text>
            </View>
          ))}
          <Text style={[s.small, { marginTop: 18 }]}>
            Local prototype · no account needed
          </Text>
        </View>
        <View
          style={{ flex: 1, minWidth: 0, width: narrow ? "100%" : undefined }}
        >
          {narrow && (
            <Text style={[s.small, { marginBottom: 12 }]}>
              {save.completed.length} / 5 helping hands ·{" "}
              {sessionDone(save) ? "A lovely day!" : `Help ${quest?.npc} next`}
            </Text>
          )}
          <View style={s.fieldHeader}>
            <View>
              <Text style={s.eyebrow}>WORLD 01</Text>
              <Text style={s.fieldTitle}>The Farm</Text>
            </View>
            <Text style={s.small}>Take your time. You're home.</Text>
          </View>
          <View
            style={{
              width: fieldWidth,
              height: fieldHeight,
              borderRadius: 24,
              overflow: "hidden",
              borderWidth: 5,
              borderColor: "#fff",
            }}
          >
            <ScrollView
              ref={scrollY}
              scrollEnabled={false}
              showsVerticalScrollIndicator={false}
            >
              <ScrollView
                ref={scrollX}
                horizontal
                scrollEnabled={false}
                showsHorizontalScrollIndicator={false}
              >
                <View style={{ width: 960, height: 720 }}>
                  <FarmArt upgrade={save.upgrade} />
                  {BUILDINGS.map((b, i) => (
                    <View
                      key={b.name}
                      style={{
                        position: "absolute",
                        left: b.x * 48,
                        top: (b.y + b.h) * 48 + 4,
                        width: b.w * 48,
                        alignItems: "center",
                      }}
                    >
                      <Text style={s.mapLabel}>
                        {b.name} • Level {save.upgrade > i ? 1 : 0}
                      </Text>
                    </View>
                  ))}
                  {NPCS.map((n, i) => (
                    <Pressable
                      key={n.name}
                      accessibilityRole="button"
                      accessibilityLabel={`Talk to ${n.name}`}
                      onPress={() => talk(n.name)}
                      style={{
                        position: "absolute",
                        left: n.x * 48,
                        top: n.y * 48 - 12,
                        width: 48,
                        alignItems: "center",
                      }}
                    >
                      {available(save, n.name) && (
                        <Text style={s.questMarker}>!</Text>
                      )}
                      <Person
                        color={
                          ["#b479ad", "#db9a58", "#779c8c", "#9a8cb4"][i % 4]
                        }
                      />
                      <Text style={s.mapLabel}>{n.name}</Text>
                    </Pressable>
                  ))}
                  <View
                    pointerEvents="none"
                    testID="player"
                    style={{
                      position: "absolute",
                      left: pos.x * 48,
                      top: pos.y * 48 - 10,
                    }}
                  >
                    <Person />
                    <Text
                      style={[
                        s.mapLabel,
                        { backgroundColor: "#5575cf", color: "white" },
                      ]}
                    >
                      You
                    </Text>
                  </View>
                </View>
              </ScrollView>
            </ScrollView>
          </View>
          <View
            style={[
              s.row,
              {
                justifyContent: "space-between",
                marginTop: 14,
                alignItems: "center",
                flexWrap: "wrap",
              },
            ]}
          >
            <View style={{ flex: 1, minWidth: 180 }}>
              <Text style={s.small}>
                WASD / arrows to explore · Enter to talk
              </Text>
              <Text style={[s.small, { marginTop: 5 }]}>
                Or use the direction buttons and tap a nearby friend.
              </Text>
              {NPCS.filter(near).map((n) => (
                <Button
                  key={n.name}
                  label={`Help ${n.name}`}
                  onPress={() => talk(n.name)}
                />
              ))}
            </View>
            <View style={{ alignItems: "center", gap: 4 }}>
              <Button label="↑" subtle onPress={() => walk(0, -1)} />
              <View style={{ flexDirection: "row", gap: 4 }}>
                <Button label="←" subtle onPress={() => walk(-1, 0)} />
                <Button label="↓" subtle onPress={() => walk(0, 1)} />
                <Button label="→" subtle onPress={() => walk(1, 0)} />
              </View>
            </View>
          </View>
          {!open && message && (
            <Text accessibilityLiveRegion="polite" style={s.notice}>
              {message}
            </Text>
          )}
          {storageMessage && <Text style={s.notice}>{storageMessage}</Text>}
        </View>
      </View>
      {(open || success || summary) && (
        <View style={s.overlay}>
          <ScrollView
            contentContainerStyle={{
              flexGrow: 1,
              justifyContent: "center",
              alignItems: "center",
              padding: 18,
            }}
          >
            <View style={[s.modal, { width: Math.min(width - 36, 750) }]}>
              {open && q ? (
                <>
                  <View style={s.row}>
                    <Person color="#b479ad" size={60} />
                    <View>
                      <Text style={s.eyebrow}>
                        {q.npc.toUpperCase()} NEEDS A HELPING HAND
                      </Text>
                      <Text style={s.heading}>Let's count together.</Text>
                    </View>
                  </View>
                  <Text style={s.instruction}>
                    Move {q.count}{" "}
                    {q.kind === "hay" ? "hay bales" : q.kind + "s"} to the{" "}
                    {q.target}.
                  </Text>
                  <Text style={s.body}>
                    Drag each one into place. Or select one, then tap the{" "}
                    {q.target}.
                  </Text>
                  <Collection
                    kind={q.kind}
                    target={q.target}
                    items={Array.from(
                      { length: q.count + 2 },
                      (_, i) => i,
                    ).filter((i) => !collected.includes(i))}
                    selected={selected}
                    select={setSelected}
                    transfer={transfer}
                    count={collected.length}
                  />
                  <Text accessibilityLiveRegion="polite" style={s.feedback}>
                    {message || "One at a time. You can do this."}
                  </Text>
                  <View
                    style={[
                      s.row,
                      { flexWrap: "wrap", justifyContent: "center" },
                    ]}
                  >
                    <Button label="Check my collection" onPress={check} />
                    <Button
                      label="Give me a hint"
                      subtle
                      onPress={() =>
                        setMessage(
                          `Count slowly from 1 to ${q.count}. You have ${collected.length}. ${collected.length > q.count ? "Return some and try again." : "Move one at a time."}`,
                        )
                      }
                    />
                    <Button
                      label="Return all"
                      subtle
                      onPress={() => {
                        setCollected([]);
                        setSelected(null);
                      }}
                    />
                  </View>
                  <Button
                    label="Back to exploring"
                    subtle
                    onPress={() => {
                      setOpen(false);
                      setMessage("");
                    }}
                  />
                </>
              ) : success ? (
                <>
                  <Text style={s.celebrate}>✦ ✧ ✦</Text>
                  <Text style={s.heading}>You helped the farm grow!</Text>
                  <Text style={s.instruction}>
                    A little care makes a big difference.
                  </Text>
                  <Text style={s.body}>
                    +100 stars ·{" "}
                    {save.completed.length <= 3
                      ? `${BUILDINGS[save.completed.length - 1].name} upgraded!`
                      : "Your neighbours say thank you!"}
                  </Text>
                  <Button
                    label="Back to the farm"
                    onPress={() => {
                      setSuccess(false);
                      if (sessionDone(save)) setSummary(true);
                    }}
                  />
                </>
              ) : (
                <>
                  <Text style={s.eyebrow}>A DAY WELL SPENT</Text>
                  <Text style={s.heading}>Look what you made possible.</Text>
                  <Text style={s.instruction}>
                    5 helping hands. A happier farm.
                  </Text>
                  <Text style={s.body}>
                    {save.score} stars · 3 farm upgrades · a whole lot of
                    kindness.
                  </Text>
                  <Text style={[s.body, { marginVertical: 20 }]}>
                    You counted eggs, guided chicks and carried hay. Your town
                    will be right here when you return.
                  </Text>
                  <Button
                    label="Keep exploring"
                    onPress={() => setSummary(false)}
                  />
                </>
              )}
            </View>
          </ScrollView>
        </View>
      )}
    </ScrollView>
  );
}
const s = StyleSheet.create({
  shell: { flex: 1, backgroundColor: "#f1eff9" },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 10,
  },
  logo: {
    fontSize: 34,
    fontWeight: "800",
    letterSpacing: -1.5,
    color: "#3e4268",
  },
  tagline: { fontSize: 13, color: "#7d7f99", marginTop: 3 },
  row: { flexDirection: "row", gap: 10, alignItems: "center" },
  pill: { padding: 12, backgroundColor: "#fff9e5", borderRadius: 16 },
  pillText: { color: "#998044", fontWeight: "700" },
  button: {
    backgroundColor: "#5678df",
    paddingHorizontal: 18,
    paddingVertical: 13,
    borderRadius: 13,
    marginTop: 8,
    minHeight: 44,
    alignItems: "center",
  },
  subtle: { backgroundColor: "#e8e8f3" },
  buttonText: { fontWeight: "700", color: "#fff", fontSize: 14 },
  sidebar: {
    width: 276,
    padding: 23,
    borderRadius: 23,
    backgroundColor: "#fff",
  },
  eyebrow: {
    fontSize: 10,
    fontWeight: "800",
    letterSpacing: 1.9,
    color: "#8b8da5",
  },
  heading: {
    fontSize: 25,
    fontWeight: "700",
    color: "#3e4262",
    marginTop: 8,
    letterSpacing: -0.6,
  },
  body: { fontSize: 14, lineHeight: 23, color: "#797d91", marginTop: 9 },
  divider: { height: 1, backgroundColor: "#eeedf5", marginVertical: 23 },
  task: { fontSize: 19, fontWeight: "700", color: "#535d7a", marginTop: 12 },
  small: { fontSize: 12, lineHeight: 19, color: "#84869b" },
  progress: { flexDirection: "row", gap: 5, marginTop: 21, marginBottom: 8 },
  progressPart: { height: 7, flex: 1, borderRadius: 4 },
  world: {
    padding: 14,
    backgroundColor: "#f0f4e8",
    borderRadius: 12,
    marginTop: 14,
  },
  worldText: { fontWeight: "700", color: "#6d8255", marginBottom: 3 },
  roadmap: {
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderColor: "#f1f0f7",
    opacity: 0.65,
  },
  fieldHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
    paddingHorizontal: 5,
  },
  fieldTitle: {
    fontSize: 25,
    fontWeight: "700",
    color: "#454d67",
    marginTop: 3,
  },
  mapLabel: {
    fontSize: 10,
    color: "#465b3d",
    fontWeight: "700",
    backgroundColor: "#fff6dc",
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 6,
    overflow: "hidden",
  },
  questMarker: {
    position: "absolute",
    top: -24,
    backgroundColor: "#fff4a4",
    color: "#8b7740",
    fontWeight: "900",
    borderRadius: 12,
    width: 23,
    height: 23,
    textAlign: "center",
    fontSize: 18,
  },
  notice: {
    padding: 15,
    backgroundColor: "#fff7e6",
    color: "#7a735a",
    borderRadius: 12,
    marginTop: 12,
  },
  overlay: {
    position: Platform.OS === "web" ? ("fixed" as any) : "absolute",
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: "rgba(49,54,75,.45)",
    zIndex: 20,
  },
  modal: { backgroundColor: "#fffdf6", borderRadius: 28, padding: 28 },
  instruction: {
    fontSize: 22,
    fontWeight: "600",
    color: "#4e5d53",
    marginTop: 22,
  },
  feedback: {
    color: "#7d8167",
    textAlign: "center",
    minHeight: 32,
    fontSize: 15,
  },
  celebrate: {
    fontSize: 58,
    color: "#dcac54",
    textAlign: "center",
    marginBottom: 20,
  },
});
