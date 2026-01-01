@tool
extends EditorPlugin

var inspector_plugin: Skeleton2DInspectorPlugin

func _enter_tree():
	print("2DRigPoser started...")
	inspector_plugin = Skeleton2DInspectorPlugin.new(self)
	add_inspector_plugin(inspector_plugin)

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
