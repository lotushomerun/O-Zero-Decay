extends MarginContainer
class_name ScreenText

static var upper_row: HBoxContainer
static var middle_row: HBoxContainer
static var bottom_row: HBoxContainer

static func register_upper_row(row: HBoxContainer) -> void: upper_row = row
static func register_middle_row(row: HBoxContainer) -> void: middle_row = row
static func register_bottom_row(row: HBoxContainer) -> void: bottom_row = row

func _ready() -> void:
	register_upper_row($Rows/Upper)
	register_middle_row($Rows/Middle)
	register_bottom_row($Rows/Bottom)
	
static func clear_row(row: HBoxContainer) -> void: for child: Control in row.get_children(): child.queue_free()

static func show_upper_text(elements: Array[Control] = [], h_alignment = BoxContainer.AlignmentMode.ALIGNMENT_CENTER, v_alignment: VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER) -> void:
	show_text(upper_row, elements, h_alignment, v_alignment)

static func show_middle_text(elements: Array[Control] = [], h_alignment = BoxContainer.AlignmentMode.ALIGNMENT_CENTER, v_alignment: VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER) -> void:
	show_text(middle_row, elements, h_alignment, v_alignment)

static func show_bottom_text(elements: Array[Control] = [], h_alignment = BoxContainer.AlignmentMode.ALIGNMENT_CENTER, v_alignment: VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER) -> void:
	show_text(bottom_row, elements, h_alignment, v_alignment)

static func show_text(row: HBoxContainer, elements: Array[Control] = [], h_alignment = BoxContainer.AlignmentMode.ALIGNMENT_CENTER, v_alignment: VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER) -> void:
	clear_row(row)
	row.alignment = h_alignment
	
	var dict: Dictionary = {
		VerticalAlignment.VERTICAL_ALIGNMENT_TOP : Control.SIZE_SHRINK_BEGIN,
		VerticalAlignment.VERTICAL_ALIGNMENT_CENTER : Control.SIZE_SHRINK_CENTER,
		VerticalAlignment.VERTICAL_ALIGNMENT_BOTTOM : Control.SIZE_SHRINK_END
	}
	
	for element: Control in elements:
		element.size_flags_vertical = dict[v_alignment]
		row.add_child(element)
