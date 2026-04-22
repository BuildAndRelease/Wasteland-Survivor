extends Node
## AudioManager autoload: procedural sound effects using AudioStreamGenerator.
## Generates simple waveform-based SFX for all game events.
## Web-compatible: no external audio files required.

const SAMPLE_RATE: int = 22050
const DEFAULT_VOLUME_DB: float = -10.0

## Pre-built audio streams cached on ready.
var _streams: Dictionary = {}

## Pool of AudioStreamPlayer nodes for concurrent playback.
var _player_pool: Array[AudioStreamPlayer] = []
var _player_2d_pool: Array[AudioStreamPlayer2D] = []
const POOL_SIZE: int = 8
const POOL_2D_SIZE: int = 8


func _ready() -> void:
	_build_player_pool()
	_generate_all_sounds()


func _build_player_pool() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = DEFAULT_VOLUME_DB
		add_child(p)
		_player_pool.append(p)
	for i in POOL_2D_SIZE:
		var p := AudioStreamPlayer2D.new()
		p.bus = "Master"
		p.volume_db = DEFAULT_VOLUME_DB
		p.max_distance = 800.0
		add_child(p)
		_player_2d_pool.append(p)


## Play a named sound effect globally (non-positional).
func play_sfx(sound_name: String, volume_offset: float = 0.0) -> void:
	if not _streams.has(sound_name):
		return
	var player := _get_free_player()
	if player == null:
		return
	player.stream = _streams[sound_name]
	player.volume_db = DEFAULT_VOLUME_DB + volume_offset
	player.play()


## Play a named sound effect at a world position (2D positional).
func play_sfx_at(sound_name: String, pos: Vector2, volume_offset: float = 0.0) -> void:
	if not _streams.has(sound_name):
		return
	var player := _get_free_2d_player()
	if player == null:
		return
	player.stream = _streams[sound_name]
	player.global_position = pos
	player.volume_db = DEFAULT_VOLUME_DB + volume_offset
	player.play()


func _get_free_player() -> AudioStreamPlayer:
	for p in _player_pool:
		if not p.playing:
			return p
	return _player_pool[0]


func _get_free_2d_player() -> AudioStreamPlayer2D:
	for p in _player_2d_pool:
		if not p.playing:
			return p
	return _player_2d_pool[0]


# --- Sound Generation ---

func _generate_all_sounds() -> void:
	_streams["player_attack"] = _gen_blip(0.08, 800.0, 400.0)
	_streams["player_hit"] = _gen_noise_hit(0.15, 300.0)
	_streams["player_death"] = _gen_descending(0.5, 400.0, 80.0)
	_streams["enemy_hit"] = _gen_blip(0.06, 600.0, 300.0)
	_streams["enemy_death"] = _gen_noise_hit(0.12, 500.0)
	_streams["enemy_death_dog"] = _gen_noise_hit(0.1, 700.0)
	_streams["enemy_death_bug"] = _gen_blip(0.1, 900.0, 200.0)
	_streams["enemy_death_giant"] = _gen_noise_hit(0.25, 200.0)
	_streams["exploder_boom"] = _gen_explosion(0.4)
	_streams["boss_slam"] = _gen_explosion(0.3)
	_streams["boss_charge"] = _gen_ascending(0.3, 200.0, 600.0)
	_streams["boss_summon"] = _gen_descending(0.4, 600.0, 200.0)
	_streams["boss_death"] = _gen_boss_death(0.8)
	_streams["level_up"] = _gen_level_up(0.5)
	_streams["skill_pickup"] = _gen_ascending(0.2, 500.0, 1000.0)
	_streams["xp_pickup"] = _gen_blip(0.04, 1200.0, 1400.0)
	_streams["wave_announce"] = _gen_wave_announce(0.6)
	_streams["victory"] = _gen_victory(1.0)
	_streams["ui_click"] = _gen_blip(0.04, 1000.0, 800.0)
	_streams["ui_hover"] = _gen_blip(0.03, 1100.0, 1100.0)
	_streams["coin_earned"] = _gen_coin(0.15)
	_streams["dodge"] = _gen_noise_hit(0.08, 1000.0)


