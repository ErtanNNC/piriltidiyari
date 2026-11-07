extends Node
## Design tokens from the Pırıltı Diyarı design system (design/tokens.json).
## design/tokens.json is a copy of the design system's tokens and is the single
## source of truth for colors, type sizes, spacing, radii and strokes.

signal theme_changed(theme_id: String)

const TOKENS_PATH := "res://design/tokens.json"

var theme_id := "light"
var _raw: Dictionary = {}
var _colors: Dictionary = {}   # name -> {theme_id: Color}
var _lengths: Dictionary = {}  # name -> float (px)
var _type_styles: Dictionary = {}  # name -> {family, size, line_height, weight}

var _fonts: Dictionary = {}  # "family:weight" -> FontVariation


func _init() -> void:
	load_tokens(TOKENS_PATH)


func load_tokens(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Tokens: %s okunamadı" % path)
		return
	_raw = parsed
	_colors.clear()
	_lengths.clear()
	_type_styles.clear()
	var themes: Array = _raw.get("color", {}).get("themes", [])
	var first_theme: String = themes[0]["id"] if themes.size() > 0 else "light"
	for t: Dictionary in _raw.get("color", {}).get("tokens", []):
		var per_theme := {}
		var v: Variant = t["value"]
		if typeof(v) == TYPE_DICTIONARY:
			for k: String in v:
				per_theme[k] = parse_color(v[k])
		else:
			per_theme[first_theme] = parse_color(v)
		per_theme["_default"] = per_theme.get(first_theme, Color.MAGENTA)
		_colors[t["name"]] = per_theme
	for family: String in ["spacing", "radius", "stroke"]:
		for t: Dictionary in _raw.get(family, {}).get("tokens", []):
			_lengths[t["name"]] = parse_length(t["value"])
	for group: Dictionary in _raw.get("type", {}).get("groups", []):
		for s: Dictionary in group.get("styles", []):
			_type_styles[s["name"]] = {
				"family": group["family"],
				"size": int(parse_length(s["fontSize"])),
				"weight": int(s["fontWeight"]),
			}


## Color token for the current theme (falls back to the first theme).
## "name@light" / "name@dark" pins a theme: text drawn with a dark outline
## over the 3D scene uses "panel@light" so it stays light in the Gece theme.
func color(token_name: String) -> Color:
	var pinned := ""
	if token_name.contains("@"):
		pinned = token_name.get_slice("@", 1)
		token_name = token_name.get_slice("@", 0)
	var per_theme: Dictionary = _colors.get(token_name, {})
	if per_theme.is_empty():
		push_warning("Tokens: bilinmeyen renk '%s'" % token_name)
		return Color.MAGENTA
	return per_theme.get(pinned if pinned != "" else theme_id, per_theme["_default"])


func has_color(token_name: String) -> bool:
	return _colors.has(token_name.get_slice("@", 0))


## spacing / radius / stroke token in pixels.
func px(token_name: String) -> float:
	return _lengths.get(token_name, 0.0)


func type_size(style_name: String) -> int:
	return _type_styles.get(style_name, {}).get("size", 18)


## A font for a type style such as "text-body" or "text-hero".
func font_for(style_name: String) -> Font:
	var s: Dictionary = _type_styles.get(style_name, {"family": "body", "weight": 600})
	return font(s["family"], s["weight"])


## "display" = Baloo 2, "body" = Nunito; weight is the variable font's wght axis.
func font(family: String, weight: int) -> Font:
	var key := "%s:%d" % [family, weight]
	if _fonts.has(key):
		return _fonts[key]
	var path := "res://assets/fonts/Baloo2-Variable.ttf" if family == "display" else "res://assets/fonts/Nunito-Variable.ttf"
	var base: FontFile = load(path)
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): weight}
	if family == "display":
		# Baloo 2 lacks nothing Turkish needs, Nunito stays as a fallback anyway.
		fv.fallbacks = [load("res://assets/fonts/Nunito-Variable.ttf")]
	_fonts[key] = fv
	return fv


func set_theme(id: String) -> void:
	if id == theme_id:
		return
	theme_id = id
	theme_changed.emit(id)


static func parse_color(value: Variant) -> Color:
	var s := String(value).strip_edges()
	if s.begins_with("#"):
		return Color.html(s)
	if s.begins_with("rgb"):
		var inner := s.substr(s.find("(") + 1, s.rfind(")") - s.find("(") - 1)
		var parts := inner.split(",")
		var c := Color(float(parts[0]) / 255.0, float(parts[1]) / 255.0, float(parts[2]) / 255.0, 1.0)
		if parts.size() > 3:
			c.a = float(parts[3])
		return c
	push_warning("Tokens: renk çözülemedi '%s'" % s)
	return Color.MAGENTA


static func parse_length(value: Variant) -> float:
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return float(value)
	return float(String(value).replace("px", ""))
