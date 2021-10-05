include windows.inc

; 初始化
; return addr   // 申请到的地址
NewVector proto     

; 释放动态数组
; IN  pVec      // 动态数组指针
DeleteVector proto :ptr DWORD

; 添加成员
; IN  pVec      // 动态数组指针
; IN  lpItem    // 成员，此项目中存储 malloc 申请到的地址
AddItem proto :ptr DWORD, :DWORD

; 获取成员
; IN  pVec      // 动态数组指针
; OUT lpItem    // 传出参数，接收获取的成员
; IN  dwIndex   // 下标
GetItem proto :ptr DWORD, :ptr DWORD, :DWORD

; 删除成员
; IN  pVec      // 动态数组指针
; IN  dwIndex   // 下标
DeleteItem proto :ptr DWORD, :DWORD

; 获取动态数组大小
; IN  pVec      // 动态数组指针
; return size   // 动态数组大小
GetVectorSize proto :ptr DWORD