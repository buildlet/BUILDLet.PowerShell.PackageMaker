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


# New-IsoImageFile
Describe "New-IsoImageFile" {

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
                Contents = @(
                    @{ Path = 'RootDirectory'; ItemType = 'Directory' }
                    @{ Path = 'RootDirectory\Readme.txt'; ItemType = 'File'; Value = 'This is readme.' }
                    @{ Path = 'RootDirectory\Empty'; ItemType = 'Directory' }
                    @{ Path = 'RootDirectory\Contents'; ItemType = 'Directory' }
                    @{ Path = 'RootDirectory\Contents\Hello.txt'; ItemType = 'File'; Value = 'Hello, world.' }
                )
                Path = '.\RootDirectory'
                DestinationPath = $null
                FileName = $null
                Options = @(
                    '-volid "Test DVD 1"'
                    '-input-charset utf-8'
                    '-output-charset utf-8'
                    '-rational-rock'
                    '-joliet'
                    '-joliet-long'
                    '-jcharset utf-8'
                    '-pad'
                )
                OutputEncoding = [System.Text.Encoding]::UTF8
                PassThru = $true
                Force = $true
                Verbose = $true
            }

            # 2) 
            @{
                Contents = @(
                    @{ Path = 'RootDirectory2'; ItemType = 'Directory' }
                    @{ Path = 'RootDirectory2\Hello.txt'; ItemType = 'File'; Value = 'Hello, world.' }
                )
                Path = '.\RootDirectory2'
                DestinationPath = '.'
                FileName = 'Test2.iso'
                Options = @(
                    '-volid "Test DVD 2"'
                    '-input-charset utf-8'
                    '-output-charset utf-8'
                    '-rational-rock'
                    '-joliet'
                    '-joliet-long'
                    '-jcharset utf-8'
                    '-pad'
                )
                OutputEncoding = [System.Text.Encoding]::UTF8
                PassThru = $true
                Force = $true
                Verbose = $false
            }
        )

        It "creates new ISO image file" -TestCases $TestCase {

            # PARAMETER(S)
            Param($Contents, $Path, $DestinationPath, $FileName, $Options, $OutputEncoding, $PassThru, $Force, $Verbose)


            # ARRANGE: NEW Contents
            $Contents | ForEach-Object {

                # NEW item (if NOT exist)
                if (-not ($_.Path | Test-Path)) { New-Item @_ }
            }


            # ACT
            if ($DestinationPath -and $FileName) {
                $actual = New-IsoImageFile -Path $Path `
                    -DestinationPath $DestinationPath -FileName $FileName `
                    -Options $Options -OutputEncoding $OutputEncoding -PassThru:$PassThru -Force:$Force -Verbose:$Verbose
            }
            elseif ($DestinationPath) {
                $actual = New-IsoImageFile -Path $Path `
                    -DestinationPath $DestinationPath `
                    -Options $Options -OutputEncoding $OutputEncoding -PassThru:$PassThru -Force:$Force -Verbose:$Verbose
            }
            elseif ($FileName) {
                $actual = New-IsoImageFile -Path $Path `
                    -FileName $FileName `
                    -Options $Options -OutputEncoding $OutputEncoding -PassThru:$PassThru -Force:$Force -Verbose:$Verbose
            }
            else {
                $actual = New-IsoImageFile -Path $Path `
                    -Options $Options -OutputEncoding $OutputEncoding -PassThru:$PassThru -Force:$Force -Verbose:$Verbose
            }


            # ASSERT (Exit Code)
            $actual | Should Be 0

            # ASSERT (File Existence)
            if ($DestinationPath -and $FileName) {
                $DestinationPath | Join-Path -ChildPath $FileName | Should Exist
            }
            elseif ($DestinationPath) {
                $DestinationPath | Join-Path -ChildPath (($Path | Split-Path -Leaf) + '.iso') | Should Exist
            }
            else {
                (Get-Location).ProviderPath | Join-Path -ChildPath (($Path | Split-Path -Leaf) + '.iso') | Should Exist
            }
        }
    }
}