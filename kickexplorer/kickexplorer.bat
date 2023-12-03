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

:: <CAUTION!>
:: このファイルは文字コード `SJIS` で保存すること
:: </CAUTION!>

@echo off

:: コードページ (文字コード) を `SJIS` に設定
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/chcp
:: https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
chcp 932 > nul

::定数
set ps1FileName=kickexplorer.ps1

::初期化
set ps1FileFullPath=%~dp0%ps1FileName%

:: Note
:: %1 内に `(` が存在する場合は、Powershell 側で `$Args[0]` でアクセスしたタイミングで構文解析?みたいなものが走るらしい。
:: 回避するために、`"` (ダブルクォート) を取り除いた状態の文字列 (`%~1`) にして、Powershell への引数指定時に `\"` で囲う。
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/call
powershell -ExecutionPolicy Bypass "& \"%ps1FileFullPath%\" \"%~1\""

:: ファイル / ディレクトリが存在しない場合
if %errorlevel% neq 0 (
    echo パスが存在しません。
    pause
    exit /b 1
)
