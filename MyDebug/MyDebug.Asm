.386
.model flat, stdcall
option casemap : none

include MyDebug.inc

; 调试信息结构体
tagDbgData struct
    m_hProc                 HANDLE      ?           ; 进程句柄
    m_dwProcessID           DWORD       ?           ; PID
    m_de                    DEBUG_EVENT <?>         ; 异常信息结构体
    m_vector                LPDWORD     ?           ; 存储断点信息
    
    m_DR0                   BOOL        ?           ; 硬件断点寄存器使用状态
    m_DR1                   BOOL        ?
    m_DR2                   BOOL        ?
    m_DR3                   BOOL        ?
    
    m_dwLastDR7             DWORD       ?           ; 保存当前硬件断点的DR7
    
tagDbgData ends  

; 断点信息
tagDbgBP struct
    m_dwAddr                DWORD       ?           ; 断点地址
    m_dwType                DWORD       ?           ; 断点类型
    m_btCode                BYTE        ?           ; 断点原数据
    
tagDbgBP ends

.const
    ; \r 0dh    \n 0ah      \t 09h
    g_strAsmCmd_jmp     db          'jmp', 0
    g_strAsmCmd_call    db          'call', 0
    g_strAsmCmd_ret     db          'ret', 0
    g_strRegCmd_eax     db          'eax', 0
    g_strRegCmd_ebx     db          'ebx', 0
    g_strRegCmd_ecx     db          'ecx', 0
    g_strRegCmd_edx     db          'edx', 0
    g_strRegCmd_esi     db          'esi', 0
    g_strRegCmd_edi     db          'edi', 0
    g_strRegCmd_eip     db          'eip', 0
    g_strRegCmd_esp     db          'esp', 0
    g_strRegCmd_ebp     db          'ebp', 0
    
    g_strFmt_CMD_       db          '[CMD]: ', 0
    g_strFmt_U_API      db          '%08X', 09h,'%s', 09h, '%s', 0dh, 0ah,0
    g_strFmt_U          db          '%08X', 09h,'%s', 0dh, 0ah,0
    g_strFmt_R_show1    db          'eax=%p ebx=%p ecx=%p edx=%p esi=%p edi=%p ', 0dh, 0ah, 0
    g_strFmt_R_show2    db          'eip=%p esp=%p ebp=%p ', 0dh, 0ah, 0
    g_strFmt_R_show3    db          'cs =%p  ss=%p  ds=%p  es=%p  fs=%p  gs=%p ', 09h, ' efl=%p ', 0dh, 0ah, 0
    g_strFmt_DW_show    db          '%08X  %04X', 0dh, 0ah, 0
    g_strFmt_DD_show    db          '%08X  %08X', 0dh, 0ah, 0
    g_strFmt_DB_addr    db          '%08X  ', 0
    g_strFmt_DB_code    db          '%02X ', 0
    g_strFmt_RN         db          0dh, 0ah, 0
    g_strFmt_ShowInfo   db          '[INFO]: %08X %s ', 0dh, 0ah, 0
    g_strFmt_ERR        db          'ERROR!!!', 0
    g_strFmt_modualInfo db          '%s ', 09h, '%08X', 0dh, 0ah, 0
    
    g_strFmt_fileName   db          'dump_%s', 0
    g_strFmt_record     db          '%08X', 09h, '%s', 0dh, 0ah, 0
    
.data
    g_strTestExe        db          'test.exe', 0       ; 调试程序
    ; g_strTestExe        db          'Tes1t.exe', 0 
    g_strScriptName     db          'DebugScript.spt', 0    ; 脚本
    g_strRecordASMFile  db          'DebugRecode.txt', 0    ; 指令记录

    g_DbgData           tagDbgData  <0>             ; 保存调试信息
    g_bIsSystemBp       BOOL        TRUE            ; 系统断点
    g_bIsSingStepCmd    BOOL        FALSE           ; 单步命令标记
    g_bBhSingStep       BOOL        FALSE           ; 硬件断点标记
    g_bIsRecordFlag     BOOL        FALSE           ; 指令记录标记
    g_dwRecordAddr      DWORD       0               ; 指令记录结束地址
    g_hRecordFile       HANDLE      NULL            ; 指令记录文件句柄
    g_bIsRunScript      BOOL        FALSE           ; 脚本执行标志
    g_hScriptFIle       HANDLE      NULL            ; 读取脚本文件句柄

.code
; 打开 .exe 文件
OpenDebugFile proc strExePath :ptr CHAR
    local   @si :STARTUPINFO
    local   @pi :PROCESS_INFORMATION
    
    invoke  RtlZeroMemory, addr @si, sizeof @si
    invoke  RtlZeroMemory, addr @pi, sizeof @pi
    
    mov     @si.cb, dword ptr sizeof @si
    
    invoke  CreateProcess, NULL, strExePath, NULL, NULL, FALSE, DEBUG_ONLY_THIS_PROCESS, NULL, NULL, addr @si, addr @pi 
    .if     eax == NULL
        mov     eax, FALSE
        ret
    .endif
    
    mov     eax, @pi.hProcess
    mov     g_DbgData.m_hProc, eax
    mov     eax, @pi.dwProcessId
    mov     g_DbgData.m_dwProcessID, eax
    invoke  CloseHandle, @pi.hThread
    
    mov     eax, TRUE
    ret
OpenDebugFile endp

; 循环等待调试事件
RunDebugLoop proc
    local   @dwResult   :DWORD
    mov     @dwResult, DBG_EXCEPTION_NOT_HANDLED
    
    .while  TRUE
        invoke  WaitForDebugEvent, offset g_DbgData.m_de, INFINITE
        .if     eax
            ; case EXCEPTION_DEBUG_EVENT:
            .if     g_DbgData.m_de.dwDebugEventCode == EXCEPTION_DEBUG_EVENT
                invoke  OnExceptionDebugEvent
                mov     @dwResult, eax
                
            ; case CREATE_THREAD_DEBUG_EVENT:
            .elseif g_DbgData.m_de.dwDebugEventCode == CREATE_THREAD_DEBUG_EVENT
            
            
            ; case CREATE_PROCESS_DEBUG_EVENT:
            .elseif g_DbgData.m_de.dwDebugEventCode == CREATE_PROCESS_DEBUG_EVENT
            
            
            ; case EXIT_THREAD_DEBUG_EVENT:
            .elseif g_DbgData.m_de.dwDebugEventCode == EXIT_THREAD_DEBUG_EVENT
            
            
            ; case EXIT_PROCESS_DEBUG_EVENT:
            .elseif g_DbgData.m_de.dwDebugEventCode == EXIT_PROCESS_DEBUG_EVENT
            
            
            ; case LOAD_DLL_DEBUG_EVENT:
            .elseif g_DbgData.m_de.dwDebugEventCode == LOAD_DLL_DEBUG_EVENT
                
            ; case UNLOAD_DLL_DEBUG_EVENT:
            .elseif g_DbgData.m_de.dwDebugEventCode == UNLOAD_DLL_DEBUG_EVENT
            
            
            ; case OUTPUT_DEBUG_STRING_EVENT:
            .elseif g_DbgData.m_de.dwDebugEventCode == OUTPUT_DEBUG_STRING_EVENT
            
            .endif
            invoke  ContinueDebugEvent, g_DbgData.m_de.dwProcessId, g_DbgData.m_de.dwThreadId, @dwResult
        .endif
    .endw
    ret
RunDebugLoop endp

; 处理调试事件
OnExceptionDebugEvent proc
    local   @dwResult           :DWORD
    mov     @dwResult, DBG_CONTINUE
    
    ; 系统断点
    .if     g_bIsSystemBp == TRUE
        ; invoke  ShowAsmInfo
        invoke  InputCommand
        mov     g_bIsSystemBp, FALSE
        mov     eax, @dwResult
        ret
    .endif
    
    ; case EXCEPTION_BREAKPOINT:
    .if     g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionCode == EXCEPTION_BREAKPOINT
        ; CC 异常
        invoke  OnBreakPoint
        mov     @dwResult, eax
        
    ; case EXCEPTION_SINGLE_STEP:
    .elseif g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionCode == EXCEPTION_SINGLE_STEP
        ; 单步异常
        invoke  OnSingleStep
        mov     @dwResult, eax
        
    ; case EXCEPTION_ACCESS_VIOLATION:
    .elseif g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionCode == EXCEPTION_ACCESS_VIOLATION
        invoke  OnAccessViolation
        mov     @dwResult, eax
        
    .endif
    
    mov     eax, @dwResult
    ret
OnExceptionDebugEvent endp

; 处理访问异常
OnAccessViolation proc
    
    mov     eax, DBG_EXCEPTION_NOT_HANDLED
    ret
OnAccessViolation endp

; 处理CC异常
OnBreakPoint proc uses ecx ebx
    local   @dwVectorSize       :DWORD
    local   @dwIndex            :DWORD
    local   @pDbgBP             :ptr tagDbgBP
    local   @bIsInputCmd        :BOOL
    
    mov     @dwVectorSize, 0
    mov     @dwIndex, 0
    mov     @pDbgBP, NULL
    mov     @bIsInputCmd, FALSE
    
    invoke  GetVectorSize, g_DbgData.m_vector
    mov     @dwVectorSize, eax
    ; 判断命中哪个断点
    mov     ecx, @dwIndex
    .while  ecx < @dwVectorSize
        invoke  GetItem, g_DbgData.m_vector, addr @pDbgBP, @dwIndex
        mov     ebx, @pDbgBP
        assume  ebx :ptr tagDbgBP
        mov     eax, g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionAddress
        .if     [ebx].m_dwAddr == eax
            ; 命中断点, 判断类型
            .if     [ebx].m_dwType == SETBP_LONG
                ; 永久BP断点, 恢复指令
                movzx   ecx, [ebx].m_btCode
                invoke  ResumeBtCode, [ebx].m_dwAddr, ecx
                ; 设置单步
                invoke  SetTFAndDecEip, TRUE, 1
                mov     @bIsInputCmd, TRUE
                .break
            .elseif [ebx].m_dwType == SETBP_TEMP
                ; 临时断点
                movzx   ecx, [ebx].m_btCode
                invoke  ResumeBtCode, [ebx].m_dwAddr, ecx
                
                invoke  SetTFAndDecEip, FALSE, 1
                mov     @bIsInputCmd, TRUE
                
                invoke  DeleteItem, g_DbgData.m_vector, @dwIndex
                invoke  crt_free, @pDbgBP
                
                .break
            .endif
        .endif      
    
        inc     @dwIndex
        mov     ecx, @dwIndex
    .endw

    .if     @bIsInputCmd
        ; invoke  ShowAsmInfo
        invoke  OnCommand_R_ShowRegister
        invoke  InputCommand
    .endif

    mov     eax, DBG_CONTINUE
    ret
