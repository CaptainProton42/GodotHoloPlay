tool
extends Node

const HoloPlayVolume = preload("HoloPlayVolume.gdns")

# Will be emitted once *all* recorings have finished processing.
signal finished

class MovieProcessor:
    var _frame_queue: Array = []
    var _active: bool = false
    var _savedir: String = ""
    var _thread: Thread = null

    signal finished

    func _init(savedir):
        self._savedir = savedir

    func start():
        self._active = true
        Thread.new().start(self, "_save_movie")

    func stop():
        self._active = false

    func queue_frame(frame: Image):
        self._frame_queue.push_back(frame)

    func _save_movie(_userdata):
        var framenum = 0
        while self._active:
            while self._frame_queue.size() > 0:
                var quilt = self._frame_queue.pop_front()
                quilt.flip_y()
                quilt.save_png("user://%s/%05d.png" % [self._savedir, framenum])
                framenum += 1
        emit_signal("finished")
        _thread.call_deferred("wait_to_finish")

# Setting this variable will start/stop the recording. (Also works in editor.)
export var recording: bool = false setget set_recording, get_recording
var _recording: bool = false

# Target FPS of the recording.
export var target_fps: int = 25

export var autorecording_enabled: bool = false
export var autorecording_start: float = 0.0
export var autorecording_duration: float = 10.0
export var autorecording_quit_when_done: bool = false

# Setting this variable saves the current quilt as an image.
# Call take_snapshot() from scripts.
export var take_snapshot: bool = false setget set_take_snapshot, get_take_snapshot

var _frametime: float = 0.0
var _total_frametime: float = 0.0
var _movie_processor: MovieProcessor = null
var _active_runners: Array = []

func set_recording(p_recording: bool) -> void:
    if (p_recording):
        _start_recording()
    else:
        _stop_recording()

func get_recording() -> bool:
    return _recording

func set_take_snapshot(p_value: bool) -> void:
    take_snapshot()

func get_take_snapshot() -> bool:
    return false

func _is_configured() -> bool:
    return get_parent().get_script() is NativeScript and get_parent().get_script().get_class_name() == HoloPlayVolume.get_class_name()

func _start_recording() -> void:
    if not _is_configured():
        return
    _recording = true
    var dt: Dictionary = OS.get_datetime()
    var savedir: String = "%04d-%02d-%02dT%02d%02d%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
    var dir = Directory.new()
    dir.open("user://")
    dir.make_dir(savedir)
    _frametime = 0.0
    _movie_processor = MovieProcessor.new(savedir)
    _active_runners.append(_movie_processor)
    _movie_processor.connect("finished", self, "_on_runner_finished", [_movie_processor])
    _movie_processor.start()

func _stop_recording() -> void:
    if _movie_processor:
        _movie_processor.stop()
    _recording = false

func _on_runner_finished(runner: MovieProcessor):
    _active_runners.erase(runner)
    if _active_runners.size() == 0:
        emit_signal("finished")
        if not Engine.is_editor_hint() and autorecording_enabled and autorecording_quit_when_done:
            get_tree().quit()

func _get_configuration_warning() -> String:
    if not _is_configured():
	    return "Parent node must be a HoloPlayVolume."
    return ""

func _ready() -> void:
    if not Engine.is_editor_hint() and autorecording_enabled:
        yield(get_tree().create_timer(autorecording_start), "timeout")
        set_recording(true)

func _process(delta: float) -> void:
    if _is_configured():
        if _recording:
            _frametime += delta
            _total_frametime += delta
            if not Engine.is_editor_hint() and autorecording_enabled and _total_frametime > autorecording_duration:
                _stop_recording()
            if (_frametime > 1.0/target_fps):
                _movie_processor.queue_frame(get_parent().get_quilt_tex().get_data())
                _frametime = fmod(_frametime, 1.0/target_fps)

func take_snapshot():
    if _is_configured():
        var dt: Dictionary = OS.get_datetime()
        var savepath: String = "user://%04d-%02d-%02dT%02d%02d%02d_snap.png" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
        var quilt = get_parent().get_quilt_tex().get_data()
        quilt.flip_y()
        quilt.save_png(savepath)