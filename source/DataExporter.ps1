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
Exports Allowed fuzzed input to a json file
.DESCRIPTION
This function exports Allowed fuzzed input to a json file
#>
function Export-AllowsFuzzedInput {
    param (
        [string]$MethodName, 
        [string]$RpcServerName, 
        [string]$RpcInterface,
        [string]$Endpoint, 
        [string]$ProcedureName, 
        [string]$MethodDefinition,
        [string]$Service,
        [string]$FuzzInput, 
        [string]$Output,
        [string]$windowsMessage,
        [string]$OutPath
    )
    begin {
        $methodEntry = [ordered]@{
            MethodName       = $MethodName
            Endpoint         = $Endpoint
            ProcedureName    = $ProcedureName
            MethodDefinition = $MethodDefinition
            Service          = $Service
            FuzzInput        = $FuzzInput
            Output           = $Output
            WindowsMessage   = $windowsMessage
        }

        # Specify target output file
        $jsonFile = "$OutPath\Allowed.json"

        # Check if the directory exists, if not, create it
        $directoryPath = Split-Path -Path $jsonFile
        if (-not (Test-Path $directoryPath)) {
            New-Item -Path $directoryPath -ItemType Directory | Out-Null
        }
    }
    process {        
        # Read existing JSON or initialize a new hashtable
        if (Test-Path $jsonFile) {
            $jsonContent = Get-Content -Path $jsonFile -Raw
            $existingData = $jsonContent | ConvertFrom-Json -AsHashtable
        } else {
            $existingData = @{}
        }

        # Ensure the RpcServerName exists in the data
        if (-not $existingData.ContainsKey($RpcServerName)) {
            $existingData[$RpcServerName] = @{}
        }

        # Get the server's interface data
        $serverData = $existingData[$RpcServerName]

        # Ensure the RpcInterface exists in the server's data
        if (-not $serverData.ContainsKey($RpcInterface)) {
            $serverData[$RpcInterface] = @()
        }

        # Add the method entry to the interface's array
        $serverData[$RpcInterface] += $methodEntry

        # Update the server data in the existing data
        $existingData[$RpcServerName] = $serverData
    }
    end {
        # Convert the data to JSON and save
        $existingData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonFile -Encoding utf8
    }
}

<#
.SYNOPSIS
Exports Access Denied fuzzed input to a json file
.DESCRIPTION
This function exports Access Denied fuzzed input to a json file
#>
function Export-AccessDeniedInput {
    param (
        [string]$MethodName, 
        [string]$RpcServerName,
        [string]$RpcInterface,
        [string]$Endpoint, 
        [string]$ProcedureName, 
        [string]$Service,
        [string]$MethodDefinition, 
        [string]$FuzzInput,
        [string]$OutPath
    )
    begin {
        $methodEntry = [ordered]@{
            MethodName       = $MethodName
            Endpoint         = $Endpoint
            ProcedureName    = $ProcedureName
            MethodDefinition = $MethodDefinition
            Service          = $Service
            FuzzInput        = $FuzzInput
            Result           = "Access Denied"
        }
        $jsonFile = "$OutPath\Denied.json"

        # Check if the directory exists, if not, create it
        $directoryPath = Split-Path -Path $jsonFile
        if (-not (Test-Path $directoryPath)) {
            New-Item -Path $directoryPath -ItemType Directory | Out-Null
        } 
    }
    process {
        # Read existing JSON or initialize a new hashtable
        if (Test-Path $jsonFile) {
            $jsonContent = Get-Content -Path $jsonFile -Raw
            $existingData = $jsonContent | ConvertFrom-Json -AsHashtable
        } else {
            $existingData = @{}
        }
        # Ensure the RpcServerName exists in the data
        if (-not $existingData.ContainsKey($RpcServerName)) {
            $existingData[$RpcServerName] = @{}
        }

        # Get the server's interface data
        $serverData = $existingData[$RpcServerName]

        # Ensure the RpcInterface exists in the server's data
        if (-not $serverData.ContainsKey($RpcInterface)) {
            $serverData[$RpcInterface] = @()
        }

        # Add the method entry to the interface's array
        $serverData[$RpcInterface] += $methodEntry

        # Update the server data in the existing data
        $existingData[$RpcServerName] = $serverData
    }
    end {
        # Convert the data to JSON and save
        $existingData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonFile -Encoding utf8    
    }
}

