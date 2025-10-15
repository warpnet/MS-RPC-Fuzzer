#  Copyright 2025 Remco van der Meer. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

<#
.SYNOPSIS
Get RPC server data
.DESCRIPTION
This cmdlet gets the RPC interfaces and available endpoints and stores it in a JSON file that can be parsed to Invoke-Fuzzer
.PARAMETER Target
Specify the RPC Server as target
.PARAMETER RpcServer
Specify the target through pipe
.INPUTS
NtCoreLib.Win32.Rpc.Server.RpcServer[]
.OUTPUTS
JSON file
.EXAMPLE
$rpcint | Get-RpcServerData -OutPath .\output\
Get's data for the parsed RPC server
#>
function Get-RpcServerData {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$false)]
        [NtCoreLib.Win32.Rpc.Server.RpcServer]$RpcServer,
        [Parameter(Mandatory=$false)]
        [string]$target,
        [string]$DbgHelpPath,
        [Parameter(Mandatory=$true)]
        [string]$OutPath,
        [switch]$getParameters,
        [switch]$RemotelyAccessibleOnly
    )
    begin {
        # Initialize DbgHelp DLL
        if (Test-Path "$env:systemdrive\Program Files (x86)\Windows Kits\10\Debuggers\x64\dbghelp.dll") {
            Set-GlobalSymbolResolver -DbgHelpPath "$env:systemdrive\Program Files (x86)\Windows Kits\10\Debuggers\x64\dbghelp.dll"   
            Write-Host "[+] dbghelp.dll successfully initialized" -ForegroundColor Green
        } else {
            if ($DbgHelpPath) {
                try {
                    Set-GlobalSymbolResolver -DbgHelpPath $DbgHelpPath    
                    Write-Host "[+] dbghelp.dll successfully initialized" -ForegroundColor Green
                } catch {
                    Write-host "[!] dbghelp.dll not found, please provide path using -DbgHelpPath" -ForegroundColor Red
                    break
                }
            } else {
                $continueWithoutDbgPath = Read-Host "[!] Could not find dbghelp.dll, continue? [Y/n] > "
                if ($continueWithoutDbgPath -eq 'n') {
                    break
                }
            }
        }

        # Check if $outPath exists, if not make the directory
        if (-Not (Test-Path $OutPath)) {
            # Creating Path
            New-Item -ItemType Directory -Path $OutPath
        }

        Write-Host "[+] Getting RPC interfaces" -ForegroundColor Green

        # First check if the user specified the -target parameter
        $rpcInterfaces = @()
        if ($target) {
            # User specified target, we should check if the path is a directory or a single file
            if (Test-Path $target) {
                $item = Get-Item $target
                try {
                    if ($item.PSIsContainer) {
                        # Target is a directory, get all executables and dll's from it
                        $rpcInterfaces = ls "$target\*" -Include "*.dll","*.exe" | Get-RpcServer -ErrorAction stop
                    } else {
                        $rpcInterfaces = "$target" | Get-RpcServer -ErrorAction stop
                    }
                    Write-Host "[+] Getting RPC Interfaces, Endpoints and Procedures for specified target $target" -ForegroundColor Green
                } catch {
                    if ($_ -match "ParsePeFile") {
                        $withoutSymbols = Read-Host "[!] Could not find Symbol file for target, continue without symbols? [Y/n] > "
                        if ($withoutSymbols -ne "n") {
                            $rpcInterfaces = $target | Get-RpcServer -IgnoreSymbols
                        }
                    }
                }
            } else {
                Write-Host "[!] The specified target path does not exist." -ForegroundColor Red
                return
            }
        }
    }

    # Check if the user piped a NtCoreLib.Win32.Rpc.Server.RpcServer object instead, and add each interface to the list
    process {
        if ($RpcServer) {
            $rpcInterfaces += $RpcServer
        }
    }

    end {
        # First check if the rpcInterfaces list is not empty
        if ($rpcInterfaces.Count -lt 1) {
            if (-Not ($target)) {
                Write-Host "[+] User did not specify a target, getting all Windows built-in RPC Interfaces and Endpoints, this may take a while on first run" -ForegroundColor DarkYellow
                Write-Host "[i] If it takes long please check if Windows asks to install DirectPlay, you can cancel or install the prompt" -ForegroundColor Blue
                $rpcInterfaces = ls "$env:systemdrive\Windows\system32\*" -Include "*.dll","*.exe" | Get-RpcServer
            } else {
                Write-Host "[!] Could not find any RPC interfaces for specified target" -ForegroundColor Red
                return
            }
        }
        Write-Host "[+] Found $($rpcInterfaces.Count) RPC Interface(s)" -ForegroundColor Yellow

        # Initialize a hashtable to hold the data for export (server name as the key)
        $serverData = @{}

        # Loop through each rpcInterface and gather data
        foreach ($rpcInt in $rpcInterfaces) {
            # Get the RPC server file path
            $rpcServerName = $rpcInt.FilePath

            # Get all available endpoints
            $endpoints = @()
            $endpoints += $rpcInt | Where-Object { $_.Endpoints } | ForEach-Object { $_.Endpoints } | Select-String "ncacn_np" | ForEach-Object { $_ -replace '.*ncacn_np:', 'ncacn_np:' }
            $endpoints += $rpcInt | Where-Object { $_.Endpoints } | ForEach-Object { $_.Endpoints } | Select-String "ncalrpc" | ForEach-Object { $_ -replace '.*ncalrpc:', 'ncalrpc:' }
            $endpoints += $rpcInt | Where-Object { $_.Endpoints } | ForEach-Object { $_.Endpoints } | Select-String "ncacn_ip_tcp" | ForEach-Object { $_ -replace '.*ncacn_ip_tcp:', 'ncacn_ip_tcp:' }

            # If no endpoints found, try getting them using -FindAlpcPort bruteforce method
            if (-Not $endpoints) {
                $endpoints = (Get-RpcEndpoint -InterfaceId $rpcInt.InterfaceId -FindAlpcPort -InterfaceVersion ($rpcInt.InterfaceVersion.Major.ToString() + "." + $rpcInt.InterfaceVersion.Minor.ToString())).BindingString
                if (-Not $endpoints) {
                    $endpoints = "no-endpoint-found"
                }
            }

            if ($getParameters) {
                # User wants to collect parameters as well
                Get-RpcParameters -RpcServer $rpcInt -DbgHelpPath $DbgHelpPath -OutPath $OutPath
            }

            # Get all methods for rpcinterface
            $client = Get-RpcClient $rpcInt -ErrorAction SilentlyContinue
            
            if ($client) {
                $methods = $Client.GetType().GetMethods() | Where-Object { $_.IsPublic -and $_.DeclaringType -eq $Client.GetType() } -ErrorAction SilentlyContinue
            }

            # Get all procedures and their definitions
            $procedures = $client | gm -ErrorAction SilentlyContinue
            $procDef = $procedures.Definition

            # Initialize an array to store the stringbindings for each endpoint
            $stringBindings = @()
            $interfaceProcedures = @()

            # Loop over each endpoint to create a client and gather the stringbindings
            foreach ($endpoint in $endpoints) {
                try {
                    $client = Get-RpcClient $rpcInt
                    
                    # Check if it's a 'ncacn_ip_tcp' endpoint and try to connect
                    if ($endpoint -match 'ncacn_ip_tcp') {
                        $stringBindings += $endpoint
                    }
                    
                    # Check if it's a 'ncacn_np' endpoint and try to connect
                    if ($endpoint -match 'ncacn_np') {
                        try {
                            $stringbinding = $endpoint | ForEach-Object { $_ -replace "^(ncacn_np:)\[", '${1}127.0.0.1[' }
                            Connect-RpcClient $client -stringBinding $stringbinding
                            $stringBindings += $stringbinding
                        } catch {
                            # Handle connection issues
                            Write-Verbose "[!] Could not connect to RPC client for endpoint: $endpoint"
                        }
                    } elseif ($endpoint -eq "no-endpoint-found" -or $RemotelyAccessibleOnly) {
                        # Still no endpoint found but the mode is remote? Then just see if we can connect to it using random named pipes (works for example with PetitPotam)
                        $pipeNames = (Get-ChildItem \\.\pipe\) | Where-Object { $_.Name -match '^[a-zA-Z0-9_]+$' } | Select-Object -ExpandProperty Name

                        foreach ($name in $pipeNames | Where-Object { $_ -ne "MGMTAPI" }) {
                            try {
                                $StringBinding = "ncacn_np:127.0.0.1[\\pipe\\$name]"
                                Connect-RpcClient $client `
                                    -StringBinding $StringBinding `
                                    -AuthenticationLevel PacketPrivacy `
                                    -AuthenticationType WinNT `
                                    -ErrorAction Stop
                                    # No error? Connected!

                                if ($client.Connected) {
                                    if ($stringBindings -notcontains $stringbinding) {
                                        $stringBindings += $stringbinding
                                    }
                                    break
                                }
                            } catch {
                                # Silently continue
                            }
                        }
                    } else {
                        # For other types of endpoints, use the stringBinding directly
                        Connect-RpcClient $client -stringBinding $endpoint
                        if ($client.ProtocolSequence -eq "ncacn_ip_tcp") {
                            $tempstringbinding = $endpoint
                        } else {
                            $tempstringbinding = $client.ProtocolSequence + ":[$($client.Endpoint)]" 
                        }
                        $stringbinding = $tempstringbinding.Replace("\RPC Control\","")
                        $stringBindings += $stringbinding
                    }
                } catch {
                    Write-Verbose "[!] Could not connect as client to $($rpcInt.Name) with endpoint: $($endpoint)"
                }
            }

            if (-Not ($StringBindings)) {
                Write-Verbose "[!] Could not find any endpoints for RPC server $($rpcInt.Name), still exporting procedures, but unable to fuzz"
            }

            # If the server name doesn't exist in the hashtable, initialize it as an empty array
            if (-not $serverData.ContainsKey($rpcServerName)) {
                $serverData[$rpcServerName] = @()
            }

            # Add the interface data under the server name
            try {
                $serverData[$rpcServerName] += [PSCustomObject]@{
                InterfaceId   = $rpcInt.InterfaceId
                StringBindings = $stringBindings
                Procedures = $procDef
                }
            } catch {
                # Silently continue
            }

            
            # If user used the -RemotelyAccessibleOnly switch, only store the RPC servers that are remotely accessible.
            if ($RemotelyAccessibleOnly) {
                $remoteProtocols = @("ncacn_np","ncacn_ip_tcp")
                $filteredServerData = @{}

                foreach ($srv in $serverData.Keys) {
                    $remoteIfaces = foreach ($iface in $serverData[$srv]) {
                        if ($iface.StringBindings -match ($remoteProtocols -join "|")) {
                            # Keep only the remote bindings
                            [PSCustomObject]@{
                                InterfaceId    = $iface.InterfaceId
                                StringBindings = $iface.StringBindings | Where-Object { $_ -match ($remoteProtocols -join "|") }
                                Procedures     = $iface.Procedures
                            }
                        }
                    }

                    if ($remoteIfaces) {
                        $filteredServerData[$srv] = $remoteIfaces
                    }
                }

                $serverData = $filteredServerData
            }

        }

        # Now write the collected data to a JSON file
        try {
            $serverData | ConvertTo-Json -Depth 3 | Out-File "$outpath\rpcServerData.json"
        } catch {
            Write-Host "[!] Could not save results to output path, check your path" -ForegroundColor Red
            return
        }        

        # Done
        Write-Host "[+] Saved RPC interfaces, Endpoints and Procedures of target to '$outpath\rpcServerData.json'" -ForegroundColor Green
        Write-Host "[+] To fuzz please run '$outpath\rpcServerData.json' | Invoke-RpcFuzzer -OutPath '$outpath'" -ForegroundColor Green
    }
}
