<#
    .SYNOPSIS
        Returns a array of the type `[Reason]`.

    .DESCRIPTION
        This command converts the array of properties that is returned by the command
        `Compare-DscParameterState`. The result is an array of the type `[Reason]` that
        can be returned in a DSC resource's property **Reasons**.

    .PARAMETER Property
       The result from the command Compare-DscParameterState.

    .PARAMETER ResourceName
       The name of the resource. Will be used to populate the property Code with
       the correct value.

    .EXAMPLE
        ConvertTo-Reason -Property (Compare-DscParameterState) -ResourceName 'MyResource'

        Returns an array of `[Reason]` that contain all the properties not in desired
        state and why a specific property is not in desired state.

    .OUTPUTS
        [Reason[]]
#>
function ConvertTo-Reason
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when the output type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([Reason[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [System.Collections.Hashtable[]]
        $Property,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceName
    )

    begin
    {
        # Always return an empty array if there are no properties to add.
        $reasons = [Reason[]] @()
    }

    process
    {
        foreach ($currentProperty in $Property)
        {
            if ($currentProperty.ExpectedValue -is [System.Enum])
            {
                # Return the string representation of the value (instead of the numeric value).
                $propertyExpectedValue = $currentProperty.ExpectedValue.ToString()
            }
            else
            {
                $propertyExpectedValue = $currentProperty.ExpectedValue
            }

            if ($property.ActualValue -is [System.Enum])
            {
                # Return the string representation of the value so that conversion to json is correct.
                $propertyActualValue = $currentProperty.ActualValue.ToString()
            }
            else
            {
                $propertyActualValue = $currentProperty.ActualValue
            }

            <#
                In PowerShell 7 the command ConvertTo-Json returns 'null' on null
                value, but not in Windows PowerShell. Switch to output empty string
                if value is null.
            #>
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                if ($null -eq $propertyExpectedValue)
                {
                    $propertyExpectedValue = ''
                }

                if ($null -eq $propertyActualValue)
                {
                    $propertyActualValue = ''
                }
            }

            # Convert the value to Json to be able to easily visualize complex types
            $propertyActualValueJson = $propertyActualValue | ConvertTo-Json -Compress
            $propertyExpectedValueJson = $propertyExpectedValue | ConvertTo-Json -Compress

            # If the property name contain the word Path, remove '\\' from path.
            if ($currentProperty.Property -match 'Path')
            {
                $propertyActualValueJson = $propertyActualValueJson -replace '\\\\', '\'
                $propertyExpectedValueJson = $propertyExpectedValueJson -replace '\\\\', '\'
            }

            $reasons += [Reason] @{
                Code   = '{0}:{0}:{1}' -f $ResourceName, $currentProperty.Property
                # Convert the object to JSON to handle complex types.
                Phrase = 'The property {0} should be {1}, but was {2}' -f @(
                    $currentProperty.Property,
                    $propertyExpectedValueJson,
                    $propertyActualValueJson
                )
            }
        }
    }

    end
    {
        return $reasons
    }
}
