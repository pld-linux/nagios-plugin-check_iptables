#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

PROGNAME=${0##*/}
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision$' | sed -e 's/[^0-9.]//g'`
ARGS="$*"

. $PROGPATH/utils.sh

iptables=/usr/sbin/iptables
sudo=/usr/bin/sudo
chain=INPUT
table=filter
verbose=0
warning=1
critical=1
setup_sudo=0

print_usage() {
    echo "Usage: $PROGNAME -C CHAIN -t TABLE"
    echo "Usage: $PROGNAME --help"
    echo "Usage: $PROGNAME --version"
}

print_help() {
	print_revision $PROGNAME $REVISION
	echo ""
	print_usage
	echo ""
	echo "This plugin tests if iptables has needed amount of rules loaded"
	echo ""

	echo "-C CHAIN"
	echo "   Chain to list. Default: $chain"
	echo "-t TABLE"
	echo "   Table to list. Default: $table"
	echo "-S"
	echo "   Install sudo rules"
	echo "-v"
	echo "   Enable verbose run"
	echo "--help"
	echo "   Print this help screen"
	echo "--version"
	echo "   Print version and license information"
	echo ""

	support
	exit 0
}

setup_sudoers() {
	new=/etc/sudoers.$$.new
	umask 0227
	cat /etc/sudoers > $new
	cat >> $new <<-EOF

	# Lines matching CHECK_IPTABLES added by $0 $ARGS on $(date)
	User_Alias CHECK_IPTABLES=nagios
	CHECK_IPTABLES ALL=(root) NOPASSWD: $list_iptables
	EOF

	if visudo -c -f $new; then
		mv -f $new /etc/sudoers
		exit 0
	fi
	rm -f $new
	exit 1
}

list_iptables() {
	# if running as root, skip sudo
	[ "$(id -u)" != 0 ] || sudo=

	$sudo $list_iptables | grep -Fc /
}

while [ $# -gt 0 ]; do
	case "$1" in
	--help)
		print_help
		exit 0
		;;

	-h)
		print_help
		exit 0
		;;

	--version)
		print_revision $PROGNAME $REVISION
		exit 0
		;;

	-V)
		print_revision $PROGNAME $REVISION
		exit 0
		;;

	-v)
		verbose=1
		;;

	-S)
		setup_sudo=1
		;;

	-C)
		chain=$2; shift
		;;

	-t)
		table=$2; shift
		;;

	-w)
		warning=$2; shift
		;;

	-c)
		critical=$2; shift
		;;

	*)
		echo >&2 "Unknown argument: $1"
		print_usage
		exit $STATE_UNKNOWN
		;;
	esac
	shift
done

rc=$STATE_UNKNOWN

list_iptables="$iptables -n -t $table -L $chain"

if [ "$setup_sudo" = 1 ]; then
	setup_sudoers
fi

count=$(list_iptables)
if [ "$count" -lt "$critical" ]; then
	rc=$STATE_CRITICAL
	state=CRITICAL
elif [ "$count" -lt "$warning" ]; then
	rc=$STATE_WARNING
	state=WARNING
else
	rc=$STATE_OK
	state=OK
fi

echo "$state: $count iptables rules in $chain chain of $table table"

exit $rc