OnBreakPoint endp

; 处理单步异常
OnSingleStep proc
    local   @dwVectorSize       :DWORD
    local   @dwIndex            :DWORD
    local   @pDbgBP             :ptr tagDbgBP
    local   @dwAddr             :DWORD
    local   @btCode             :DWORD
    local   @ctx                :CONTEXT
    local   @hThread            :HANDLE

    mov     @dwVectorSize, 0
    mov     @dwIndex, 0
    mov     @pDbgBP, NULL
    mov     @dwAddr, 0
    mov     @hThread, NULL
    invoke  RtlZeroMemory, addr @ctx, sizeof @ctx

    invoke  GetVectorSize, g_DbgData.m_vector
    mov     @dwVectorSize, eax
    ; 判断是否需要重设断点
    mov     ecx, @dwIndex
    .while  ecx < @dwVectorSize
        invoke  GetItem, g_DbgData.m_vector, addr @pDbgBP, @dwIndex
        mov     ebx, @pDbgBP
        assume  ebx :ptr tagDbgBP
        ; 如果是永久断点
        .if     [ebx].m_dwType == SETBP_LONG
            ; 重设INT3断点
            mov     eax, [ebx].m_dwAddr
            mov     @dwAddr, eax
            movzx   eax, [ebx].m_btCode
            mov     @btCode, eax
            invoke  DeleteItem, g_DbgData.m_vector, @dwIndex
            invoke  crt_free, @pDbgBP
            invoke  ResumeBtCode, @dwAddr, @btCode
            invoke  SetBP, @dwAddr, SETBP_LONG
        .endif
        
        inc     @dwIndex
        mov     ecx, @dwIndex
    .endw
    
    ; 判断是否指令记录
    .if     g_bIsRecordFlag == TRUE
        invoke  OnCommand_GJ, g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionAddress
        mov     eax, g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionAddress
        .if     eax == g_dwRecordAddr
            mov     g_bIsRecordFlag, FALSE
            invoke  CloseHandle, g_hRecordFile
        .endif
    .endif
    
    ; 重设硬件断点
    .if     g_bBhSingStep == TRUE
        mov     eax, g_DbgData.m_dwLastDR7
        mov     @ctx.iDr7, eax 
        mov     g_bBhSingStep, FALSE
    .endif
    
    ; 处理硬件断点
    invoke  OpenThread, THREAD_ALL_ACCESS, FALSE, g_DbgData.m_de.dwThreadId
    mov     @hThread, eax
    mov     @ctx.ContextFlags, CONTEXT_ALL
    invoke  GetThreadContext, @hThread, addr @ctx
    mov     eax, @ctx.iDr6
    .if     eax & 1b
        mov     eax, @ctx.regFlag
        or      eax, 100h
        mov     @ctx.regFlag, eax
        mov     g_bBhSingStep, TRUE
        
        ; 记录当前硬件断点信息
        mov     eax, @ctx.iDr7
        mov     g_DbgData.m_dwLastDR7, eax
        ; 取消硬件断点
        xor     @ctx.iDr7, 00000000000000000000000000000001b
        
        mov     @ctx.iDr6, 0
        invoke  SetThreadContext, @hThread, addr @ctx
        
        invoke  OnCommand_R_ShowRegister
        invoke  InputCommand
        
    .elseif eax & 10b
        mov     eax, @ctx.regFlag
        or      eax, 100h
        mov     @ctx.regFlag, eax
        mov     g_bBhSingStep, TRUE
        
        ; 记录当前硬件断点信息
        mov     eax, @ctx.iDr7
        mov     g_DbgData.m_dwLastDR7, eax
        ; 取消硬件断点
        xor     @ctx.iDr7, 00000000000000000000000000000100b
        
        mov     @ctx.iDr6, 0
        invoke  SetThreadContext, @hThread, addr @ctx
        
        invoke  OnCommand_R_ShowRegister
        invoke  InputCommand
        
    .elseif eax & 100b
        mov     eax, @ctx.regFlag
        or      eax, 100h
        mov     @ctx.regFlag, eax
        mov     g_bBhSingStep, TRUE
        
        ; 记录当前硬件断点信息
        mov     eax, @ctx.iDr7
        mov     g_DbgData.m_dwLastDR7, eax
        ; 取消硬件断点
        xor     @ctx.iDr7, 00000000000000000000000000010000b
        
        mov     @ctx.iDr6, 0
        invoke  SetThreadContext, @hThread, addr @ctx
        
        invoke  OnCommand_R_ShowRegister
        invoke  InputCommand
        
    .elseif eax & 1000b
        mov     eax, @ctx.regFlag
        or      eax, 100h
        mov     @ctx.regFlag, eax
        mov     g_bBhSingStep, TRUE
        
        ; 记录当前硬件断点信息
        mov     eax, @ctx.iDr7
        mov     g_DbgData.m_dwLastDR7, eax
        ; 取消硬件断点
        xor     @ctx.iDr7, 00000000000000000000000001000000b
        
        mov     @ctx.iDr6, 0
        invoke  SetThreadContext, @hThread, addr @ctx
        
        invoke  OnCommand_R_ShowRegister
        invoke  InputCommand
        
    .else
        mov     @ctx.iDr6, 0
        invoke  SetThreadContext, @hThread, addr @ctx
    .endif
    
    invoke  CloseHandle, @hThread

    .if     g_bIsSingStepCmd == TRUE
        mov     g_bIsSingStepCmd, FALSE
        invoke  OnCommand_R_ShowRegister
        ; invoke  ShowAsmInfo
        .if     g_bIsRecordFlag == FALSE
            invoke  InputCommand
        .endif
    .endif
    
    mov     eax, DBG_CONTINUE
    ret
OnSingleStep endp

; 显示信息
ShowAsmInfo proc
    local   @dwAddr             :DWORD
    local   @aryCode[16]        :BYTE
    local   @dwReadOrWriteSize  :DWORD
    local   @strAsm[128]        :CHAR
    local   @dwCodeSize         :DWORD
    
    mov     eax, g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionAddress
    mov     @dwAddr, eax
    mov     @dwCodeSize, 0
    mov     @dwReadOrWriteSize, 0
    invoke  RtlZeroMemory, addr @aryCode, sizeof @aryCode
    invoke  RtlZeroMemory, addr @strAsm, sizeof @strAsm
    
    invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwAddr, addr @aryCode, sizeof @aryCode, addr @dwReadOrWriteSize
    invoke  ResumeShowCode, @dwAddr, addr @aryCode
    invoke  Decode2Asm, addr @aryCode, addr @strAsm, addr @dwCodeSize, @dwAddr
    
    invoke  crt_printf, offset g_strFmt_ShowInfo, @dwAddr, addr @strAsm
    ret
ShowAsmInfo endp

; 恢复指令
ResumeBtCode proc dwAddr :DWORD, btData :DWORD
    local   @btData             :BYTE
    local   @dwOldProc          :DWORD
    local   @dwReadOrWriteSize  :DWORD
    
    mov     eax, btData
    mov     @btData, al
    mov     @dwOldProc, 0
    mov     @dwReadOrWriteSize, 0
    
    invoke  VirtualProtectEx, g_DbgData.m_hProc, dwAddr, sizeof @btData, PAGE_READWRITE, addr @dwOldProc
    ; 写入
    invoke  WriteProcessMemory, g_DbgData.m_hProc, dwAddr, addr @btData, sizeof @btData, addr @dwReadOrWriteSize
    invoke  VirtualProtectEx, g_DbgData.m_hProc, dwAddr, sizeof @btData, @dwOldProc, addr @dwOldProc

    ret
ResumeBtCode endp

; 输入指令并解析
InputCommand proc
    local   @szCommand[MAXBYTE]     :CHAR           ; 接收输入的命令
    
    
    mov     eax, TRUE
    .while   eax == TRUE
        invoke  RtlZeroMemory, addr @szCommand, sizeof @szCommand
        
        .if     g_bIsRunScript == FALSE
            invoke  crt_printf, offset g_strFmt_CMD_
            invoke  crt_gets, addr @szCommand
        .else
            invoke  GetScriptCmd, addr @szCommand
        .endif
        invoke  TransCommand, addr @szCommand
    .endw

    ret
InputCommand endp

; 获取脚本命令
GetScriptCmd proc uses ecx @szCommand :ptr CHAR
    local   @dwReadSize         :DWORD
    local   @btCode             :BYTE

    .while      TRUE
        ; 读文件
        invoke  ReadFile, g_hScriptFIle, @szCommand, 1, addr @dwReadSize, NULL
        
        mov     ecx, @szCommand
        movzx   eax, byte ptr [ecx]
        .if     al == 0dh     
            ; 读完一行
            ; 在读一次 0ah
            invoke  ReadFile, g_hScriptFIle, addr @btCode, 1, addr @dwReadSize, NULL
            ret
        .endif
        
        .if     @dwReadSize == 0
            ; 文件末尾
            mov     g_bIsRunScript, FALSE
            invoke  CloseHandle, g_hScriptFIle
            ret
        .endif  
        
        inc     @szCommand
    .endw

    ret
GetScriptCmd endp

