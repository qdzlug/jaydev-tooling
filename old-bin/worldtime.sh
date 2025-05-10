#!/bin/sh
#
# Print the specified (or current) time from base time in other time zones
# and the converse
#

# Base time zone from/to which to convert
TZBASE=UTC

# Time zones to display
# See /usr/share/zoneinfo/ for more names
TZONES='UTC Europe/London America/New_York America/Chicago America/Denver America/Los_Angeles Asia/Seoul Asia/Singapore Asia/Hong_Kong'
##TZONES='UTC Europe/London CST6CDT MST7MDT PST8PDT'

# Display format
FORMAT='%H:%M (%p) %Z %a %m %b %Y'

if [ "$1" ] ; then
  time="$1"
else
  time=`date +%T`
fi

# Show the time from the specified input time zone in the specified output
# time zone
showtime()
{
  TZIN=$1
  TZOUT=$2

  TZ=$TZOUT date --date='TZ="'$TZIN'"'" $time" +"$time $TZIN is $TZOUT $FORMAT"
}

echo "Convert input into output timezones..."
for tz in $TZONES ; do
  showtime $TZBASE $tz
done

echo

echo "Convert output into input timezones..."
for tz in $TZONES ; do
  showtime $tz $TZBASE
done

