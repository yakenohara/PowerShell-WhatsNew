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

    .PARAMETER TimeDepth
    タイムスタンプを取得する相対的深さ (デフォルトは `-Depth` と同じ)
    `-Depth` パラメータより大きい値の場合は、その差分の分まで深いディレクトリを探索し、最新のタイムスタンプを使用します。
    `-Depth` より小さい値の場合は、走査対象のディレクトリのタイムスタンプはそのすべての子要素とディレクトリそのものの中から最新のタイムスタンプを使用します。

    .PARAMETER FileOnly
    走査対象をファイルに限定します (デフォルト: $false)

    .PARAMETER DirectoryOnly
    走査対象をにディレクトリ限定します (デフォルト: $false)

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
    [System.Int32]$Depth = 0, # 型は signed int (32bit) でないといけない
    [ValidateScript({
        if (($_ -ne $null ) -and ($_ -isnot [System.Int32])){ # 型は signed int (32bit) でないといけない
            return $false
        } else {
            return $true
        }
    })]$TimeDepth,

    # ファイル限定指定
    [switch]$FileOnly,

    # フォルダー限定指定
    [switch]$DirectoryOnly
)

# <引数チェック>
if ($DirInfo -eq $null) { # `-DirInfo` が指定されなかった場合
    [System.String]$DirInfo = $PSScriptRoot # この .ps1 ファイルが配置されたディレクトリを指定。文字列型。(`Get-ChildItem` のオプション `-Path` が文字列型である必要があるため)

} elseif ($DirInfo -is [System.IO.DirectoryInfo]) { # ディレクトリオブジェクトの指定の場合
    [System.String]$DirInfo = $DirInfo.FullName # パス文字列に変換 (`Get-ChildItem` のオプション `-Path` が文字列型である必要があるため)
}
if ($TimeDepth -eq $null){ # `-TimeDepth` が指定されなかった場合
    $TimeDepth = $Depth # `-Depth` と同じ値を使用
}
if ($FileOnly) { # 走査対象をファイルに限定している場合
    $str_FileOpt = " -File"
} else {
    $str_FileOpt = ""
}
if ($DirectoryOnly) { # 走査対象をファイルに限定している場合
    $str_DirOpt = " -Directory"
} else {
    $str_DirOpt = ""
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

# 検索対象となる `System.IO.FileInfo` オブジェクトリストを作成
$str_GetChildItemCmdlet = "Get-ChildItem -Path `"$DirInfo`"$str_FileOpt$str_DirOpt -Recurse -Depth $uint32_ScanDepth -Force"

$obj_FofDInfos = Invoke-Expression $str_GetChildItemCmdlet | # `System.IO.FileInfo` オブジェクトリストを取得
    Sort-Object -Property FullName # フルパスの名称で sort

# 対象件数が 0 だった場合は終了
if ($obj_FofDInfos -eq $null){ # 対象件数が 0 だった場合
    Write-Error "パス `"$DirInfo`" が存在しないか、その配下に子項目が存在しません。"
    exit 1
    # Note:
    # `return` は使用しない。バッチファイルから call される想定のため。
    # `%errorlevel%` で取得可能な値しか返さない(`0` or `1` しか使えない仕様?)
    # `return` を使用するとコマンドプロンプトに値が表示されてしまう
}

[System.Management.Automation.PathInfo]$obj_Curdir = Get-Location # カレントディレクトリを一時保存
Set-Location $DirInfo # 相対パスを取得するためにカレントディレクトリを指定ディレクトリに移動

$int32_tmp = ($TimeDepth - $Depth - 1)
for ($int32_Idx = 0 ; $int32_Idx -lt $obj_FofDInfos.count ; $int32_Idx++){
    
    # Write-Host "($($int32_Idx + 1) of $($obj_FofDInfos.count)) $($obj_FofDInfos[$int32_Idx].FullName)"
    # Write-Host $obj_FofDInfos[$int32_Idx].GetType().FullName
    [System.String]$str_RelPath = Resolve-Path -Path $obj_FofDInfos[$int32_Idx].FullName -Relative # カレントディレクトリからの相対パスを取得
    $str_RelPath = $str_RelPath -replace "^\.\\","" # 先頭の `.\` を削除
    # Write-host $str_RelPath

    # https://learn.microsoft.com/ja-jp/dotnet/api/system.text.regularexpressions.regex.matches?view=net-8.0#system-text-regularexpressions-regex-matches(system-string-system-string)
    if (([regex]::Matches($str_RelPath, '\\')).Count -eq $uint32_ScanDepth){
        
        if ((-1) -ne $int32_tmp){ # `-TimeDepth` パラメータが指定されていた場合

            IF ($obj_FofDInfos[$int32_Idx].GetType() -eq [System.IO.DirectoryInfo]) { # ディレクトリの場合
                
                $str_FullName = $obj_FofDInfos[$int32_Idx].FullName
                if (0 -le $int32_tmp) {
                    $str_GetChildItemCmdlet = "Get-ChildItem -Path `"$str_FullName`"$str_FileOpt$str_DirOpt -Recurse -Depth $int32_tmp -Force"
                } else {
                    $str_GetChildItemCmdlet = "Get-ChildItem -Path `"$str_FullName`"$str_FileOpt$str_DirOpt -Recurse -Force"
                }
                $obj_FofDInfosForTime = Invoke-Expression $str_GetChildItemCmdlet | Sort-Object -Property LastWriteTime -Descending
                
                if ($obj_FofDInfosForTime -ne $null){ # 子項目が存在する場合

                    # 現在のディレクトリのタイムスタンプより小項目のタイムスタンプが新しい場合
                    if (0 -lt (New-TimeSpan -Start $obj_FofDInfos[$int32_Idx].LastWriteTime -End $obj_FofDInfosForTime[0].LastWriteTime).TotalMilliseconds) {
                        Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfosForTime[0].LastWriteTime

                    }else{ # 現在のディレクトリのタイムスタンプが小項目のタイムスタンプが新しい場合
                        Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfos[$int32_Idx].LastWriteTime
                    }

                } else {
                    Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfos[$int32_Idx].LastWriteTime
                }

            } else { # ファイルの場合
                Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfos[$int32_Idx].LastWriteTime

            }

        } else { # `-TimeDepth` パラメータが指定されていない場合
            Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfos[$int32_Idx].LastWriteTime
        }
    }

}

Set-Location $obj_Curdir # カレントディレクトリをもとに戻す
