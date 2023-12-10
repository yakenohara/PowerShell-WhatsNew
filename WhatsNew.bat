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

:: �����Ώۃt�H���_
::     �t���p�X�Ŏw�肵�܂��B
::     `folderPath=` �̒��ォ��L�ڂ��܂��B (`=` �̒���ɃX�y�[�X�͓���܂���)
::     �p�X���ɃX�y�[�X���܂܂��ꍇ�ł����̂܂܋L�ڂ��܂��B
::      (e.g. `set folderPath=C:\Users\myname\s p a c e`)
::     �f�t�H���g `%~dp0%` �͂��̃o�b�`�t�@�C�����z�u���ꂽ�f�B���N�g��
set folderPath=%~dp0%

:: ��������[��
::     �Ⴆ�΁A"D:\test" �̔z���� "D:\test\xxx\yyy" ���z�u���ꂽ�K�w�ɑ΂��đ����������ꍇ�A`1` ���w�肵�܂��B
::     `0` �̏ꍇ�́A�����Ώۃf�B���N�g�������A
::     `-1` �̏ꍇ�́A�����Ώۃf�B���N�g�����z�u���ꂽ�K�w�A
::     `-2` �̏ꍇ�́A�����Ώۃf�B���N�g���� 1 �K�w����Ӗ����܂��B
set /a depth=1

:: -----------------------------------------------------</User Setting>

:: �萔
set ps1FileName=WhatsNew.ps1

:: ������
set ps1FileFullPath=%~dp0%ps1FileName%

:: �����Ώۃf�B���N�g��������̍Ō�� `\` ���폜
echo %folderPath%|findstr \\$ >nul && set folderPath=%folderPath:~0,-1%
:: Note
:: `findstr` -> ������𐳋K�\���Ō���
::              �����Ńq�b�g�����ꍇ�́A errorlevel �� `0` �ƂȂ�
::              �q�b�g���Ȃ������ꍇ�́A errorlevel �� `1` �ƂȂ�
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/findstr
:: `&&`      -> `findstr` ���s�� errorlevel == `0` �̏ꍇ�����ȍ~�̃R�}���h�����s
:: `set`     -> ������u���𕶎��ʒu�w��Ŏ��s (�ȉ� `set /?` �ɂ��w���v�����o��)
:: ```
::     %folderPath:~0,-2%
:: 
:: �͍Ō�� 2 �����ȊO�̂��ׂĂ��W�J����܂��B
:: ```

:: Call powershell
:: Note
:: Powershell �ւ̑� 1 �����ɃX�y�[�X�����݂��Ă� OK �Ƃ��邽�߂� `"` (�_�u���N�H�[�g) �Ŋ����Ă��邪�A
:: �I�[�� `"` �ɑ΂���G�X�P�[�v `\` �� 2 �����L�ڂ��Ȃ��Ƃ����Ȃ�
:: `powershell` �R�}���h�ւ̈��������ŕϐ��W�J�������̂� `Bypass` �ȍ~�̕������ `"` �Ŋ����Ă��邪�A
:: ���̓����� `"` ���g�p���邽�߂ɂ́A `\` �ŃG�X�P�[�v���Ȃ���΂Ȃ�Ȃ��B <- ���������ɃG�X�P�[�v���邽�߁H
powershell -ExecutionPolicy Bypass "& \"%ps1FileFullPath%\" -DirInfo \"%folderPath%\" -Depth %depth%"