; 处理输入或读取的指令 
TransCommand proc szCommand :ptr CHAR
    local   @pCmd                   :ptr CHAR       ; 用于解析的命令指针
    local   @dwAddr                 :DWORD          ; 解析后的地址
    local   @pNextCmd               :ptr CHAR       ; 解析地址后的指针位置
    local   @dwAccess               :DWORD          ; 硬件断点操作长度 1/2/4/8
    
    mov     @pCmd, 0
    mov     @dwAddr, 0
    mov     @pNextCmd, NULL
    mov     @dwAccess, 0

    ; 跳过空白字符
    invoke  SkipWhiteChar, szCommand
    mov     @pCmd, eax
    ; mov     eax, @pCmd
    movzx   eax, byte ptr [eax]
    
    ; case 'u'
    .if     al == 'u'
        ; ++pCmd
        inc     @pCmd
        ; 获取地址
        invoke  SkipWhiteChar, @pCmd
        mov     @pCmd, eax
        invoke  crt_strtoul, @pCmd, NULL, dword ptr 16
        mov     @dwAddr, eax
        .if     @dwAddr == 0
            ; 解析出错
            mov     eax, TRUE
            ret
        .endif
        invoke  OnCommand_U, @dwAddr, 20
        ; 不执行，输入下一条命令
        mov     eax, TRUE
        ret
    
    ; case 'r'
    .elseif al == 'r'
        invoke  crt_strlen, @pCmd
        .if     eax < 3
            ; 查看
            invoke  OnCommand_R_ShowRegister
        .else
            ; 修改
            ; ++pCmd
            inc     @pCmd
            invoke  SkipWhiteChar, @pCmd
            mov     @pCmd, eax
            invoke  OnCommand_R_SetRegister, @pCmd
        .endif
        ; 不执行，输入下一条命令
        mov     eax, TRUE
        ret
        
    ; case d
    .elseif al == 'd'
        ; ++pCmd
        inc     @pCmd
        mov     eax, @pCmd
        movzx   eax, byte ptr [eax]
        push    eax
        
        ; ++pCmd
        inc     @pCmd
        ; 获取地址
        invoke  SkipWhiteChar, @pCmd
        mov     @pCmd, eax
        invoke  crt_strtoul, @pCmd, NULL, dword ptr 16
        mov     @dwAddr, eax
        
        pop     eax
        ; case 'b'
        .if     al == 'b'
            ; db
            invoke  OnCommand_DB_ShowMem, @dwAddr, 50h
        .elseif al == 'w'
            ; dw
            invoke  OnCommand_DB_ShowMem, @dwAddr, 2
        .elseif al == 'd'
            ; dd   
            invoke  OnCommand_DB_ShowMem, @dwAddr, 4
        .elseif al == 'u'
            mov     eax, @pCmd
            movzx   eax, byte ptr [eax]
            .if     al == 'm'
                inc     @pCmd
                mov     eax, @pCmd
                movzx   eax, byte ptr [eax]
                .if     al == 'p'
                    inc     @pCmd
                    mov     eax, @pCmd
                    movzx   eax, byte ptr [eax]
                    .if     al == 'P'
                        inc     @pCmd
                        mov     eax, @pCmd
                        movzx   eax, byte ptr [eax]
                        .if     al == 'E'
                            ; dumpPE
                            invoke  OnCommand_DUMP_PE
                            mov     eax, TRUE
                            ret
                        .endif
                    .endif
                .endif
            .endif
        .endif
        ; 不执行，输入下一条命令
        mov     eax, TRUE
        ret
        
    ; case e
    .elseif al == 'e'
        ; ++pCmd
        inc     @pCmd
        ; 获取地址
        invoke  SkipWhiteChar, @pCmd
        mov     @pCmd, eax
        invoke  crt_strtoul, @pCmd, addr @pNextCmd, dword ptr 16
        mov     @dwAddr, eax
        
        invoke  SkipWhiteChar, @pNextCmd
        mov     @pCmd, eax
        
        invoke  OnCommand_E_SetMem, @dwAddr, @pCmd
        ; 不执行，输入下一条命令
        mov     eax, TRUE
        ret
        
    ; case p
    .elseif al == 'p'
        invoke  OnCommand_P
        ; 执行
        mov     eax, FALSE
        ret
        
    ; case t
    .elseif al == 't'
        invoke  OnCommand_T
        ; 执行
        mov     eax, FALSE
        ret
        
    ; case g
    .elseif al == 'g'
        ; ++pCmd
        inc     @pCmd
        mov     eax, @pCmd
        movzx   eax, byte ptr [eax]
        .if     al == 'u'
            ; 执行到返回
            invoke  OnCommand_GU
            mov     eax, FALSE
            ret
        .elseif al == 'j'
            ; 指令记录
            inc     @pCmd
            ; 获取地址
            invoke  SkipWhiteChar, @pCmd
            mov     @pCmd, eax
            invoke  crt_strtoul, @pCmd, addr @pNextCmd, dword ptr 16
            mov     @dwAddr, eax
            
            invoke  OnCommand_GJ, @dwAddr
            mov     eax, FALSE
            ret
        .endif
        
        ; g
        invoke  OnCommand_G
        mov     eax, FALSE
        ret
       
    ; case b
    .elseif al == 'b'
        ; ++pCmd
        inc     @pCmd
        mov     eax, @pCmd
        movzx   eax, byte ptr [eax]
        .if     al == 'p'
            ; ++pCmd
            inc     @pCmd
            ; 获取地址
            invoke  SkipWhiteChar, @pCmd
            mov     @pCmd, eax
            invoke  crt_strtoul, @pCmd, NULL, dword ptr 16
            mov     @dwAddr, eax
            
            invoke  OnCommand_BP, @dwAddr
            mov     eax, TRUE
            ret
            
        .elseif al == 'h'
            ; bh    
            inc     @pCmd
            invoke  SkipWhiteChar, @pCmd
            mov     @pCmd, eax
            movzx   eax, byte ptr [eax]
            push    eax
            
            ; 获取操作长度
            inc     @pCmd
            invoke  crt_strtoul, @pCmd, NULL, dword ptr 16
            mov     @dwAccess, eax
            ; 获取操作地址
            inc     @pCmd
            invoke  SkipWhiteChar, @pCmd
            mov     @pCmd, eax
            invoke  crt_strtoul, @pCmd, NULL, dword ptr 16
            mov     @dwAddr, eax
            
            pop     eax
            .if     al == 'e'
                invoke  OnCommand_BH, @dwAddr, 1, 0
            .elseif al == 'r'
                invoke  OnCommand_BH, @dwAddr, @dwAccess, 3
            .elseif al == 'w'    
                invoke  OnCommand_BH, @dwAddr, @dwAccess, 1
            .endif
            mov     eax, TRUE
            ret
            
        .endif
    
    ; case m
    .elseif al == 'm'
        inc     @pCmd
        mov     eax, @pCmd
        movzx   eax, byte ptr [eax]
        .if     al == 'l'
            invoke  OnCommand_ML
            mov     eax, TRUE
            ret
        .endif
        
    ; case s
    .elseif al == 's'
        inc     @pCmd
        mov     eax, @pCmd
        movzx   eax, byte ptr [eax]
        .if     al == 'c'
            invoke  OnCommand_SC
            mov     eax, TRUE
            ret
        .endif
        
    ;case q
    .elseif al == 'q'
        invoke  Exit_Process
    .endif

    mov     eax, TRUE
    ret
TransCommand endp

; 指令记录
OnCommand_GJ proc dwAddr :DWORD
    local   @dwReadOrWriteSize  :DWORD
    local   @dwReadAddr         :DWORD
    local   @szAsmBuff[16]      :BYTE       ; 读取缓冲区
    local   @strAsmCode[128]    :BYTE       ; 得到的反汇编指令信息
    local   @dwCodeSize         :UINT       ; 解析指令长度
    local   @strOpcode[64]      :BYTE       ; 机器码信息
    local   @strWriteData[MAXBYTE]:BYTE     ; 写入文件缓冲区
    local   @dwWriteDataSize    :DWORD     ;  写入文件的字节数
    local   @hThread        :HANDLE
    local   @ctx            :CONTEXT

    mov     @dwReadOrWriteSize, 0
    mov     @dwReadAddr, 0
    mov     @dwCodeSize, 0
    mov     @dwWriteDataSize, 0
    
    invoke  RtlZeroMemory, addr @szAsmBuff, sizeof @szAsmBuff
    invoke  RtlZeroMemory, addr @strAsmCode, sizeof @strAsmCode
    invoke  RtlZeroMemory, addr @strOpcode, sizeof @strOpcode
    
    mov     @hThread, NULL
    invoke  RtlZeroMemory, addr @ctx, sizeof @ctx
    
    ; 获取寄存器信息
    invoke  OpenThread, THREAD_ALL_ACCESS, FALSE, g_DbgData.m_de.dwThreadId
    mov     @hThread, eax
    mov     @ctx.ContextFlags, CONTEXT_ALL
    invoke  GetThreadContext, @hThread, addr @ctx
    
    mov     eax, @ctx.regEip
    mov     @dwReadAddr, eax
    
    ; 创建文件
    .if     g_bIsRecordFlag == FALSE
        invoke  CreateFile, addr g_strRecordASMFile, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
        mov     g_hRecordFile, eax
        .if     g_hRecordFile == INVALID_HANDLE_VALUE
            mov     eax, NULL
            ret
        .endif
        mov     eax, dwAddr
        mov     g_dwRecordAddr, eax
        mov     g_bIsRecordFlag, TRUE
        ; 在下一行下断点
        invoke  ReadProcessMemory, g_DbgData.m_hProc, g_dwRecordAddr, addr @szAsmBuff, sizeof @szAsmBuff, addr @dwReadOrWriteSize
        invoke  ResumeShowCode, @dwReadAddr, addr @szAsmBuff
        ; 解析指令
        invoke  Decode2AsmOpcode, addr @szAsmBuff, addr @strAsmCode, addr @strOpcode, addr @dwCodeSize, @dwReadAddr
        mov     eax, @dwCodeSize
        add     eax, dwAddr
        invoke  SetBP, eax, SETBP_TEMP
    .endif
    
    ; 反汇编当前地址
    invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwReadAddr, addr @szAsmBuff, sizeof @szAsmBuff, addr @dwReadOrWriteSize
    invoke  ResumeShowCode, @dwReadAddr, addr @szAsmBuff
    ; 解析指令
    invoke  Decode2AsmOpcode, addr @szAsmBuff, addr @strAsmCode, addr @strOpcode, addr @dwCodeSize, @dwReadAddr
    
    ; 写入文件
    invoke  wsprintf, addr @strWriteData, offset g_strFmt_record, @dwReadAddr, addr @strAsmCode
    invoke  crt_strlen, addr @strWriteData
    mov     @dwWriteDataSize, eax
    invoke  WriteFile, g_hRecordFile, addr @strWriteData, @dwWriteDataSize, addr @dwWriteDataSize, NULL
    
    invoke  OnCommand_T
    
    ret
OnCommand_GJ endp

; 脚本功能
OnCommand_SC proc
    invoke  CreateFile, offset g_strScriptName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov     g_hScriptFIle, eax
    .if     g_hScriptFIle == INVALID_HANDLE_VALUE
        mov     eax, NULL
        ret
    .endif
    mov     g_bIsRunScript, TRUE
    ret
OnCommand_SC endp

; 查看模块列表
OnCommand_ML proc
    local   @hModuleSnap    :HANDLE
    local   @me32           :MODULEENTRY32
    
    mov     @hModuleSnap, NULL
    invoke  RtlZeroMemory, addr @me32, sizeof @me32

    invoke  CreateToolhelp32Snapshot, TH32CS_SNAPMODULE, g_DbgData.m_dwProcessID
    mov     @hModuleSnap, eax
    ; check
    
    mov     @me32.dwSize, sizeof MODULEENTRY32
    invoke  Module32First, @hModuleSnap, addr @me32
    .if     eax != TRUE
        invoke  crt_printf, offset g_strFmt_ERR
        invoke  CloseHandle, @hModuleSnap
        ret    
    .endif
    
    .while  TRUE
        invoke  crt_printf, offset g_strFmt_modualInfo, addr @me32.szModule, @me32.modBaseAddr
        
        invoke  Module32Next, @hModuleSnap, addr @me32
        .if     eax != TRUE
            .break
        .endif
    .endw
    
    invoke  CloseHandle, @hModuleSnap
    
    ret
OnCommand_ML endp

; 内存dumpPE到文件
OnCommand_DUMP_PE proc uses ecx
    local   @dwVectorSize               :DWORD
    local   @dwIndex                    :DWORD
    local   @pDbgBP                     :ptr tagDbgBP
    local   @dwAddr                     :DWORD
    local   @dwBtCode                   :DWORD          
    local   @dwImageBase                :DWORD          ; IMAGEBASE
    local   @dosHeader                  :IMAGE_DOS_HEADER
    local   @ntHeader                   :IMAGE_NT_HEADERS
    local   @dwNTOffset                 :DWORD          ; NT偏移
    local   @hModuleSnap                :HANDLE         ; 进程快照句柄
    local   @me32                       :MODULEENTRY32  ; 模块信息
    local   @dwReadOrWriteSize          :DWORD          ; 读取的字节
    local   @dwSectionNumber            :DWORD          ; 节数量
    local   @dwSectionOffset            :DWORD          ; 节偏移
    local   @dwPEHeaderSize             :DWORD          ; PE 头大小
    local   @pWriteData                 :ptr BYTE       
    local   @strFileName[MAXBYTE]       :CHAR           ; 文件名
    local   @hFileHandle                :HANDLE         ; 文件句柄
    local   @pSection                   :ptr IMAGE_SECTION_HEADER
    local   @i                          :DWORD
    local   @dwSectionVirtualAddress    :DWORD          ; 内存地址
    local   @dwSectionVirtualSize       :DWORD          ; 内存大小
    local   @dwSectionRawSize           :DWORD          ; 文件大小
    local   @pRawData                   :ptr BYTE
    
    mov     @dwVectorSize,  0
    mov     @dwIndex, 0
    mov     @pDbgBP, 0
    mov     @dwAddr, 0
    mov     @dwBtCode, 0
    mov     @dwNTOffset, 0
    mov     @dwImageBase, 0
    mov     @hModuleSnap, NULL
    mov     @dwSectionNumber, 0 
    mov     @dwSectionOffset, 0  
    mov     @dwPEHeaderSize, 0
    mov     @pWriteData, NULL
    mov     @hFileHandle, NULL
    mov     @pSection, NULL
    mov     @i, 0
    mov     @dwSectionVirtualAddress, 0
    mov     @dwSectionVirtualSize, 0
    mov     @dwSectionRawSize, 0
    mov     @pRawData, NULL
    invoke  RtlZeroMemory, addr @me32, sizeof @me32
    invoke  RtlZeroMemory, addr @dosHeader, sizeof @dosHeader
    invoke  RtlZeroMemory, addr @ntHeader, sizeof @ntHeader
    invoke  RtlZeroMemory, addr @strFileName, sizeof @strFileName
    
    invoke  wsprintf, addr @strFileName, offset g_strFmt_fileName, offset g_strTestExe
    
    ; 创建文件
    invoke  CreateFile, addr @strFileName, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov     @hFileHandle, eax
    .if     @hFileHandle == INVALID_HANDLE_VALUE
        mov     eax, NULL
        ret
    .endif
    
    ; 获取模块基址
    invoke  CreateToolhelp32Snapshot, TH32CS_SNAPMODULE, g_DbgData.m_dwProcessID
    mov     @hModuleSnap, eax
    ; check
    
    mov     @me32.dwSize, sizeof MODULEENTRY32
    invoke  Module32First, @hModuleSnap, addr @me32
    .if     eax != TRUE
        invoke  crt_printf, offset g_strFmt_ERR
        invoke  CloseHandle, @hModuleSnap
        ret    
    .endif
    
    mov     eax, @me32.modBaseAddr
    mov     @dwImageBase, eax
    
    invoke  GetVectorSize, g_DbgData.m_vector
    mov     @dwVectorSize, eax
    ; 还原所有断点
    mov     ecx, @dwIndex
    .while  ecx < @dwVectorSize
        invoke  GetItem, g_DbgData.m_vector, addr @pDbgBP, @dwIndex
        mov     ebx, @pDbgBP
        assume  ebx :ptr tagDbgBP
        movzx   eax, [ebx].m_btCode
        invoke  ResumeBtCode, [ebx].m_dwAddr, eax
        inc     @dwIndex
        mov     ecx, @dwIndex
    .endw
    
    ; 读取Dos Header
    invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwImageBase, addr @dosHeader, sizeof @dosHeader, addr @dwReadOrWriteSize
    ; 计算NT Header偏移
    mov     eax, @dosHeader.e_lfanew
    add     eax, @dwImageBase
    mov     @dwNTOffset, eax
    invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwNTOffset, addr @ntHeader, sizeof @ntHeader, addr @dwReadOrWriteSize
    
    movzx   eax, @ntHeader.FileHeader.NumberOfSections
    mov     @dwSectionNumber, eax
    mov     eax, @dwNTOffset 
    movzx   ecx, @ntHeader.FileHeader.SizeOfOptionalHeader
    add     eax, ecx
    add     eax, 18h ; offsetof(IMAGE_NT_HEADERS32, OptionalHeader)
    sub     eax, @dwImageBase
    mov     @dwSectionOffset, eax
    mov     eax, @ntHeader.OptionalHeader.SizeOfHeaders
    mov     @dwPEHeaderSize, eax
    
    invoke  crt_malloc, @dwPEHeaderSize
    mov     @pWriteData, eax
    ; check
    
    invoke  RtlZeroMemory, @pWriteData, @dwPEHeaderSize
    invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwImageBase, @pWriteData, @dwPEHeaderSize, addr @dwReadOrWriteSize
    ; 写入PE头到文件
    invoke  WriteFile, @hFileHandle, @pWriteData, @dwPEHeaderSize, addr @dwReadOrWriteSize, NULL
    
    ; 写入节
    mov     eax, @pWriteData
    add     eax, @dwSectionOffset
    mov     @pSection, eax
    
    mov     ecx, @i
    .while  ecx < @dwSectionNumber
        mov     ebx, @pSection
        assume  ebx :ptr IMAGE_SECTION_HEADER
        mov     eax, @dwImageBase
        add     eax, [ebx].VirtualAddress
        mov     @dwSectionVirtualAddress, eax
        mov     eax, [ebx].Misc.VirtualSize
        mov     @dwSectionVirtualSize, eax
        mov     eax, [ebx].SizeOfRawData
        mov     @dwSectionRawSize, eax
        
        invoke  crt_malloc, @dwSectionRawSize
        mov     @pRawData, eax
        ; check
    
        invoke  RtlZeroMemory, @pRawData, @dwSectionRawSize
        
        invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwSectionVirtualAddress, @pRawData, @dwSectionRawSize, addr @dwReadOrWriteSize
        ; 写入文件
        invoke  WriteFile, @hFileHandle, @pRawData, @dwSectionRawSize, addr @dwReadOrWriteSize, NULL
    
        invoke  crt_free, @pRawData
    
        mov     eax, @pSection
        add     eax, sizeof IMAGE_SECTION_HEADER
        mov     @pSection, eax
        inc     @i
        mov     ecx, @i
    .endw
    
    invoke  crt_free, @pWriteData
    invoke  CloseHandle, @hFileHandle
    
    ; 设置所有断点
    mov     ecx, @dwIndex
    .while  ecx < @dwVectorSize
        invoke  GetItem, g_DbgData.m_vector, addr @pDbgBP, @dwIndex
        mov     ebx, @pDbgBP
        assume  ebx :ptr tagDbgBP
        movzx   eax, [ebx].m_btCode
        invoke  SetBP, [ebx].m_dwAddr, [ebx].m_dwType
        inc     @dwIndex
        mov     ecx, @dwIndex
    .endw
    
    ret
OnCommand_DUMP_PE endp

