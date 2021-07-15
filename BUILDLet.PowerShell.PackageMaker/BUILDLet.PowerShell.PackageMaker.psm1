<###############################################################################
 The MIT License (MIT)

 Copyright (c) 2015 Daiki Sakamoto

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

################################################################################
Function Get-WindowsKitsToolPath {
<#

.SYNOPSIS
Windows 10 SDK や Windows Driver Kit (WDK for Windows 10) に含まれるツールのパスを取得します。

.DESCRIPTION
Windows 10 SDK や WDK for Windows 10 がインストール済みのシステムで、各種ツールの実行ファイル (*.exe) のパスを取得します。

.INPUTS
System.String
パイプを使用して、FileName パラメーターをこのコマンドに渡すことができます。

.OUTPUTS
System.Management.Automation.PathInfo[]
このコマンドは、検出したツールのパスの配列を返します。

.NOTES
通常、Windows 10 SDK や WDK for Windows 10 のツール群は
C:\Program Files\Windows Kits\10\bin\<$Version>\<$Platform>\<$FileName>
(x64 の場合は C:\Program Files (x86)\Windows Kits\10\bin\<$Version>\<$Platform>\<$FileName>)
か、あるいは
C:\Program Files\Windows Kits\10\bin\<$Platform>\<$FileName>
(x64 の場合は C:\Program Files (x86)\Windows Kits\10\bin\<$Platform>\<$FileName>)
にインストールされています。

.EXAMPLE
Get-WindowsKitsToolPath -FileName signtool.exe -Version *
このシステムにインストールされている全てのバージョンの Windows 10 SDK の全てのプラットフォームの signtool.exe のパスを取得します。

.EXAMPLE
Get-WindowsKitsToolPath -FileName signtool.exe -Version 10.0.19041.0 -Platform x86
Windows 10 SDK (10.0.19041.0) の x86 プラットフォームの signtool.exe のパスを取得します。

.EXAMPLE
Get-WindowsKitsToolPath -FileName inf2cat.exe
このシステムにインストールされている inf2cat.exe のパスを取得します。

#>
    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]
        # ツールの実行ファイル (*.exe) の名前を指定します。
        $FileName,

        [Parameter()]
        [AllowNull()]
        [string]
        # バージョンを指定します。
        # '*' を指定すると、検出可能な全てのバージョンを取得します。
        # このパラメーターを省略するか、または $null を指定すると、
        # C:\Program Files\Windows Kits\10\bin\<$Version>\<$Platform>\<$FileName> ではなく、
        # C:\Program Files\Windows Kits\10\bin\<$Platform>\<$FileName> を検索します。
        $Version,

        [Parameter()]
        [string]
        # プラットフォームを指定します。
        # '*' を指定すると、検出可能な全てのプラットフォームを取得します。
        # 既定では '*' です。
        $Platform = '*'
    )


    # Pre-Processing Operations
    # Begin {}


    # Input Processing Operations
    Process {

        $InstalledRootsPath = "HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Kits\Installed Roots"
        $InstalledRootsPath64 = "HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots"

        if (Test-Path -Path $InstalledRootsPath) {

            $TargetPath = $InstalledRootsPath
        }
        elseif (Test-Path -Path $InstalledRootsPath64) {

            $TargetPath = $InstalledRootsPath64
        }
        else {
            throw [System.Management.Automation.ItemNotFoundException] `
                "Both '$InstalledRootsPath' and '$InstalledRootsPath64' was not found."
        }

        # Get Value of "KitsRoot10"
        $KitsRoot10Path = (Get-Item -Path $TargetPath).GetValue("KitsRoot10")

        if ($Version) {
            $KitsRoot10Path |
            Join-Path -ChildPath bin |
            Join-Path -ChildPath $Version |
            Join-Path -ChildPath $Platform |
            Join-Path -ChildPath $FileName |
            Resolve-Path |
            Sort-Object |
            Write-Output
        }
        else {
            $KitsRoot10Path |
            Join-Path -ChildPath bin |
            Join-Path -ChildPath $Platform |
            Join-Path -ChildPath $FileName |
            Resolve-Path |
            Sort-Object |
            Write-Output
        }
    }


    # Post-Processing Operations
    # End {}
}
#>

################################################################################
Function Invoke-SignTool {
<#

.SYNOPSIS
SignTool.exe  (署名ツール) を実行します。

.DESCRIPTION
SignTool.exe  (署名ツール) を実行します。
署名ツールはコマンド ライン ツールで、ファイルにデジタル署名を添付し、ファイルの署名を検証し、ファイルにタイム スタンプを付けます。

.INPUTS
System.String
パイプを使用して、SignToolPath パラメーターを Invoke-SignTool コマンドレットに渡すことができます。

.OUTPUTS
System.String, System.Int32
SignTool.exe の標準出力ストリームへの出力結果を返します。
PassThru オプションが指定されたときは、SignTool.exe の終了コードを返します。

.NOTES
このコマンドを実行する PC に、あらかじめ SignTool.exe がインストールされている必要があります。
SignTool.exe は Windows Software Development Kit (Windows SDK) に含まれています。

.EXAMPLE
Invoke-SignTool -Command 'sign' -Options @('/f C:\PFX\sign.pfx', '/p 12345678', '/t http://timestamp.verisign.com/scripts/timstamp.dll', '/v') -FilePath @('D:\Setup.exe', 'E:\Setup.exe') -PassThru -RetryCount 10 -RetryInterval 3 -Verbose
証明書 C:\PFX\sign.pfx で、'D:\Setup.exe' および 'E:\Setup.exe' にコード署名をします。
パスワードには 12345678 を指定しています。
タイムスタンプサーバーに http://timestamp.verisign.com/scripts/timstamp.dll を指定しています。
署名に失敗した場合は 3 秒間隔で10 回までリトライします。
SignTool.exe の終了コードがパイプラインへ出力されます。
SignTool.exe の出力結果は、警告ストリームに出力されます。

.LINK
SignTool (Windows Drivers)
https://msdn.microsoft.com/en-us/library/windows/hardware/ff551778.aspx

.LINK
SignTool.exe (署名ツール)
https://msdn.microsoft.com/ja-jp/library/8s9b9yaz.aspx

#>
    [CmdletBinding(DefaultParameterSetName = 'SignToolVersion')]
    Param (

        [Parameter(Position = 0, ParameterSetName = 'SignToolVersion')]
        [string]
        # SignTool.exe が収録されている Windows SDK のバージョンを指定します。
        # '*' を指定すると、複数のバージョンが検出された場合、最も新しいバージョンの SignTool.exe が指定されます。
		# 既定では '*' です。
        $SignToolVersion = '*',

        [Parameter(Position = 1, ParameterSetName = 'SignToolVersion')]
        [ValidateSet('x86', 'x64', 'arm', 'arm64')]
        [string]
		# SignTool.exe のプラットフォームを指定します。
		# 既定では x86 です。
        $SignToolPlatform = 'x86',

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'SignToolPath', ValueFromPipeline = $true)]
        [string]
        # Windows SDK がインストールされていないシステム上で、SignTool.exe のパスを直接指定する場合等に、
        # SignTool.exe のパスを指定します。
        $SignToolPath,

        [Parameter(Position = 2, ParameterSetName = 'SignToolVersion')]
        [Parameter(Position = 1, ParameterSetName = 'SignToolPath')]
        [ValidateSet('sign', 'timestamp', 'verify', 'catdb', 'remove')]
        [string]
        # 5 つのコマンド (sign、timestamp、verify、catdb または remove) のうちのいずれか 1 つを指定します。
        $Command,

        [Parameter(Position = 3, ParameterSetName = 'SignToolVersion')]
        [Parameter(Position = 2, ParameterSetName = 'SignToolPath')]
        [string[]]
        # SignTool.exe へのオプションを文字列の配列として指定します。
        $Options,

        [Parameter(Position = 4, ParameterSetName = 'SignToolVersion', ValueFromPipeline = $true)]
        [Parameter(Position = 3, ParameterSetName = 'SignToolPath', ValueFromPipeline = $true)]
        [string[]]
        # コマンドに対する対象ファイルへのパス (filename(s) パラメーター) を指定します。
        $FilePath,

        [Parameter()]
        [System.Text.Encoding]
        # SignTool.exe の標準出力ストリームおよび標準エラー ストリームのエンコードを指定します。
        # 既定のエンコーディングは [System.Text.Encoding]::UTF8 です。
        $OutputEncoding = [System.Text.Encoding]::UTF8,

        [Parameter()]
        [switch]
        # SignTool.exe の終了コードを返します。
        # また、SignTool.exe の標準出力ストリームへの出力が、警告メッセージ ストリームへリダイレクトされます。
        $PassThru,

        [Parameter()]
        [ValidateRange(0, 255)]
        [int]
        # SignTool.exe の終了コードが 0 以外だった場合に、リトライする回数を指定します。
        # 既定の設定は 0 回です。
        $RetryCount = 0,

        [Parameter()]
        [ValidateRange(0, 60 * 60)]
        [int]
        # SignTool.exe の終了コードが 0 以外だった場合に、リトライする間隔を秒数で指定します。
        # 既定の設定は 0 秒です。
        $RetrySecond = 0,

        [Parameter()]
        [ValidateRange(0, 255)]
        [int]
        # FilePath パラメーターに複数のファイルが指定されている場合、
        # PacketSize パラメーターで指定されたファイル数のファイルセットに分割して、SignTool.exe を複数回実行します。
        # PacketSize パラメーターに 0 を指定すると、全てのファイルを対象に SignTool.exe を 1 回実行します。
        # 既定では 0 です。
        $PacketSize = 0
    )


    # Pre-Processing Operations
    Begin {

        # GET Paths of SignTool.exe (and Validate it)
        if ($SignToolPath) {
            if (-not ($PSCmdlet.GetResolvedProviderPathFromPSPath($SignToolPath)[0] | Test-Path)) {
                Write-Error -Exception (New-Object System.IO.FileNotFoundException)
            }
        }
        else {
            $SignToolPath = (Get-WindowsKitsToolPath -FileName 'signtool.exe' -Version $SignToolVersion -Platform $SignToolPlatform)[-1].Path
        }

        # Prapare variable for aggregate $FilePath
        $filepaths = @()
    }


    # Input Processing Operations
    Process {

        # Aggregate $FilePath.ProviderPath into $filepaths
        $FilePath |
        ForEach-Object { $_ | Resolve-Path } |
        Where-Object { $_ | Test-Path -PathType Leaf } |
        ForEach-Object { $filepaths += $_.ProviderPath }
    }


    # Post-Processing Operations
    End {

        # Calculate number of files in a packet / number of packets
        if ($PacketSize -gt 0) {
            $num_files_in_packet = $PacketSize
            $num_packets = [System.Math]::Ceiling($filepaths.Count / $PacketSize)
        }
        else {
            $num_files_in_packet = $filepaths.Count
            $num_packets = 1
        }

        # Do command line for each Fileset(s)
        for ($count = 0; $count -lt $num_packets; $count++) {

            # Construct '<filename(s)>' parameter for Signtool.exe
            $filenames_param = ""
            for ($i = 0; $i -lt $num_files_in_packet; $i++) {
                if ((($num_files_in_packet * $count) + $i) -lt $filepaths.Count) {
                    $filenames_param += (' "' + $filepaths[($num_files_in_packet * $count) + $i] + '"')
                }
            }
            $filenames_param = $filenames_param.Trim()

            # Execute Signtool.exe as command line (OUTPUT)
            Invoke-Process `
                -FilePath $SignToolPath `
                -ArgumentList (@($Command) + $Options + @($filenames_param)) `
                -OutputEncoding $OutputEncoding `
                -PassThru:$PassThru `
                -RetryCount $RetryCount `
                -RetrySecond $RetrySecond `
                -Verbose:($VerbosePreference -ne 'SilentlyContinue') `
                -WhatIf:$WhatIfPreference
        }
    }
}
#>

####################################################################################################
Function Get-AuthenticodeTimeStampString {
<#

.SYNOPSIS
デジタル署名のタイムスタンプを取得します。

.DESCRIPTION
SignTool.exe (署名ツール) を使って、指定されたファイルのデジタル署名のタイムスタンプを文字列として取得します。
コマンドラインは 'signtool verify /pa /v <filename(s)>' です。

.INPUTS
System.String
パイプを使用して、FilePath パラメーターを Get-AuthenticodeTimeStampString コマンドレットに渡すことができます。

.OUTPUTS
System.String
デジタル署名のタイムスタンプを文字列として取得します。

.NOTES
このコマンドを実行する PC に、あらかじめ SignTool.exe がインストールされている必要があります。
SignTool.exe は Windows Software Development Kit (Windows SDK) に含まれています。

.EXAMPLE
Get-AuthenticodeTimeStampString -FilePath 'D:\Setup.exe'
'D:\Setup.exe' のデジタル署名のタイムスタンプを取得します。

.EXAMPLE
@('D:\Setup.exe', 'E:\Setup.exe') | Get-AuthenticodeTimeStampString
'D:\Setup.exe' および 'E:\Setup.exe' のデジタル署名のタイムスタンプを取得します。

#>
    [CmdletBinding(DefaultParameterSetName = 'SignToolVersion')]
    Param (

        [Parameter(Position = 0, ParameterSetName = 'SignToolVersion')]
        [string]
        # SignTool.exe が収録されている Windows SDK のバージョンを指定します。
        # '*' を指定すると、複数のバージョンが検出された場合、最も新しいバージョンの SignTool.exe が指定されます。
		# 既定では '*' です。
        $SignToolVersion = '*',

        [Parameter(Position = 1, ParameterSetName = 'SignToolVersion')]
        [ValidateSet('x86', 'x64', 'arm', 'arm64')]
        [string]
		# SignTool.exe のプラットフォームを指定します。
		# 既定では x86 です。
        $SignToolPlatform = 'x86',

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'SignToolPath', ValueFromPipeline = $true)]
        [string]
        # Windows SDK がインストールされていないシステム上で、SignTool.exe のパスを直接指定する場合等に、
        # SignTool.exe のパスを指定します。
        $SignToolPath,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'SignToolVersion', ValueFromPipeline = $true)]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'SignToolPath', ValueFromPipeline = $true)]
        [string[]]
        # タイムスタンプを取得するファイルのパスを指定します。
        $FilePath
    )


    # Pre-Processing Operations
    # Begin { }


    # Input Processing Operations
    Process {

        # Construct parameter for Invoke-SignTool function
        $param_common = @{
            Command = 'verify'
            Option = @('/pa','/v')
            FilePath = $FilePath
            Verbose = ($VerbosePreference -ne 'SilentlyContinue')
        }

        # Execute Signtool.exe as command line (OUTPUT)
        switch ($PSCmdlet.ParameterSetName) {

            'SignToolVersion' {
                Invoke-SignTool @param_common `
                    -SignToolVersion $SignToolVersion `
                    -SignToolPlatform $SignToolPlatform `
                    -ErrorAction SilentlyContinue `
                    -OutVariable Stdout 2>&1 > $null
            }

            'SignToolPath' {
                Invoke-SignTool @param_common `
                    -SignToolPath $SignToolPath `
                    -ErrorAction SilentlyContinue `
                    -OutVariable Stdout 2>&1 > $null
            }

            Default { throw }
        }

        # Verbose Output
        $stdout | ForEach-Object { $_ | Write-Verbose }

        # Extract result text
        $pattern = 'The signature is timestamped: '
        $stdout | Select-String -Pattern $pattern | ForEach-Object {

            # OUTPUT
            $_.Line.Substring($pattern.Length) | Write-Output
        }
    }


    # Post-Processing Operations
    # End { }
}
#>

