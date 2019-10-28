[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceDir,
    [Parameter(Mandatory=$true)]
    [string]$DestDir,
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [string]$Suffix,
    [uint32]$RetainDays,
    [uint32]$RetainCount
)

[scriptblock]$getfiles = {
    Get-ChildItem $DestDir -File -Filter $($Name+'-*'+$ext)
}

if (-not $Suffix) {
    $Suffix = [datetime]::Now.ToString('yyyyMMddHHmmss')
}

$SourceDir = $SourceDir | Resolve-Path
$DestDir   = $DestDir | Resolve-Path

[string]$ext = '.tar.gz'

[string]$BackupFile = Join-Path $DestDir $($Name + '-' + $Suffix + $ext)

Write-Verbose "Zipping '$SourceDir' to '$BackupFile'"

& tar -zcf "$BackupFile" "$SourceDir"

if ($RetainDays) {
    [string[]]$to_drop = & $getfiles |
                            Where-Object { [datetime]::Now.Subtract($_.LastWriteTime).TotalDays -gt $RetainDays } |
                                Select-Object -ExpandProperty FullName

    Write-Verbose "Removing $($to_drop.Count) backups older than $RetainDays days."

    Remove-Item -Path $to_drop -Force
}

if ($RetainCount) {
    $count = @(& $getfiles).Count
    if ($count -gt $RetainCount) {
        $drop = $count - $RetainCount
        Write-Verbose "Removing $drop old backups."
        & $getfiles |
            Sort-Object LastWriteTime -Descending |
                Select-Object -Last $drop |
                    Remove-Item -Force
    }
}
