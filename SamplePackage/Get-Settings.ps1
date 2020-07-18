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
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]
    # 設定ファイル (INI ファイル) のパスを指定します。
    $Path
)

<###############################################################################
 Process
################################################################################>

# Read Raw Content of Settings File
$RawContent = Get-Content -Path $Path -Raw

# Repeat in order to replace strings in the right side
while ($true) {

    # GET [Strings] Section from Raw Content
    $Strings = Get-PrivateProfile -InputObject $RawContent -Section 'Strings'

    # Update Content of Settings File (.ini)
    $Strings.Keys | ForEach-Object {

        # Replace Strings
        $RawContent = $RawContent.Replace("%$_%", $Strings[$_])
    }

    # Roop Exit Condition Check:
    $RawContent -split [System.Environment]::NewLine | ForEach-Object {

        # GET Line
        $line = $_

        # for Replacable Strings
        $Strings.Keys | ForEach-Object {

            # Check if Strings to be replaced is remaind or not
            if ($line -like "*%$_%*") {

                # Continue
                continue
            }
        }
    }

    # Break
    break
}

# OUTPUT Settings Read from Settings File (.ini)
Get-PrivateProfile -InputObject $RawContent | Write-Output
