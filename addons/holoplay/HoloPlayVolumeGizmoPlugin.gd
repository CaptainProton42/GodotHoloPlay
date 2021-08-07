extends EditorSpatialGizmoPlugin

const HoloPlayVolume = preload("HoloPlayVolume.gdns")

var undo_redo : UndoRedo

func _init() -> void:
    create_material("focus", Color("#ff7f00"))
    create_material("bounds", Color("#cc66cc"))
    create_handle_material("handles")
    create_icon_material("icon", preload("icon_gizmo_holoplayvolume.svg"))

func get_name() -> String:
    return "HoloPlayVolumeGizmo"

func has_gizmo(spatial) -> bool:
    if spatial.get_script() is NativeScript and spatial.get_script().get_class_name() == HoloPlayVolume.get_class_name():
        return true
    else:
        return false

func redraw(gizmo: EditorSpatialGizmo) -> void:
    gizmo.clear()

    var display: HoloPlayVolume = gizmo.get_spatial_node()

    var aspect: float = display.get_aspect()
    var size: float = display.size
    var near: float = size * display.near_clip
    var far: float = size * display.far_clip

    var half_extents: Vector2 = Vector2(0.5 * size, 0.5 * size / aspect)

    # Focus plane
    var lines: PoolVector3Array = PoolVector3Array()
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, 0.0))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, 0.0))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, 0.0))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, 0.0))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, 0.0))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, 0.0))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, 0.0))
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, 0.0))

    # Top indicator notch.
    lines.push_back(Vector3(-0.2*half_extents.x, half_extents.y, 0.0))
    lines.push_back(Vector3(0.0, 1.2*half_extents.y, 0.0))
    lines.push_back(Vector3(0.0, 1.2*half_extents.y, 0.0))
    lines.push_back(Vector3(0.2*half_extents.x, half_extents.y, 0.0))

    gizmo.add_lines(lines, get_material("focus", gizmo), false)

    # Near plane.
    lines = PoolVector3Array()
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, near))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, near))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, near))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, near))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, near))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, near))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, near))
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, near))

    # Far plane.
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, -far))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, -far))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, -far))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, -far))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, -far))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, -far))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, -far))
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, -far))

    # Cross on the far plane.
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, -far))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, -far))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, -far))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, -far))

    # Connecting edges.
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, near))
    lines.push_back(Vector3(-half_extents.x, -half_extents.y, -far))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, near))
    lines.push_back(Vector3( half_extents.x, -half_extents.y, -far))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, near))
    lines.push_back(Vector3( half_extents.x,  half_extents.y, -far))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, near))
    lines.push_back(Vector3(-half_extents.x,  half_extents.y, -far))

    gizmo.add_lines(lines, get_material("bounds", gizmo), false)

    # Handles
    var handles: PoolVector3Array = PoolVector3Array()
    handles.push_back(Vector3(0.0, 0.0, near))
    handles.push_back(Vector3(0.0, 0.0, -far))
    handles.push_back(Vector3(0.5*size, 0.5*size/aspect, 0.0));
    gizmo.add_handles(handles, get_material("handles"))

    gizmo.add_unscaled_billboard(get_material("icon"), 0.05)

func get_handle_name(gizmo: EditorSpatialGizmo, index: int) -> String:
    match index:
        0:
            return "near_clip"
        1:
            return "far_clip"
        2:
            return "size"
        _:
            return ""

func get_handle_value(gizmo: EditorSpatialGizmo, index: int) -> float:
    var display: HoloPlayVolume = gizmo.get_spatial_node()
    match index:
        0:
            return display.near_clip
        1:
            return display.far_clip
        2:
            return display.size
        _:
            return 0.0

func set_handle(gizmo: EditorSpatialGizmo, index: int, camera: Camera, point: Vector2) -> void:
    var display: HoloPlayVolume = gizmo.get_spatial_node()

    var gt: Transform = display.get_global_transform()
    var gi: Transform = gt.affine_inverse()

    var ray_from: Vector3 = camera.project_ray_origin(point)
    var ray_dir: Vector3 = camera.project_ray_normal(point)

    var sg: Array = [ gi.xform(ray_from), gi.xform(ray_from + ray_dir * 4096)]

    if (index < 2):
        var r: PoolVector3Array = Geometry.get_closest_points_between_segments(Vector3(0, 0, -4096), Vector3(0, 0, 4096), sg[0], sg[1])
        var d: float = r[0].z

        match index:
            0:
                display.near_clip = d / display.size
            1:
                display.far_clip = -d / display.size
    elif (index == 2):
        var r: PoolVector3Array = Geometry.get_closest_points_between_segments(Vector3(0, 0, 0), Vector3(4096, 4096 / display.get_aspect(), 0), sg[0], sg[1])
        var d: float = r[0].x

        display.size = 2.0 * d

func commit_handle(gizmo: EditorSpatialGizmo, index: int, restore, cancel: bool = false) -> void:
    var display: HoloPlayVolume = gizmo.get_spatial_node()

    match index:
        0:
            if cancel:
                display.near_plane = restore
                return
            undo_redo.create_action("Change HoloPlayVolume Near Clip")
            undo_redo.add_do_property(display, "near_clip", display.near_clip)
            undo_redo.add_undo_property(display, "near_clip", restore)
            undo_redo.commit_action()
        1:
            if cancel:
                display.far_plane = restore
                return
            undo_redo.create_action("Change HoloPlayVolume Far Clip")
            undo_redo.add_do_property(display, "far_clip", display.far_clip)
            undo_redo.add_undo_property(display, "far_clip", restore)
            undo_redo.commit_action()
        2:
            if cancel:
                display.size = restore
                return
            undo_redo.create_action("Change HoloPlayVolume Size")
            undo_redo.add_do_property(display, "size", display.size)
            undo_redo.add_undo_property(display, "size", restore)
            undo_redo.commit_action()