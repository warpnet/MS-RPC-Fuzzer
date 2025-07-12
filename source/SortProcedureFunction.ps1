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
Sort procedures based on their input and output parameters
.DESCRIPTION
This function sorts procedures based on their input and output parameters,
prioritizing methods that produce complex types needed by other methods.
It attempts a topological sort to ensure producers are called before consumers.
#>
function SortProcedures {
    param (
        [Parameter(Mandatory=$true)]
        [System.Reflection.MethodInfo[]]$methods
    )

    # Helper function to determine if a given Type is considered "complex" for fuzzing purposes.
    # A type is considered complex if it's not a common primitive or a byte array.
    function Test-IsComplexType {
        param (
            [Parameter(Mandatory=$true)]
            [System.Type]$Type
        )
        $primitiveTypes = @(
            [string], [int], [int32], [int64],
            [double], [float], [single],
            [bool], [byte], [char],
            [datetime], [guid], [void], [byte[]]
        )

        # If the type is in our list of primitive types, it's not complex.
        if ($primitiveTypes.Contains($Type)) {
            return $false
        }

        # If it's an enum, it's generally not considered a complex object for this purpose.
        if ($Type.IsEnum) {
            return $false
        }

        if ($Type.IsClass -or $Type.IsValueType) {
            return $true
        }

        return $false
    }

    # Data structures to store information about each method and its dependencies
    $methodInfo = @{}
    $complexTypeProducers = @{}
    $complexTypeConsumers = @{}

    # Step 1: Analyze each method to identify its complex inputs and outputs
    foreach ($method in $methods) {
        $methodName = $method.Name
        $currentMethodComplexInputs = @()
        $currentMethodComplexOutputs = @()

        foreach ($param in $method.GetParameters()) {
            if (Test-IsComplexType $param.ParameterType) {
                $complexTypeName = $param.ParameterType.FullName
                $currentMethodComplexInputs += $complexTypeName

                # Add this method to the list of consumers for this complex type
                if (-not $complexTypeConsumers.ContainsKey($complexTypeName)) {
                    $complexTypeConsumers[$complexTypeName] = @()
                }
                if (-not ($complexTypeConsumers[$complexTypeName] -contains $methodName)) {
                    $complexTypeConsumers[$complexTypeName] += $methodName
                }
            }
        }

        # Analyze Output Parameters (Return Type and out/ref parameters in the return type fields if it's a struct)
        if ($method.ReturnType -ne [void]) {
            # Check the return type itself
            if (Test-IsComplexType $method.ReturnType) {
                $complexTypeName = $method.ReturnType.FullName
                $currentMethodComplexOutputs += $complexTypeName
                if (-not $complexTypeProducers.ContainsKey($complexTypeName)) {
                    $complexTypeProducers[$complexTypeName] = @()
                }
                if (-not ($complexTypeProducers[$complexTypeName] -contains $methodName)) {
                    $complexTypeProducers[$complexTypeName] += $methodName
                }
            }

            # Check fields of the return type (if it's a custom type/struct)
            foreach ($field in $method.ReturnType.GetFields()) {
                if (-not $field.IsVirtual -and -not $field.IsHideBySig -and $field.FieldType -ne $null -and $field.Name -match '^p\d+$') {
                    if (Test-IsComplexType $field.FieldType) {
                        $complexTypeName = $field.FieldType.FullName
                        $currentMethodComplexOutputs += $complexTypeName
                        if (-not $complexTypeProducers.ContainsKey($complexTypeName)) {
                            $complexTypeProducers[$complexTypeName] = @()
                        }
                        if (-not ($complexTypeProducers[$complexTypeName] -contains $methodName)) {
                            $complexTypeProducers[$complexTypeName] += $methodName
                        }
                    }
                }
            }
        }

        $methodInfo[$methodName] = [PSCustomObject]@{
            Name = $methodName
            MethodObject = $method
            ComplexInputs = $currentMethodComplexInputs | Select-Object -Unique
            ComplexOutputs = $currentMethodComplexOutputs | Select-Object -Unique
        }
    }

    # Step 2: Prepare for Topological Sort
    $sortedMethods = [System.Collections.Generic.List[string]]::new()
    $unresolvedDependencies = @{}
    $readyQueue = [System.Collections.Queue]::new()

    # Initialize unresolvedDependencies and readyQueue
    foreach ($name in $methodInfo.Keys) {
        $methodObj = $methodInfo[$name]
        $numUnresolved = 0
        foreach ($inputType in $methodObj.ComplexInputs) {
            # An input is unresolved if no known method produces it, or if its producer hasn't been processed yet
            if ($complexTypeProducers.ContainsKey($inputType)) {
                $numUnresolved++
            }
        }

        if ($numUnresolved -eq 0) {
            $readyQueue.Enqueue($name)
        } else {
            $unresolvedDependencies[$name] = $numUnresolved
        }
    }

    # Step 3: Perform Topological Sort using Kahn's algorithm
    while ($readyQueue.Count -gt 0) {
        $currentMethodName = $readyQueue.Dequeue()
        $sortedMethods.Add($currentMethodName)

        # For each complex type produced by the current method
        foreach ($outputType in $methodInfo[$currentMethodName].ComplexOutputs) {

            if ($complexTypeConsumers.ContainsKey($outputType)) {
                foreach ($consumerMethodName in $complexTypeConsumers[$outputType]) {

                    if ($unresolvedDependencies.ContainsKey($consumerMethodName)) {
                        $unresolvedDependencies[$consumerMethodName]--

                        if ($unresolvedDependencies[$consumerMethodName] -eq 0) {
                            $readyQueue.Enqueue($consumerMethodName)
                            $unresolvedDependencies.Remove($consumerMethodName)
                        }
                    }
                }
            }
        }
    }

    # Step 4: Handle Unresolvable Methods (cycles or truly unproducible dependencies)
    if ($unresolvedDependencies.Count -gt 0) {
        foreach ($name in $unresolvedDependencies.Keys) {
            $sortedMethods.Add($name)
        }
    }

    # Reconstruct the sorted list of actual MethodInfo objects
    $finalSortedMethodObjects = @()
    foreach ($methodName in $sortedMethods) {
        $finalSortedMethodObjects += $methodInfo[$methodName].MethodObject
    }

    return $finalSortedMethodObjects
}
