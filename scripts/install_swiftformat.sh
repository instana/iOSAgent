if which tools >/dev/null; then
  cd tools
else
  mkdir tools
  cd tools
fi

git clone --depth 1 https://github.com/nicklockwood/SwiftFormat
cd SwiftFormat
swift build -c release
