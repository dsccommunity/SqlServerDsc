<#
    This check is made so that the real SqlServer or SQLPS module is not loaded into
    the session when the CI runs unit tests of SqlServerDsc. It would conflict with
    the stub types and stub commands used in the unit tests. This is a workaround
    because we cannot set a specific module as a nested module in the module manifest,
    the user must be able to choose to use either SQLPS or SqlServer.
#>
if (-not $env:SqlServerDscCI)
{
    try
    {
        <#
            Import SQL commands and types into the session, so that types used
            by commands can be parsed.
        #>
        Import-SqlDscPreferredModule -ErrorAction 'Stop'
    }
    catch
    {
        <#
            It is not possible to throw the error from Import-SqlDscPreferredModule
            since it will just fail the command Import-Module with an obscure error.
        #>
        Write-Warning -Message $_.Exception.Message
    }
}
