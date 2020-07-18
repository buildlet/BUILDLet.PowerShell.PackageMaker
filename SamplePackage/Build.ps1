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
#Requires -Modules BUILDLet.PowerShell.Utilities
#Requires -Modules BUILDLet.PowerShell.PackageMaker


<###############################################################################
 Variable(s)
################################################################################>
$ScriptVersion = '1.0.0.0'


<###############################################################################
 Function(s)
################################################################################>
Function PrintTask ($taskNum, $task, $arg) {

    # OUTPUT
    ("Task[$taskNum]: $task $arg") | Write-Host -ForegroundColor $ForegroundColor
}

Function GetParameters ($words) {

    # Container for return value
    $params = @{}


    # for words
    $words | ForEach-Object {

        # GET word
        $word = $_

        if (-not $word.Contains('=')) {
            
            # Parameters:

            # GET Section of PARAMETERS from word
            $section = $Settings[$word]

            # for section of 1st word
            $section.Keys | ForEach-Object {

                # GET Parameter
                $param_name = $_.Trim()
                $param_value = $section[$_].Trim()
        
                # OUTPUT
                "    + '$param_name' = '$param_value'" | Write-Host -ForegroundColor $ForegroundColor
        
                # ADD Parameter
                $params += @{ $param_name = $param_value }
            }
        }
        else {

            # Parameter Name and its value array:

            # GET Parameter Name, Section Name of parameter value array and its content
            $param_name = $word.Split('=')[0].Trim()
            $param_value_section_name = $word.Split('=')[1].Trim()
            $param_value_section = $Settings[$param_value_section_name]

            # Container of parameter value array
            $param_value_array = @()

            # for parameter value array
            $param_value_section.Keys | Sort-Object | ForEach-Object {

                # GET Key number of parameter value array
                $numkey = $_.Trim()

                # GET Value of parameter value array
                $param_value = $param_value_section[$numkey].Trim()

                # OUTPUT
                "    + '$param_name'[$numkey] = '$param_value'" | Write-Host -ForegroundColor $ForegroundColor

                # ADD Value
                $param_value_array += $param_value_section[$numkey].Trim()
            }

            # ADD Parameter
            $params += @{ $param_name = $param_value_array }
        }
    }


    # RETURN
    return $params
}

<###############################################################################
 Process
################################################################################>

# OUTPUT
''
'[' + $MyInvocation.MyCommand + '] is reading the Settings...'

# GET Settings from Settings File (.ini)
$Settings = . ($PSScriptRoot | Join-Path -ChildPath 'Get-Settings.ps1') -Path $Path


# SET Preferences and Variable(s)
$Script:ErrorActionPreference = $Settings.'Preferences'.'ErrorActionPreference'
$Script:VerbosePreference = $Settings.'Preferences'.'VerbosePreference'
$ForegroundColor = $Settings.'Preferences'.'ForegroundColor'


# START Message
@"
***********************************************
 BUILDLet PackageMaker Toolkit for PowerShell
 (BUILDLet.PowerShell.PackageMaker)
 Sample Package Build Script (Version $ScriptVersion)
 Copyright (C) 2020 Daiki Sakamoto
***********************************************
"@ |
Write-Host -ForegroundColor $ForegroundColor

# START Time
'START: ' + ($StartTime = Get-Date).ToString('yyyy/MM/dd hh:mm:ss') |
Write-Host -ForegroundColor $ForegroundColor


# Do Tasks
$Settings.'Tasks'.Keys | Sort-Object | ForEach-Object {

    # GET Key, Value, Task, and continuing Words
    $key = $_
    $value = $Settings.'Tasks'.$Key
    $task = $value.Split(':')[0]
    $words = @($value.Split(':')[1].Split(','))

    # Switch Tasks
    switch ($task) {

        'Remove' {

            # SET Variable(s)
            $item = $words[0].Trim()

            # OUTPUT
            PrintTask $key $task "'$item'"

            # Remove Item (File or Directory)
            if (Test-Path -Path $item) { Remove-Item -Path $item -Recurse -Force }
        }

        'MkDir' {

            # SET Variable(s)
            $dir = $words[0].Trim()

            # OUTPUT
            PrintTask $key $task "'$item'"

            # NEW Directory
            New-Item -Path $dir -ItemType Directory -Force > $null
        }

        'Copy' {

            # SET Variable(s)
            $src = $words[0].Trim()
            $dest = $words[1].Trim()

            # OUTPUT
            PrintTask $key $task "'$src' -> '$dest'"

            # COPY File
            Copy-Item -Path $src -Destination $dest -Recurse -Force
        }

        'Move' {

            # SET Variable(s)
            $src = $words[0].Trim()
            $dest = $words[1].Trim()

            # OUTPUT
            PrintTask $key $task "'$src' -> '$dest'"

            # MOVE Item (File or Directory)
            Move-Item -Path $src -Destination $dest -Force
        }

        'Rename' {

            # SET Variable(s)
            $src = $words[0].Trim()
            $dest = $words[1].Trim()

            # OUTPUT
            PrintTask $key $task "'$src' -> '$dest'"

            # RENAME Item (File or Directory)
            Rename-Item -Path $src -NewName $dest -Force
        }

        'Expand' {

            # SET Variable(s)
            $src = $words[0].Trim()
            $dest = $words[1].Trim()
            $passwd = $words[2].Trim()

            # OUTPUT
            PrintTask $key $task "'$src' -> '$dest'"

            # Expand Zip File
            Expand-ZipFile -Path $src -DestinationPath $dest -Password $passwd -Force -Verbose:($VerbosePreference -ne 'SilentlyContinue') > $null
        }

        'Zip' {

            # SET Variable(s)
            $src = $words[0].Trim()
            $dest = $words[1].Trim()
            $passwd = $words[2].Trim()

            # OUTPUT
            PrintTask $key $task "'$src' -> '$dest'"

            # NEW Zip File
            New-ZipFile -Path $src -DestinationPath $dest -Password $passwd -Force -Verbose:($VerbosePreference -ne 'SilentlyContinue')
        }

        'Sign' {

            # OUTPUT
            PrintTask $key $task

            # GET Parameters
            $params = GetParameters $words

            # ADD Signature
            Invoke-SignTool @params -Command 'sign' -Verbose:($VerbosePreference -ne 'SilentlyContinue')
        }

        'Inf2Cat' {

            # OUTPUT
            PrintTask $key $task

            # GET Parameters
            $params = GetParameters $words

            # NEW Catalog File
            Invoke-Inf2Cat @params -Verbose:($VerbosePreference -ne 'SilentlyContinue')
        }

        'GenIsoImage' {

            # OUTPUT
            PrintTask $key $task

            # GET Parameters
            $params = GetParameters $words

            # NEW ISO Image File
            New-IsoImageFile @params -Force -Verbose:($VerbosePreference -ne 'SilentlyContinue')
        }

        'Readme' {

            # OUTPUT
            PrintTask $key $task

            # GET Parameters
            $params = GetParameters $words

            # NEW ISO Image File
            .\Update-Readme.ps1 @params -Verbose:($VerbosePreference -ne 'SilentlyContinue')
        }

        Default {
            # Throw NotSupportedExcepction
            throw New-Object System.NotSupportedException
        }
    }
    # Switch Tasks
}
# Do Tasks


# END Time (and Elapsed Time)
'END: ' + ($EndTime = Get-Date).ToString('yyyy/MM/dd hh:mm:ss') +
" (Elapsed Time: " + ($EndTime - $StartTime).ToString() + ")" |
Write-Host -ForegroundColor $ForegroundColor
#>
