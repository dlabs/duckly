#!/usr/bin/env bash

pry -Ilib -r "duckly" -r "dotenv" \
  -e "Dotenv.load; d = duck = Duckly.new(email: ENV['DUCK_UID'], password: ENV['DUCK_PWD']);"

