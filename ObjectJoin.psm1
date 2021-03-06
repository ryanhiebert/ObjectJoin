﻿function AddItemProperties($item, $properties, $output)
{
    if($item -ne $null)
    {
        foreach($property in $properties)
        {
            $propertyHash =$property -as [hashtable]
            if($propertyHash -ne $null)
            {
                $hashName=$propertyHash["name"] -as [string]
                if($hashName -eq $null)
                {
                    throw "there should be a string Name"  
                }
         
                $expression=$propertyHash["expression"] -as [scriptblock]
                if($expression -eq $null)
                {
                    throw "there should be a ScriptBlock Expression"  
                }
         
                $_=$item
                $expressionValue=& $expression
         
                $output | add-member -MemberType "NoteProperty" -Name $hashName -Value $expressionValue -Force
            }
            else
            {
                # .psobject.Properties allows you to list the properties of any object, also known as "reflection"
                foreach($itemProperty in $item.psobject.Properties)
                {
                    if ($itemProperty.Name -like $property)
                    {
                        $output | add-member -MemberType "NoteProperty" -Name $itemProperty.Name -Value $itemProperty.Value -Force
                    }
                }
            }
        }
    }
}

    
function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties, $Type)
{
    $output = new-object psobject

    if($Type -eq "AllInRight")
    {
        # This mix of rightItem with LeftProperties and vice versa is due to
        # the switch of Left and Right arguments for AllInRight
        AddItemProperties $rightItem $leftProperties $output
        AddItemProperties $leftItem $rightProperties $output
    }
    else
    {
        AddItemProperties $leftItem $leftProperties $output
        AddItemProperties $rightItem $rightProperties $output
    }
    $output
}

<#
.Synopsis
   Joins two lists of objects
.DESCRIPTION
   Joins two lists of objects
.EXAMPLE
   Join-Object $a $b "Id" ("Name","Salary")
