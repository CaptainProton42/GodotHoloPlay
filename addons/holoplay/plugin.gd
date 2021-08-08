tool
extends EditorPlugin

const HoloPlayVolumeGizmoPlugin = preload("HoloPlayVolumeGizmoPlugin.gd")

var gizmo_plugin = HoloPlayVolumeGizmoPlugin.new()

func get_editor_scale() -> float:
	# Hacky way to get the editor scale from GDSCript.
	# Pretty much a direct translation from editor_node.cpp.
	var editor_scale = 1.0

	var display_scale = get_editor_interface().get_editor_settings().get_setting("interface/editor/display_scale")
	
	match display_scale:
		0:
			if OS.get_name() == 'OSX':
				editor_scale = OS.get_screen_max_scale()
			else:
				if OS.get_screen_dpi() >= 192 && OS.get_screen_size().y >= 1400:
					editor_scale = 2.0;
				elif OS.get_screen_size().y <= 800:
					editor_scale = 0.75;
				else:
					editor_scale = 1.0
		1:
			editor_scale = 0.75
		2:
			editor_scale = 1.0
		3:
			editor_scale = 1.25
		4:
			editor_scale = 1.5
		5:
			editor_scale = 1.75
		6:
			editor_scale = 2.0
		_:
			editor_scale = get_editor_interface().get_editor_settings().get_setting("interface/editor/custom_display_scale")

	return editor_scale

func create_icon(resource):
	var editor_scale: float = get_editor_scale()
	var img: Image = resource.get_data() 
	img.resize(editor_scale * 16, editor_scale * 16)
	var icon = ImageTexture.new()
	icon.create_from_image(img)
	return icon

func _enter_tree() -> void:
	add_custom_type("HoloPlayVolume", "Spatial", preload("HoloPlayVolume.gdns"), create_icon(preload("icon_holoplayvolume.svg")))
	add_custom_type("HoloPlayRecorder", "Node", preload("HoloPlayRecorder.gd"), create_icon(preload("icon_holoplayrecorder.svg")))
	add_spatial_gizmo_plugin(gizmo_plugin)

	gizmo_plugin.undo_redo = get_undo_redo()

	# Add "Hide Main Window" property to project settings.
	#ProjectSettings.set_initial_value("holoplay/hide_main_window", false)

	#var property_info = {
	#	"name": "holoplay/hide_main_window",
	#	"type": TYPE_BOOL,
	#}

	#ProjectSettings.add_property_info(property_info)

func _exit_tree() -> void:
	remove_custom_type("HoloPlayVolume")
	remove_custom_type("HoloPlayRecorder")
	remove_spatial_gizmo_plugin(gizmo_plugin)