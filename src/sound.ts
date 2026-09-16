export class SoundGate {
  private unlocked = false;
  private muted = false;
  private hidden = false;
  constructor(private port: { play: () => void; pause: () => void }) {}
  sync(muted: boolean, hidden: boolean) {
    this.muted = muted;
    this.hidden = hidden;
    this.apply();
  }
  gesture() {
    this.unlocked = true;
    this.apply();
  }
  get allowed() {
    return this.unlocked && !this.muted && !this.hidden;
  }
  private apply() {
    if (this.allowed) this.port.play();
    else this.port.pause();
  }
}
