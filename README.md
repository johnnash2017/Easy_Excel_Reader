这是一个超级轻量的.xlsx读取并应用其数据的工具。 |  This is a super lightweight tool for reading.xlsx files and applying their data.

创建一个godot4.4新工程并覆盖至根目录，然后关闭编辑器再重新打开编辑器以保证错误的UID引用被修正即可运行test.tscn场景进行测试。 |  Create a new Godot 4.4 project and overwrite it to the root directory, then close and reopen the editor to ensure that the incorrect UID references are corrected, and you can run the test.tscn scene for testing.


#这部分负责从excel转换为字典 | This part is responsible for converting from Excel to dictionary 
godot_excel_reader：https://github.com/johnnash2017/godot_excel_reader


#这部分负责从字典转换为表格实例，提供查询 | This part is responsible for converting from dictionary to table instance, providing query functionality

核心代码 | Core code
```gdscript
class_name TableInstance
const UNIQUE_IDENTIFIER:String = "ID"  # 常量：唯一标识符字段名 | Constant: Unique identifier field name
const USAGE_IDENTIFIER:String = "导出配置"  # 常量：使用配置字段名 | Constant: Usage configuration field name
const BOOLEAN_IDENTIFIERS:Array[String] = ["是", "yes", "true", "1"]  # 常量：布尔值标识符数组 | Constant: Boolean identifiers array

class DataTable:
	var data: Dictionary  # 数据存储字典 | Data storage dictionary
	var multi_level_table: bool = false  # 是否为多级表标志 | Multi-level table flag
	
	# 构造函数，初始化数据和多级表标志 | Constructor, initialize data and multi-level table flag
	func _init(_Dictionary, _multi_level_table: bool):
		self.data = _Dictionary
		self.multi_level_table = _multi_level_table
	
	# 获取数据的方法，仅用于多级表 | Method to get data, only used for multi-level tables
	func get_data(_id, _column:String, _level:int=1) -> Variant:
		if multi_level_table == false:
			return data[_id][_column]
		else:
			return data[_id][_level][_column]

# 静态方法，生成可查询的数据表对象 | Static method, generate queryable data table object
static func generate_queryable_data(workbook, sheet_name:String)-> DataTable:
	return json_to_queryable_data(workbook.get_sheet_by_name(sheet_name)["data"], sheet_name)
	
# 静态方法，将JSON数据转换为可查询的数据表对象 | Static method, convert JSON data to queryable data table object
static func json_to_queryable_data(json: Dictionary, sheet_name:String) -> DataTable:
	var dictionary: Dictionary = {}  # 返回值字典 | Return value dictionary

	var row_list:Array=json_to_array(json)  # 将JSON转换为数组并丢弃所有键，保留所有值 | Convert JSON to array and discard all keys, retain all values
	row_list=filter_empty_id_rows_and_columns(row_list)  # 过滤掉空ID行和列 | Filter out empty ID rows and columns
	
	if row_list.size() < 2:  # 至少需要两行（标题行和数据类型行） | At least need two rows (header and data types)
		return DataTable.new(dictionary, false)
	
	var header_row:Array = row_list[0]  # 第一行是标题行 | First row is header type
	var data_type_row:Array = row_list[1]  # 第二行是数据类型行 | Second row is data type

	var id_exists = header_row.find(UNIQUE_IDENTIFIER)
	if id_exists == -1:  # 如果ID列不存在，则不需要返回任何内容 | If ID column does not exist, no need to return anything
		print(sheet_name, ": File does not contain 'ID' field.")
		return DataTable.new(dictionary, false)

	var export_config_exists = header_row.find(USAGE_IDENTIFIER)  # 查找“ExportConfig”列是否存在，如果不存在则返回-1 | Find if "ExportConfig" column exists, returns -1 if not
	var id_count: Dictionary = {}  # 临时字典用于检测重复ID | Temporary dictionary to detect duplicate IDs
	# 第一次循环，检测重复ID | First loop, detect duplicate IDs
	for _row in range(2, row_list.size()):  # 从第三行开始读取 | Start reading from third row
		var current_row = row_list[_row]
		var row_data:Dictionary = {}  # 将数据标准化为字典 | Normalize data into a dictionary
		for _col in range(header_row.size()):
			var value = current_row[_col]
			var data_type = data_type_row[_col]
			row_data[header_row[_col]] = convert_data_type(value, data_type, sheet_name, _col)
		var id = row_data.get(UNIQUE_IDENTIFIER,"")
		# 检查ExportConfig列 | Check ExportConfig column
		if export_config_exists != -1:
			if row_data.get(USAGE_IDENTIFIER, "false") != true:  # 默认值为"false" | Default value is "false"
				continue  # 如果ExportConfig为假，则跳过当前项 | Skip current item if ExportConfig is false
		# 记录ID计数 | Record ID count
		if id_count.has(id):
			id_count[id] += 1
		else:
			id_count[id] = 1
	# 检测是否有重复ID，如果有则表示是多级表 | Check for duplicate IDs, presence means it's a multi-level table
	var has_duplicate_ids = false
	for count in id_count.values():
		if count > 1:
			has_duplicate_ids = true
			break
	# 第二次循环，读取数据并将数据写入字典，基于ID重复情况 | Second loop, read data and write to dictionary based on ID duplication situation
	for _row in range(2, row_list.size()):  # 从第三行开始读取 | Start reading from third row
		var current_row = row_list[_row]
		if current_row.size() != header_row.size():
			continue
		
		var row_data:Dictionary = {}
		for _col in range(header_row.size()):
			var value = current_row[_col]
			var data_type = data_type_row[_col]
			row_data[header_row[_col]] = convert_data_type(value, data_type, sheet_name, _col)
		
		var id = row_data.get(UNIQUE_IDENTIFIER, "")
		# 检查ExportConfig列 | Check ExportConfig column
		if export_config_exists != -1:
			var export_config_value = row_data.get(USAGE_IDENTIFIER, "false")  # 默认值为"false" | Default value is "false"
			if export_config_value != true:
				continue  # 如果ExportConfig为假，则跳过当前项 | Skip current item if ExportConfig is false
		# 根据ID重复情况将数据写入字典 | Write to dictionary based on ID duplication situation
		if has_duplicate_ids:
			if not dictionary.has(id): 
				dictionary[id]={1: row_data}
			else:
				var number = dictionary[id].size() + 1  # 如果此字典已存在，则递增序列号 | If this dictionary already exists, increment sequence
				dictionary[id][number] = row_data  # 添加新的编号 | Add new number
		else:
			dictionary[id] = row_data  # 新ID，直接添加 | New ID, add directly
	return DataTable.new(dictionary, has_duplicate_ids)

# 静态方法，将字典转换为数组 | Static method, convert dictionary to array
static func json_to_array(dictionary: Dictionary) -> Array:
	var array: Array = []
	var max_width:int = 0 
	for row in dictionary.values():  # 找到该表的最大列宽 | Find the maximum column width of this table
		for unit in row.keys():
			if unit>max_width:
				max_width=unit
	# 遍历字典的所有键值对 | Traverse all key-value pairs in the dictionary
	for key in dictionary.keys():
		var current_row: Array = []
		# 如果当前行宽度小于最大宽度，则用空字符填充 | If the current row width is less than the maximum width, fill with empty characters
		while current_row.size() < max_width:
			current_row.append("")  # 用空字符填充 | Fill with empty character
		# 将当前行添加到数组中 | Add the current row to the array
		array.append(current_row)
	
	var array_row=0
	for _row in dictionary.keys():
		var array_col=0
		for _col in dictionary[_row].keys():
			var value = dictionary[_row][_col]
			if value is String:
				array[_row-1][_col-1]=value
			else :
				array[_row-1][_col-1]=str(value)  # 为了简化，将数据转换为字符串 | For simplicity, convert data to string
			pass
			array_row=array_col+1
		array_row=array_row+1
	return array

# 静态方法，过滤空ID行和列 | Static method, filter empty ID rows and columns
static func filter_empty_id_rows_and_columns(table: Array) -> Array:
	# 先处理空列 | Handle empty columns first
	if table.size() >= 2:
		var columns_to_remove = []
		# 遍历所有列 | Traverse all columns
		for col_index in range(table[0].size()):
			var first_row_content = table[0][col_index]
			var second_row_content = table[1][col_index]
			
			# 检查第一行和第二行是否都为空 | Check if both first row and second row are empty
			if first_row_content == "" or second_row_content == "":
				columns_to_remove.append(col_index)
		
		# 构建处理后的新表格（移除空列） | Construct the processed new table (remove empty columns)
		var table_after_column_processing = []
		for row in table:
			var new_row = []
			for j in range(row.size()):
				if not columns_to_remove.has(j):
					new_row.append(row[j])
			table_after_column_processing.append(new_row)
		table = table_after_column_processing
	
	# 然后处理空ID行 | Then handle empty ID rows
	var filtered_table: Array = []
	# 找到ID列的位置 | Find the position of the ID column
	var id_index: int = -1
	for i in range(table[0].size()):
		if table[0][i] == UNIQUE_IDENTIFIER:
			id_index = i
			break
	
	if id_index == -1:
		return table
	
	# 保留标题行和数据类型行 | Retain header and data type row
	filtered_table.append(table[0])
	filtered_table.append(table[1])
	
	# 过滤ID为空的行 | Filter rows with empty ID
	for i in range(2, table.size()):
		if table[i][id_index] != "":
			filtered_table.append(table[i])
	
	return filtered_table

# 静态方法，根据数据类型转换值 | Static method, convert value according to data type
static func convert_data_type(value: String, data_type: String, sheet_name:String, col:int) -> Variant:
	match data_type.to_lower():
		"int":
			return value.to_int()
		"float":
			return value.to_float()
		"string":
			return value
		"bool":
			return config_to_boolean(value.to_lower())
		"variant":
			return auto_detect_type(value)
		_:
			print(sheet_name,"_",col,"_未知数据类型: ", data_type)
			return value  # 返回原始值 | Return original value

# 静态方法，将配置转换为布尔值 | Static method, convert configuration to boolean
static func config_to_boolean(value: String) -> bool:
	for identifier in BOOLEAN_IDENTIFIERS:
		if value == identifier:
			return true
	return false
	
# 静态方法，自动检测数据类型 | Static method, auto-detect data type
static func auto_detect_type(value: String) -> Variant:
	var integer_value: int = value.to_int()
	if value == str(integer_value):
		return integer_value
	var float_value: float = value.to_float()
	if value == str(float_value):
		return float_value
	return value  # 默认为字符串 | Default to string
```
