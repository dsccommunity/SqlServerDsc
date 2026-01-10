---
Category: How-to
---

# Troubleshooting Report Server

This guide covers diagnostic techniques for troubleshooting _Power BI Report Server_
(PBIRS) and _SQL Server Reporting Services_ (SSRS). It explains how to retrieve
log file locations, analyze log content, and query Windows event logs for
error information.

> [!NOTE]
> The examples in this guide use the instance name `'PBIRS'` for _Power BI
> Report Server_. If you are using _SQL Server Reporting Services_ or have a
> custom instance name, substitute `'PBIRS'` with your instance name (e.g.,
> `'SSRS'` or your custom name).

## Log Files

Report servers store log files in the `ErrorDumpDirectory` configured during
setup. This folder contains service logs, portal logs, and memory dumps that
are useful for diagnosing issues.

> [!NOTE]
> For comprehensive information about all available Reporting Services log
> files and sources (including execution logs, trace logs, HTTP logs, and
> performance logs), see [Reporting Services log files and sources](https://learn.microsoft.com/en-us/sql/reporting-services/report-server/reporting-services-log-files-and-sources).
> For detailed information about trace log configuration and content, see
> [Report Server Service Trace Log](https://learn.microsoft.com/en-us/sql/reporting-services/report-server/report-server-service-trace-log).

### Getting the Log Path

Use the `Get-SqlDscRSLogPath` command to retrieve the log folder path:

```powershell
Get-SqlDscRSLogPath -InstanceName 'PBIRS'
```

Alternatively, pipe a configuration object from `Get-SqlDscRSConfiguration`:

```powershell
Get-SqlDscRSConfiguration -InstanceName 'PBIRS' | Get-SqlDscRSLogPath
```

### Common Log File Types

The log folder typically contains these file types:

- `ReportingServicesService*.log` - Web service activity and error logs
- `RSPortal*.log` - Portal access and activity logs
- `SQLDumpr*.mdmp` - Memory dumps for crash analysis

### Listing Log Files

To list all files in the log folder with their sizes and timestamps:

```powershell
$logPath = Get-SqlDscRSLogPath -InstanceName 'PBIRS'

Get-ChildItem -Path $logPath -Recurse -File |
    Select-Object -Property FullName, Length, LastWriteTime
```

To filter for only `.log` files:

```powershell
$logPath = Get-SqlDscRSLogPath -InstanceName 'PBIRS'

Get-ChildItem -Path $logPath -Recurse -File -Filter '*.log' |
    Select-Object -Property FullName, Length, LastWriteTime
```

### Reading Log Content

To read the last 50 lines from the most recent service log:

<!-- markdownlint-disable MD013 -->
```powershell
$logPath = Get-SqlDscRSLogPath -InstanceName 'PBIRS'

Get-ChildItem -Path $logPath -Filter 'ReportingServicesService*.log' |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -First 1 |
    ForEach-Object -Process { Get-Content -Path $_.FullName -Tail 50 }
```
<!-- markdownlint-enable MD013 -->

To read from all log files:

```powershell
$logPath = Get-SqlDscRSLogPath -InstanceName 'PBIRS'

Get-ChildItem -Path $logPath -Filter '*.log' -Recurse | ForEach-Object -Process {
    Write-Host "--- $($_.Name) ---" -ForegroundColor Cyan
    Get-Content -Path $_.FullName -Tail 50
    Write-Host "--- End of $($_.Name) ---" -ForegroundColor Cyan
}
```

## Windows Event Log

Report server components write events to the Windows Application log. Querying
these events can reveal errors not captured in the file-based logs.

### Relevant Event Providers

When filtering events, look for these provider names:

- `Report Server Windows Service (SSRS)` - Core report server service events
- `RSInstallerEventLog` - Installation and configuration events
- `MSSQL$<InstanceName>` - Database engine events (e.g., `MSSQL$PBIRS`)
- `SQLAgent$<InstanceName>` - SQL Agent events if subscriptions are used

### Querying Error Events

To retrieve the last 50 error events from the Application log:

<!-- markdownlint-disable MD013 -->
```powershell
Get-WinEvent -LogName 'Application' -MaxEvents 50 -FilterXPath '*[System[Level=2]]' |
    ForEach-Object -Process {
        "[$($_.TimeCreated)] [$($_.ProviderName)] $($_.Message)"
    }
```
<!-- markdownlint-enable MD013 -->

To filter for report server-specific providers:

<!-- markdownlint-disable MD013 -->
```powershell
$providers = @(
    'Report Server Windows Service (SSRS)'
    'RSInstallerEventLog'
)

Get-WinEvent -LogName 'Application' -MaxEvents 100 |
    Where-Object -FilterScript { $_.ProviderName -in $providers } |
    ForEach-Object -Process {
        "[$($_.TimeCreated)] [$($_.LevelDisplayName)] $($_.Message)"
    }
```
<!-- markdownlint-enable MD013 -->

### Listing Active Providers

To see which providers have written recent events (useful for identifying
the correct provider name for your environment):

```powershell
Get-WinEvent -LogName 'Application' -MaxEvents 200 |
    Select-Object -ExpandProperty ProviderName -Unique |
    Sort-Object
```

## Complete Diagnostic Script

The following script combines all diagnostic techniques into a single output
for troubleshooting:

<!-- markdownlint-disable MD013 -->
```powershell
$instanceName = 'PBIRS'

# Get log path
$logPath = Get-SqlDscRSLogPath -InstanceName $instanceName -ErrorAction 'Stop'

Write-Host "Log path: $logPath" -ForegroundColor Green

# List all files in log folder
if (Test-Path -Path $logPath)
{
    $allFiles = Get-ChildItem -Path $logPath -Recurse -File -ErrorAction 'SilentlyContinue'

    Write-Host "`nFiles in log folder ($($allFiles.Count) files):" -ForegroundColor Cyan

    foreach ($file in $allFiles)
    {
        Write-Host "  $($file.FullName) (Size: $($file.Length) bytes, Modified: $($file.LastWriteTime))"
    }

    # Output last 50 lines of each .log file
    $logFiles = $allFiles | Where-Object -FilterScript { $_.Extension -eq '.log' }

    foreach ($logFile in $logFiles)
    {
        Write-Host "`n--- Last 50 lines of $($logFile.Name) ---" -ForegroundColor Yellow

        Get-Content -Path $logFile.FullName -Tail 50 -ErrorAction 'SilentlyContinue'

        Write-Host "--- End of $($logFile.Name) ---" -ForegroundColor Yellow
    }
}
else
{
    Write-Warning -Message "Log path does not exist: $logPath"
}

# Output Windows Application log errors
Write-Host "`n--- Last 50 Application log error events ---" -ForegroundColor Magenta

$events = Get-WinEvent -LogName 'Application' -MaxEvents 50 -FilterXPath '*[System[Level=2]]' -ErrorAction 'SilentlyContinue'

foreach ($event in $events)
{
    Write-Host "[$($event.TimeCreated)] [$($event.ProviderName)] $($event.Message)"
}

Write-Host "--- End of Application log error events ---" -ForegroundColor Magenta
```
<!-- markdownlint-enable MD013 -->

> [!TIP]
> Save this script to a file and run it when troubleshooting report server
> issues. Redirect output to a file using `> diagnostic-output.txt` to share
> with support teams.
