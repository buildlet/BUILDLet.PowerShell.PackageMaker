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


# Invoke-Inf2Cat
Describe "Invoke-Inf2Cat" {

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
                InfFileContent =
@'
[Version]
Signature="$Windows NT$"
Provider=%Company%
ClassGUID={4D36E979-E325-11CE-BFC1-08002BE10318}
Class=Printer
CatalogFile=Test.CAT
DriverVer=06/29/2020,1.0.0.0
ClassVer=4.0

[Manufacturer]
%Company%=BUILDLet,NTamd64

[BUILDLet]
"Test Printer 9000" = Test9000,USBPRINT\BUILDLetTest_Printer66E5
"Test Printer 9100" = Test9000,USBPRINT\BUILDLetTest_PrinterA6B4

[BUILDLet.NTamd64]
"Test Printer 9000" = Test9000,USBPRINT\BUILDLetTest_Printer66E5
"Test Printer 9100" = Test9000,USBPRINT\BUILDLetTest_PrinterA6B4

[Test9000]
CopyFiles=Test9000_FILES

[Test9000_FILES]
Test.dll
Test2.dll

[SourceDisksNames.amd64]
1 = %DISK1%,,,

[SourceDisksNames.x86]
1 = %DISK1%,,,

[DestinationDirs]
DefaultDestDir=66000

[SourceDisksFiles]
Test.dll=1
Test2.dll=1

[Strings]
Company="BUILDLet"
DISK1="BUILDLet Test Printer 9000 Installation DVD"
'@
                InfFileName = 'Test.inf'
                OtherFileNames = @('Test.dll', 'Test2.dll')
                Inf2CatVersion = $null
                Inf2CatPlatform = $null
                Inf2CatPath = $null
                DriverPackagePath = ($TargetDir | Join-Path -ChildPath 'TestPackage')
                WindowsVersionList = '10_RS5_X86,10_RS5_X64,10_19H1_X86,10_19H1_X64,Server2016_X64'
                OutputEncoding = [System.Text.Encoding]::UTF8
                PassThru = $true
                Verbose = $true
            }
        )

        It "adds code signing" -TestCases $TestCase {

            # PARAMETER(S)
            Param($InfFileContent, $InfFileName, $OtherFileNames,
                $Inf2CatVersion, $Inf2CatPlatform, $Inf2CatPath, $DriverPackagePath, $WindowsVersionList, $OutputEncoding, $PassThru, $Verbose)

                
            # ARRANGE: NEW Package Directory
            New-Item -Path $DriverPackagePath -ItemType Directory -Force

            # ARRANGE: NEW Test.inf
            $InfFileContent | Out-File -FilePath ($DriverPackagePath | Join-Path -ChildPath $InfFileName)

            # ARRANGE: COPY BUILDLet.PowerShell.Utilities.dll -> $TargetDir/TestPackage/*.dll (if NOT exist)
            $OtherFileNames | ForEach-Object {

                # Target File Path
                $target_filepath = $DriverPackagePath | Join-Path -ChildPath $_

                # COPY Target File (if NOT exist)
                if (-not ($target_filepath | Test-Path)) {
                    Copy-Item `
                        -Path ((Get-InstalledModule -Name 'BUILDLet.PowerShell.Utilities').InstalledLocation | Join-Path -ChildPath 'BUILDLet.PowerShell.Utilities.dll') `
                        -Destination $target_filepath `
                        -Force
                }
            }


            # ACT
            if ($Inf2CatPath) {

                # $Inf2CatPath is specified.
                $actual = Invoke-Inf2Cat -Inf2CatPath $Inf2CatPath `
                    -DriverPackagePath $DriverPackagePath -WindowsVersionList $WindowsVersionList -OutputEncoding $OutputEncoding -PassThru:$PassThru -Verbose:$Verbose
            }
            else
            {
                # $Inf2CatPath is NOT specified.

                if ($Inf2CatVersion -and $SignToolPlatform) {

                    # Both $Inf2CatVersion and $Inf2CatPlatform is specified.
                    $actual = Invoke-Inf2Cat -Inf2CatVersion $Inf2CatVersion -Inf2CatPlatform $Inf2CatPlatform `
                    -DriverPackagePath $DriverPackagePath -WindowsVersionList $WindowsVersionList -OutputEncoding $OutputEncoding -PassThru:$PassThru -Verbose:$Verbose
                }
                elseif ($Inf2CatVersion) {

                    # $Inf2CatVersion is specified.
                    # ($Inf2CatPlatform is NOT specified.)
                    $actual = Invoke-Inf2Cat -Inf2CatVersion $Inf2CatVersion `
                        -DriverPackagePath $DriverPackagePath -WindowsVersionList $WindowsVersionList -OutputEncoding $OutputEncoding -PassThru:$PassThru -Verbose:$Verbose
                }
                elseif ($Inf2CatPlatform) {

                    # $Inf2CatPlatform is specified.
                    # ($Inf2CatVersion is NOT specified.)
                    $actual = Invoke-Inf2Cat -Inf2CatPlatform $Inf2CatPlatform `
                        -DriverPackagePath $DriverPackagePath -WindowsVersionList $WindowsVersionList -OutputEncoding $OutputEncoding -PassThru:$PassThru -Verbose:$Verbose
                }
                else {

                    # $Inf2CatVersion and $Inf2CatPlatform is NOT specified.
                    $actual = Invoke-Inf2Cat `
                        -DriverPackagePath $DriverPackagePath -WindowsVersionList $WindowsVersionList -OutputEncoding $OutputEncoding -PassThru:$PassThru -Verbose:$Verbose
                }
            }

            # ASSERT
            $actual | Should Be 0
        }
    }
}