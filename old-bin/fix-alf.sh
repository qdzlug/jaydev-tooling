#!/bin/bash

# Check for procs...
ps -ef | grep Alf | grep python

# Kill procs...
kill $(ps -ef | grep Alf | grep python | awk '{print $2}')

# Check again...
ps -ef | grep Alf | grep python