; 硬件执行断点
OnCommand_BH proc dwAddr :DWORD, dwBhLen :DWORD, dwDhType :DWORD
    local   @hThread        :HANDLE
    local   @ctx            :CONTEXT
    local   @lpItem         :LPDWORD
    local   @pDbgBP         :ptr tagDbgBP
    local   @dwIndex        :DWORD
    local   @btCode         :DWORD
    local   @dwAddr         :DWORD
    local   @dwVectorSize   :DWORD
    
    mov     @hThread, NULL
    mov     @lpItem, NULL
    mov     @pDbgBP, NULL
    mov     @dwIndex, NULL
    mov     @btCode, 0
    mov     @dwAddr, 0
    mov     @dwVectorSize, 0
    
    invoke  RtlZeroMemory, addr @ctx, sizeof @ctx
    
    invoke  OpenThread, THREAD_ALL_ACCESS, FALSE, g_DbgData.m_de.dwThreadId
    mov     @hThread, eax
    mov     @ctx.ContextFlags, CONTEXT_ALL
    invoke  GetThreadContext, @hThread, addr @ctx
    
    ; 判断占用情况
    mov     eax, dwAddr
    .if     @ctx.iDr0 == eax || @ctx.iDr1 == eax || @ctx.iDr2 == eax || @ctx.iDr3 == eax
        mov     eax, FALSE
        ret
    .endif
    
    ; 判断是否有BP断点，如果有则恢复机器码并删除
    invoke  GetVectorSize, g_DbgData.m_vector
    mov     @dwVectorSize, eax
    mov     ecx, @dwIndex
    .while  ecx < @dwVectorSize
        invoke  GetItem, g_DbgData.m_vector, addr @pDbgBP, @dwIndex
        mov     ebx, @pDbgBP
        assume  ebx :ptr tagDbgBP
        mov     eax, dwAddr
        .if     [ebx].m_dwAddr == eax
            mov     eax, [ebx].m_dwAddr
            mov     @dwAddr, eax
            movzx   eax, [ebx].m_btCode
            mov     @btCode, eax
            invoke  DeleteItem, g_DbgData.m_vector, @dwIndex
            invoke  crt_free, @pDbgBP
            invoke  ResumeBtCode, @dwAddr, @btCode
        .endif  
        inc     @dwIndex
        mov     ecx, @dwIndex
    .endw
    
    .if     g_DbgData.m_DR0 == FALSE
        mov     eax, dwAddr
        mov     @ctx.iDr0, eax
        or      @ctx.iDr7, 00000000000000000000000000000001b
        
        .if     dwBhLen == 1
            or      @ctx.iDr7, 00000000000000000000000000000000b
        .elseif dwBhLen == 2
            or      @ctx.iDr7, 00000000000001000000000000000000b
        .elseif dwBhLen == 4
            or      @ctx.iDr7, 00000000000011000000000000000000b
        .endif
        
        .if     dwDhType == 3       ; 访问
            or      @ctx.iDr7, 00000000000000110000000000000000b
        .elseif dwDhType == 0   ; 执行
            or      @ctx.iDr7, 00000000000000000000000000000000b
        .elseif dwDhType == 1   ; 写入
            or      @ctx.iDr7, 00000000000000010000000000000000b
        .endif
        
        invoke  SetThreadContext, @hThread, addr @ctx
        mov     g_DbgData.m_DR0, TRUE
        
    .elseif g_DbgData.m_DR1 == FALSE
        mov     eax, dwAddr
        mov     @ctx.iDr1, eax
        
        or      @ctx.iDr7, 00000000000000000000000000000100b
        
        .if dwBhLen == 0 || dwBhLen == 1
            or      @ctx.iDr7, 00000000000000000000000000000000b
        .elseif dwBhLen == 2
            or      @ctx.iDr7, 00000000010000000000000000000000b
        .elseif dwBhLen == 4
            or      @ctx.iDr7, 00000000110000000000000000000000b
        .endif
        
        .if     dwDhType == 3       ; 访问
            or      @ctx.iDr7, 00000000001100000000000000000000b
        .elseif dwDhType == 0   ; 执行
            or      @ctx.iDr7, 00000000000000000000000000000000b
        .elseif dwDhType == 1   ; 写入
            or      @ctx.iDr7, 00000000000100000000000000000000b
        .endif
        
        invoke  SetThreadContext, @hThread, addr @ctx
        mov     g_DbgData.m_DR1, TRUE
    .elseif g_DbgData.m_DR2 == FALSE
        mov     eax, dwAddr
        mov     @ctx.iDr2, eax
        
        or      @ctx.iDr7, 00000000000000000000000000010000b
        
        .if     dwBhLen == 0 || dwBhLen == 1
            or      @ctx.iDr7, 00000000000000000000000000000000b
        .elseif dwBhLen == 2
            or      @ctx.iDr7, 00000100000000000000000000000000b
        .elseif dwBhLen == 4
            or      @ctx.iDr7, 00001100000000000000000000000000b
        .endif
        
        .if     dwDhType == 3       ; 访问
            or      @ctx.iDr7, 00000000000000000000000011b
        .elseif dwDhType == 0   ; 执行
            or      @ctx.iDr7, 00000000000000000000000000000000b
        .elseif dwDhType == 1   ; 写入
            or      @ctx.iDr7, 00000000000000000000000001b
        .endif
        
        invoke  SetThreadContext, @hThread, addr @ctx
        mov     g_DbgData.m_DR2, TRUE
    .elseif g_DbgData.m_DR3 == FALSE
        mov     eax, dwAddr
        mov     @ctx.iDr3, eax
        
        or      @ctx.iDr7, 00000000000000000000000001000000b
        
        .if     dwBhLen == 0 || dwBhLen == 1
            or  @ctx.iDr7, 00000000000000000000000000000000b
        .elseif dwBhLen == 2
            or  @ctx.iDr7, 01000000000000000000000000000000b
        .elseif dwBhLen == 4
            or  @ctx.iDr7, 11000000000000000000000000000000b
        .endif
        
        .if     dwDhType == 3       ; 访问
            or  @ctx.iDr7, 00110000000000000000000000000000b
        .elseif dwDhType == 0   ; 执行
            or  @ctx.iDr7, 00000000000000000000000000000000b
        .elseif dwDhType == 1   ; 写入
            or  @ctx.iDr7, 00010000000000000000000000000000b
        .endif
        
        invoke  SetThreadContext, @hThread, addr @ctx
        mov     g_DbgData.m_DR3, TRUE
    .endif
    
    invoke  CloseHandle, @hThread
    mov eax, TRUE
    ret
OnCommand_BH endp

; 处理 G 命令
OnCommand_G proc

    ret
OnCommand_G endp

; 处理 GU 命令
OnCommand_GU proc
    local   @dwAddr             :DWORD
    local   @aryCode[16]        :BYTE
    local   @dwReadOrWriteSize  :DWORD
    local   @strAsm[128]        :CHAR
    local   @dwCodeSize         :DWORD
    
    mov     eax, g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionAddress
    mov     @dwAddr, eax
    
    .while  TRUE
        mov     @dwCodeSize, 0
        mov     @dwReadOrWriteSize, 0
        invoke  RtlZeroMemory, addr @aryCode, sizeof @aryCode
        invoke  RtlZeroMemory, addr @strAsm, sizeof @strAsm
        invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwAddr, addr @aryCode, sizeof @aryCode, addr @dwReadOrWriteSize
        invoke  ResumeShowCode, @dwAddr, addr @aryCode
        invoke  Decode2Asm, addr @aryCode, addr @strAsm, addr @dwCodeSize, @dwAddr
        ; 判断是否是ret
        invoke  crt_strstr, addr @strAsm, offset g_strAsmCmd_ret
        .if     eax != NULL
            ; 设置临时断点
            invoke  SetBP, @dwAddr, SETBP_TEMP
            .break
        .endif
        mov     eax, @dwCodeSize
        add     @dwAddr, eax
    .endw
    
    ret
OnCommand_GU endp

; 处理BP断点
OnCommand_BP proc uses ecx ebx dwAddr :DWORD
    local   @dwVectorSize       :DWORD
    local   @dwIndex            :DWORD
    local   @pDbgBP             :ptr tagDbgBP
    
    mov     @dwVectorSize,  0
    mov     @dwIndex, 0
    mov     @pDbgBP, 0
    
    invoke  GetVectorSize, g_DbgData.m_vector
    mov     @dwVectorSize, eax
    ; 检查断点是否存在
    mov     ecx, @dwIndex
    .while  ecx < @dwVectorSize
        invoke  GetItem, g_DbgData.m_vector, addr @pDbgBP, @dwIndex
        mov     ebx, @pDbgBP
        assume  ebx :ptr tagDbgBP
        mov     eax, dwAddr
        .if     [ebx].m_dwAddr == eax
            ret
        .endif
        
        inc     @dwIndex
        mov     ecx, @dwIndex
    .endw
    
    ; 添加断点
    invoke  SetBP, dwAddr, SETBP_LONG
    
    ret
OnCommand_BP endp

; 设置BP断点
SetBP proc uses ebx dwAddr :DWORD, dwType :DWORD
    local   @btCode             :BYTE       
    local   @dwOldProc          :DWORD
    local   @dwReadOrWriteSize  :DWORD
    local   @btOldCode          :BYTE       ; 原内存数据
    local   @pDbgBP             :ptr tagDbgBP
    
    mov     byte ptr @btCode, 0cch
    mov     @dwOldProc, 0
    mov     @dwReadOrWriteSize, 0
    mov     byte ptr @btOldCode, 0
    
    ; 读取原数据
    invoke  ReadProcessMemory, g_DbgData.m_hProc, dwAddr, addr @btOldCode, sizeof @btOldCode, addr @dwReadOrWriteSize 
    
    ; 修改内存属性
    invoke  VirtualProtectEx, g_DbgData.m_hProc, dwAddr, sizeof @btCode, PAGE_READWRITE, addr @dwOldProc
    ; 写入
    invoke  WriteProcessMemory, g_DbgData.m_hProc, dwAddr, addr @btCode, sizeof @btCode, addr @dwReadOrWriteSize
    ; 还原内存
    invoke  VirtualProtectEx, g_DbgData.m_hProc, dwAddr, sizeof @btCode, @dwOldProc, addr @dwOldProc
    
    ; 断点信息
    invoke  crt_malloc, sizeof tagDbgBP
    mov     @pDbgBP, eax
    ; check
    
    invoke  RtlZeroMemory, @pDbgBP, sizeof tagDbgBP
    
    mov     ebx, @pDbgBP
    assume  ebx :ptr tagDbgBP
    mov     eax, dwAddr
    mov     [ebx].m_dwAddr, eax
    mov     eax, dwType
    mov     [ebx].m_dwType, eax
    movzx   eax, @btOldCode
    mov     byte ptr [ebx].m_btCode, al 
    
    ; 保存断点信息到动态数组中
    invoke  AddItem, g_DbgData.m_vector, @pDbgBP

    ret
SetBP endp

; 还原机器码
ResumeShowCode proc uses ecx ebx dwAddr :DWORD, aryCode :ptr BYTE
    local   @dwVectorSize       :DWORD
    local   @dwIndex            :DWORD
    local   @pDbgBP             :ptr tagDbgBP
    
    mov     @dwVectorSize, 0
    mov     @dwIndex, 0
    mov     @pDbgBP, NULL
    
    invoke  GetVectorSize, g_DbgData.m_vector
    mov     @dwVectorSize, eax
    ; 判断命中哪个断点
    mov     ecx, @dwIndex
    .while  ecx < @dwVectorSize
        invoke  GetItem, g_DbgData.m_vector, addr @pDbgBP, @dwIndex
        mov     ebx, @pDbgBP
        assume  ebx :ptr tagDbgBP
        mov     eax, dwAddr
        .if     [ebx].m_dwAddr == eax
            movzx   eax, [ebx].m_btCode
            mov     ecx, aryCode
            mov     [ecx], al 
            .break
        .endif
        inc     @dwIndex
        mov     ecx, @dwIndex
    .endw
    
    ret
ResumeShowCode endp

; 单步步过
OnCommand_P proc
    local   @dwAddr             :DWORD
    local   @aryCode[16]        :BYTE
    local   @dwReadOrWriteSize  :DWORD
    local   @strAsm[128]        :CHAR
    local   @dwCodeSize         :DWORD
    
    mov     eax, g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionAddress
    mov     @dwAddr, eax
    mov     @dwCodeSize, 0
    mov     @dwReadOrWriteSize, 0
    invoke  RtlZeroMemory, addr @aryCode, sizeof @aryCode
    invoke  RtlZeroMemory, addr @strAsm, sizeof @strAsm
    
    invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwAddr, addr @aryCode, sizeof @aryCode, addr @dwReadOrWriteSize
    invoke  ResumeShowCode, @dwAddr, addr @aryCode
    invoke  Decode2Asm, addr @aryCode, addr @strAsm, addr @dwCodeSize, @dwAddr
    
    ; 判断是否是Call
    invoke  crt_strstr, addr @strAsm, offset g_strAsmCmd_call
    .if     eax != NULL
        ; 在Call命令的下一行设置断点
        mov     eax, @dwAddr
        add     eax, @dwCodeSize
        mov     @dwAddr, eax
        invoke  SetBP, @dwAddr, SETBP_TEMP
    .else
        ; 直接设置单步
        invoke  SetTFAndDecEip, TRUE, 0
        mov     g_bIsSingStepCmd, TRUE
    .endif
    
    ret
