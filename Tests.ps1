# Requires PSUnit to be installed. http://psunit.org
. PSUnit.ps1

Import-Module -Name ".\ObjectJoin.psm1" -Force

function Compare-ObjectProperties
{
    Param($a, $b)

    $aProperties = $a | Get-Member -MemberType NoteProperty
    $bProperties = $b | Get-Member -MemberType NoteProperty

    diff $aProperties $bProperties
}

function Test.ObjectJoin_Merge-Object_ObjectsOneFromPipelineImplicitParams()
{
    $a = New-Object PSObject -Property @{id='a';name='Aye'}
    $b = New-Object PSObject -Property @{color='green';level=7}
    $ab = New-Object PSObject -Property @{id='a';name='Aye';color='green';level=7}

    $Actual = $a | Merge-Object $b

    Assert-That -ActualValue $Actual -Constraint {(Compare-ObjectProperties $ActualValue $ab) -eq $null}
}

function Test.ObjectJoin_Merge-Object_ObjectsImplicitParams()
{
    $a = New-Object PSObject -Property @{id='a';name='Aye'}
    $b = New-Object PSObject -Property @{color='green';level=7}
    $ab = New-Object PSObject -Property @{id='a';name='Aye';color='green';level=7}

    $Actual = Merge-Object $a $b

    Assert-That -ActualValue $Actual -Constraint {(Compare-ObjectProperties $ActualValue $ab ) -eq $null}
}

function Test.ObjectJoin_Merge-Object_ObjectsOneFromPipelineExplicitParams()
{
    $a = New-Object PSObject -Property @{id='a';name='Aye'}
    $b = New-Object PSObject -Property @{color='green';level=7}
    $ab = New-Object PSObject -Property @{id='a';name='Aye';color='green';level=7}

    $Actual = $a | Merge-Object -Base $b

    Assert-That -ActualValue $Actual -Constraint {(Compare-ObjectProperties $ActualValue $ab) -eq $null}
}

function Test.ObjectJoin_Merge-Object_ObjectsExplicitParams()
{
    $a = New-Object PSObject -Property @{id='a';name='Aye'}
    $b = New-Object PSObject -Property @{color='green';level=7}
    $ab = New-Object PSObject -Property @{id='a';name='Aye';color='green';level=7}

    $Actual = Merge-Object -InputObject $a -Base $b

    Assert-That -ActualValue $Actual -Constraint {(Compare-ObjectProperties $ActualValue $ab) -eq $null}
}

function Test.ObjectJoin_Merge-Object_ObjectsWithConflictingProperties()
{
    $a = New-Object PSObject -Property @{id='a';name='Aye'}
    $b = New-Object PSObject -Property @{name='Bee';color='green';level=7}
    $ab = New-Object PSObject -Property @{id='a';name='Bee';color='green';level=7}

    $Actual = Merge-Object -InputObject $a -Base $b

    Assert-That -ActualValue $Actual -Constraint {(Compare-ObjectProperties $ActualValue $ab) -eq $null}
}

function Test.ObjectJoin_Merge-Object_ArraysNaively()
{}

function Test.ObjectJoin_Merge-Object_ArraysNaivelyAppendInputExtras()
{}

function Test.ObjectJoin_Merge-Object_ArraysNaivelyDiscardBaseExtras()
{}

function Test.ObjectJoin_Merge-Object_ArraysSameIndexProperty()
{}

function Test.ObjectJoin_Merge-Object_ArraysDifferentIndexProperty()
{}
