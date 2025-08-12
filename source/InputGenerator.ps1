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
Generates fuzz input for a parameter
.DESCRIPTION
This function generates fuzz input for a parameter
#>
function GenerateInput {
    param (
        [string]$paramType,
        [int]$count,
        [string]$Canary,
        $minStrLen = 5,
        $maxStrLen = 20,
        $minIntSize = 10,
        $maxIntSize = 100,
        $minByteArrLen = 100,
        $maxByteArrLen = 1000
    )

    # Convert PSCustomObject to Hashtable (if needed)
    if ($existingData -isnot [hashtable]) {
        $hashTable = @{}
        foreach ($property in $existingData.PSObject.Properties) {
            $hashTable[$property.Name] = $property.Value
        }
        $existingData = $hashTable
    }

    # Initialize new data array
    $newData = @()
    # Create a function for this that takes parameters for minimum/maximum length of String
    if ($paramType -eq [System.String]) {
        if ($NoSpecialChars) {
            $characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        } else {
            $characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()~-=+?><,;][{}_|"
        }        
        for ($i = 0; $i -lt $count; $i++) {
            $stringLength = Get-Random -Minimum $minStrLen -Maximum $maxStrLen
            $randomString = -join (Get-Random -InputObject $characters.ToCharArray() -Count $stringLength)
            $newData += ($Canary + "_$randomString")
            return $newData
        }
    }   

    # Generate random 32-bit Integer
    if ($paramType -eq [System.Int32]) {
        for ($i = 0; $i -lt $count; $i++) {  
            $newData = Get-Random -Minimum $minIntSize -Maximum $maxIntSize
            return $newData
        }
    }

    if ($paramType -eq [System.Byte[]]) {
        for ($i = 0; $i -lt $count; $i++) {
            $characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()~-=+?><,.;][{}_|"
            $stringLength = Get-Random -Minimum $minByteArrLen -Maximum $maxByteArrLen
            $randomString = -join (Get-Random -InputObject $characters.ToCharArray() -Count $stringLength)
            $newData += ($Canary + "_$randomString")          
            $byteArrStr = ,([System.Text.Encoding]::UTF8.GetBytes($newData))
            return ,$byteArrStr
        }
    }
}
