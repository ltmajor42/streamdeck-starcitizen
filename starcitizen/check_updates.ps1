[xml]$xml = Get-Content 'packages.config'
foreach ($pkg in $xml.packages.package) {
  $id = $pkg.id
  $version = $pkg.version
  $url = "https://api.nuget.org/v3-flatcontainer/$($id.ToLower())/index.json"
  try {
    $response = Invoke-RestMethod -Uri $url -Method Get
    $stableVersions = $response.versions | Where-Object { $_ -notmatch '-' }
    if ($stableVersions) {
      $latest = ($stableVersions | Sort-Object { [version]$_ } -Descending)[0]
      if ([version]$latest -gt [version]$version) {
        Write-Host "$id current: $version, latest: $latest - UPDATE AVAILABLE"
      } else {
        Write-Host "$id current: $version, latest: $latest - UP TO DATE"
      }
    } else {
      Write-Host "$id : No stable versions found"
    }
  } catch {
    Write-Host "Error checking $id : $_"
  }
}

