#! /bin/sh
# v2022.117
# For instance, pass an argument like '^Essential: yes'.

set -e
trap 'test $? = 0 || echo "\"$0\" failed!" >& 2' 0

qrx() {
	printf '%s\n' "$1" | sed 's!/!\\&!g'
}

add_outfield() {
	rx=`qrx "$1"`
	out_cks=$out_cks${out_cks:+$NL}'/^\('$rx'\):/ H'
}
NL=`printf '\n:'`; NL=${NL%:}

out_cks= match_cks=
record_prefix=
while getopts p:o: opt
do
	case $opt in
		p) record_prefix='\n'`qrx "$OPTARG"`;;
		o) add_outfield "$OPTARG";;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

if test -z "$out_cks"
then
	# Anchored match. Append '.*' if just a name prefix.
	add_outfield Package
fi

: ${1?:field name/value search regex}
while test $# != 0
do
	rx=`qrx "$1"`
	match_cks=$match_cks${match_cks:+$NL}'/'$rx'/ b match'
	shift
done

sed '
	1 {
		# Initialize HOLD space with "F".
		x; s/^/F'"$record_prefix"'/; x
	}
	/^$/ {
		:ckout
		# Output HOLD space after managing to remove "T\n"-prefix.
		g; s/^T\n//; t show
		:reset
		# Initialize HOLD space for every new record with "F"-prefix.
		s/^.*/F'"$record_prefix"'/
		:save
		h
		b drop
		:show
		p
		b reset
	}
	# Append requested output field lines to HOLD space.
	'"$out_cks"'
	# Match search fields.
	'"$match_cks"'
	$ b ckout
	b drop
	:match
	# Record matches search expression.
	# Change HOLD space prefix to "T".
	g; s/^F/T/; t save
	# Nothing to do: Prefix should already be "T".
	:drop
	# Do not display this input line.
	d
' plist
