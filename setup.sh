#!/usr/bin/env bash
set -euo pipefail

# Read versions from the .tool-versions file
erlang_version=$(grep '^erlang ' .tool-versions | awk '{print $2}')
elixir_version=$(grep '^elixir ' .tool-versions | awk '{print $2}')

# Create a working directory
mkdir -p deps
cd deps

# Install Erlang
echo "Installing Erlang $erlang_version..."
wget -q https://github.com/erlang/otp/releases/download/OTP-${erlang_version}/otp_src_${erlang_version}.tar.gz
tar -xf otp_src_${erlang_version}.tar.gz
cd otp_src_${erlang_version}
./configure
make -j$(nproc)
sudo make install
cd ..

# Install Elixir
echo "Installing Elixir $elixir_version..."
wget -q https://github.com/elixir-lang/elixir/releases/download/v${elixir_version}/Precompiled.zip
unzip -q Precompiled.zip -d elixir-${elixir_version}
sudo cp -r elixir-${elixir_version}/* /usr/local/

# Cleanup
cd ..
rm -rf deps

echo "Installation complete."
elixir -v
