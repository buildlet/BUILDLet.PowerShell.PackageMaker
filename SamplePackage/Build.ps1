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


<###############################################################################
 Parameter(s)
################################################################################>
Param(
    [Parameter()]
    [ValidateScript({ Test-Path -Path $_ })]
    [string]
    # 設定ファイル (INI ファイル) のパスを指定します。
    $Path = ($PSScriptRoot | Join-Path -ChildPath 'Build.ini')
)


<###############################################################################
 Requires
################################################################################>
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.Utilities'; ModuleVersion = '1.5.2' }
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.PackageMaker'; ModuleVersion = '1.5.2' }


<###############################################################################
 Variable(s)
################################################################################>
# Script Version
$ScriptVersion = '1.5.3'

# Foreground Color
$ForegroundColor = 'Green'


<###############################################################################
 Function(s)
################################################################################>
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


<###############################################################################
 Process
################################################################################>
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

# OUTPUT: START Time & $Path (Setting File Name)
($StartTime = Get-Date).ToString('yyyy/MM/dd hh:mm:ss') + ' [START]' | Write-Host -ForegroundColor $ForegroundColor

# OUTPUT
"Read Settings from '$Path'..." | Write-Host -ForegroundColor $ForegroundColor

# GET Settings from Settings File (.ini)
$Settings = Get-PrivateProfile -InputObject (Get-Content -Path $Path -Raw | Expand-InfStringKey -ErrorAction 'Stop') -ErrorAction 'Stop'

# OUTPUT
# (Get-Date).ToString('yyyy/MM/dd hh:mm:ss') | Write-Host -ForegroundColor $ForegroundColor


# GET Preferences
if ($Settings.ContainsKey('Preferences')) {

    # VerbosePreference
    if ($Settings.'Preferences'.ContainsKey('VerbosePreference')) {

        # SET VerbosePreference
        $Script:VerbosePreference = $Settings.'Preferences'.'VerbosePreference'
    }

    # ErrorActionPreference
    if ($Settings.'Preferences'.ContainsKey('ErrorActionPreference')) {

        # SET ErrorActionPreference
        $Script:ErrorActionPreference = $Settings.'Preferences'.'ErrorActionPreference'
    }

}


# for each Tasks
$Settings.'Tasks'.Keys | ForEach-Object {

    # GET Key & Value
    $key = $_
    $value = $Settings.'Tasks'.$key

    # GET Task & Command
    $Task = $value
    $Command = $Settings.$Task.'Command'

    # OUTPUT: Key, Task, Command
    ''
    "Task[$key]: $Task" | Write-Host -ForegroundColor $ForegroundColor
    "  $Command" | Write-Host -ForegroundColor $ForegroundColor


    # GET Command Parameter(s)
    $Parameters = @{}
    $Settings.$Task.Keys | Where-Object { $_ -ne 'Command' } | ForEach-Object {

        # GET Parameter Name & Value
        $param_name = $_
        $param_value = $Settings.$Task.$_

        # SET NullOutput Flag: If outout should be redirected, or not.
        $NullOutput = ($param_name -eq '>null')

        # SET VariableOutput Flag 
        $VariableOutput = ($param_name -like '->*')


        # BUILD Command Parameter(s)
        if ((-not $NullOutput) -and (-not $VariableOutput)) {

            # UPDATE Parameter Value as Array or Hashtable
            if ($param_value -like "$Task*") {

                # Check if all Keys are int, or not
                $int_Keys = @()
                $parsed = -1
                $Settings.$param_value.Keys | ForEach-Object { $int_Keys += [int]::TryParse($_, [ref]$parsed) }

                if ($int_Keys -notcontains $false) {
                
                    # BUILD Parameter as Array
                    $param_array = @()
                    $Settings.$param_value.Keys | Sort-Object | Where-Object {

                        # ADD value of Parameter Array
                        $param_array += ConvertFrom-Expression($Settings.$param_value.$_)
                    }
                    $param_value = $param_array
                }
                else {
                    
                    # BUILD Parameter as Hashtable
                    $param_hashtable = @{}
                    $Settings.$param_value.Keys | Where-Object {

                        # ADD value of Parameter Hashtable
                        $param_hashtable += @{ $_ = ConvertFrom-Expression($Settings.$param_value.$_) }
                    }
                    $param_value = $param_hashtable
                }
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
                "    -$param_name {" | Write-Host -ForegroundColor $ForegroundColor
                for ($i = 0; $i -lt $param_value.Count; $i++) {
                    ("      " + $param_value[$i]) | Write-Host -ForegroundColor $ForegroundColor
                }
                "    }" | Write-Host -ForegroundColor $ForegroundColor
            }
            elseif ($param_value -is [hashtable]) {

                # OUTPUT: Parameter as Hashtable
                "    -$_ {" | Write-Host -ForegroundColor $ForegroundColor
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


        # GET Variable Name
        $var_name > $null
        if ($VariableOutput) {
            $var_name = $param_name.Substring('->'.Length).Trim()
        }
    }


    # Keys includes 'Command' 
    if ($null -ne $Command) {

        # GET Expression
        $Expression = $Command
        if ($Parameters.Count -gt 0) { $Expression += ' @Parameters' }
        $Expression += ' -Verbose:($Script:VerbosePreference -ne "SilentlyContinue")'
        if ($null -ne $Script:ErrorActionPreference) { $Expression += ' -ErrorAction $Script:ErrorActionPreference' }

        # Verbose Output: Expression
        "Expression = $Expression" | Write-Verbose


        # Execute Command with Parameter(s)
        Invoke-Expression -Command $Expression | ForEach-Object {

            # GET Result
            $result = $_

            # Switch output
            if ($NullOutput) {

                # Redirect output to NULL
                $result > $null
            }
            elseif ($VariableOutput) {

                # Redirect output to Variable
                $result | Set-Variable -Name $var_name -Scope 'Script'

                # OUTPUT Variable Name & Value
                "  Variable '$var_name' = $result" | Write-Host -ForegroundColor $ForegroundColor
            }
            else {

                # DO NOT Redirect output to NULL
                $result
            }
        }
    }
}
# for each Tasks


# GET End Time & its Text
$EndTimeText = ($EndTime = Get-Date).ToString('yyyy/MM/dd hh:mm:ss')

# END Time (and Elapsed Time)
''
"$EndTimeText [END] (Elapsed Time = " + ($EndTime - $StartTime).ToString() + ")" | Write-Host -ForegroundColor $ForegroundColor
#>