#>
function Join-Object
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # List to join with $Right
        [Parameter(Mandatory=$true, Position=0)][object[]]$Left,

        # List to join with $Left
        [Parameter(Mandatory=$true, Position=1)][object[]]$Right,

        # Condition in which an item in the left matches an item in the right
        # typically something like: {$args[0].Id -eq $args[1].Id}
        [Parameter(Mandatory=$true, Position=2)][scriptblock]$Where,

        # Properties from $Left we want in the output.
        # Each property can:
        # - Be a plain property name like "Name"
        # - Contain wildcards like "*"
        # - Be a hashtable like @{Name="Product Name";Expression={$_.Name}}. Name is the output property name
        #   and Expression is the property value. The same syntax is available in select-object and it is 
        #   important for join-object because joined lists could have a property with the same name
        [Parameter(Mandatory=$true, Position=3)][object[]]$LeftProperties,

        # Properties from $Right we want in the output.
        # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
        [Parameter(Mandatory=$true, Position=4)][object[]]$RightProperties,

        # Type of join. 
        #   AllInLeft will have all elements from Left at least once in the output, and might appear more than once
        # if the where clause is true for more than one element in right, Left elements with matches in Right are 
        # preceded by elements with no matches. This is equivalent to an outer left join (or simply left join) 
        # SQL statement.
        #  AllInRight is similar to AllInLeft.
        #  OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
        # match in Right. This is equivalent to a SQL inner join (or simply join) statement.
        #  AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
        # in right with at least one match in left, followed by all entries in Right with no matches in left, 
        # followed by all entries in Left with no matches in Right.This is equivallent to a SQL full join.
        [Parameter(Mandatory=$false, Position=5)]
        [ValidateSet("AllInLeft","OnlyIfInBoth","AllInBoth", "AllInRight")]
        [string]$Type="OnlyIfInBoth"
    )

    Begin
    {
        # a list of the matches in right for each object in left
        $leftMatchesInRight = new-object System.Collections.ArrayList

        # the count for all matches  
        $rightMatchesCount = New-Object "object[]" $Right.Count

        for($i=0;$i -lt $Right.Count;$i++)
        {
            $rightMatchesCount[$i]=0
        }
    }

    Process
    {
        if($Type -eq "AllInRight")
        {
            # for AllInRight we just switch Left and Right
            $aux = $Left
            $Left = $Right
            $Right = $aux
        }

        # go over items in $Left and produce the list of matches
        foreach($leftItem in $Left)
        {
            $leftItemMatchesInRight = new-object System.Collections.ArrayList
            $null = $leftMatchesInRight.Add($leftItemMatchesInRight)

            for($i=0; $i -lt $right.Count;$i++)
            {
                $rightItem=$right[$i]

                if($Type -eq "AllInRight")
                {
                    # For AllInRight, we want $args[0] to refer to the left and $args[1] to refer to right,
                    # but since we switched left and right, we have to switch the where arguments
                    $whereLeft = $rightItem
                    $whereRight = $leftItem
                }
                else
                {
                    $whereLeft = $leftItem
                    $whereRight = $rightItem
                }

                if(Invoke-Command -ScriptBlock $where -ArgumentList $whereLeft,$whereRight)
                {
                    $null = $leftItemMatchesInRight.Add($rightItem)
                    $rightMatchesCount[$i]++
                }
            
            }
        }

        # go over the list of matches and produce output
        for($i=0; $i -lt $left.Count;$i++)
        {
            $leftItemMatchesInRight=$leftMatchesInRight[$i]
            $leftItem=$left[$i]
                               
            if($leftItemMatchesInRight.Count -eq 0)
            {
                if($Type -ne "OnlyIfInBoth")
                {
                    WriteJoinObjectOutput $leftItem  $null  $LeftProperties  $RightProperties $Type
                }

                continue
            }

            foreach($leftItemMatchInRight in $leftItemMatchesInRight)
            {
                WriteJoinObjectOutput $leftItem $leftItemMatchInRight  $LeftProperties  $RightProperties $Type
            }
        }
    }

    End
    {
        #produce final output for members of right with no matches for the AllInBoth option
        if($Type -eq "AllInBoth")
        {
            for($i=0; $i -lt $right.Count;$i++)
            {
                $rightMatchCount=$rightMatchesCount[$i]
                if($rightMatchCount -eq 0)
                {
                    $rightItem=$Right[$i]
                    WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties $Type
                }
            }
        }
    }
}

# Derived From http://stackoverflow.com/a/7475744
Function Clone-Object {
    Param([Parameter(Mandatory=$true,ValueFromPipeline=$true)]$Source)
    Process
    {
        $MemoryStream = New-Object IO.MemoryStream
        $Formatter = New-Object Runtime.Serialization.Formatters.Binary.BinaryFormatter
        $Formatter.Serialize($MemoryStream, $Source)
        $MemoryStream.Position = 0
        $Formatter.Deserialize($MemoryStream)
    }
}

# GOTCHA: If using pipeline input, KeyProperty must be used as a Named Parameter, not Positional
# If no KeyProperty is given, a hash table is created with integer indexes
function ConvertTo-KeyedHashTable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$InputObject,
        [string]$KeyProperty
    )
    
    Begin { $Dict = @{}; $i = 0 }
    Process {
        if ($KeyProperty -eq $null) { $Key = $i }
        else { $Key = $InputObject.$($KeyProperty) }
        $Dict += @{$Key=$InputObject}
        if ($i % 100 -eq 99) { Write-Verbose "$($i+1) Records Added." }
        $i++
    }
    End {$Dict}
}

