# Get-RpcServerData
This cmdlet can be used to gather RPC server data information for a RPC interface. This should be used **before** invoking the fuzzer.
It will output a json file: rpcSererData.json, which can be parsed to `Invoke-RPCFuzzer`, which can be parsed to `Import-DataToNeo4j`.

## Usage
```
NAME
    Get-RpcServerData

SYNTAX
    Get-RpcServerData [[-RpcServer] <RpcServer>] [[-target] <string>] [[-DbgHelpPath] <string>] [[-OutPath] <string>] [<CommonParameters>] [[-getParameters]

OPTIONS
    -RpcServer              A NtCoreLib.Win32.Rpc.Server.RpcServer object from Get-RpcServer (can also be piped)
    -Target                 A path to a specific .dll or .exe or directory containing dll's and executables
    -DbgHelpPath            The path to dbghelp.dll for symbols
    -OutPath                The path to export the gathered information to json files
    -getParameters          Switch for collecting parameters as well
```

## Examples
Target a specific executable
```powershell
Get-RpcServerData -target "C:\Windows\system32\spoolsv.exe" -OutPath .\output\
[+] dbghelp.dll successfully initialized
[+] Getting RPC interfaces'
[+] Getting RPC Interfaces and Endpoints for specified target C:\Windows\system32\spoolsv.exe
[+] Found 5 RPC Interface(s)
[+] Saved RPC interfaces and Endpoints of target to 'rpcServerData.json'
[+] To Fuzz please run '.\rpcServerData.json' | Invoke-RpcFuzzer -other -options'
```

Target a specific directory, gets all executables and DLLs from the specified directory
```powershell
Get-RpcServerData -target "C:\Users\testuser\Documents\" -OutPath .\output\
[+] dbghelp.dll successfully initialized
[+] Getting RPC interfaces'
[+] Getting RPC Interfaces and Endpoints for specified target C:\Users\testuser\Documents\
[+] Found 6 RPC Interface(s)
[+] Saved RPC interfaces and Endpoints of target to 'rpcServerData.json'
[+] To Fuzz please run '.\rpcServerData.json' | Invoke-RpcFuzzer -other -options'
```

Pipe a NtCoreLib.Win32.Rpc.Server.RpcServer object from Get-RpcServer
```powershell
$rpcint | get-RpcServerData -OutPath .\output\
[+] dbghelp.dll successfully initialized
[+] Getting RPC interfaces'
[+] Found 5 RPC Interface(s)
[+] Saved RPC interfaces and Endpoints of target to 'rpcServerData.json'
[+] To Fuzz please run '.\rpcServerData.json' | Invoke-RpcFuzzer -other -options'
```

Pipe a NtCoreLib.Win32.Rpc.Server.RpcServer object from Get-RpcServer and also gather the parameters
```powershell
$rpcint | get-RpcServerData -OutPath .\output\ -getParameters
[+] dbghelp.dll successfully initialized
[+] Getting RPC interfaces'
[+] Found 5 RPC Interface(s)
[+] Saved RPC interfaces and Endpoints of target to 'rpcServerData.json'
[+] To Fuzz please run '.\rpcServerData.json' | Invoke-RpcFuzzer -other -options'
```