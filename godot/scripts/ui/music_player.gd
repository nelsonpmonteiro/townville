extends AudioStreamPlayer
## MusicPlayer — looping background track on the Music bus.
##
## The stream is looped in code (loop = true on the imported MP3) and routed to
## the "Music" bus so VolumeControl's Music slider changes it without touching
## the placement "pop" SFX.
##
## Web autoplay: browsers block audio until the first user gesture. The engine
## starts playback immediately; if the browser suspended the context, the first
## key/click resumes it and we restart playback from the top.

const TRACK_PATH := "res://assets/audio/pastoral-peace.mp3"

var _kickstarted := false

func _ready() -> void:
	name = "MusicPlayer"
	bus = "Music"
	autoplay = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not ResourceLoader.exists(TRACK_PATH):
		push_warning("MusicPlayer: track missing at %s" % TRACK_PATH)
		return
	var track := load(TRACK_PATH)
	if track is AudioStreamMP3:
		track.loop = true
	stream = track
	finished.connect(_on_finished)
	play()

## MP3 loop flag is honoured by the engine, but a stream that ends for any other
## reason (seek, web suspend) must restart or the map goes silent for good.
func _on_finished() -> void:
	play()

## Called from Game on the first user gesture: browsers only unlock the audio
## context after one, so playback started at _ready() may be silently suspended.
func kickstart() -> void:
	if _kickstarted:
		return
	_kickstarted = true
	if stream and not playing:
		play()

func is_music_playing() -> bool:
	return playing
