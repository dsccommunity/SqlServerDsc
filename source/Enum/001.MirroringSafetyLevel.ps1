<#
    .SYNOPSIS
        Enum for database mirroring safety level.

    .DESCRIPTION
        This enum represents the mirroring safety level for a database.
        The value None (0) indicates that mirroring is not configured for the
        database.
#>
enum MirroringSafetyLevel
{
    None    = 0
    Unknown = 1
    Off     = 2
    Full    = 3
}
