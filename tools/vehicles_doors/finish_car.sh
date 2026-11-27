#!/bin/bash
# finish_car.sh <game_dir> <id> [lod ids...]: after zh_build.py + zh_post.py and the car's outline in doors_zh.json:
# repair (idempotent), cut the doors, render the cabin picture, install into vehicles/models.
set -e
H=$(cd "$(dirname "$0")" && pwd); G=$1; ID=$2; shift 2
python3 $H/fix_wheels.py $G $ID > /dev/null
python3 $H/flip_dump.py $G/${ID}_body $G/${ID}_w0 $G/${ID}_w1 $G/${ID}_w2 $G/${ID}_w3 > /dev/null
python3 $H/cut_doors.py $G/${ID}_body $G/cut $ID | tail -1
python3 $H/install_car.py $G $ID "$@" 2>&1 | tail -1
