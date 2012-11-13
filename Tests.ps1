$here = (Split-Path -Parent $MyInvocation.MyCommand.Definition)
Import-Module -Name ($here + "\ObjectJoin.psm1") -Force

Write-Host "Test Merging two objects"

Write-Host "Test Merging two arrays niavely"

Write-Host "Test Merging an array to an object"

Write-Host "Test Merging an object to an array"

Write-Host "Test Merging two arrays with different indexes"

Write-Host "Test Merging a large base to a small input array, appending extras"

Write-Host "Test Merging a small base to a large array, appending extras"


# Other tests here. There's alot of permutations of this command to test.