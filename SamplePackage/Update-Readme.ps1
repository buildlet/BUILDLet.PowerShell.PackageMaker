<###############################################################################
 The MIT License (MIT)

 Copyright (c) 2021 Daiki Sakamoto

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
Param (
    [Parameter(ParameterSetName = 'Path', Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]
    # 入力ファイルのパスを指定します。
    $Path,

    [Parameter(ParameterSetName = 'Path', Mandatory = $true, Position = 1)]
    [hashtable]
    # 置換対象の文字列セットを指定します。
    $SubstitutionTable,

    [Parameter(ParameterSetName = 'Path')]
    [string]
    # 入力ファイルのエンコーディングを指定します。
    # 既定のエンコーディングは UTF8 です。
    $Encoding = 'UTF8',

    [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
    [switch]
    # このスクリプトのバージョンを表示します。
    $Version
)


# Required Module(s)
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.Utilities'; ModuleVersion = '1.6.0' }
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.PackageMaker'; ModuleVersion = '1.6.0' }


# SET Script Version
$ScriptVersion = '1.6.0'

# RETURN: Version
if ($Version) { return $ScriptVersion }


# Replace strings & Output it to File
(Get-Content -Path $Path -Encoding $Encoding -Raw | Get-StringReplacedBy -SubstitutionTable $SubstitutionTable) `
| Out-File -FilePath $Path -Encoding $Encoding -NoNewline
