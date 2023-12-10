::<License>------------------------------------------------------------
::
:: Copyright (c) 2023 Shinnosuke Yakenohara
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.
::
::-----------------------------------------------------------</License>

@echo off

:: <User Setting>------------------------------------------------------

:: 走査対象フォルダ
::     フルパスで指定します。
::     `folderPath=` の直後から記載します。 (`=` の直後にスペースは入れません)
::     パス名にスペースが含まれる場合でもそのまま記載します。
::      (e.g. `set folderPath=C:\Users\myname\s p a c e`)
::     デフォルト `%~dp0%` はこのバッチファイルが配置されたディレクトリ
set folderPath=%~dp0%

:: 走査する深さ
::     例えば、"D:\test" の配下の "D:\test\xxx\yyy" が配置された階層に対して走査したい場合、`1` を指定します。
::     `0` の場合は、走査対象ディレクトリ直下、
::     `-1` の場合は、走査対象ディレクトリが配置された階層、
::     `-2` の場合は、走査対象ディレクトリの 1 階層上を意味します。
set /a depth=1

:: -----------------------------------------------------</User Setting>

:: 定数
set ps1FileName=WhatsNew.ps1

:: 初期化
set ps1FileFullPath=%~dp0%ps1FileName%

:: 走査対象ディレクトリ文字列の最後の `\` を削除
echo %folderPath%|findstr \\$ >nul && set folderPath=%folderPath:~0,-1%
:: Note
:: `findstr` -> 文字列を正規表現で検索
::              検索でヒットした場合は、 errorlevel が `0` となる
::              ヒットしなかった場合は、 errorlevel が `1` となる
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/findstr
:: `&&`      -> `findstr` 実行で errorlevel == `0` の場合だけ以降のコマンドを実行
:: `set`     -> 文字列置換を文字位置指定で実行 (以下 `set /?` によるヘルプ抜き出し)
:: ```
::     %folderPath:~0,-2%
:: 
:: は最後の 2 文字以外のすべてが展開されます。
:: ```

:: Call powershell
:: Note
:: Powershell への第 1 引数にスペースが存在しても OK とするために `"` (ダブルクォート) で括っているが、
:: 終端の `"` に対するエスケープ `\` は 2 文字記載しないといけない
:: `powershell` コマンドへの引数内部で変数展開したいので `Bypass` 以降の文字列を `"` で括っているが、
:: この内部で `"` を使用するためには、 `\` でエスケープしなければならない。 <- それをさらにエスケープするため？
powershell -ExecutionPolicy Bypass "& \"%ps1FileFullPath%\" -DirInfo \"%folderPath%\" -Depth %depth%"
