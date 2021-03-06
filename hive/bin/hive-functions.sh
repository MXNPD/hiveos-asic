#!/usr/bin/env bash


#
# Copyright (C) 2016-2020  Hiveon
# Distributed under GNU GENERAL PUBLIC LICENSE 2.0
# License information can be found in the LICENSE file or at https://github.com/minershive/hiveos-asic/blob/master/LICENSE
#
# Linted by shellcheck 0.3.7
#


declare -r library_mission='Client for ASICs: Oh my handy little functions'
declare -r library_version='0.1.9'


# !!! bash strict mode, no unbound variables

#set -o nounset # !!! this is a library, so we don't want to break the other's scripts


#
# functions: script infrastructure
#

function print_script_version {
	echo -e "${YELLOW-}${script_mission}, version ${script_version}${NOCOLOR-}"
	echo
}

function errcho {
	#
	# Usage: errcho [arg...]
	#
	# uniform error logging to stderr
	#

	echo -e -n "${BRED-}$0"
	for (( i=${#FUNCNAME[@]} - 2; i >= 1; i-- )); { echo -e -n "${RED-}:${BRED-}${FUNCNAME[i]}"; }
	echo -e " error:${NOCOLOR-} $*"

} 1>&2

function debugcho {
	#
	# Usage: debugcho [arg...]
	#
	# uniform debug logging to stderr
	#

	# vars

	local this_argument

	# code

	echo -e -n "${DGRAY-}DEBUG $0"
	for (( i=${#FUNCNAME[@]} - 2; i >= 1; i-- )); { echo -e -n ":${FUNCNAME[i]}"; }
	for this_argument in "$@"; do
		printf " %b'%b%q%b'" "${CYAN-}" "${DGRAY-}" "${this_argument}" "${CYAN-}"
	done
	echo "${NOCOLOR-}"

} 1>&2


#
# functions: audit
#
# we need to audit externally--does the script work as intended or not (like the system returns exitcode "file not found")
# [[ $( script_to_audit ) != 'I AM FINE' ]] && echo "Something wrong with $script_to_check"
#

function print_i_am_doing_fine_then_exit () {
	#
	# Usage: print_i_am_fine_and_exit
	#

	# code

	echo "$__audit_ok_string"
	exit $(( exitcode_OK ))
}

function is_script_exist_and_doing_fine {
	#
	# Usage: is_script_exist_and_doing_fine
	#

	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r script_name="${1-}"

	# code

	is_program_in_the_PATH "$script_name" && [[ "$( "$script_name" --audit )" == "$__audit_ok_string" ]]
}


#
# functions: conditionals
#

function iif {
	#
	# Usage: iif flag cmd [arg...]
	#
	# if true (flag==1), runs cmd
	#

	# args

	(( $# < 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r -i condition="${1-}"
	local -r -a cmd=( "${@:2}" )

	# code

	if (( condition )); then
		"${cmd[@]}" # execute a command
	fi
}

function iif_pipe {
	#
	# Usage: iif flag cmd [arg...]
	#
	# if true (flag==1), runs cmd
	# if false (flag==0), copy stdin to stdout, if stdin not empty
	# could be used to construct conditional pipelines
	#

	# args

	(( $# < 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r -i condition="${1-}"
	local -r -a cmd=( "${@:2}" )

	# code

	if (( condition )); then
		"${cmd[@]}" # execute a command
	else
		cat - # pass stdin to stdout
	fi
}

function is_program_in_the_PATH {
	#
	# Usage: is_program_in_the_PATH 'program_name'
	#

	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r program_name="$1"

	# code

	type -p "$program_name" &> /dev/null
}

function is_function_exist {
	#
	# Usage: is_function_exist 'function_name'
	#
	# stdin: none
	# stdout: none
	# exit code: boolean
	#

	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r function_name="$1"

	# code

	declare -F -- "$function_name" >/dev/null
}

function is_first_floating_number_bigger_than_second {
	#
	# Usage: is_first_floating_number_bigger_than_second 'first_number' 'second_number'
	#

	# args

	(( $# != 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r first_number="${1-}"
	local -r second_number="${2-}"

	# code

	# 1. trivial test based on string comparison
	if [[ "$first_number" == "$second_number" ]]; then
		 false
	# 2. compare a part before the dot as numbers
	elif (( ${first_number%.*} == ${second_number%.*} )); then
		[[ "${first_number#*.}" > "${second_number#*.}" ]] # intentional text compare
	else
		(( ${first_number%.*} > ${second_number%.*} ))
	fi
}

function is_first_version_equal_to_second {
	#
	# Usage: is_first_version_equal_to_second 'first_version' 'second_version'
	#

	# args

	(( $# != 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local first_version="${1-}"
	local second_version="${2-}"

	# vars

	local IFS=.-
	local -i idx
	local -a first_version_array second_version_array

	# code

	if [[ "$first_version" != "$second_version" ]]; then
		first_version="${first_version//dev/}"
		second_version="${second_version//dev/}"

		first_version_array=( $first_version )
		second_version_array=( $second_version )

		# fill empty fields in first_version_array with zeros
		for (( idx=${#first_version_array[@]}; idx < ${#second_version_array[@]}; idx++ )); do
			first_version_array[idx]=0
		done
		for (( idx=0; idx < ${#first_version_array[@]}; idx++ )); do
			# you don't need double quotes here but we need to fix a syntax highlighting issue
			(( "10#${first_version_array[idx]}" > "10#${second_version_array[idx]-0}" )) && return $(( exitcode_GREATER_THAN ))
			(( "10#${first_version_array[idx]}" < "10#${second_version_array[idx]-0}" )) && return $(( exitcode_LESS_THAN ))
		done
	fi

	return $(( exitcode_IS_EQUAL ))
	declare -r -i exitcode_IS_EQUAL=0
declare -r -i exitcode_GREATER_THAN=1
declare -r -i exitcode_LESS_THAN=2

}


#
# functions: text
#

function strip_ansi {
	#
	# Usage: strip_ansi 'text'
	#        cat file | strip_ansi
	#
	# strips ANSI codes from text
	#
	# < or $1: The text to strip
	# >: ANSI stripped text
	#

	# args

	(( $# > 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r input_text="${1:-$( < /dev/stdin )}" # get from arg or stdin

	# vars

	local line=''

	# code

	while IFS='' read -r line || [[ -n "$line" ]]; do
		(
			shopt -s extglob
			printf '%s\n' "${line//$'\e'[\[(]*([0-9;])[@-n]/}"
		)
	done <<< "$input_text"
}


#
# functions: math
#

function calculate_percent_from_number {
	#
	# Usage: calculate_percent_from_number 'percent' 'number'
	#
	# gives result rounded to the *nearest* integer, not the frac part as in the bash builtin arithmetics
	#

	# args

	(( $# != 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r -i percent="${1-}"
	local -r -i number="${2-}"

	# code

	printf '%.0f\n' "$((10**9 * (number * percent) / 100 ))e-9" # yay, neat trick
}

function set_bits_by_mask {
	#
	# Usage: set_bits_by_mask 'variable_by_ref' 'bitmask_by_ref'
	#
	
	# args

	(( $# != 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r -n variable_by_ref="${1-}"
	local -r -n bitmask_by_ref="${2-}"

	# code

	(( variable_by_ref |= bitmask_by_ref )) # bitwise OR
}


#
# functions: files
#

function get_file_last_modified_time_in_seconds {
	#
	# Usage: get_file_last_modified_time_in_seconds 'file_name'
	#

	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r file_name="${1-}"

	# code

	if [[ -f "$file_name" ]]; then
		date -r "$file_name" '+%s'
	else
		errcho "'$file_name' not found"
		return $(( exitcode_ERROR_NOT_FOUND ))
	fi
}

function get_file_size_in_bytes {
	#
	# Usage: get_file_size_in_bytes 'file_name'
	#
	# highly portable, uses ls
	#

	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r file_name="${1-}"

	# arrays

	local -a ls_output_field=()

	# code

	# parse ls output to array
	# -rwxr-xr-x 1 0 0 4745 Apr  3 16:03 log-watcher.sh
	# 0          1 2 3 4    5    6 7     8
	if [[ -f "$file_name" ]] && ls_output_field=( $( ls -dn "$file_name" ) ); then
		# print 5th field
		echo "${ls_output_field[4]}"
	else
		errcho "$file_name not found"
		return $(( exitcode_ERROR_NOT_FOUND ))
	fi
}


#
# functions: date & time
#

function get_current_system_time_in_seconds {
	#
	# Usage: get_current_system_time_in_seconds
	#

	printf '%(%s)T\n' -1
}

function set_variable_to_current_system_time_in_seconds {
	#
	# Usage: set_variable_to_current_system_time_in_seconds 'variable_to_set_by_ref'
	#

	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r -n variable_to_set_by_ref="${1-}" # get var by ref

	# code

	# shellcheck disable=SC2034
	variable_to_set_by_ref="$( get_current_system_time_in_seconds )"
}

function seconds2dhms {
	#
	# Usage: seconds2dhms 'time_in_seconds' ['delimiter']
	#
	# Renders time_in_seconds to 'XXd XXh XXm[ XXs]' string
	# Default delimiter = ' '
	#

	# args

	(( $# < 1 || $# > 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -i -r time_in_seconds="${1#-}" # strip sign, get ABS
	local -r delimiter_DEFAULT=' '
	local -r delimiter="${2-${delimiter_DEFAULT}}"

	# consts

	local -i -r days="$(( time_in_seconds / 60 / 60 / 24 ))"
	local -i -r hours="$(( time_in_seconds / 60 / 60 % 24 ))"
	local -i -r minutes="$(( time_in_seconds / 60 % 60 ))"
	local -i -r seconds="$(( time_in_seconds % 60 ))"

	# code

	(( days > 0 ))					&&	printf '%ud%s'	"$days" "$delimiter"
	(( hours > 0 ))					&&	printf '%uh%s'	"$hours" "$delimiter"
	(( minutes > 0 ))				&&	printf '%um%s'	"$minutes"
	(( minutes > 0 && days < 1 ))	&&	printf '%s'		"$delimiter"
	(( days < 1 ))					&&	printf '%us'	"$seconds" # no seconds if days > 0
										printf '\n'
}

function format_date_in_seconds {
	#
	# Usage: format_date_in_seconds 'time_in_seconds' ['date_format']
	#
	# 'time_in_seconds' can be -1 for a current time
	# 'date_format' as in strftime(3) OR special 'dhms' format
	#

	# args

	(( $# < 1 || $# > 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -i -r time_in_seconds="${1-}"
	local -r date_format_DEFAULT='%F %T'
	local -r date_format="${2-${date_format_DEFAULT}}"

	# code

	if [[ $date_format == 'dhms' ]]; then
		seconds2dhms "$time_in_seconds"
	else
		printf "%(${date_format})T\n" "$time_in_seconds"
	fi
}

function get_system_uptime_in_seconds {
	#
	# Usage: get_system_uptime_in_seconds
	#

	# vars

	local -a uptime_line
	local cputime_line
	local -i system_uptime_in_seconds

	# code

	# 'test -s' - do not work on procfs files
	# 'test -r' - file exists and readable 
	if [[ -r /proc/uptime ]]; then
		uptime_line=( $( < /proc/uptime ) )
		system_uptime_in_seconds=$(( ${uptime_line/\.} / 100 ))
	elif [[ -r /proc/sched_debug ]]; then
		# do we really need a second option?
		cputime_line="$( grep -F -m 1 '\.clock' /proc/sched_debug )"
		if [[ $cputime_line =~ [^0-9]*([0-9]*).* ]]; then
			system_uptime_in_seconds=$(( BASH_REMATCH[1] / 1000 ))
		fi
	else
		errcho '/proc/uptime or /proc/sched_debug not found'
		return $(( exitcode_ERROR_NOT_FOUND ))
	fi

	printf '%u\n' "$system_uptime_in_seconds"
}

function snore {
	#
	# Usage: snore 1
	#        snore 0.2
	#
	# pure bash 'sleep'
	# https://blog.dhampir.no/content/sleeping-without-a-subprocess-in-bash-and-how-to-sleep-forever

	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r sleep_time="${1-}"

	# vars

	local IFS

	# code

	# shellcheck disable=SC1083
	# ...man bash:
	# Each redirection that may be preceded by a file descriptor number may instead be preceded by a word of the form {varname}.
	[[ -n "${__snore_fd:-}" ]] || exec {__snore_fd}<> <(:)
	read -r -t "${sleep_time}" -u "$__snore_fd" || :
}


#
# functions: strings
#

function get_substring_position_in_string {
	#
	# Usage: get_substring_position_in_string
	#

	# args

	(( $# != 2 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r substring="$1"
	local -r string="$2"

	# vars

	local prefix

	# code

	prefix="${string%%${substring}*}"

	if (( ${#prefix} != ${#string} )); then
		echo "${#prefix}"
		return $(( exitcode_OK ))
	else
		return $(( exitcode_ERROR_NOT_FOUND ))
	fi
}


#
# functions: processes
#

function pgrep_count {
	#
	# Usage: pgrep_count 'pattern'
	#
	# pgrep --count naive emulator
	#
	
	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r pattern="$1"

	# vars

	local marker self

	# code

	printf -v marker '%(%s)T-%s-%u%u' -1 "$FUNCNAME" "${RANDOM}" "${RANDOM}"
	self="${$}[[:space:]].+${FUNCNAME}"

	ps w | tail -n +2 | grep -E -e "$pattern" -e "$marker" -- | grep -Evc -e "$marker" -e "$self" --
}

function pgrep_quiet {
	#
	# Usage: pgrep_quiet 'pattern'
	#
	# pgrep --quiet naive emulator
	#
	
	# args

	(( $# != 1 )) && { errcho 'invalid number of arguments'; return $(( exitcode_ERROR_IN_ARGUMENTS )); }
	local -r pattern="$1"

	# vars

	local marker self

	# code

	printf -v marker '%(%s)T:%s:%u%u' -1 "$FUNCNAME" "${RANDOM}" "${RANDOM}"
	self="${$}[[:space:]].+${FUNCNAME}"

	ps w | tail -n +2 | grep -E -e "$pattern" -e "$marker" -- | grep -Evq -e "$marker" -e "$self" --
}


#
# the last: functions lister
#

function __list_functions {
	#
	# List all functions but started with '_'
	#

	# consts

	local -r private_function_attribute_RE='^_'

	# vars

	local function_name=''
	local -a all_functions=()
	local -a private_functions=()
	local -a public_functions=()

	# code

	all_functions=( $( compgen -A function ) )

	for function_name in "${all_functions[@]}"; do
		if [[ "${function_name}" =~ $private_function_attribute_RE ]]; then
			private_functions+=("$function_name")
		else
			public_functions+=("$function_name")
		fi
	done

	if (( ${#private_functions[@]} != 0 )); then
		echo "${#private_functions[@]} private function(s):"
		echo
		printf '%s\n' "${private_functions[@]}"
		echo
	fi

	echo "${#public_functions[@]} public function(s):"
	echo
	printf '%s\n' "${public_functions[@]}"
	echo
}


# consts

declare -r __audit_ok_string='I AM DOING FINE'
# shellcheck disable=SC2034
declare -r -i exitcode_OK=0
declare -r -i exitcode_ERROR_NOT_FOUND=1
declare -r -i exitcode_ERROR_IN_ARGUMENTS=127
# shellcheck disable=SC2034
declare -r -i exitcode_ERROR_SOMETHING_WEIRD=255

declare -r -i exitcode_IS_EQUAL=0
declare -r -i exitcode_GREATER_THAN=1
declare -r -i exitcode_LESS_THAN=2


# main

if ! ( return 0 2>/dev/null ); then # not sourced

	declare -r script_mission="$library_mission"
	declare -r script_version="$library_version"

	case "$*" in
		'')
			source colors
			print_script_version
			__list_functions
			;;
		*)
			if is_function_exist "$1"; then
				"$@" # potentially unsafe
			else
				errcho "function '$1' is not defined"
			fi
			;;
	esac
fi
