# <License>------------------------------------------------------------

#  Copyright (c) 2022 Shinnosuke Yakenohara

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
# このファイルは文字コード `UTF-8 (BOM 付き)` で保存すること
# エラーメッセージに日本語を含めるため
# </CAUTION!>

# カスタム URI スキーム名
$str_schemeName = 'kickexplorer'

# HttpUtilityクラス の有効化
Add-Type -AssemblyName System.Web
# Write-Host ($Args[0] -replace "^$str_schemeName`:", "")
$str_path = [System.Web.HttpUtility]::UrlDecode(($Args[0] -replace "^$str_schemeName`:", "")) # パーセントエンコードされた文字列をデコード

if (-not (Test-Path $str_path)) {
    Write-Error "パス `"$str_path`" が存在しません。"
    exit 1
}

# エクスプローラーで表示
# Note
# なぜか `/n` を付与しないと explorer が最前面に現れない
if ((Get-Item $str_path).PSIsContainer) { # パスがフォルダの場合
    Start-Process explorer "/n, `"$str_path`"" # フォルダを開く
} else { # パスがファイルの場合
    Start-Process explorer "/n,/select,`"$str_path`"" # ファイルを選択した状態でエクスプローラーを開く
}
