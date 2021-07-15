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

# Target Module:
$target_module_name = 'BUILDLet.PowerShell.PackageMaker'

# Check Required Module
. ($PSScriptRoot | Join-Path -ChildPath Test-RequiredModule.ps1)

# Import Target Module
# (Get Target Module, remove it if required, and import it again)
if ($null -ne ($target_module = Get-Module -Name $target_module_name)) { $target_module | Remove-Module }
Import-Module -Name ($PSScriptRoot | Split-Path -Parent | Join-Path -ChildPath $target_module_name)


# NEW & SET $TargetDir
$TargetDir = New-Item -Path ($PSScriptRoot | Join-Path -ChildPath 'bin') -ItemType Directory -Force


# Get-WindowsKitsToolPath
Describe "Get-WindowsKitsToolPath" {

    BeforeEach {

        # Set Location
        $TargetDir | Set-Location
    }


    AfterEach {

        # Reset Location
        $PSScriptRoot | Set-Location
    }


    Context "When External Program File is specified" {

        $TestCase = @(

            # 1) signtool.exe, *, *
            @{
                FileName = 'signtool.exe'
                Version = '*'
                Platform = '*'
            }

            # 2) signtool.exe, 10.0.19041.0, x86
            @{
                FileName = 'signtool.exe'
                Version = '10.0.19041.0'  # (2020/6/28)
                Platform = 'x86'
            }

            # 3) signtool.exe, *, * -> Not Found
            @{
                FileName = 'signtool.exe'
                Version = $null
                Platform = $null
            }

            # 4) inf2cat.exe, $null, $null
            @{
                FileName = 'inf2cat.exe'
                Version = $null
                Platform = $null
            }

            # 5) inf2cat.exe, *, *
            @{
                FileName = 'inf2cat.exe'
                Version = '*'
                Platform = '*'
            }
        )

        It "returns path array" -TestCases $TestCase {

            # PARAMETER(S)
            Param($FileName, $Version, $Platform)

            # ACT
            if ($Version -and $Platform) {
                $actual = Get-WindowsKitsToolPath -FileName $FileName -Version $Version -Platform $Platform
            }
            elseif ((-not $Version) -and $Platform) {
                $actual = Get-WindowsKitsToolPath -FileName $FileName -Platform $Platform
            }
            elseif ($Version -and (-not $Platform)) {
                $actual = Get-WindowsKitsToolPath -FileName $FileName -Version $Version
            }
            else {
                $actual = Get-WindowsKitsToolPath -FileName $FileName
            }

            # OUTPUT (Count)
            ("`tNumber of Path Array = " + $actual.Count) | Write-Host

            for ($i = 0; $i -lt $actual.Count; $i++) {

                # OUTPUT
                ("`tPath[$i] = '" + $actual[$i] + "'") | Write-Host
                
                # ASSERT
                $actual[$i] | Should Exist
            }
        }
    }
}