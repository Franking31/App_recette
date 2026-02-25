#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter pub get
flutter build web --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY