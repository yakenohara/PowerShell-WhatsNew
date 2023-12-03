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
:: ���̃t�@�C���͕����R�[�h `SJIS` �ŕۑ����邱��
:: </CAUTION!>

@echo off

:: �R�[�h�y�[�W (�����R�[�h) �� `SJIS` �ɐݒ�
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/chcp
:: https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
chcp 932 > nul

::�萔
set ps1FileName=kickexplorer.ps1

::������
set ps1FileFullPath=%~dp0%ps1FileName%

:: Note
:: %1 ���� `(` �����݂���ꍇ�́APowershell ���� `$Args[0]` �ŃA�N�Z�X�����^�C�~���O�ō\�����?�݂����Ȃ��̂�����炵���B
:: ������邽�߂ɁA`"` (�_�u���N�H�[�g) ����菜������Ԃ̕����� (`%~1`) �ɂ��āAPowershell �ւ̈����w�莞�� `\"` �ň͂��B
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/call
powershell -ExecutionPolicy Bypass "& \"%ps1FileFullPath%\" \"%~1\""

:: �t�@�C�� / �f�B���N�g�������݂��Ȃ��ꍇ
if %errorlevel% neq 0 (
    echo �p�X�����݂��܂���B
    pause
    exit /b 1
)
