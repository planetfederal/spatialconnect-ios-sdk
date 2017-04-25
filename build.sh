#!/bin/bash

carthage update; xcodebuild -project SpatialConnect.xcodeproj; -scheme SpatialConnect build
