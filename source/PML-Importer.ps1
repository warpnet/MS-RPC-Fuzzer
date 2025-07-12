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
Exports Process Monitor events that are relevant
.DESCRIPTION
This function exports Process Monitor events that are relevant
.PARAMETER FilePath
Specify the filepath to the Process Monitor CSV file
.PARAMETER Canary
Specify the canary that was used to fuzz to apply as filter for relevant events
#>
function Import-PML {
    param (
        [string]$FilePath,
        [string]$Canary
    )

    # Check if the file exists
    if (!(Test-Path $FilePath)) {
        Write-Host "File not found: $FilePath"
        return
    }

    # Load the CSV into PowerShell
    $events = Import-Csv $FilePath

    # Filter events by Canary in the Path
    $filteredEvents = $events | Where-Object { 
        $_.Path -like "*$Canary*"
    }

    # Remove duplicate events based on relevant fields
    $uniqueEvents = $filteredEvents | Sort-Object Process, PID, Operation, Path, Result -Unique

    # Check if any unique events exist
    if ($uniqueEvents.Count -eq 0) {
        Write-Host "[!] No unique function calls found to map in Neo4j. Check your Canary or Operation type." -ForegroundColor Red
        exit
    }

    # Add the unique events to Neo4j
    foreach ($event in $uniqueEvents) {
        Add-FunctionCallToAllowedInput -PMLEvent $event -Canary $Canary
    }
    Write-Host "[+] Successfully imported Process Monitor events to Neo4j" -ForegroundColor Cyan
}
