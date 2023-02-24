Write-Output "Starting Terraform modules build..."
$sw = [Diagnostics.Stopwatch]::StartNew()
$path = '.\.examples'
$pathFilter = 'main.tf'
$pathDepth = 2

$childItems = Get-ChildItem -Path $path -Recurse -Depth $pathDepth -Filter $pathFilter 
$childItemsCount = $childItems.Length
Write-Output "-----"
Write-Output "Items found: $childItemsCount"

$childItems | Foreach-Object -ThrottleLimit 5 -Parallel {
  #Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname
  $directoryAbsolutePath = $PSItem.Directory.FullName | Resolve-Path -Relative
  $directoryRelativePath = $PSItem.Directory.FullName | Resolve-Path -Relative
  Write-Output "[$directoryRelativePath] Starting..."
  Set-Location $directoryAbsolutePath

  terraform init -input=false -backend=false
  terraform validate
}

Write-Output "-----"
$sw.Stop()

Write-Output "Job duration: $($sw.Elapsed.ToString("c"))"
