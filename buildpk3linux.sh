# Ringslinger Revolution - PK3 Build Script (for Linux))
# If anything is ever added or removed from the mod,
# please check this script to make sure the mod builds correctly!
# Special thanks to the SRB2 MRCE project for their build_MRCE.bat script for being a great help!

# IMPORTANT NOTE: Please make sure to save this script with LF line endings! Otherwise, it will not work properly under Linux!

# Please update the version numbers below in case they get changed for RSR updates

MAIN_NAME=ZRSR_RingslingerRevolution
MAIN_VERSION=2.1-alpha

TMZ_NAME=RSR_SL_TechnoMadness
TMZ_VERSION=2.1-alpha

MP_NAME=RSR_MF_DeathmatchPack
MP_VERSION=2.1-alpha

# Create the "build" directory if it doesn't exist
# This directory is ignored by the git repo, so don't worry about making changes here
rm -rf "./build"
mkdir build

# Main PK3
# This should exclude:
# - Level select pictures
# - Everything but the "Killbox" level header in the SOC folder
# - Multiplayer levels
# - MUSICDEF_MP.txt
7za u -mx5 -tzip -x@./exclude-main.txt ./build/$MAIN_NAME-v$MAIN_VERSION.pk3 ./src/*
7za rn ./build/$MAIN_NAME-v$MAIN_VERSION.pk3 @./rename-main.txt
#7za d ./build/$MAIN_NAME-v$MAIN_VERSION.pk3 Lua/rsr/freeslots

# Techno Madness PK3
7za u  -mx5 -tzip ./build/$TMZ_NAME-v$TMZ_VERSION.pk3 ./srctmz/*

# Deathmatch Pack PK3
# This should exclude:
# - HUD Graphics
# - Level header for Killbox
# - Sounds folder
# - init.lua
# - TRNSLATE.txt
7za u -mx5 -tzip -x@./exclude-mp.txt ./build/$MP_NAME-v$MP_VERSION.pk3 ./src/*
7za rn ./build/$MP_NAME-v$MP_VERSION.pk3 @./rename-mp.txt

