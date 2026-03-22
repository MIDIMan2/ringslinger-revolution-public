:: Ringslinger Revolution - PK3 Build Script
:: If anything is ever added or removed from the mod,
:: please check this script to make sure the mod builds correctly!
:: Special thanks to the SRB2 MRCE project for their build_MRCE.bat script for being a great help!

:: Please update the version numbers below in case they get changed for RSR updates

set "mainName=ZRSR_RingslingerRevolution"
set "mainVersion=2.1"

set "tmzName=RSR_SL_TechnoMadness"
set "tmzVersion=2.1"

set "mpName=RSR_MF_DeathmatchPack"
set "mpVersion=2.1"

:: Create the "build" directory if it doesn't exist
:: This directory is ignored by the git repo, so don't worry about making changes here
mkdir build
del /S /Q .\build\*

:: Use 7za to create PK3s of the "wadsrc" directory and put it in the "build" directory
cd tools

:: Main PK3
:: This should exclude:
:: - Level select pictures
:: - Everything but the "Killbox" level header in the SOC folder
:: - Multiplayer levels
:: - MUSICDEF_MP.txt
7za u -mx5 -tzip -x@../exclude-main.txt ../build/%mainName%-v%mainVersion%.pk3 ../src/*
7za rn ../build/%mainName%-v%mainVersion%.pk3 @../rename-main.txt

:: Techno Madness PK3
7za u  -mx5 -tzip ../build/%tmzName%-v%tmzVersion%.pk3 ../srctmz/*

:: Deathmatch Pack PK3
:: This should exclude:
:: - HUD Graphics
:: - Level header for Killbox
:: - Sounds folder
:: - init.lua
:: - TRNSLATE.txt
7za u -mx5 -tzip -x@../exclude-mp.txt ../build/%mpName%-v%mpVersion%.pk3 ../src/*
7za rn ../build/%mpName%-v%mpVersion%.pk3 @../rename-mp.txt

cd ..