## Generate a simple frequency sweep blip.
func _gen_blip(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	for i in length:
		var t: float = float(i) / float(length)
		var freq: float = lerpf(freq_start, freq_end, t)
		var envelope: float = 1.0 - t  # Linear decay
		var val: float = sin(t * freq * TAU * duration) * envelope * 0.5
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Generate noise burst for hit/impact sounds.
func _gen_noise_hit(duration: float, filter_freq: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var prev: float = 0.0
	var rc: float = 1.0 / (TAU * filter_freq)
	var dt: float = 1.0 / float(SAMPLE_RATE)
	var alpha: float = dt / (rc + dt)
	for i in length:
		var t: float = float(i) / float(length)
		var envelope: float = (1.0 - t) * (1.0 - t)
		var noise: float = randf_range(-1.0, 1.0)
		prev = prev + alpha * (noise - prev)
		var val: float = prev * envelope * 0.6
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Generate explosion sound (low noise + sine).
func _gen_explosion(duration: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var prev: float = 0.0
	var rc: float = 1.0 / (TAU * 150.0)
	var dt: float = 1.0 / float(SAMPLE_RATE)
	var alpha: float = dt / (rc + dt)
	for i in length:
		var t: float = float(i) / float(length)
		var envelope: float = (1.0 - t) * (1.0 - t)
		var noise: float = randf_range(-1.0, 1.0)
		prev = prev + alpha * (noise - prev)
		var sine: float = sin(t * 80.0 * TAU * duration) * 0.3
		var val: float = (prev * 0.7 + sine) * envelope * 0.7
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Ascending sweep.
func _gen_ascending(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var phase: float = 0.0
	for i in length:
		var t: float = float(i) / float(length)
		var freq: float = lerpf(freq_start, freq_end, t)
		phase += freq / float(SAMPLE_RATE)
		var envelope: float = minf(t * 5.0, 1.0) * (1.0 - t * 0.5)
		var val: float = sin(phase * TAU) * envelope * 0.4
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Descending sweep.
func _gen_descending(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var phase: float = 0.0
	for i in length:
		var t: float = float(i) / float(length)
		var freq: float = lerpf(freq_start, freq_end, t)
		phase += freq / float(SAMPLE_RATE)
		var envelope: float = (1.0 - t)
		var val: float = sin(phase * TAU) * envelope * 0.4
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Boss death: dramatic descending explosion.
func _gen_boss_death(duration: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var prev: float = 0.0
	var rc: float = 1.0 / (TAU * 120.0)
	var dt: float = 1.0 / float(SAMPLE_RATE)
	var alpha: float = dt / (rc + dt)
	var phase: float = 0.0
	for i in length:
		var t: float = float(i) / float(length)
		var freq: float = lerpf(300.0, 40.0, t)
		phase += freq / float(SAMPLE_RATE)
		var noise: float = randf_range(-1.0, 1.0)
		prev = prev + alpha * (noise - prev)
		var sine: float = sin(phase * TAU)
		var envelope: float = (1.0 - t * 0.8)
		var val: float = (prev * 0.5 + sine * 0.5) * envelope * 0.7
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Level up jingle: ascending arpeggio.
func _gen_level_up(duration: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var notes: Array[float] = [523.0, 659.0, 784.0, 1047.0]  # C5, E5, G5, C6
	var note_len: int = length / notes.size()
	var phase: float = 0.0
	for i in length:
		var note_idx: int = mini(i / note_len, notes.size() - 1)
		var local_t: float = float(i % note_len) / float(note_len)
		var freq: float = notes[note_idx]
		phase += freq / float(SAMPLE_RATE)
		var envelope: float = (1.0 - local_t * 0.7) * 0.4
		var val: float = sin(phase * TAU) * envelope
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Wave announcement fanfare.
func _gen_wave_announce(duration: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var phase: float = 0.0
	for i in length:
		var t: float = float(i) / float(length)
		var freq: float = 440.0
		if t < 0.3:
			freq = 440.0
		elif t < 0.6:
			freq = 554.0
		else:
			freq = 659.0
		phase += freq / float(SAMPLE_RATE)
		var envelope: float = (1.0 - t) * minf(t * 10.0, 1.0) * 0.4
		var val: float = sin(phase * TAU) * envelope
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Victory fanfare: major chord arpeggio.
func _gen_victory(duration: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var notes: Array[float] = [523.0, 659.0, 784.0, 1047.0, 1319.0, 1568.0]
	var note_len: int = length / notes.size()
	var phase: float = 0.0
	for i in length:
		var note_idx: int = mini(i / note_len, notes.size() - 1)
		var local_t: float = float(i % note_len) / float(note_len)
		var freq: float = notes[note_idx]
		phase += freq / float(SAMPLE_RATE)
		var global_t: float = float(i) / float(length)
		var envelope: float = (1.0 - local_t * 0.5) * (1.0 - global_t * 0.3) * 0.4
		var val: float = sin(phase * TAU) * envelope
		_write_sample(samples, i, val)
	return _make_wav(samples)


## Coin pickup: short bright double-blip.
func _gen_coin(duration: float) -> AudioStreamWAV:
	var samples := _alloc_samples(duration)
	var length: int = samples.size() / 2
	var phase: float = 0.0
	for i in length:
		var t: float = float(i) / float(length)
		var freq: float = 1200.0 if t < 0.5 else 1500.0
		phase += freq / float(SAMPLE_RATE)
		var local_t: float = fmod(t * 2.0, 1.0)
		var envelope: float = (1.0 - local_t) * 0.4
		var val: float = sin(phase * TAU) * envelope
		_write_sample(samples, i, val)
	return _make_wav(samples)


# --- Utility ---

func _alloc_samples(duration: float) -> PackedByteArray:
	var count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)  # 16-bit = 2 bytes per sample
	return bytes


func _write_sample(buffer: PackedByteArray, index: int, value: float) -> void:
	var clamped: float = clampf(value, -1.0, 1.0)
	var int_val: int = int(clamped * 32767.0)
	buffer[index * 2] = int_val & 0xFF
	buffer[index * 2 + 1] = (int_val >> 8) & 0xFF


func _make_wav(samples: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = samples
	return wav
