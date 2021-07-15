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


# Get-AuthenticodeTimeStampString
Describe "Expand-InfStringKey" {

    Context "normally" {

        $TestCase = @(

            # 1)
            @{
                InputObject = @"
[SECTION]
KEY=%STRKEY%
[STRINGS]
STRKEY=VALUE
"@
                Expected = @"
[SECTION]
KEY=VALUE
[STRINGS]
STRKEY=VALUE
"@
            }

            # 2)
            @{
                InputObject = @"
[SECTION]
KEY1=%STRKEY1%
KEY2=%STRKEY2%
KEY3=%STRKEY3%
[STRINGS]
STRKEY1=VALUE
STRKEY2=%STRKEY1%
STRKEY3=%STRKEY2%
"@
                Expected = @"
[SECTION]
KEY1=VALUE
KEY2=VALUE
KEY3=VALUE
[STRINGS]
STRKEY1=VALUE
STRKEY2=VALUE
STRKEY3=VALUE
"@
            }
        )
        
        It "expands strng kye in InputObject" -TestCases $TestCase {

            # PARAMETER(S)
            Param($inputObject, $Expected)

            # ARRANGE
            # (None)

            # ACT
            $actual = Expand-InfStringKey -InputObject $InputObject

            # ASSERT
            $actual | Should Be $Expected
        }
    }
}