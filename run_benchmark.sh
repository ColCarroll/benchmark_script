#!/usr/bin/env bash

# Note: set up an identity file in ~/.ssh/config that looks something like
# Host pymc_benchmarks
#   HostName github.com
#   User benchmarker
#   IdentityFile /home/whoever/.ssh/id_rsa.benchmarker
#   IdentitiesOnly yes
set -ex # fail on first error, print commands

SSH_HOST="pymc_benchmarks"
GIT_REMOTE="git@${SSH_HOST}:pymc-devs/pymc3.git"
OUTPUT_REMOTE="git@${SSH_HOST}:ColCarroll/pymc3-benchmarks.git"
LOCAL_DIR="$HOME/pymc3"
START_SHA="40ccb10936fae21dd59db15585aef01cdae36eda" # 3.0, January 9, 2017
BENCHMARK_DIR="$LOCAL_DIR/benchmarks"
OUTPUT_DIR="$BENCHMARK_DIR/benchmarks"
START_DIR=$(pwd)

# Swappable install function for different projects
install() {
  source $LOCAL_DIR/scripts/install_miniconda.sh
  source $LOCAL_DIR/scripts/create_testenv.sh --global
}

if [ ! -d "$LOCAL_DIR" ]; then
  git clone "$GIT_REMOTE" "$LOCAL_DIR"
  install
  conda install -y asv
  cd "$BENCHMARK_DIR"
  yes | asv machine
fi

cd "$LOCAL_DIR"
git pull origin master

# Make sure the output directory is there
if [ ! -d "$OUTPUT_DIR" ]; then
  git clone "$OUTPUT_REMOTE" "$OUTPUT_DIR"
fi

# Make sure output directory is current
cd "$OUTPUT_DIR"
git pull

# Run benchmarks
cd "$BENCHMARK_DIR"
asv run --skip-existing-commits $START_SHA..master

# Push results back to display site
cd "$OUTPUT_DIR"
git add -u
git commit -m 'Benchmarks from $(date)'
git push origin master

# Go back to start
cd "$START_DIR"