# FUTURE: Customize so that Primary Array can be from the Pipeline
# Why isn't it like that already? Because new data is unordered. Ordering data requires having all the data already.
# So the new, and therefore unordered, data must come in by the Pipeline.
Function Merge-Object {
    [CmdletBinding()]
     Param(
        [Parameter(Mandatory=$true,Position=0)][object[]]$Base,
        [Alias("Key")][string]$BaseKey='',
        [string]$InputKey=$BaseKey,
        [switch]$AppendExtras=$false,     #Input
        [switch]$DiscardLeftovers=$false, #Base
        [switch]$OrderedBase=$false,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][object]$_
        )
    Begin {
        Function Merge($Base, $Additional) {
            $Clone = $Base | Clone-Object
            ForEach ($Property in $($Additional | Get-Member -Type Property, NoteProperty))
            {
                $Clone | Add-Member -MemberType NoteProperty -Name $Property.name `
                    -Value $Additional.$($Property.Name) -ErrorAction SilentlyContinue
            }
            Return $Clone
        }
        Write-Verbose "Initializing Hash and Indexes"
        $BaseHash=@{} ;$i=0; $BaseIndex=0; $BaseKeyIndex=$null
    }
    Process {
        Write-Verbose "$i $BaseIndex $($_.$($InputKey)) $BaseKeyIndex"
        $Merger = $null # The object from the base to merge with the current pipline input
        if ($BaseKey -ne '' -and $InputKey -ne '' -and 
            ($_.$($InputKey) -eq $null -or $Base[$BaseIndex].$($BaseKey) -eq $null)) {
            if ($_.$($InputKey) -eq $null -and $Base[$BaseIndex].$($BaseKey) -eq $null) {
                Throw "Both the current base and input have a null key property."
            } elseif ($_.$($InputKey) -eq $null) {
                Throw "The current input has a null key property."
            } elseif ($Base[$BaseIndex].$($BaseKey) -eq $null) {
                Throw "The current base has a null key property."
            }
        }
        if ($BaseKey -eq '') {
            $Merger = $Base[$i]
            $BaseIndex++
        } elseif ($BaseHash.ContainsKey($_.$($InputKey))) {
            $Merger = $BaseHash[$_.$($InputKey)]
            $BaseHash.Remove($_.$($InputKey))
        } else {
            while(
                $Base[$BaseIndex] -ne $null -and
                $_.$($InputKey) -ne $Base[$BaseIndex].$($BaseKey) -and
                (!$OrderedBase -or $BaseKeyIndex -lt $_.$($InputKey))
            ) {
                $BaseHash.Add($Base[$BaseIndex].$($BaseKey), $Base[$BaseIndex])
                $BaseKeyIndex = $Base[$BaseIndex].$($BaseKey)
                $BaseIndex++
                if ($BaseIndex -ne 0 -and $BaseIndex % 100 -eq 0)
                { Write-Verbose "$BaseIndex BaseObjects Processed" }
            } 
            if ($_.$($InputKey) -eq $Base[$BaseIndex].$($BaseKey)) {
                $Merger = $Base[$BaseIndex]
                $BaseKeyIndex = $Base[$BaseIndex].$($BaseKey)
                $BaseIndex++
                if ($BaseIndex -ne 0 -and $BaseIndex % 100 -eq 0)
                { Write-Verbose "$BaseIndex BaseObjects Processed" }
            }
        }

        if ($Merger -eq $null) {
            if ($AppendExtras) {$_ | Clone-Object}
        } else { Merge $Merger $_ }
        $i++
        if ($i -ne 0 -and $i % 200 -eq 0) {Write-Verbose "$i InputObjects Processed"}
    }
    End {
        Write-Verbose $BaseIndex
        if (!$DiscardLeftovers) {
            Write-Verbose "Emptying Base Cache"
            $BaseHash.GetEnumerator() | % { $_.Value | Clone-Object }
            while ($Base[$BaseIndex] -ne $null) {
                $Base[$BaseIndex] | Clone-Object
                $BaseIndex++
                if ($BaseIndex -ne 0 -and $BaseIndex % 100 -eq 0)
                { Write-Verbose "$BaseIndex BaseObjects Processed" }
            }
        }
    }
}