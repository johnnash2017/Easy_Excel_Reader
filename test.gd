extends Node2D

# 中文注释：
#1 每列的第一行是列名，每个表若想在游戏中调
# 用就必须有“ID”列，这个唯一标识的名字可以在代码里改
#2 每列的第二行是列的类型，目前仅支持Int、float、String、Bool几
# 种基础类型，在代码里可以拓展更多类型或对特定类型进行多样处理
#3 无ID的行会被忽略，即便该行后续的列中配置了数据
#4 导出配置列默认为True，若为False则该行数据不会
# 被使用，导出配置列用不上可以不配
#5 查询表格时只需要给出ID和列名即可获得数据，当一个
# 表内多行拥有相同ID时该表将被视为多级表，查询该表需要额外输入一个等级参数

# English Comments:
#1 The first row of each column is the column name, each table must have an "ID" column if it wants to be used in the game.
# This unique identifier can be changed in the code.
#2 The second row of each column is the type of the column, currently only Int, float, String, Bool are supported.
# More types can be extended or specific types can be handled diversely in the code.
#3 Rows without an ID will be ignored, even if data is configured in subsequent columns.
#4 Export configuration columns default to True, if False then the row data will not be used.
# Export configuration columns that are unused can be omitted.
#5 When querying a table, you only need to provide the ID and column name to get the data.
# If multiple rows in a table have the same ID, the table will be considered a multi-level table,
# and querying this table requires an additional level parameter.

func  _ready() -> void:
	#技能表内拥有相同ID，是个多级表，需要额外输入一个等级参数
	#多级表输入额外的参数是用来确定该数据等级的，不同ID的等级数量可以不同
	print(Table.技能.get_data("火球术","升级说明",2))
	print(Table.技能.get_data("火球术","升级说明",3))
	print(Table.技能.get_data("火球术","升级说明",4))
	
	#等级表内没有多个ID，是个非多级表，不需要输入等级参数，输入了也没用
	#并且其ID是Int类型，ID可以是字符类型也可以是数值类型
	print(Table.等级.get_data(1,"经验需求"))
	print(Table.等级.get_data(2,"经验需求"))
	print(Table.等级.get_data(3,"经验需求"))
	print(Table.等级.get_data(4,"经验需求"))
	
	#任何列类型都在ableInstance的convert_data_type方法处理
	#布尔值类型在TableInstance的BOOLEAN_IDENTIFIERS属性和config_to_boolean方法中定义
	print(Table.角色.get_data("战士","远程"))
	print(Table.角色.get_data("射手","远程"))
	
	print(Table.语言.get_data("文本1","文本_英文"))
	print(Table.语言.get_data("文本2","文本_英文"))
	
	print(Table.语言.data)