OnCommand_P endp

; 单步步入
OnCommand_T proc
    invoke  SetTFAndDecEip, TRUE, 0
    mov     g_bIsSingStepCmd, TRUE
    ret
OnCommand_T endp

; 设置单步
SetTFAndDecEip proc uses ecx bTF :BOOL, dwDecVal :DWORD
    local   @hThread        :HANDLE
    local   @ctx            :CONTEXT
    
    mov     @hThread, NULL
    invoke  RtlZeroMemory, addr @ctx, sizeof @ctx
    
    invoke  OpenThread, THREAD_ALL_ACCESS, FALSE, g_DbgData.m_de.dwThreadId
    mov     @hThread, eax
    mov     @ctx.ContextFlags, CONTEXT_ALL
    invoke  GetThreadContext, @hThread, addr @ctx
    
    mov     eax, @ctx.regEip
    ; mov     ecx, dwDecVal
    sub     eax, dwDecVal
    mov     [@ctx.regEip], eax
    
    ; 判断是否需要设置单步异常
    .if     bTF == TRUE
        mov     eax, @ctx.regFlag
        or      eax, 100h
        mov     @ctx.regFlag, eax
    .endif
    
    invoke  SetThreadContext, @hThread, addr @ctx
    invoke  CloseHandle, @hThread
    ret
SetTFAndDecEip endp

; 修改内存
OnCommand_E_SetMem proc dwAddr :DWORD, pCode :ptr CHAR
    local   @strCode[3]         :CHAR
    local   @bCode              :BYTE
    local   @dwReadOrWriteSize  :DWORD
    local   @dwOldProc          :DWORD
    
    mov     @bCode, 0
    
    mov     eax, pCode
    movzx   eax, byte ptr [eax]
    .while  al != 0
        invoke  SkipMemWhitrChar, pCode
        mov     pCode, eax
        
        invoke  RtlZeroMemory, addr @strCode, sizeof @strCode
        invoke  crt_memcpy, addr @strCode, pCode, 2 
        
        invoke  crt_strtoul, addr @strCode, NULL, 16
        mov     @bCode, al
        
        invoke  VirtualProtectEx, g_DbgData.m_hProc, dwAddr, sizeof @bCode, PAGE_READWRITE, addr @dwOldProc
        invoke  WriteProcessMemory, g_DbgData.m_hProc, dwAddr, addr @bCode, sizeof @bCode, addr @dwReadOrWriteSize
        invoke  VirtualProtectEx, g_DbgData.m_hProc, dwAddr, sizeof @bCode, @dwOldProc, addr @dwOldProc
        
        inc     dwAddr
        
        inc     pCode
        inc     pCode
        mov     eax, pCode
        movzx   eax, byte ptr [eax]
    .endw
    
    ret
OnCommand_E_SetMem endp

; 处理输入的十六进制值
SkipMemWhitrChar proc pStrCode :ptr CHAR
    mov     eax, pStrCode
    movzx   eax, byte ptr [eax]
    .while  al == ' ' || al == 0dh || al == 0ah
        inc     pStrCode
        mov     eax, pStrCode
        movzx   eax, byte ptr [eax]
    .endw
    mov     eax, pStrCode
    ret
SkipMemWhitrChar endp

; 显示内存
OnCommand_DB_ShowMem proc uses ecx edx dwAddr :DWORD, dwSize :DWORD
    local   @aryCode[16]        :BYTE
    local   @byteCode           :DWORD
    local   @wordCode           :DWORD
    local   @dwordCode          :DWORD
    local   @dwReadOrWriteSize  :DWORD
    local   @dwRowCount         :DWORD
    local   @dwAddr             :DWORD
    
    mov     @wordCode, 0
    mov     @dwordCode, 0
    mov     @dwReadOrWriteSize, 0
    mov     @dwRowCount, 1
    mov     eax, dwAddr
    mov     @dwAddr, eax
    
    invoke  RtlZeroMemory, addr @aryCode, sizeof @aryCode
    
    .if     dwSize == 2
        ; dw
        invoke  ReadProcessMemory, g_DbgData.m_hProc, dwAddr, addr @aryCode, 2, addr @dwReadOrWriteSize 
        movzx   eax, word ptr @aryCode
        mov     @wordCode, eax
        
        invoke  crt_printf, offset g_strFmt_DW_show, dwAddr, @wordCode
        ret
    .elseif dwSize == 4
        ; dd
        invoke  ReadProcessMemory, g_DbgData.m_hProc, dwAddr, addr @aryCode, 4, addr @dwReadOrWriteSize 
        mov     eax, dword ptr @aryCode
        mov     @dwordCode, eax
        
        invoke  crt_printf, offset g_strFmt_DW_show, dwAddr, @dwordCode
        ret
    .endif
    
    invoke  crt_printf, offset g_strFmt_DB_addr, @dwAddr
    .while      dwSize > 0
        
        invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwAddr, addr @aryCode, 1, addr @dwReadOrWriteSize
        movzx   eax, byte ptr @aryCode
        mov     @byteCode, eax
        
        invoke  crt_printf, offset g_strFmt_DB_code, @byteCode
        
        ; 换行
        inc     @dwAddr
        mov     eax, @dwRowCount
        mov     ecx, 16
        div     ecx
        .if     edx == 0
            invoke  crt_printf, offset g_strFmt_RN
            .if     dwSize != 1
                invoke  crt_printf, offset g_strFmt_DB_addr, @dwAddr
            .endif
        .endif
        
        dec     dwSize
        inc     @dwRowCount
    .endw
    
    ret
OnCommand_DB_ShowMem endp

; 查看寄存器
OnCommand_R_ShowRegister proc
    local   @dwAddr     :DWORD
    local   @hThread    :HANDLE
    local   @ctx        :CONTEXT
    
    mov     eax, g_DbgData.m_de.u.Exception.pExceptionRecord.ExceptionAddress
    mov     @dwAddr, eax
    invoke  RtlZeroMemory, addr @ctx, sizeof @ctx
    
    mov     ecx, g_DbgData.m_de.dwThreadId
    invoke  OpenThread, THREAD_ALL_ACCESS, FALSE, g_DbgData.m_de.dwThreadId
    mov     @hThread, eax
    
    mov     @ctx.ContextFlags, CONTEXT_ALL
    invoke  GetThreadContext, @hThread, addr @ctx
    
    invoke crt_printf, offset g_strFmt_R_show1, @ctx.regEax, @ctx.regEbx, @ctx.regEcx, @ctx.regEdx, @ctx.regEsi, @ctx.regEdi
    invoke crt_printf, offset g_strFmt_R_show2, @ctx.regEip, @ctx.regEsp, @ctx.regEbp
    invoke crt_printf, offset g_strFmt_R_show3, @ctx.regCs, @ctx.regSs, @ctx.regDs, @ctx.regEs, @ctx.regFs, @ctx.regGs, @ctx.regFlag
    
    invoke  CloseHandle, @hThread
    invoke  OnCommand_U, @dwAddr, 1
    
    mov     eax, TRUE
    ret
OnCommand_R_ShowRegister endp

; 修改寄存器
OnCommand_R_SetRegister proc pCmd :ptr CHAR
    local   @pAddr      :ptr CHAR
    local   @dwAddr     :DWORD
    local   @hThread    :HANDLE
    local   @ctx        :CONTEXT

    mov     @pAddr, NULL
    mov     @dwAddr, 0
    mov     @hThread, NULL
    
    invoke  RtlZeroMemory, addr @ctx, sizeof @ctx

    ; 解析地址
    mov     eax, pCmd
    add     eax, 3
    mov     @pAddr, eax
    invoke  SkipWhiteChar, @pAddr
    mov     @pAddr, eax
    invoke  crt_strtoul, @pAddr, NULL, dword ptr 16
    mov     @dwAddr, eax
    
    invoke  OpenThread, THREAD_ALL_ACCESS, FALSE, g_DbgData.m_de.dwThreadId
    mov     @hThread, eax
    mov     @ctx.ContextFlags, CONTEXT_ALL
    invoke  GetThreadContext, @hThread, addr @ctx
    
    ; eax
    invoke  crt_strstr, pCmd, offset g_strRegCmd_eax
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEax, eax
    .endif
    
    ; ebx
    invoke  crt_strstr, pCmd, offset g_strRegCmd_ebx
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEbx, eax
    .endif
    
    ; ecx
    invoke  crt_strstr, pCmd, offset g_strRegCmd_ecx
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEcx, eax
    .endif
    
    ; edx
    invoke  crt_strstr, pCmd, offset g_strRegCmd_edx
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEdx, eax
    .endif
    
    ; esi
    invoke  crt_strstr, pCmd, offset g_strRegCmd_esi
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEsi, eax
    .endif
    
    ; edi
    invoke  crt_strstr, pCmd, offset g_strRegCmd_edi
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEdi, eax
    .endif
    
    ; eip
    invoke  crt_strstr, pCmd, offset g_strRegCmd_eip
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEip, eax
    .endif
    
    ; esp
    invoke  crt_strstr, pCmd, offset g_strRegCmd_esp
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEsp, eax
    .endif
    
    ; ebp
    invoke  crt_strstr, pCmd, offset g_strRegCmd_ebp
    .if     eax  != NULL
        mov     eax, @dwAddr
        mov     @ctx.regEbp, eax
    .endif
    
    invoke  SetThreadContext, @hThread, addr @ctx
    invoke  CloseHandle, @hThread
    mov     eax, TRUE
    ret
OnCommand_R_SetRegister endp

; 跳过空白字符
SkipWhiteChar proc pCommand :ptr CHAR
    .while  TRUE
        mov     eax, pCommand
        movzx   eax, byte ptr [eax]
        .if     al == ' '
            inc     pCommand
            .continue
        ; .elseif al == '\t'
        .elseif al == 09h
            inc     pCommand
            .continue
        .else
            .break
        .endif
    .endw
    mov     eax, pCommand
    ret
SkipWhiteChar endp

