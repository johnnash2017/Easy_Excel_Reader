extends Node
#这个脚本需要设置为全局脚本 | This script needs to be set as a global script
const _表格路径:String= "res://test.xlsx"#excel
var _excel = ExcelReader.ExcelFile.open(_表格路径)
var _workbook = _excel.get_workbook()

var 语言: TableInstance.DataTable = TableInstance.generate_queryable_data(_workbook,"语言")
var 技能: TableInstance.DataTable = TableInstance.generate_queryable_data(_workbook,"技能")
var 角色: TableInstance.DataTable = TableInstance.generate_queryable_data(_workbook,"角色")
var 等级: TableInstance.DataTable = TableInstance.generate_queryable_data(_workbook,"等级")
