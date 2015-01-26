#!/bin/sh

THIS_DIR=$(cd $(dirname $0); pwd)

bundle exec puma -t 8:32 -e production -b unix://${THIS_DIR}/tmp/server.sock     
