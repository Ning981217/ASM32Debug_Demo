include windows.inc
include kernel32.inc
include user32.inc
include msvcrt.inc
include Disasm.inc
include DebugData.Inc

includelib kernel32.lib
includelib user32.lib
includelib msvcrt.lib
includelib Disasm.lib
includelib DebugData.lib

SETBP_TEMP      equ 1       ; 临时断点
SETBP_LONG      equ 2       ; 永久断点

; 打开 .exe 文件
OpenDebugFile proto :ptr CHAR
; 循环等待调试事件
RunDebugLoop proto
; 跳过空白字符
SkipWhiteChar proto :ptr CHAR
; 输入指令并解析
InputCommand proto
; 处理调试事件
OnExceptionDebugEvent proto
; 处理CC异常
OnBreakPoint proto
; 处理单步异常
OnSingleStep proto
; 处理访问异常
OnAccessViolation proto

; 处理 U 命令事件
OnCommand_U proto :DWORD, :DWORD
; 查看寄存器
OnCommand_R_ShowRegister proto
; 修改寄存器
OnCommand_R_SetRegister proto :ptr CHAR
; 显示内存
OnCommand_DB_ShowMem proto :DWORD, :DWORD
; 修改内存
OnCommand_E_SetMem proto :DWORD, :ptr CHAR
; 单步步过
OnCommand_P proto
; 单步步入
OnCommand_T proto
; 处理BP断点
OnCommand_BP proto :DWORD
; 处理 G 命令
OnCommand_G proto
; 处理 GU 命令
OnCommand_GU proto
; 硬件断点
OnCommand_BH proto :DWORD, :DWORD, :DWORD
; 内存dumpPE到文件
OnCommand_DUMP_PE proto
; 查看模块列表
OnCommand_ML proto
; 脚本
OnCommand_SC proto
; 指令记录
OnCommand_GJ proto :DWORD

; 处理输入的十六进制值
SkipMemWhitrChar proto :ptr CHAR
; 显示信息
ShowAsmInfo proto

; 获取API名称
GetASMApiName proto :DWORD, :ptr CHAR
; 设置单步
SetTFAndDecEip proto :BOOL, :DWORD
; 设置BP断点
SetBP proto :DWORD, :DWORD
; 恢复指令
ResumeBtCode proto :DWORD, :DWORD
; 还原机器码
ResumeShowCode proto :DWORD, :ptr BYTE
; 处理输入或读取的指令 
TransCommand proto :ptr CHAR
; 获取脚本命令
GetScriptCmd proto :ptr CHAR

; RVA转FA
TransRvaToFa proto :HANDLE, :DWORD, :ptr DWORD, :ptr DWORD
; VA转RVA
TransVaToRva proto :HANDLE, :DWORD, :ptr DWORD
; 小尾转大尾
TransLittleToBig proto :DWORD

; 退出并释放动态数组
Exit_Process proto
; 程序入口
main proto