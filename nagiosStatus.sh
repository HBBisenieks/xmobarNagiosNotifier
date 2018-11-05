#/bin/bash

# nagiosStatus.sh
#
# Simple Nagios status fetcher for use with xmobar
# prints number of unhandled Critical, Warning, and Unknown nagios alerts
# with nice, eye-catching colors, straight to your status bar
#
# deploy to your .xmobarrc with
# Run Com "/path/to/nagiosStatus.sh" [] "nagios" 600
# 
# MIT License
#
# Copyright (c) 2018 Hilary B. Bisenieks
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# nagios server address
host=""

# if host is unreachable, exit 1
ping -c 1 $host > /dev/null 2>&1

if [ $? -ne 0 ] ; then
	echo "$host unreachable"
	exit 1
fi

# set up environment and clear info from previous checks
dir="nag"
mkdir -p "$dir"
cd "$dir" || exit 1
rm -f statPage statPageLog

# set the rest of the variables only if server is reachable
# status is for UNHANDLED problems, for all problems, remove everything between ? and servicestatustypes=28
servicePage="/nagios/cgi-bin/status.cgi?host=all&type=detail&hoststatustypes=3&serviceprops=42&servicestatustypes=28"
hostPage="/nagios/cgi-bin/status.cgi?hostgroup=all&style=hostdetail&hoststatustypes=12&hostprops=42"
options="-T 10 -t 4 -w 1 --retry-connrefused --server-response"
statusPages="$servicePage $hostPage"

# username and password for nagios user if server is secured with htpasswd
user=""
pass=""

# files for status and log
statPage="statPage"
statPageLog="statPageLog"

# status colors -- can be names or hex colors
critColor="red"
warnColor="yellow"
unkColor="orange"
critical=0
warning=0
unknown=0

nagCheck () {
	# get status
	wget $options http://$host$1 -O "$statPage" -o "$statPageLog" --user="$user" --password="$pass"

	# exit 1 if wget fails
	if [ $? != 0 ] ; then
		echo "Unable to fetch staus info"
		exit 1
	fi

	# check for OK HTTP header
	rcode=`grep "HTTP/1.1 200 OK" "$statPageLog" | awk '{ print $2 }'`

	# if HTTP 200 OK, proceed, otherwise return HTTP status and exit
	if [ "$rcode" -eq "200" ] ; then
		# get numbers for critical, warning, and unknown statuses
		c=`egrep  "BGCRITICAL'>(1/1|2/2|3/3|4/4)" "$statPage" | wc -l | sed -e 's/ //g'`
		w=`egrep  "BGWARNING'>(1/1|2/2|3/3|4/4)" "$statPage" | wc -l | sed -e 's/ //g'`
		u=`egrep "BGUNKNOWN" "$statPage" | wc -l | sed -e 's/ //g'`
		critical=$((critical + c))
		warning=$((warning + w))
		unknown=$((unknown + u))
	else
		echo "Server returned HTTP $rcode"
		exit 1
	fi
}

for i in $statusPages ; do
	nagCheck $i
done

# format nonzero numbers for problem statuses for use with xmobar
if [ "$critical" -gt 0 ] ; then
	cOut="<fc=$critColor>$critical</fc>"
else
	cOut="$critical"
fi

if [ "$warning" -gt 0 ] ; then
	wOut="<fc=$warnColor>$warning</fc>"
else
	wOut="$warning"
fi

if [ "$unknown" -gt 0 ] ; then
	uOut="<fc=$unkColor>$unknown</fc>"
else
	uOut="$unknown"
fi

echo "C:$cOut W:$wOut U:$uOut"
exit 0
