# <License>------------------------------------------------------------

#  Copyright (c) 2023 Shinnosuke Yakenohara

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# -----------------------------------------------------------</License>

# <CAUTION!>
# このファイルは UTF-8 (BOM 付き) で保存すること。(ターミナルに日本語メッセージを表示するため)
# </CAUTION!>

<#
    .SYNOPSIS
    //todo 関数またはスクリプトの簡単な説明
    
    .PARAMETER DirInfo
    走査対象ディレクトリ
    文字列型か [System.IO.DirectoryInfo] 型である必要があります。

    .PARAMETER Depth
    走査対象ディレクトリからの相対的深さ (デフォルト: 0)
    例えば、"D:\test" の配下の "D:\test\xxx\yyy" が配置された階層にまで走査したい場合、`1` を指定します。
    `0` の場合は、走査対象ディレクトリ直下、
    `-1` の場合は、走査対象ディレクトリが配置された階層、
    `-2` の場合は、走査対象ディレクトリの 1 階層上を意味します。
#>
# Note:
# '.PARAMETER <パラメーター名>' で使用する "<パラメーター名>" は、アッパーキャメルケースを使用しないと `Get-Help <スクリプトファイル> -full` 実行時にうまく認識されないらしい
# https://learn.microsoft.com/ja-jp/previous-versions/windows/powershell-scripting/hh847834(v=wps.640)?redirectedfrom=MSDN#parameter-%E3%83%91%E3%83%A9%E3%83%A1%E3%83%BC%E3%82%BF%E3%83%BC%E5%90%8D

Param(
    # 走査対象ディレクトリ
    [ValidateScript({
        if (($_ -ne $null ) -and ($_ -isnot [System.String]) -and ($_ -isnot [System.IO.DirectoryInfo])){ # 型は文字列か [DirectoryInfo](https://learn.microsoft.com/ja-jp/dotnet/api/system.io.directoryinfo?view=net-8.0) でないといけない
            return $false
        } else {
            return $true
        }
    })]$DirInfo,

    # 階層の深さ
    [System.Int32]$Depth = 0 # 型は signed int (32bit) でないといけない
)

# <引数チェック>
if ($DirInfo -eq $null) { # 指定されなかった場合
    [System.String]$DirInfo = $PSScriptRoot # この .ps1 ファイルが配置されたディレクトリを指定。文字列型。(`Get-ChildItem` のオプション `-Path` が文字列型である必要があるため)

} elseif ($DirInfo -is [System.IO.DirectoryInfo]) { # ディレクトリオブジェクトの指定の場合
    [System.String]$DirInfo = $DirInfo.FullName # パス文字列に変換 (`Get-ChildItem` のオプション `-Path` が文字列型である必要があるため)
}
# </引数チェック>

if ($Depth -lt 0) {
    [System.UInt32]$NumOfUpLevelOfHierarchy = $Depth * (-1)
    $DirInfo = Convert-Path ($DirInfo + ("\.." * $NumOfUpLevelOfHierarchy))
    # Note:
    # 存在しないパスが指定された場合は "Convert-Path : パス '(パス名)' が存在しないため検出できません。" でエラー終了する

    [System.UInt32]$uint32_ScanDepth = 0 # タイムスタンプを検査する階層の深さ

} else {
    [System.UInt32]$uint32_ScanDepth = $Depth # タイムスタンプを検査する階層の深さ
}

#todo 削除
Write-Host $DirInfo
Write-Host $uint32_ScanDepth

# 検索対象となる `System.IO.FileInfo` オブジェクトリストを作成
$obj_FofDInfos = 
    Get-ChildItem -Path $DirInfo -Recurse -Depth $uint32_ScanDepth -Force | # `System.IO.FileInfo` オブジェクトリストを取得
    Sort-Object -Property FullName # フルパスの名称で sort
#todo ファイル指定は `-File` https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-childitem?view=powershell-7.4#-file
# ディレクトリ指定は `-Directory` https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-childitem?view=powershell-7.4#-directory


# 対象件数が 0 だった場合は終了
if ($obj_FofDInfos -eq $null){ # 対象件数が 0 だった場合
    Write-Error "パス `"$DirInfo`" が存在しないか、その配下に子項目が存在しません。"
    exit 1
    # Note:
    # `return` は使用しない。バッチファイルから call される想定のため。
    # `%errorlevel%` で取得可能な値しか返さない(`0` or `1` しか使えない仕様?)
    # `return` を使用するとコマンドプロンプトに値が表示されてしまう
}

for ($int32_Idx = 0 ; $int32_Idx -lt $obj_FofDInfos.count ; $int32_Idx++){
    
    Write-Host "($($int32_Idx + 1) of $($obj_FofDInfos.count)) $($obj_FofDInfos[$int32_Idx].FullName)"
    Write-Host $obj_FofDInfos[$int32_Idx].GetType().FullName

}