####################################################################################################
Function Invoke-Inf2Cat {
<#

.SYNOPSIS
ドライバー パッケージ用のカタログ ファイルを作成します。

.DESCRIPTION
Inf2Cat.exe を使って、指定されたドライバー パッケージ用のカタログ ファイルを作成します。

.INPUTS
System.String
パイプを使用して、PackagePath パラメーターを New-CatalogFile コマンドレットに渡すことができます。

.OUTPUTS
System.String, System.Int32
Inf2Cat.exe の標準出力ストリームへの出力結果を返します。
PassThru オプションが指定されたときは、Inf2Cat.exe の終了コードを返します。

.NOTES
このコマンドを実行する PC に、あらかじめ Inf2Cat.exe がインストールされている必要があります。
Inf2Cat.exe は Windows Driver Kit (WDK) に含まれています。

.EXAMPLE
New-CatalogFile -PackagePath 'D:\Drivers\x86' -WindowsVersionList 'Vista_X86,7_X86,8_X86,6_3_X86,10_X86,Server2008_X86'
ドライバー パッケージ 'D:\Drivers\x86' に対して未署名のカタログ ファイルを作成します。

.EXAMPLE
New-CatalogFile -PackagePath 'D:\Drivers\x64' -WindowsVersionList 'Vista_X64,7_X64,8_X64,6_3_X64,10_X64,Server2008_X64,Server2008R2_X64,Server8_X64,Server6_3_X64,Server10_X64'
ドライバー パッケージ 'D:\Drivers\x64' に対して未署名のカタログ ファイルを作成します。

.LINK
Inf2Cat (Windows Drivers)
https://msdn.microsoft.com/en-us/library/windows/hardware/ff547089.aspx

#>
    [Alias('New-CatalogFile')]
    [CmdletBinding(DefaultParameterSetName = 'Inf2CatVersion')]
    Param (

        [Parameter(Position = 0, ParameterSetName = 'Inf2CatVersion')]
        [AllowNull()]
        [string]
        # Inf2Cat.exe が収録されている WDK のバージョンを指定します。
        # '*' を指定すると、複数のバージョンが検出された場合、最も新しいバージョンの Inf2Cat.exe が指定されます。
        # $null を指定すると、
        # C:\Program Files\Windows Kits\10\bin\<$Version>\<$Platform>\Inf2Cat.exe ではなく、
        # C:\Program Files\Windows Kits\10\bin\<$Platform>\Inf2Cat.exe を検索します。
		# 既定では $null です。
        $Inf2CatVersion = $null,

        [Parameter(Position = 1, ParameterSetName = 'Inf2CatVersion')]
        [ValidateSet('x86', 'x64', 'arm', 'arm64')]
        [string]
		# Inf2Cat.exe のプラットフォームを指定します。
		# 既定では x86 です。
        $Inf2CatPlatform = 'x86',

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Inf2CatPath')]
        [string]
        # WDK for Windows 10 がインストールされていないシステム上で、Inf2Cat.exe のパスを直接指定する場合等に、
        # Inf2Cat.exe のパスを指定します。
        $Inf2CatPath,

        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $true, ParameterSetName = 'Inf2CatVersion')]
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'Inf2CatPath')]
        [string]
        # カタログ ファイルを作成するドライバー パッケージの INF ファイルが格納されているディレクトリのパスを指定します。
        # /driver: スイッチとともに Inf2Cat.exe に渡されます。
        $DriverPackagePath,

        [Parameter(Mandatory = $true, Position = 3, ValueFromPipeline = $true, ParameterSetName = 'Inf2CatVersion')]
        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $true, ParameterSetName = 'Inf2CatPath')]
        [string]
        # Inf2Cat.exe に /os: スイッチとともに渡す WindowsVersionList パラメーターを指定します。
        $WindowsVersionList,

        [Parameter()]
        [switch]
        # Inf2Cat.exe の /uselocaltime スイッチを指定します。
        $UseLocalTime,

        [Parameter()]
        [switch]
        # Inf2Cat.exe の /nocat スイッチを指定します。
        $NoCatalogFiles,

        [Parameter()]
        [switch]
        # Inf2Cat.exe の /pageHashes スイッチを指定します。
        $PageHashes,

        [Parameter()]
        [System.Text.Encoding]
        # Inf2Cat.exe の標準出力ストリームおよび標準エラー ストリームのエンコードを指定します。
        # 既定のエンコーディングは [System.Text.Encoding]::UTF8 です。
        $OutputEncoding = [System.Text.Encoding]::UTF8,

        [Parameter()]
        [switch]
        # Inf2Cat.exe の終了コードを返します。
        # また、Inf2Cat.exe の標準出力ストリームへの出力が、警告メッセージ ストリームへリダイレクトされます。
        $PassThru
    )


    # Pre-Processing Operations
    Begin {

        # GET Inf2Cat.exe Path (and Validate it)
        if ($Inf2CatPath) {
            if (-not ($PSCmdlet.GetResolvedProviderPathFromPSPath($Inf2CatPath)[0] | Test-Path)) {
                Write-Error -Exception (New-Object System.IO.FileNotFoundException)
            }
        }
        else {
            $Inf2CatPath = (Get-WindowsKitsToolPath -FileName 'inf2cat.exe' -Version $Inf2CatVersion -Platform $Inf2CatPlatform).Path
        }
    }


    # Input Processing Operations
    Process {

        # Aggregate $DriverPackagePath.ProviderPath into $filepaths
        $DriverPackagePath |
        Resolve-Path |
        Where-Object { $_ | Test-Path -PathType Container } |
        ForEach-Object {

            # GET $driver
            $driver = $_.ProviderPath

            # Construct parameter for 'Inf2Cat.exe'
            [string[]]$ArgumentList = @()
            $ArgumentList += "/driver:`"$driver`""
            $ArgumentList += "/os:$WindowsVersionList"
            if ($UseLocalTime) { $ArgumentList += '/uselocaltime' }
            if ($NoCatalogFiles) { $ArgumentList += '/nocat' }
            if ($PageHashes) { $ArgumentList += '/pageHashes' }
            if ($VerbosePreference -ne 'SilentlyContinue') { $ArgumentList += '/verbose' }

            # Execute Signtool.exe as command line (OUTPUT)
            Invoke-Process `
                -FilePath $Inf2CatPath `
                -ArgumentList $ArgumentList `
                -PassThru:$PassThru `
                -OutputEncoding $OutputEncoding `
                -Verbose:($VerbosePreference -ne 'SilentlyContinue') `
                -WhatIf:$WhatIfPreference
        }
    }


    # Post-Processing Operations
    # End { }
}
#>

####################################################################################################
Function New-IsoImageFile {
<#

.SYNOPSIS
Rock Ridge 属性付きハイブリッド ISO9660 / JOLIET / HFS ファイルシステムイメージを作成します。

.DESCRIPTION
WSL (Windows Subsystem for Linux) の genisoimage コマンドを使って、ISO イメージ ファイルを作成します。

.INPUTS
System.String
パイプを使用して、Path パラメーターを New-ISOImageFile コマンドレットに渡すことができます。

.OUTPUTS
System.String, System.Int32
genisoimage コマンドの標準出力ストリームへの出力結果を返します。
PassThru オプションが指定されたときは、genisoimage コマンドの終了コードを返します。

.NOTES
このコマンドを実行する PC で、あらかじめ WSL (Windows Subsystem for Linux) が有効になっている必要があります。
また、genisoimage がインストールされている必要があります。

.EXAMPLE
New-IsoImageFile -Path C:\Input -DestinationPath C:\Release -FileName 'hoge.iso'
'C:\Input' をルート ディレクトリとした ISO イメージ ファイル 'hoge.iso' を、フォルダー 'C:\Release' に作成します。

.EXAMPLE
New-IsoImageFile -Path C:\Input -DestinationPath C:\Release -FileName 'hoge.iso' -Options @(
    '-input-charset utf-8'
    '-output-charset utf-8'
    '-rational-rock'
    '-joliet'
    '-joliet-long'
    '-jcharset utf-8'
    '-pad'
)

#>
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        # ISO9660 ファイルシステムにコピーするルートディレクトリのパスを指定します。
        # genisoimage.exe の 'pathspec' パラメーターに相当します。
        $Path,

        [Parameter(Position = 1)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        # 作成した ISO イメージ ファイルを保存するパスを指定します。
        # 指定したパスが存在しない場合は、エラーになります。
        # 既定の設定は、カレントディレクトリです。
        $DestinationPath = (Get-Location).Path,

        [Parameter(Position = 2)]
        [string]
        # 書き込まれる ISO9660 ファイルシステムイメージのファイル名を指定します。
        # 既定では、Path パラメーターの値に、拡張子 '.iso' を付加したファイル名が設定されます。
        $FileName = (($Path | Split-Path -Leaf) + '.iso'),

        [Parameter()]
        [string[]]
        # genisoimage コマンドに渡すオプション パラメーターを指定します。
        # ここで指定できるオプションの詳しい説明は、genisoimage あるいは mkisofs コマンドのヘルプを参照してください。
        $Options,

        [Parameter()]
        [System.Text.Encoding]
        # genisoimage コマンドの標準出力ストリームおよび標準エラー ストリームのエンコードを指定します。
        # 既定のエンコーディングは [System.Text.Encoding]::UTF8 です。
        $OutputEncoding = [System.Text.Encoding]::UTF8,

        [Parameter()]
        [switch]
        # genisoimage コマンドの終了コードを返します。
        # また、genisoimage コマンドの標準出力ストリームへの出力が、警告メッセージ ストリームへリダイレクトされます。
        $PassThru,

        [Parameter()]
        [switch]
        # 出力先のパスに既にファイルが存在する場合に、そのファイルを上書きします。
        # 既定の設定では、出力先のパスに既にファイルが存在する場合はエラーになります。
        # 出力先のパスに既にディレクトリが存在する場合は、常にエラーになります。
        $Force
    )


    # Pre-Processing Operations
    # Begin { }


    # Input Processing Operations
    Process {

        # SET $iso_filepath
        $iso_filepath = $DestinationPath | Join-Path -ChildPath $FileName

        # Validate $iso_filepath
        if ($iso_filepath | Test-Path -PathType Leaf) {

            # Check if $Force Parameter is specified
            if ($Force.IsPresent) {

                # Remove the file at $iso_filepath
                Remove-Item $iso_filepath -Force -Recurse
            }
            else {

                # ERROR
                throw New-Object System.IO.IOException
            }
        }

        # Construct ArgumentList
        [string[]]$ArgumentList = @('genisoimage')
        $Options | ForEach-Object { $ArgumentList += $_ }
        $ArgumentList += ('-output "' + (ConvertTo-WslPath -Path $iso_filepath) + '"')
        $ArgumentList += ('"' + (ConvertTo-WslPath -Path $Path) + '"')

        # ShouldProcess
        if ($PSCmdlet.ShouldProcess($Path, "Create ISO Image File '$iso_filepath'")) {

            # Execute Signtool.exe as command line (OUTPUT)
            Invoke-Process `
                -FilePath 'wsl' `
                -ArgumentList $ArgumentList `
                -PassThru:$PassThru `
                -OutputEncoding $OutputEncoding `
                -Verbose:($VerbosePreference -ne 'SilentlyContinue') `
                -WhatIf:$WhatIfPreference
        }
    }


    # Post-Processing Operations
    # End { }
}
#>

####################################################################################################
Function Expand-InfStringKey {
<#
.SYNOPSIS
INF ファイル内の文字列キーを展開します。

.DESCRIPTION
入力文字列を INF ファイルのコンテンツとして読み込み、Strings セクションで定義された文字列キーを展開します。

.INPUTS
System.String
パイプを使用して、Path パラメーターを Expand-InfStringKey コマンドレットに渡すことができます。

.OUTPUTS
System.String
文字列キーを展開した結果の文字列を出力します。

.NOTES
このコマンドは、文字列キー内の '%' 文字は、'%%' に展開しません。

.EXAMPLE
$profile = Get-Content -Path 'SAMPLE.INF' -Raw | Expand-InfStringKey -InputObject | Get-PrivateProfile
SAMPLE.INF 内の文字列キーを展開して、INI ファイルとして読み込みます。

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        # 入力文字列を指定します。
        $InputObject
    )


    # Pre-Processing Operations
    # Begin { }


    # Input Processing Operations
    Process {

        # Repeat in order to replace strings in the right side
        while ($true) {

            # GET [Strings] Section from RAW string
            $Strings = Get-PrivateProfile -InputObject $InputObject -Section 'Strings'

            # Update RAW string
            $Strings.Keys | ForEach-Object {

                # Replace Strings
                $InputObject = $InputObject.Replace("%$_%", $Strings[$_])
            }

            # Exit Condition Check Loop:
            $InputObject -split [System.Environment]::NewLine | ForEach-Object {

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

        # OUTPUT
        $InputObject | Write-Output
    }


    # Post-Processing Operations
    # End { }
}
#>

####################################################################################################
Export-ModuleMember -Function * -Alias *
