curl -L 'https://github.com/realm/SwiftLint/releases/latest/download/portable_swiftlint.zip' -o swiftlint.zip
if which tools >/dev/null; then
  echo tools folder already exists
else
  mkdir tools
fi

unzip swiftlint.zip -d tools/swiftlint
rm -f swiftlint.zip
