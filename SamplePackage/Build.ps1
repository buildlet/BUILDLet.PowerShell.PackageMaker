<###############################################################################
 The MIT License (MIT)

 Copyright (c) 2020 Daiki Sakamoto

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
################################################################################>

# Parameter(s)
Param(
    [Parameter()]
    [ValidateScript({ Test-Path -Path $_ })]
    [string]
    # 設定ファイル (INI ファイル) のパスを指定します。
    $Path = ($PSScriptRoot | Join-Path -ChildPath 'Build.ini')
)

# Required Module(s)
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.Utilities'; ModuleVersion = '1.6.6' }
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.PackageMaker'; ModuleVersion = '1.6.7' }

# Script Version
$ScriptVersion = '1.6.8'

# Foreground Color
$ForegroundColor = 'Green'


################################################################################
# Function(s)
################################################################################

# ConvertFrom-Expression
Function ConvertFrom-Expression($expression) {

    # Null Check
    if ($null -ne $expression) {

        if ($expression.Trim() -like '{*}') {

            # UPDATE $expression (Remove outer '{}')
            $expression = $expression.Trim().Substring(1, $expression.Trim().Length - 2).Trim()

            if ($expression -like '{*}') {

                # RETURN $expression w/o outer '{}'
                return $expression
            }
            else {
                
                # RETURN $expression executed result
                return (Invoke-Expression -Command $expression)
            }
        }
    }

    # RETURN original $expression
    return $expression
}

# Out-ElapsedTime
Function Out-ElapsedTime {

    # Parameter(s)
    Param([datetime]$StartTime)

    # GET Curent Time
    $CurrentTime = Get-Date

    # GET Curent Time Text (as Formated Text)
    $CurrentTimeText = ($CurrentTime).ToString('yyyy/MM/dd hh:mm:ss')

    # GET Elapsed Time Text (as Formated Text)
    $ElapsedTimeText = ($CurrentTime - $StartTime).ToString()

    # OUTPUT Current Time and Elapsed Time
    "$CurrentTimeText (Elapsed Time: $ElapsedTimeText)" | Write-Host -ForegroundColor $ForegroundColor
}

################################################################################
# START
################################################################################

# OUTPUT: START Message
@"
************************************************
 BUILDLet PackageMaker Toolkit for PowerShell
 (BUILDLet.PowerShell.PackageMaker)
 Build Script Version $ScriptVersion
 Copyright (C) 2020 Daiki Sakamoto
************************************************
"@ |
Write-Host -ForegroundColor $ForegroundColor

# OUTPUT: START Time
($StartTime = Get-Date).ToString('yyyy/MM/dd hh:mm:ss') | Write-Host -ForegroundColor $ForegroundColor

# OUTPUT
"Read Settings from '$Path'..." | Write-Host -ForegroundColor $ForegroundColor

# GET Settings from Settings File (.ini)
$Settings = Get-PrivateProfile -InputObject (Get-Content -Path $Path -Raw | Expand-InfStringKey -ErrorAction 'Stop') -ErrorAction 'Stop'


# SET Preferences
if ($Settings.ContainsKey('Preferences')) {

    # for Preferences
    $Settings.'Preferences'.Keys | ForEach-Object {

        # GET Preference
        $pref_key = $_
        $pref_value = $Settings.'Preferences'.$pref_key

        # SET Preference
        switch ($pref_key) {
            'VerbosePreference' {
                
                # SET VerbosePreference
                $Script:VerbosePreference = $pref_value
            }
            'ErrorActionPreference' {

                # SET ErrorActionPreference
                $Script:ErrorActionPreference = $pref_value
            }
            Default {}
        }

        # OUTPUT Preference
        ("Set `$Script:$pref_key = '" + ($pref_value) + "'") | Write-Host -ForegroundColor $ForegroundColor
    }
}


