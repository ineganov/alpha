#!/bin/sh

diff trace.log sanity/golden_log | grep Starting -A 1000 | grep Exiting -B 1000