; 处理 U 命令事件
OnCommand_U proc uses ecx dwAddr :DWORD, dwShowCount :DWORD
    local   @szAsmBuff[16]  :BYTE       ; 读取缓冲区
    local   @strAsmCode[128]:BYTE       ; 得到的反汇编指令信息
    local   @dwReadOrWrite  :DWORD      ; 读取的字节
    local   @dwReadAddr     :DWORD      ; 读取地址
    local   @dwCount        :DWORD      ; 循环次数
    local   @dwCodeSize     :UINT       ; 解析指令长度
    local   @bHasJmp        :BOOL       ; 是否包含jmp
    local   @bHasCall       :BOOL       ; 是否包含call
    local   @pCmd           :ptr CHAR   ; 指针，处理反汇编信息
    local   @dwAsmIATAddr   :DWORD      ; jmp或call之后的地址
    local   @strAPIName     :ptr CHAR   ; API名称
    local   @strShowApiName[MAXBYTE]:ptr CHAR
    
    local   @strOpcode[64]  :BYTE
    invoke  RtlZeroMemory, addr @strOpcode, sizeof @strOpcode
    invoke  RtlZeroMemory, addr @strShowApiName, sizeof @strShowApiName
    
    ; 初始化
    invoke  RtlZeroMemory, addr @szAsmBuff, 16
    invoke  RtlZeroMemory, addr @strAsmCode, 128
    mov     @dwReadOrWrite, 0
    mov     eax, dwShowCount
    mov     @dwCount, eax
    mov     @dwCodeSize, 0
    mov     @bHasJmp, FALSE
    mov     @bHasCall, FALSE
    mov     @pCmd, NULL
    mov     @dwAsmIATAddr, 0
    mov     @strAPIName, NULL
        
    mov     eax, dwAddr
    mov     @dwReadAddr, eax
    
    ; 循环指令
    .while  @dwCount > 0
        ; 读取内存
        invoke  ReadProcessMemory, g_DbgData.m_hProc, @dwReadAddr, addr @szAsmBuff, sizeof @szAsmBuff, addr @dwReadOrWrite
        invoke  ResumeShowCode, @dwReadAddr, addr @szAsmBuff
        ; 解析指令
        invoke  Decode2AsmOpcode, addr @szAsmBuff, addr @strAsmCode, addr @strOpcode, addr @dwCodeSize, @dwReadAddr
        
        ; 判断是否为 call 或 jmp
        invoke  crt_strstr, addr @strAsmCode, offset g_strAsmCmd_jmp
        mov     @bHasJmp, eax
        invoke  crt_strstr, addr @strAsmCode, offset g_strAsmCmd_call
        mov     @bHasCall, eax
        
        .if     @bHasJmp == NULL && @bHasCall == NULL
            ; 直接打印
            invoke  crt_printf, offset g_strFmt_U, @dwReadAddr, addr @strAsmCode
        .elseif
            .if     @bHasJmp != NULL
                mov     eax, @dwCodeSize
                sub     eax, 4
                mov     ecx, 2
                mul     ecx
                lea     ecx, @strOpcode
                add     ecx, eax
                mov     @pCmd, ecx
            .else
                ; call
                lea     eax, @strAsmCode
                add     eax, 5
                mov     @pCmd, eax
            .endif
            
            ; 解析地址
            invoke  crt_strtoul, @pCmd, NULL, dword ptr 16
            mov     @dwAsmIATAddr, eax
            
            .if     @bHasJmp != NULL
                invoke  TransLittleToBig, @dwAsmIATAddr
                mov     @dwAsmIATAddr, eax 
            .endif
            
            invoke  GetASMApiName, @dwAsmIATAddr, addr @strShowApiName
            mov     @strAPIName, eax
            .if     @strAPIName == NULL
                invoke  crt_printf, offset g_strFmt_U, @dwReadAddr, addr @strAsmCode
            .else                
                invoke  crt_printf, offset g_strFmt_U_API, @dwReadAddr, addr @strAsmCode, addr @strShowApiName
            .endif
        .endif 
        
        mov     eax, @dwCodeSize
        add     @dwReadAddr, eax
        dec     @dwCount
    .endw

    ret
OnCommand_U endp

; 获取API名称
GetASMApiName proc uses ecx dwAddr :DWORD, strShowApiName :ptr CHAR
    local   @hFileHandle        :HANDLE
    local   @dwReadOrWriteSize  :DWORD
    local   @dwNewFilePointer   :LARGE_INTEGER
    local   @dosHeader          :IMAGE_DOS_HEADER
    local   @ntHeader           :IMAGE_NT_HEADERS
    local   @optionalHeader     :IMAGE_OPTIONAL_HEADER
    local   @dwImportRva        :DWORD
    local   @dwImportFa         :DWORD
    local   @dwImportVa         :DWORD
    local   @iat                :IMAGE_IMPORT_DESCRIPTOR
    local   @iat_empty          :IMAGE_IMPORT_DESCRIPTOR
    local   @dwIATReadOffset    :DWORD
    local   @dwApiRva           :DWORD
    local   @dwApiNameRva       :DWORD
    local   @dwApiNameFa        :DWORD
    local   @dwApiNameVa        :DWORD
    local   @dwFuncTable        :DWORD
    local   @strOpcode[64]      :BYTE
    local   @pCmd               :ptr CHAR
    local   @strAsmCode[128]    :BYTE       ; 得到的反汇编指令信息
    local   @dwCodeSize         :UINT       ; 解析指令长度
    local   @dwAsmIATAddr       :DWORD 
    local   @dwElseAddr         :DWORD
    local   @bHasJmp            :BOOL 
    local   @bHasCall           :BOOL
    local   @szAsmBuff[16]      :BYTE       ; 读取缓冲区
    local   @dwReadOrWrite      :DWORD      ; 读取的字节
    
    mov     @hFileHandle, NULL
    mov     @dwReadOrWriteSize, 0
    mov     @dwImportRva, 0
    mov     @dwImportFa, 0
    mov     @dwImportVa, 0
    mov     @dwApiRva, 0
    mov     @dwApiNameRva, 0
    mov     @dwApiNameFa, 0
    mov     @dwApiNameVa, 0
    mov     @dwFuncTable, 0
    mov     @dwCodeSize, 0
    mov     @pCmd, 0
    mov     @dwAsmIATAddr, 0
    mov     @dwElseAddr, 0
    mov     @bHasJmp, FALSE
    mov     @bHasCall, FALSE
    mov     @dwReadOrWrite, 0
    
    invoke  RtlZeroMemory, addr @strAsmCode, 128
    invoke  RtlZeroMemory, addr @strOpcode, sizeof @strOpcode
    invoke  RtlZeroMemory, addr @szAsmBuff, 16
    
    invoke  RtlZeroMemory, addr @dwNewFilePointer, sizeof @dwNewFilePointer
    invoke  RtlZeroMemory, addr @dosHeader, sizeof @dosHeader
    invoke  RtlZeroMemory, addr @ntHeader, sizeof @ntHeader
    invoke  RtlZeroMemory, addr @iat_empty, sizeof @iat_empty
    
    invoke  ReadProcessMemory, g_DbgData.m_hProc, dwAddr, addr @szAsmBuff, sizeof @szAsmBuff, addr @dwReadOrWrite 
    ; 解析指令
    invoke  Decode2AsmOpcode, addr @szAsmBuff, addr @strAsmCode, addr @strOpcode, addr @dwCodeSize, dwAddr
    ; 判断是否为 call 或 jmp
    invoke  crt_strstr, addr @strAsmCode, offset g_strAsmCmd_jmp
    mov     @bHasJmp, eax
    invoke  crt_strstr, addr @strAsmCode, offset g_strAsmCmd_call
    mov     @bHasCall, eax
            
    .if     @bHasJmp == NULL
                        ;    && @bHasCall == NULL
    .else
        mov     eax, @dwCodeSize
        sub     eax, 4
        mov     ecx, 2
        mul     ecx
        lea     ecx, @strOpcode
        add     ecx, eax
        mov     @pCmd, ecx
        
        ; 解析地址
        invoke  crt_strtoul, @pCmd, NULL, dword ptr 16
        mov     @dwAsmIATAddr, eax
        
        invoke  TransLittleToBig, @dwAsmIATAddr
        mov     @dwAsmIATAddr, eax 
    .endif
    
    ; 读文件
    invoke  CreateFile, offset g_strTestExe, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov     @hFileHandle, eax
    .if     @hFileHandle == INVALID_HANDLE_VALUE
        mov     eax, NULL
        ret
    .endif

    ; 地址转RVA
    invoke  TransVaToRva, @hFileHandle, dwAddr, addr @dwApiRva
    invoke  TransVaToRva, @hFileHandle, @dwAsmIATAddr, addr @dwElseAddr

    invoke  ReadFile, @hFileHandle, addr @dosHeader, sizeof @dosHeader, addr @dwReadOrWriteSize, NULL
    invoke  SetFilePointer, @hFileHandle, @dosHeader.e_lfanew, NULL, FILE_BEGIN
    ; invoke  SetFilePointer, @hFileHandle, @dosHeader.e_lfanew, addr @dwNewFilePointer, FILE_BEGIN
    invoke  ReadFile, @hFileHandle, addr @ntHeader, sizeof @ntHeader, addr @dwReadOrWriteSize, NULL
    
    ; 获取导入表
    lea     eax, @ntHeader.OptionalHeader.DataDirectory
    add     eax, 8
    assume  eax : ptr IMAGE_DATA_DIRECTORY
    mov     ecx, [eax].VirtualAddress
    mov     @dwImportRva, ecx
    
    invoke  TransRvaToFa, @hFileHandle, @dwImportRva, addr @dwImportFa, addr @dwImportVa
    invoke  SetFilePointer, @hFileHandle, @dwImportFa, NULL, FILE_BEGIN
    
    .while  TRUE
        invoke  RtlZeroMemory, addr @iat, sizeof @iat
        invoke  ReadFile, @hFileHandle, addr @iat, sizeof @iat, addr @dwReadOrWriteSize, NULL
        
        invoke  crt_memcmp, addr @iat, addr @iat_empty, sizeof @iat
        .if     eax == 0
            ; 空表，遍历结束
            .break;
        .endif
        
        ; 保存当前文件指针位置
        invoke  SetFilePointer, @hFileHandle, 0, NULL, FILE_CURRENT
        mov     @dwIATReadOffset, eax
        
        ; 判断是否命中API地址
        mov     eax, @iat.FirstThunk
        .if     @dwApiRva == eax || @dwElseAddr == eax
            ; 直接命中
            mov     eax, @iat.OriginalFirstThunk
            mov     @dwApiNameRva, eax
            
            invoke  TransRvaToFa, @hFileHandle, @dwApiNameRva, addr @dwApiNameFa, addr @dwApiNameVa
            invoke  SetFilePointer, @hFileHandle, @dwApiNameFa, NULL, FILE_BEGIN
            invoke  ReadFile, @hFileHandle, addr @dwFuncTable, sizeof @dwFuncTable, addr @dwReadOrWriteSize, NULL
            invoke  TransRvaToFa, @hFileHandle, @dwFuncTable, addr @dwApiNameFa, addr @dwApiNameVa

            mov     eax, @dwApiNameFa
            add     eax, 2
            mov     @dwApiNameFa, eax
            
            invoke  SetFilePointer, @hFileHandle, @dwApiNameFa, NULL, FILE_BEGIN
            invoke  ReadFile, @hFileHandle, strShowApiName, MAXBYTE, addr @dwReadOrWriteSize, NULL
            
            invoke  CloseHandle, @hFileHandle
            mov     eax, @dwApiNameVa
            ret
        .else    
            
            
        .endif
        
        ; 还原文件指针
        invoke  SetFilePointer, @hFileHandle, @dwIATReadOffset, NULL, FILE_BEGIN
    .endw
    
    invoke  CloseHandle, @hFileHandle
    mov     eax, NULL
    ret
