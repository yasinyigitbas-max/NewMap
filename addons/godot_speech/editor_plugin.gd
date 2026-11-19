@tool
extends EditorPlugin
var _exp: EditorExportPlugin

func _enter_tree() -> void:
	_exp = SpeechExport.new()
	add_export_plugin(_exp)

func _exit_tree() -> void:
	remove_export_plugin(_exp)

class SpeechExport extends EditorExportPlugin:
	const DIR := "res://addons/godot_speech/bin/"
	func _get_name() -> String: return "GodotSpeech"
	func _supports_platform(p: EditorExportPlatform) -> bool:
		return p is EditorExportPlatformAndroid
	# Paths are relative to res://addons/ (Godot v2 Android plugin convention).
	func _get_android_libraries(_p: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var f := "GodotSpeech-debug.aar" if debug else "GodotSpeech-release.aar"
		if not FileAccess.file_exists(DIR + f):
			push_error("GodotSpeech: missing " + DIR + f + " (run android/GodotSpeech/build_aar.sh)")
			return PackedStringArray()
		return PackedStringArray(["godot_speech/bin/" + f])
	func _get_android_dependencies(_p: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray() # plugin uses only android.* + godot-lib
