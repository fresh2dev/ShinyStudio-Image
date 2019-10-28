[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Source,
    [string]$Destination,
    [string]$To = 'html'
)

$Source = $Source | Resolve-Path

[string]$SourceDir  = Split-Path $Source -Parent

if (-not $Destination) {
    $Destination = Join-Path $SourceDir 'index.html'
}
else {
    $Destination = $Destination | Resolve-Path
}

[string]$SourceFile = Split-Path $Source -Leaf
[string]$FileExt    = [System.IO.Path]::GetExtension($SourceFile)
[string]$HtmlName   = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile) + '.html'
[string]$HtmlPath   = Join-Path $SourceDir $HtmlName


$env:PATH = "/conda3/envs/$env:VIRTUAL_ENV/bin:" + $env:PATH

if ($FileExt.ToLower() -eq '.rmd') {
    & /usr/local/bin/r -e "rmarkdown::render('$Source', 'html_document', output_file='$Destination')"
}
elseif ($FileExt.ToLower() -eq '.ipynb') {
    & jupyter nbconvert "$Source" --to $To --execute -y --template full
    Write-Host "Moving '$HtmlPath' to '$Destination'"
    Move-Item "$HtmlPath" "$Destination" -Force
}
