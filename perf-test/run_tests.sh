#!/bin/bash
set -ex

# Install dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y wget gnupg ca-certificates
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Set up the Chrome wrapper
mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable-orig
echo '#!/bin/bash' > /usr/bin/google-chrome-stable
echo 'exec /usr/bin/google-chrome-stable-orig --no-sandbox --headless --disable-gpu "$@"' >> /usr/bin/google-chrome-stable
chmod +x /usr/bin/google-chrome-stable

# Run the tests
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart test --platform chrome