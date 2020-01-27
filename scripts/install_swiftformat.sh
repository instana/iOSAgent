if which tools >/dev/null; then
  cd tools
else
  mkdir tools
  cd tools
fi

mkdir SwiftFormat
git clone --depth 1 https://github.com/nicklockwood/SwiftFormat SwiftFormat-src
cd SwiftFormat-src
swift build -c release
cp CommandLineTool/swiftformat ../SwiftFormat
cd ..
rm -rf SwiftFormat-src

