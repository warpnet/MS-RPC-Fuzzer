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

# Global variables for Neo4j connection
$Global:Neo4jBaseUri = ""
$Global:Neo4jAuthHeader = ""
<#
.SYNOPSIS
Configures the Neo4j connection
.DESCRIPTION
This function configures the Neo4j connection
.PARAMETER BaseUri
Specify the Neo4j host
.PARAMETER Username
Specify the Neo4j username
.PARAMETER Password
Specify the Neo4j password
.OUTPUTS
None
#>
function Set-CustomNeo4jConfiguration {
    param (
        [string]$BaseUri,
        [string]$Username,
        [SecureString]$Password
    )

    # Convert SecureString to plaintext (only in memory, avoid persisting it)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)

    # Encode credentials for Basic Authentication
    $authInfo = ("{0}:{1}" -f $Username, $PlainPassword)
    $encodedAuth = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($authInfo))

    # Clear plaintext password from memory
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

    # Set global variables for base URI and authorization header
    $Global:Neo4jBaseUri = $BaseUri
    $Global:Neo4jAuthHeader = "Basic $encodedAuth"

    # Test the connection by sending a simple query
    try {
        Invoke-CustomNeo4jQuery -Query "RETURN 'Connection Successful' AS Result" | Out-Null
        return $true
    } catch {
        Write-Error "Failed to connect to Neo4j. Please check your credentials and Neo4j server."
    }
}

<#
.SYNOPSIS
Invokes a Neo4j Query
.DESCRIPTION
This function invokes a Neo4j Query
.PARAMETER Query
Specify the Neo4j cipher query
.OUTPUTS
None
#>
function Invoke-CustomNeo4jQuery {
    param (
        [string]$Query
    )

    # Ensure that base URI and auth header are set
    if (-not $Global:Neo4jBaseUri -or -not $Global:Neo4jAuthHeader) {
        throw "Neo4j connection is not configured. Run Set-CustomNeo4jConfiguration first."
    }

    # Construct the request body
    $body = @{
        statements = @(
            @{
                statement = $Query
                resultDataContents = @("row", "graph")
            }
        )
    } | ConvertTo-Json -Depth 5 # The default depth when converting an in-memory JSON object to JSON data is 2, we will need more for our purposes

    # Send HTTP POST request to Neo4j API
    try {
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $response = Invoke-RestMethod -Uri "$Global:Neo4jBaseUri/db/neo4j/tx/commit" `
                                      -Method Post `
                                      -Headers @{ Authorization = $Global:Neo4jAuthHeader; Connection = "close" } `
                                      -Body $body `
                                      -ContentType "application/json" `
                                      -WebSession $session

        # Check for errors in the response
        if ($response.errors.Count -gt 0) {
            throw "Error executing query: $($response.errors[0].message)"
        }

        # Return the query result
        return $response.results[0].data
    } catch {
        throw "Failed to execute query: $_"
    }
}