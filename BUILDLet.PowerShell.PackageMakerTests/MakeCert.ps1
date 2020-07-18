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

Param (
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [string]
    $FilePath = 'Test',

    [Parameter(Mandatory = $true, Position = 1)]
    [SecureString]
    $Password
)

# GET File path base
$filepath_base = $FilePath -replace @(
    Split-Path -Path $FilePath -Leaf
    [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
)

# NEW Self Signed Certificate
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "BUILDLet Code Signing Test Certificate"

# EXPORT as CER File
Export-Certificate  -FilePath ($filepath_base + '.cer') -Cert $cert -Type CERT

# EXPORT as PFX File
Export-PfxCertificate -Cert $cert -FilePath ($filepath_base + '.pfx') -Password $Password -Force

# REMOVE Certificate
Remove-Item -Path $cert.PSPath
