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
. ($PSScriptRoot | Join-Path -ChildPath 'RequiredModule.ps1')

# Import Target Module
# (Get Target Module, remove it if required, and import it again)
if ($null -ne ($target_module = Get-Module -Name $target_module_name)) { $target_module | Remove-Module }
Import-Module -Name ($PSScriptRoot | Split-Path -Parent | Join-Path -ChildPath $target_module_name)


# NEW & SET $TargetDir
$TargetDir = New-Item -Path ($PSScriptRoot | Join-Path -ChildPath 'bin') -ItemType Directory -Force


# Get-AuthenticodeTimeStampString
Describe "Get-AuthenticodeTimeStampString" {

    BeforeEach {

        # Set Location
        Set-Location -Path $TargetDir
    }


    AfterEach {

        # Reset Location
        Set-Location -Path $PSScriptRoot
    }


    Context "normally" {

        $TestCase = @(

            # 1) 
            @{
                TestDirName = 'TestPackage'
                SignToolVersion = $null
                SignToolPlatform = $null
                SignToolPath = $null
                FilePath = @('Test.dll', 'Test2.dll')
                Verbose = $true
            }
        )

        It "gets Authenticode Time Stamp" -TestCases $TestCase {

            # PARAMETER(S)
            Param($TestDirName, $SignToolVersion, $SignToolPlatform, $SignToolPath, $FilePath, $Verbose)


            # ARRANGE: Set Location
            Set-Location -Path ($TargetDir | Join-Path -ChildPath $TestDirName)


            # Validate Target File existence
            $FilePath | ForEach-Object {

                # SET Test Inconclusive
                if (-not ($_ | Test-Path)) {
                    Set-TestInconclusive -Message ("Target File '$_' was not found.")
                }
            }

            
            # ACT
            if ($SignToolPath) {

                # $SignToolPath is specified.
                $actual = Get-AuthenticodeTimeStampString -SignToolPath $SignToolPath `
                    -FilePath $FilePath -Verbose:$Verbose
            }
            else
            {
                # $SignToolPath is NOT specified.

                if ($SignToolVersion -and $SignToolPlatform) {

                    # $SignToolVersion and $SignToolPlatform is specified.
                    $actual = Get-AuthenticodeTimeStampString -SignToolVersion $SignToolVersion -SignToolPlatform $SignToolPlatform `
                        -FilePath $FilePath -Verbose:$Verbose
                }
                elseif ($SignToolVersion) {

                    # $SignToolVersion is specified.
                    # ($SignToolPlatform is NOT specified.)
                    $actual = Get-AuthenticodeTimeStampString -SignToolVersion $SignToolVersion `
                        -FilePath $FilePath -Verbose:$Verbose
                }
                elseif ($SignToolPlatform) {

                    # $SignToolPlatform is specified.
                    # ($SignToolVersion is NOT specified.)
                    $actual = Get-AuthenticodeTimeStampString -SignToolPlatform $SignToolPlatform `
                        -FilePath $FilePath -Verbose:$Verbose
                }
                else {

                    # $SignToolVersion and $SignToolPlatform is NOT specified.
                    $actual = Get-AuthenticodeTimeStampString `
                        -FilePath $FilePath -Verbose:$Verbose
                }
            }

            # OUTPUT
            $actual | ForEach-Object { "`t$_" | Write-Host }

            # ASSERT
            # (None)
        }
    }
}