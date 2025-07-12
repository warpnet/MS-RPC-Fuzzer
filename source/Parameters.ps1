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
Gets all parameters for a RPC server
.DESCRIPTION
This cmdlet gets all parameters for a RPC server and stores it in a json file
.PARAMETER Target
Specify the RPC Server as target
.PARAMETER RpcServer
Specify the target through pipe
.INPUTS
NtCoreLib.Win32.Rpc.Server.RpcServer[]
.OUTPUTS
JSON file
.EXAMPLE
$rpcint | Get-RpcParameters -OutPath .\output\
Get's parameters for the parsed RPC server
#>
function Get-RpcParameters {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        [NtCoreLib.Win32.Rpc.Server.RpcServer]$RpcServer,
        [Parameter(Mandatory=$false)]
        [string]$target, 
        [string]$DbgHelpPath,      
        [string]$OutPath
    )
    begin {
        # Initialize DbgHelp DLL
        if (Test-Path "$env:systemdrive\Program Files (x86)\Windows Kits\10\Debuggers\x64\dbghelp.dll") {
            Set-GlobalSymbolResolver -DbgHelpPath "$env:systemdrive\Program Files (x86)\Windows Kits\10\Debuggers\x64\dbghelp.dll"   
        } else {
            if ($DbgHelpPath) {
                try {
                    Set-GlobalSymbolResolver -DbgHelpPath $DbgHelpPath    
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
        if (-Not (Test-Path $outPath)) {
            # Creating Path
            New-Item -ItemType Directory -Path $OutPath
        }

        # First check if the user specified the -target parameter
        $rpcInterfaces = @()
        if ($target) {
            # User specified target, we should check if the path is a directory or a single file
            if (Test-Path $target) {
                $item = Get-Item $target
                if ($item.PSIsContainer) {
                    # Target is a directory, get all executables and dll's from it
                    $rpcInterfaces = ls "$target\*" -Include "*.dll","*.exe" | Get-RpcServer
                } else {
                    $rpcInterfaces = "$target" | Get-RpcServer
                }
                Write-Host "[+] Getting RPC Interfaces and Endpoints for specified target $target" -ForegroundColor Green
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
        foreach ($rpcInt in $rpcInterfaces) {
            # Get all methods for rpcinterface
            $client = Get-RpcClient $rpcInt
            $methods = $Client.GetType().GetMethods() | Where-Object { $_.IsPublic -and $_.DeclaringType -eq $Client.GetType() }
            
            # Loop over each method and gather the parameters

            $outputParams = @()
            $inputParams = @()

            foreach ($method in $Methods) {
                # Get complex output parameters
                $outputParams += $method.ReturnType.GetFields() | Where-Object {
                    !$_.IsVirtual -and !$_.IsHideBySig -and $_.FieldType -ne $null -and $_.Name -match '^p\d+$' -and !($_.FieldType -eq [Int32])
                } | Select-Object @{Name='MethodName'; Expression={$method.Name}}, Name, @{Name='FieldType'; Expression={$_.FieldType.FullName}}

                # Get input parameter types and positions
                $paramIndex = 0
                foreach ($param in $method.GetParameters()) {
                    $paramType = $param.ParameterType.FullName

                    # Exclude System.String and System.Int32
                    if ($paramType -ne "System.String" -and $paramType -ne "System.Int32") {
                        $inputParams += [PSCustomObject]@{
                            MethodName = $method.Name
                            Name       = "p$paramIndex"
                            FieldType  = $paramType
                        }
                    }
                    $paramIndex++
                }
            }

            # Export output parameters
            foreach ($param in $outputParams) {
                Export-Parameters -RpcServerName $rpcInt.Name -RpcInterface $rpcint.InterfaceId.Guid -MethodName $param.MethodName -Position $param.Name -ParameterType $param.FieldType -is "Output" -OutPath $OutPath
            }

            # Export input parameters
            foreach ($param in $inputParams) {
                Export-Parameters -RpcServerName $rpcInt.Name -RpcInterface $rpcint.InterfaceId.Guid -MethodName $param.MethodName -Position $param.Name -ParameterType $param.FieldType -is "Input" -OutPath $OutPath
            }        
        }
    }
}