<#
.SYNOPSIS
Exports Error fuzzed input to a json file
.DESCRIPTION
This function exports Error fuzzed input to a json file
#>
function Export-ErrorFuzzedInput {
    param (
        [string]$MethodName, 
        [string]$RpcServerName,
        [string]$RpcInterface,
        [string]$Endpoint, 
        [string]$ProcedureName, 
        [string]$Service,
        [string]$MethodDefinition, 
        [string]$FuzzInput,
        [string]$Errormessage,
        [string]$OutPath
    )
    begin {
        $methodEntry = [ordered]@{
            MethodName       = $MethodName
            Endpoint         = $Endpoint
            ProcedureName    = $ProcedureName
            MethodDefinition = $MethodDefinition
            Service          = $Service
            FuzzInput        = $FuzzInput
            Errormessage     = $Errormessage
        }

        # Specify target output file
        $jsonFile = "$OutPath\Error.json"

        # Check if the directory exists, if not, create it
        $directoryPath = Split-Path -Path $jsonFile
        if (-not (Test-Path $directoryPath)) {
            New-Item -Path $directoryPath -ItemType Directory | Out-Null
        }
    }
    process {
        # Read existing JSON or initialize a new hashtable
        if (Test-Path $jsonFile) {
            $jsonContent = Get-Content -Path $jsonFile -Raw
            $existingData = $jsonContent | ConvertFrom-Json -AsHashtable
        } else {
            $existingData = @{}
        }

        # Ensure the RpcServerName exists in the data
        if (-not $existingData.ContainsKey($RpcServerName)) {
            $existingData[$RpcServerName] = @{}
        }

        # Get the server's interface data
        $serverData = $existingData[$RpcServerName]

        # Ensure the RpcInterface exists in the server's data
        if (-not $serverData.ContainsKey($RpcInterface)) {
            $serverData[$RpcInterface] = @()
        }

        # Add the method entry to the interface's array
        $serverData[$RpcInterface] += $methodEntry

        # Update the server data in the existing data
        $existingData[$RpcServerName] = $serverData
    }
    end {
        # Convert the data to JSON and save
        $existingData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonFile -Encoding utf8
    }
}

<#
.SYNOPSIS
Exports parameters of a RPC method to a JSON file
.DESCRIPTION
This function exports parameters of a RPC method to a JSON file
#>
function Export-Parameters() {
    param (
        [string]$RpcServerName,
        [string]$RpcInterface,        
        [string]$MethodName,
        $ParameterType,
        $Position,
        [string]$is,
        [string]$OutPath
    )
    begin {
        $parameterEntry = [ordered]@{
            MethodName       = $MethodName
            ParameterType    = $ParameterType
            Position         = $Position
            Is               = $is
        }    

        $jsonFile = "$OutPath\Parameters.json"

        # Check if the directory exists, if not, create it
        $directoryPath = Split-Path -Path $jsonFile
        if (-not (Test-Path $directoryPath)) {
            New-Item -Path $directoryPath -ItemType Directory | Out-Null
        }
    }
    process {
        # Read existing JSON or initialize a new hashtable
        if (Test-Path $jsonFile) {
            $jsonContent = Get-Content -Path $jsonFile -Raw
            $existingData = $jsonContent | ConvertFrom-Json -AsHashtable
        } else {
            $existingData = @{}
        }

        # Ensure the RpcServerName exists in the data
        if (-not $existingData.ContainsKey($RpcServerName)) {
            $existingData[$RpcServerName] = @{}
        }

        # Get the server's interface data
        $serverData = $existingData[$RpcServerName]

        # Ensure the RpcInterface exists in the server's data
        if (-not $serverData.ContainsKey($RpcInterface)) {
            $serverData[$RpcInterface] = @()
        }

        # Add the method entry to the interface's array
        $serverData[$RpcInterface] += $parameterEntry

        # Update the server data in the existing data
        $existingData[$RpcServerName] = $serverData
    }
    end {
        # Convert the data to JSON and save
        $existingData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonFile -Encoding utf8
    }
}