# Requires PSUnit to be installed. http://psunit.org
. PSUnit.ps1

Import-Module -Name ".\ObjectJoin.psm1" -Force

function Test.ObjectJoin_Merge-Object_MergeTwoObjectsOneFromPipeline()
{
    $a = New-Object PSObject -Property @{id='a';name='Aye'}
    $b = New-Object PSObject -Property @{color='green';level=7}
    $ab = New-Object PSObject -Property @{id='a';name='Aye';color='green';level=7}

    $Actual = $a | Merge-Object $b

    Assert-That -ActualValue $Actual -Constraint {(Compare-Object $ActualValue $ab) -eq $null}
}

#Write-Host "Test Merging two objects"

#Write-Host "Test Merging two arrays niavely"

#Write-Host "Test Merging an array to an object"

#Write-Host "Test Merging an object to an array"

#Write-Host "Test Merging two arrays with different indexes"

#Write-Host "Test Merging a large base to a small input array, appending extras"

#Write-Host "Test Merging a small base to a large array, appending extras"


# Other tests here. There's alot of permutations of this command to test.
