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


# Invoke-SignTool
Describe "Invoke-SignTool" {

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
                Command = 'sign'
                Options = @('/f ..\..\Test.pfx', '/p 12345', '/t http://timestamp.digicert.com/?alg=sha1', '/v')
                FilePath = @('Test.dll', 'Test2.dll')
                OutputEncoding = [System.Text.Encoding]::UTF8
                PassThru = $true
                RetryCount = 0
                RetrySecond = 0
                PacketSize = 0
                Verbose = $true
            }
        )

        It "adds code signing" -TestCases $TestCase {

            # PARAMETER(S)
            Param($TestDirName, $SignToolVersion, $SignToolPlatform, $SignToolPath, $Command, $Options, $FilePath,
                $OutputEncoding, $PassThru, $RetryCount, $RetrySecond, $PacketSize, $Verbose)


            # ARRANGE: NEW Package Directory
            New-Item -Path ($TargetDir | Join-Path -ChildPath $TestDirName) -ItemType Directory -Force

            # ARRANGE: COPY BUILDLet.PowerShell.Utilities.dll -> $TargetDir/TestPackage/*.dll
            $FilePath | ForEach-Object {

                # Target File Path
                $target_filepath = $TargetDir | Join-Path -ChildPath $TestDirName | Join-Path -ChildPath $_

                # COPY Target File
                Copy-Item `
                    -Path ((Get-InstalledModule -Name 'BUILDLet.PowerShell.Utilities').InstalledLocation | Join-Path -ChildPath 'BUILDLet.PowerShell.Utilities.dll') `
                    -Destination $target_filepath `
                    -Force
            }

            # ARRANGE: Set Location
            Set-Location -Path ($TargetDir | Join-Path -ChildPath $TestDirName)

            
            # ACT
            if ($SignToolPath) {

                # $SignToolPath is specified.
                $actual = Invoke-SignTool -SignToolPath $SignToolPath `
                    -Command $Command -Options $Options -FilePath $FilePath -OutputEncoding $OutputEncoding -PassThru:$PassThru `
                    -RetryCount $RetryCount -RetrySecond $RetrySecond -PacketSize $PacketSize -Verbose:$Verbose
            }
            else
            {
                # $SignToolPath is NOT specified.

                if ($SignToolVersion -and $SignToolPlatform) {

                    # $SignToolVersion and $SignToolPlatform is specified.
                    $actual = Invoke-SignTool -SignToolVersion $SignToolVersion -SignToolPlatform $SignToolPlatform `
                        -Command $Command -Options $Options -FilePath $FilePath -OutputEncoding $OutputEncoding -PassThru:$PassThru `
                        -RetryCount $RetryCount -RetrySecond $RetrySecond -PacketSize $PacketSize -Verbose:$Verbose
                }
                elseif ($SignToolVersion) {

                    # $SignToolVersion is specified.
                    # ($SignToolPlatform is NOT specified.)
                    $actual = Invoke-SignTool -SignToolVersion $SignToolVersion `
                        -Command $Command -Options $Options -FilePath $FilePath -OutputEncoding $OutputEncoding -PassThru:$PassThru `
                        -RetryCount $RetryCount -RetrySecond $RetrySecond -PacketSize $PacketSize -Verbose:$Verbose
                }
                elseif ($SignToolPlatform) {

                    # $SignToolPlatform is specified.
                    # ($SignToolVersion is NOT specified.)
                    $actual = Invoke-SignTool -SignToolPlatform $SignToolPlatform `
                        -Command $Command -Options $Options -FilePath $FilePath -OutputEncoding $OutputEncoding -PassThru:$PassThru `
                        -RetryCount $RetryCount -RetrySecond $RetrySecond -PacketSize $PacketSize -Verbose:$Verbose
                }
                else {

                    # $SignToolVersion and $SignToolPlatform is NOT specified.
                    $actual = Invoke-SignTool `
                        -Command $Command -Options $Options -FilePath $FilePath -OutputEncoding $OutputEncoding -PassThru:$PassThru `
                        -RetryCount $RetryCount -RetrySecond $RetrySecond -PacketSize $PacketSize -Verbose:$Verbose
                }
            }

            # ASSERT
            $actual | Should Be 0
        }
    }
}