GetASMApiName endp

; Rva To Fa
TransRvaToFa proc uses ecx edx ebx file :HANDLE, dwRva :DWORD, dwFa :ptr DWORD, dwVa :ptr DWORD
    local   @dwReadOrWriteSize      :DWORD
    local   @dwSaveFileOffset       :DWORD
    local   @bIsHit                 :BOOL
    local   @dwPosition             :DWORD
    local   @dwPostionNt            :DWORD
    local   @dosHeader              :IMAGE_DOS_HEADER
    local   @ntHeader               :IMAGE_NT_HEADERS
    local   @pSection               :ptr IMAGE_SECTION_HEADER
    local   @dwNeedSpace            :DWORD  ; 申请空间大小
    local   @dwRvaDiff              :DWORD  ; Rva差值
    local   @dwRvaSizeOfHeaders     :DWORD  
    local   @i                      :DWORD
    local   @dwRvaAddressBegin      :DWORD
    local   @dwRvaAddressEnd        :DWORD
    
    local   @dwNumberOfSection      :DWORD  ; 节数量
    local   @dwImageBase            :DWORD  ; ImageBase
    local   @dwFileAlignment        :DWORD  ; 文件对齐值
    local   @dwSectionAlignment     :DWORD  ; 内存对齐值
    local   @dwSizeOfHeader         :DWORD  ; 头大小

    mov     @dwReadOrWriteSize, 0
    mov     @dwSaveFileOffset, 0
    mov     @bIsHit, FALSE
    mov     @dwPosition, 0
    mov     @dwPostionNt, 0
    invoke  RtlZeroMemory, addr @dosHeader, sizeof @dosHeader
    invoke  RtlZeroMemory, addr @ntHeader, sizeof @ntHeader
    mov     @pSection, 0
    mov     @dwNeedSpace, 0
    mov     @dwRvaDiff, 0
    mov     @dwRvaSizeOfHeaders, 0
    
    mov     @dwNumberOfSection, 0
    mov     @dwImageBase, 0
    mov     @dwFileAlignment, 0
    mov     @dwSectionAlignment, 0
    mov     @dwSizeOfHeader, 0
    
    ; 保存当前文件指针
    invoke  SetFilePointer, file, 0, NULL, FILE_CURRENT
    mov     @dwSaveFileOffset, eax
    ; 移动文件指针到头部
    invoke  SetFilePointer, file, 0, NULL, FILE_BEGIN
    invoke  ReadFile, file, addr @dosHeader, sizeof @dosHeader, addr @dwReadOrWriteSize, NULL
    invoke  SetFilePointer, file, @dosHeader.e_lfanew, NULL, FILE_BEGIN
    invoke  SetFilePointer, file, 0, NULL, FILE_CURRENT
    mov     @dwPostionNt, eax
    invoke  ReadFile, file, addr @ntHeader, sizeof @ntHeader, NULL, FILE_BEGIN
    
    movzx   eax, @ntHeader.FileHeader.NumberOfSections
    mov     @dwNumberOfSection, eax
    mov     eax, @ntHeader.OptionalHeader.ImageBase
    mov     @dwImageBase, eax
    mov     eax, @ntHeader.OptionalHeader.FileAlignment 
    mov     @dwFileAlignment, eax
    mov     eax, @ntHeader.OptionalHeader.SectionAlignment 
    mov     @dwSectionAlignment, eax
    mov     eax, @ntHeader.OptionalHeader.SizeOfHeaders 
    mov     @dwSizeOfHeader, eax

    mov     eax, @dwNumberOfSection
    mov     ecx, sizeof IMAGE_SECTION_HEADER
    mul     ecx
    mov     @dwNeedSpace, eax
    invoke  crt_malloc, @dwNeedSpace
    mov     @pSection, eax
    ; check
    
    invoke  RtlZeroMemory, @pSection, @dwNeedSpace
    mov     eax, @dwPostionNt
    movzx   ecx, @ntHeader.FileHeader.SizeOfOptionalHeader
    add     eax, ecx
    add     eax, 18h
    mov     @dwPosition, eax
    
    invoke  SetFilePointer, file, @dwPosition, NULL, FILE_BEGIN
    invoke  ReadFile, file, @pSection, @dwNeedSpace, addr @dwReadOrWriteSize, NULL
    
    mov     eax, dwRva
    add     eax, @dwImageBase
    mov     ecx, dwVa
    mov     [ecx], eax
    
    ; 判断是否命中头部
    mov     edx, 0
    mov     eax, @dwSizeOfHeader
    div     @dwSectionAlignment
    .if     edx > 0
        inc     eax
    .endif
    mul     @dwSectionAlignment
    mov     @dwRvaSizeOfHeaders, eax
    .if     dwRva < eax
        mov     @bIsHit, TRUE
        mov     eax, dwRva
        mov     @dwRvaDiff, eax
        
        mov     eax, dwRva
        mov     ecx, dwFa
        mov     [ecx], eax
    .endif
    
    .if     !@bIsHit
        mov     @i, 0
        mov     eax, @dwNumberOfSection
        .while  @i < eax
            mov     eax, @i
            mov     ecx, sizeof IMAGE_SECTION_HEADER
            mul     ecx
            mov     ecx, @pSection
            add     eax, ecx
            mov     ebx, eax
            assume  ebx :ptr IMAGE_SECTION_HEADER
            mov     eax, [ebx].VirtualAddress
            mov     @dwRvaAddressBegin, eax
            mov     edx, 0
            mov     eax, @dwRvaAddressBegin
            add     eax, [ebx].Misc.VirtualSize
            div     @dwSectionAlignment
            .if     edx > 0
                inc     eax
            .endif
            mul     @dwSectionAlignment
            mov     @dwRvaAddressEnd, eax
        
            ; 判断是否命中节
            mov     eax, @dwRvaAddressBegin
            mov     ecx, @dwRvaAddressEnd
            .if     dwRva >= eax && dwRva < ecx
                mov     eax, dwRva
                sub     eax, @dwRvaAddressBegin
                mov     @dwRvaDiff, eax
                
                mov     eax, [ebx].PointerToRawData
                add     eax, @dwRvaDiff
                mov     ecx, dwFa
                mov     [ecx], eax
                
                mov     @bIsHit, TRUE
                .break
            .endif
        
            mov     eax, @dwNumberOfSection
            inc     @i
        .endw
    .endif
    
    .if     !@bIsHit
        invoke      SetFilePointer, file, @dwSaveFileOffset, NULL, FILE_BEGIN
        invoke      crt_free, @pSection
        mov         eax, FALSE
        ret
    .endif
    
    invoke      SetFilePointer, file, @dwSaveFileOffset, NULL, FILE_BEGIN
    invoke      crt_free, @pSection
    mov         eax, TRUE
    ret
TransRvaToFa endp

; Va to Rva
TransVaToRva proc uses ecx edx ebx file :HANDLE, dwVa :DWORD, dwRva :ptr DWORD
    local   @dwReadOrWriteSize      :DWORD
    local   @dwSaveFileOffset       :DWORD
    local   @dwPostionNt            :DWORD
    local   @dosHeader              :IMAGE_DOS_HEADER
    local   @ntHeader               :IMAGE_NT_HEADERS

    mov     @dwReadOrWriteSize, 0
    mov     @dwSaveFileOffset, 0
    mov     @dwPostionNt, 0
    invoke  RtlZeroMemory, addr @dosHeader, sizeof @dosHeader
    invoke  RtlZeroMemory, addr @ntHeader, sizeof @ntHeader
    
    ; 保存当前文件指针
    invoke  SetFilePointer, file, 0, NULL, FILE_CURRENT
    mov     @dwSaveFileOffset, eax
    ; 移动文件指针到头部
    invoke  SetFilePointer, file, 0, NULL, FILE_BEGIN
    invoke  ReadFile, file, addr @dosHeader, sizeof @dosHeader, addr @dwReadOrWriteSize, NULL
    invoke  SetFilePointer, file, @dosHeader.e_lfanew, NULL, FILE_BEGIN
    invoke  SetFilePointer, file, 0, NULL, FILE_CURRENT
    mov     @dwPostionNt, eax
    invoke  ReadFile, file, addr @ntHeader, sizeof @ntHeader, NULL, FILE_BEGIN
    
    mov     ecx, @ntHeader.OptionalHeader.ImageBase
    mov     eax, [dwVa]
    sub     eax, ecx
    
    mov     ecx, dwRva
    mov     [ecx], eax
    
    invoke      SetFilePointer, file, @dwSaveFileOffset, NULL, FILE_BEGIN
    mov         eax, TRUE
    ret
TransVaToRva endp

; 小尾转大尾
TransLittleToBig proc uses ebx esi edi dwLe :DWORD
    mov     eax, dword ptr [dwLe]   
    and     eax, 0FFh  
    shl     eax, 18h  
    mov     ecx, dword ptr [dwLe]   
    and     ecx, 0FF00h  
    shl     ecx, 8  
    or      eax, ecx  
    mov     edx, dword ptr [dwLe]  
    and     edx, 0FF0000h  
    sar     edx, 8  
    or      eax, edx  
    mov     ecx, dword ptr [dwLe]  
    sar     ecx, 18h  
    and     ecx, 0FFh  
    or      eax, ecx  
    ret
TransLittleToBig endp

Exit_Process proc
    invoke  DeleteVector, g_DbgData.m_vector
    invoke  ExitProcess,0
    
    ret
Exit_Process endp

main proc
    ; 入口
    invoke  OpenDebugFile, offset g_strTestExe
    
    invoke  NewVector
    mov     g_DbgData.m_vector, eax
    
    invoke  RunDebugLoop
    
    mov     eax, 0
    ret
main endp
    
end main