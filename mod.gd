extends RefCounted

const ENABLED_KEY: StringName = &"enabled"
const CHANCE_KEY: StringName = &"encounter_chance"
const SUICUNE: int = 245
const SUICUNE_LEVEL: int = 40
const SUICUNE_SLOT: int = 2

class RoamChance:
	var mod_id: StringName
	func _init(id: StringName) -> void:
		mod_id = id

	func roam_encounter_chance(_context: Dictionary) -> int:
		var host: Gen2ModHost = Gen2ModHost.instance()
		if not bool(host.option(mod_id, ENABLED_KEY)):
			return 100
		if not bool(host.progress().get(&"beasts_released", false)):
			return 100
		var percent: int = int(host.option(mod_id, CHANCE_KEY))
		return clampi(roundi(float(percent) * 256.0 / 100.0), 0, 256)

func register(host: Gen2ModHost, manifest: PokeModManifest) -> void:
	host.register_option(manifest.id, {
		"key": ENABLED_KEY,
		"label": "LEGENDARY BEASTS",
		"values": [false, true],
		"labels": ["OFF", "ON"],
		"default": false,
	})

	var values: Array[int] = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
	var labels: Array[String] = ["10", "20", "30", "40", "50", "60", "70", "80", "90", "100"]

	host.register_option(manifest.id, {
		"key": CHANCE_KEY,
		"label": "ENCOUNTER CHANCE",
		"values": values,
		"labels": labels,
		"default": 50,
	})

	host.register_roam_encounter_chance(manifest.id, RoamChance.new(manifest.id))

	host.progress_changed.connect(
		func(_progress: Dictionary) -> void:
			_try_crystal_suicune(host, manifest.id)
	)
	host.option_changed.connect(
		func(mod: StringName, key: StringName, _value: Variant) -> void:
			if mod == manifest.id and key == ENABLED_KEY:
				_try_crystal_suicune(host, manifest.id)
	)

	_try_crystal_suicune(host, manifest.id)

func _try_crystal_suicune(host: Gen2ModHost, id: StringName) -> void:
	if host.target_game() != &"crystal":
		return
	if not bool(host.option(id, ENABLED_KEY)):
		return

	var progress: Dictionary = host.progress()
	if not bool(progress.get(&"beasts_released", false)):
		return
	if not bool(progress.get(&"fought_suicune", false)):
		return

	var caught: Array = progress.get(&"caught_species", [])
	if SUICUNE in caught:
		return

	var roamers: Array = host.roamers()
	if roamers.size() < 3:
		return

	for roamer: Dictionary in roamers:
		if int(roamer.get("species", 0)) == SUICUNE:
			return

	if int((roamers[SUICUNE_SLOT] as Dictionary).get("species", 0)) != 0:
		return

	host.request_roamer(id, SUICUNE_SLOT, SUICUNE, SUICUNE_LEVEL)
