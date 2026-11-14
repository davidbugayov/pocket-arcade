extends Node

# Pocket Arcade: Squad Rush - Sound Synthesizer & Audio Manager
# Zero external asset dependencies: synthesizes procedural audio streams.

var players: Array[AudioStreamPlayer] = []
var player_index: int = 0
const POOL_SIZE = 12

var streams: Dictionary = {}

func _ready() -> void:
	# Create pool of players
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		players.append(p)
	
	_generate_all_sounds()

func _generate_all_sounds() -> void:
	streams["shoot_rifle"] = _synth_shoot(440.0, 110.0, 0.08, 0.6)
	streams["shoot_shotgun"] = _synth_shotgun(220.0, 60.0, 0.14, 0.8)
	streams["shoot_minigun"] = _synth_shoot(660.0, 220.0, 0.05, 0.5)
	streams["hit"] = _synth_noise(0.04, 0.4, true)
	streams["explosion"] = _synth_explosion(0.35, 0.9)
	streams["gate_positive"] = _synth_gate_positive()
	streams["gate_negative"] = _synth_gate_negative()
	streams["coin"] = _synth_coin()
	streams["victory"] = _synth_victory()
	streams["defeat"] = _synth_defeat()
	streams["click"] = _synth_click()

func play(sound_name: String, pitch_rnd: float = 0.05) -> void:
	if not GameManager.sound_enabled:
		return
	if not streams.has(sound_name):
		return
	if players.is_empty():
		return
	
	var p = players[player_index]
	player_index = (player_index + 1) % POOL_SIZE
	p.stream = streams[sound_name]
	p.pitch_scale = 1.0 + randf_range(-pitch_rnd, pitch_rnd)
	p.play()

# Synthesis helpers (8-bit unsigned PCM, 22050 Hz)
func _synth_shoot(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(start_freq, end_freq, t)
		phase += 2.0 * PI * freq / float(rate)
		var env = (1.0 - t) * (1.0 - t)
		var sample = sin(phase) * env * volume
		# Mix in subtle noise at start
		if t < 0.2:
			sample = lerpf(sample, (randf() * 2.0 - 1.0) * env * volume, 0.4)
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_shotgun(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(start_freq, end_freq, t * t)
		phase += 2.0 * PI * freq / float(rate)
		var env = 1.0 - t
		var noise = randf() * 2.0 - 1.0
		var sample = (sin(phase) * 0.4 + noise * 0.6) * env * volume
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_explosion(duration: float, volume: float) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var low_phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var env = pow(1.0 - t, 1.5)
		low_phase += 2.0 * PI * lerpf(80.0, 30.0, t) / float(rate)
		var rumble = sin(low_phase) * 0.5
		var noise = randf() * 2.0 - 1.0
		var sample = (rumble + noise * 0.7) * env * volume
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_noise(duration: float, volume: float, high_pass: bool = false) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var last = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var raw = randf() * 2.0 - 1.0
		var val = raw
		if high_pass:
			val = raw - last * 0.7
			last = raw
		var sample = val * (1.0 - t) * volume
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_gate_positive() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.28
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var freqs = [523.25, 659.25, 783.99, 1046.5] # C5, E5, G5, C6
	var segment = total_samples / freqs.size()
	
	var phase = 0.0
	for i in range(total_samples):
		var seg_idx = clampi(i / segment, 0, freqs.size() - 1)
		var freq = freqs[seg_idx]
		phase += 2.0 * PI * freq / float(rate)
		var t = float(i) / float(total_samples)
		var env = 1.0 - (t * 0.5)
		var sample = sin(phase) * env * 0.6
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_gate_negative() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.25
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(220.0, 75.0, t)
		phase += 2.0 * PI * freq / float(rate)
		var env = 1.0 - t
		var sample = (sin(phase) + 0.3 * sin(phase * 2.0)) * env * 0.7
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_coin() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.16
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	var half = total_samples / 2
	for i in range(total_samples):
		var freq = 987.77 if i < half else 1318.51 # B5, then E6
		phase += 2.0 * PI * freq / float(rate)
		var t_local = float(i % half) / float(half)
		var env = 1.0 - t_local
		var sample = sin(phase) * env * 0.55
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_victory() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.65
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
	var seg = total_samples / notes.size()
	var phase = 0.0
	for i in range(total_samples):
		var note_idx = clampi(i / seg, 0, notes.size() - 1)
		phase += 2.0 * PI * notes[note_idx] / float(rate)
		var t = float(i) / float(total_samples)
		var env = 1.0 - (t * 0.3)
		var sample = sin(phase) * env * 0.65
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_defeat() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.55
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerpf(350.0, 90.0, t * t)
		phase += 2.0 * PI * freq / float(rate)
		var env = 1.0 - t
		var sample = (sin(phase) + 0.2 * (randf() * 2.0 - 1.0)) * env * 0.7
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _synth_click() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.03
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		phase += 2.0 * PI * 800.0 / float(rate)
		var env = (1.0 - t) * (1.0 - t)
		var sample = sin(phase) * env * 0.4
		var byte_val = clampi(int((sample * 0.5 + 0.5) * 255.0), 0, 255)
		bytes[i] = byte_val
	
	return _make_wav(bytes, rate)

func _make_wav(bytes: PackedByteArray, rate: int) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

