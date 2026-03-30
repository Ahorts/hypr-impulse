#!/usr/bin/env bash

pkill qs
sleep 0.5
pkexec /usr/local/bin/vynx update
qs -c ii