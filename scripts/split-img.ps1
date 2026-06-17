param(
    [int]$MaxPerDir = 800
)
Set-StrictMode -Version Latest
cd $PSScriptRoot\..\
# Ensure on main and up-to-date
git checkout main
git pull --ff-only origin main
# create working branch
$branch = 'reorganize/img-split-final'
if (git rev-parse --verify $branch 2>$null) {
    git branch -D $branch
}
git checkout -b $branch

$files = Get-ChildItem -Path .\img -File | Where-Object { -not $_.PSIsContainer } | Sort-Object Name
Write-Output "Found $($files.Count) files to move"
$idx = 0
foreach ($f in $files) {
    $idx++
    $part = [math]::Floor(($idx-1)/$MaxPerDir)
    $dirName = "img/part_{0:D3}" -f $part
    if (-not (Test-Path $dirName)) {
        New-Item -ItemType Directory -Path $dirName | Out-Null
    }
    $src = Join-Path -Path 'img' -ChildPath $f.Name
    $dst = Join-Path -Path $dirName -ChildPath $f.Name
    Write-Output "Moving: $src -> $dst"
    git mv -- "$src" "$dst"
}

if ((git status --porcelain) -ne $null) {
    git commit -m "Reorganize img into part_* folders to avoid GitHub UI truncation (split $MaxPerDir/files)" -a
    git push -u origin $branch
    Write-Output "Pushed branch: $branch"
} else {
    Write-Output "No changes to commit"
}

Write-Output "Done"
