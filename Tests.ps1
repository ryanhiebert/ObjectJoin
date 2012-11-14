# Requires PSUnit to be installed. http://psunit.org
. PSUnit.ps1

Import-Module -Name ".\ObjectJoin.psm1" -Force

function Compare-ObjectProperties
{
    Param($a, $b)

    $aProperties = @($a | Get-Member -MemberType NoteProperty)
    $bProperties = @($b | Get-Member -MemberType NoteProperty)

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
{
    $a = @(
        (New-Object PSObject -Property @{color="red";index=1}),
        (New-Object PSObject -Property @{color="blue";index=2}),
        (New-Object PSObject -Property @{color="green";index=3})
    )
    $b = @(
        (New-Object PSObject -Property @{size="small";starbucks="tall"}),
        (New-Object PSObject -Property @{size="medium";starbucks="grande"}),
        (New-Object PSObject -Property @{size="large";starbucks="venti"})
    )
    $ab = @(
        (New-Object PSObject -Property @{color='red';index=1;size='small';starbucks='tall'}),
        (New-Object PSObject -Property @{color='blue';index=2;size='medium';starbucks='grande'}),
        (New-Object PSObject -Property @{color='green';index=3;size='large';starbucks='venti'})
    )

    $Actual = $a | Merge-Object $b
    $Differences = @($Actual | ForEach -Begin {$i=0} -Process {
        if((Compare-ObjectProperties $_ $ab[$i]) -ne $null) {$false}
        $i = $i + 1
    })

    Assert-That -ActualValue $Differences -Constraint {$ActualValue.Count -eq 0}
}

function Test.ObjectJoin_Merge-Object_ArraysNaivelyAppendInputExtras()
{
    $a = @(
        (New-Object PSObject -Property @{color="red";index=1}),
        (New-Object PSObject -Property @{color="blue";index=2}),
        (New-Object PSObject -Property @{color="green";index=3})
    )
    $b = @(
        (New-Object PSObject -Property @{size="small";starbucks="tall"}),
        (New-Object PSObject -Property @{size="medium";starbucks="grande"})
    )
    $ab = @(
        (New-Object PSObject -Property @{color='red';index=1;size='small';starbucks='tall'}),
        (New-Object PSObject -Property @{color='blue';index=2;size='medium';starbucks='grande'}),
        (New-Object PSObject -Property @{color='green';index=3})
    )

    $Actual = $a | Merge-Object $b -AppendExtras
    $Differences = @($Actual | ForEach -Begin {$i=0} -Process {
        if((Compare-ObjectProperties $_ $ab[$i]) -ne $null) {$false}
        $i = $i + 1
    })

    Assert-That -ActualValue $Differences -Constraint {$ActualValue.Count -eq 0}
}

function Test.ObjectJoin_Merge-Object_ArraysNaivelyDiscardBaseExtras()
{
    $a = @(
        (New-Object PSObject -Property @{color="red";index=1}),
        (New-Object PSObject -Property @{color="blue";index=2})
    )
    $b = @(
        (New-Object PSObject -Property @{size="small";starbucks="tall"}),
        (New-Object PSObject -Property @{size="medium";starbucks="grande"}),
        (New-Object PSObject -Property @{size="large";starbucks="venti"})
    )
    $ab = @(
        (New-Object PSObject -Property @{color='red';index=1;size='small';starbucks='tall'}),
        (New-Object PSObject -Property @{color='blue';index=2;size='medium';starbucks='grande'})
    )

    $Actual = $a | Merge-Object $b -DiscardLeftovers
    $Differences = @($Actual | ForEach -Begin {$i=0} -Process {
        if((Compare-ObjectProperties $_ $ab[$i]) -ne $null) {$false}
        $i = $i + 1
    })

    Assert-That -ActualValue $Differences -Constraint {$ActualValue.Count -eq 0}
}

#function Test.ObjectJoin_Merge-Object_ArraysSameIndexProperty()
#{}

#function Test.ObjectJoin_Merge-Object_ArraysDifferentIndexProperty()
#{}
