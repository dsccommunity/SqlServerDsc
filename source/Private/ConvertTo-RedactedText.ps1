<#
    .SYNOPSIS
        Redacts a text from one or more specified phrases.

    .DESCRIPTION
        Redacts a text using best effort from one or more specified phrases. For
        it to work the sensitiv phrases must be known and passed into the parameter
        RedactText. If any single character in a phrase is wrong the sensitiv
        information will not be redacted. The redaction is case-insensitive.

    .PARAMETER Text
        Specifies the text that will be redacted.

    .PARAMETER RedactPhrase
        Specifies one or more phrases to redact from the text. Text strings will
        be escaped so they will not be interpreted as regular expressions (RegEx).

    .PARAMETER RedactWith
        Specifies a phrase that will be used as redaction.

    .EXAMPLE
        ConvertTo-RedactedText -Text 'My secret phrase: secret123' -RedactPhrase 'secret123'

        Returns the text with the phrases redacted with the default redaction phrase.

    .EXAMPLE
        ConvertTo-RedactedText -Text 'My secret phrase: secret123' -RedactPhrase 'secret123' -RedactWith '----'

        Returns the text with the phrases redacted to '----'.
#>
function ConvertTo-RedactedText
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String]
        $Text,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $RedactPhrase,

        [Parameter()]
        [System.String]
        $RedactWith = '*******'
    )

    process
    {
        $redactedText = $Text

        foreach ($redactString in $RedactPhrase)
        {
            <#
                Escaping the string to handle strings which could look like
                regular expressions, like passwords.
            #>
            $escapedRedactedString = [System.Text.RegularExpressions.Regex]::Escape($redactString)

            $redactedText = $redactedText -ireplace $escapedRedactedString, $RedactWith # cSpell: ignore ireplace
        }

        return $redactedText
    }
}