# for each Tasks
$Settings.'Tasks'.Keys | ForEach-Object {

    # GET Key & Value
    $task_id = $_
    $task_name = $Settings.'Tasks'.$task_id

    # GET Task & Command
    $Task = $Settings.$task_name
    $command = $Task.'Command'

    # OUTPUT: Current Time, Elapsed Time, Key, Task and Command
    ''
    Out-ElapsedTime $StartTime
    "Task[$task_id]: $task_name" | Write-Host -ForegroundColor $ForegroundColor
    "  $command" | Write-Host -ForegroundColor $ForegroundColor

    # GET Command Parameter(s)
    $Parameters = @{}
    $OutputRedirection = $null
    $Task.Keys | Where-Object { $_ -ne 'Command' } | ForEach-Object {

        # GET Parameter Name & Value
        $param_name = $_
        $param_value = $Task.$param_name

        # Check Parameter
        if (($param_name -match '\> *\$null') -and ($null -eq $param_value)) {

            # Parameter is Output Null Redirection

            # SET Null Output Redirection
            $OutputRedirection = $param_name

            # To avoid UseDeclaredVarsMoreThanAssignments (#0414)
            $OutputRedirection > $null
        }
        else {
        
            # BUILD Command Parameter(s)

            # UPDATE Parameter Value as Array, Hashtable or other
            if ($param_value -like "@ARRAY:*") {

                # BUILD Parameter as Array
                $array_section = $Settings.$param_value
                $array_param = @()
                $array_section.Keys | Sort-Object | ForEach-Object {

                    # ADD value of Parameter Array
                    $array_param += ConvertFrom-Expression($array_section.$_)
                }

                # Overwrite as Array
                $param_value = $array_param
            }
            elseif ($param_value -like "@HASHTABLE:*") {
                    
                # BUILD Parameter as Hashtable
                $hashtable_section = $Settings.$param_value
                $hashtable_param = @{}
                $hashtable_section.Keys | ForEach-Object {

                    # ADD value of Parameter Hashtable
                    $hashtable_param += @{ $_ = ConvertFrom-Expression($hashtable_section.$_) }
                }

                # Overwrite as Hashtable
                $param_value = $hashtable_param
            }
            else {

                # Execute Expression if needed
                $param_value = ConvertFrom-Expression($param_value)
            }

            # ADD Parameter
            $Parameters += @{ $param_name = $param_value }

            # OUTPUT: Command Parameter(s)
            if ($param_value -is [array]) {

                # OUTPUT: Parameter as Array
                "    -$param_name @(" | Write-Host -ForegroundColor $ForegroundColor
                for ($i = 0; $i -lt $param_value.Count; $i++) {
                    ("      " + $param_value[$i]) | Write-Host -ForegroundColor $ForegroundColor
                }
                "    )" | Write-Host -ForegroundColor $ForegroundColor
            }
            elseif ($param_value -is [hashtable]) {

                # OUTPUT: Parameter as Hashtable
                "    -$_ @{" | Write-Host -ForegroundColor $ForegroundColor
                $param_value.Keys | ForEach-Object {
                    ("      " + $_ + ' = ' + $param_value.$_) | Write-Host -ForegroundColor $ForegroundColor
                }
                "    }" | Write-Host -ForegroundColor $ForegroundColor
            }
            else {

                # OUTPUT: Parameter (NOT Array / Hashtable)
                ("    -$_ " + $param_value) | Write-Host -ForegroundColor $ForegroundColor
            }
        }
    }

    # OUTPUT: Append Output Redirection
    if ($OutputRedirection) {
        "    $OutputRedirection" | Write-Host -ForegroundColor $ForegroundColor
    }

    # Keys includes 'Command' 
    if ($null -ne $command) {

        # GET Expression
        $Expression = $command

        # Append Parameters to Expression
        if ($Parameters.Count -gt 0) { $Expression += ' @Parameters' }

        # Append VerbosePreferences to Expression
        $Expression += ' -Verbose:($Script:VerbosePreference -ne "SilentlyContinue")'
        if ($null -ne $Script:ErrorActionPreference) { $Expression += ' -ErrorAction $Script:ErrorActionPreference' }

        # Append Output Redirection to Expression
        $Expression += " $OutputRedirection"

        # Verbose Output: Expression
        "Expression = $Expression" | Write-Verbose

        # Execute Command with Parameter(s)
        Invoke-Expression -Command $Expression
    }
}
# for each Tasks

# OUTPUT: END Time (and Elapsed Time)
''
Out-ElapsedTime $StartTime
#>
