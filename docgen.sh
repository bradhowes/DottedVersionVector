#!/bin/bash

set -x

rm -rf ./docs/*
[[ -d images ]] && cp -r images docs/

# xcodebuild -workspace SoundFonts.xcworkspace -scheme App

JAZZY=$(type -p jazzy)

${JAZZY} --module DottedVersionVector \
         --module-version 1.0.0 \
         --min-acl internal \
         --swift-build-tool spm \
         -g https://github.com/bradhowes/DottedVersionVector \
         -a "Brad Howes" \
         -u https://linkedin.com/in/bradhowes
