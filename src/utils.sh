print_logo() {
	r_echo ' _   _ _   _ ____ _____ __  __ ___ ____  ____   ___  ____  '
	r_echo '| | | | | | / ___|_   _|  \/  |_ _|  _ \|  _ \ / _ \|  _ \ '
	r_echo '| |_| | | | \___ \ | | | |\/| || || |_) | |_) | | | | |_) |'
	r_echo '|  _  | |_| |___) || | | |  | || ||  _ <|  _ <| |_| |  _ < '
	r_echo '|_| |_|\___/|____/ |_| |_|  |_|___|_| \_\_| \_\\___/|_| \_\'
	r_echo
	r_echo "hustmirror-cli ${script_version} build ${build_time}"
}

display_help() {
	print_logo
	r_echo "A CLI Bash script to generate a configuration file"
	r_echo "for software repository on different distributions"
	r_echo
	r_echo "Usage: $0 [option...] " >&2
	r_echo
	r_echo "   -h, --help                 Display help message"
	r_echo
}

source_os_release() {
	# /etc/os-release does exist in most Linux distributions, and BSD variants
	test -e /etc/os-release && os_release='/etc/os-release' || os_release='/usr/lib/os-release'
	. "${os_release}"
}

is_root() {
	[ "$(id -u)" -eq 0 ] 
}

has_command() {
	command -v "${1}" >/dev/null 2>&1
}

has_sudo() {
	has_command sudo
}

has_curl() {
	has_command curl
}

has_git() {
	has_command git
}

has_sed() {
	has_command sed
}

is_tty() {
	[ -t 0 ]
}

c_echo() {
	if has_command printf; then
		printf "$*\n"
	else
		echo "$*"
	fi
}

r_echo() {
	if has_command printf; then
		printf "%s\n" "$*"
	else
		echo "$*"
	fi
}

echo_red() {
	if is_tty; then
		c_echo "\033[0;31m${1}\033[0m"
	else
		c_echo "${1}"
	fi
}

echo_green() {
	if is_tty; then
		c_echo "\033[0;32m${1}\033[0m"
	else
		c_echo "${1}"
	fi
}

echo_yellow() {
	if is_tty; then
		c_echo "\033[0;33m${1}\033[0m"
	else
		c_echo "${1}"
	fi
}

echo_blue() {
	if is_tty; then
		c_echo "\033[0;34m${1}\033[0m"
	else
		c_echo "${1}"
	fi
}

print_error() {
	echo_red "[ERR] ${1}"
}

print_warning() {
	echo_yellow "[WARN] ${1}"
}

print_success() {
	echo_green "[+] ${1}"
}

print_info() {
	echo_green "[!] ${1}"
}

print_status() {
	echo_yellow "[*] ${1}"
}

print_question() {
	echo_yellow "[?] ${1}"
}

get_input() {
	if ! is_tty; then return 1; fi
	[ -n "${1}" ] && print_question "${1}"
	read -r -p "[>] " input
	if [ -z "${input}" ]; then
		input="${2}"
	fi
}

confirm() {
	if ! is_tty; then return 1; fi
	# call with a prompt string or use a default
	get_input "${1:-Are you sure?} [y/N]"
	case "${input}" in
		[yY][eE][sS]|[yY])
			true
			;;
		*)
			false
			;;
	esac
}

confirm_y() {
	if ! is_tty; then return 0; fi
	# call with a prompt string or use a default
	get_input "${1:-Are you sure?} [Y/n]"
	case "${input}" in
		[nN][oO]|[nN])
			false
			;;
		*)
			true
			;;
	esac
}

print_supported() {
	print_info "Supported softwares:"
	echo "$supported_softwares" | xargs echo "   " | fold -s -w 80
}

set_sudo(){
	sudo=''
	if ! is_root; then
		print_warning "You are not root, trying to use sudo..."
		has_sudo || {
			print_error "No sudo command found, please install sudo first."
			return 1
		}
		sudo='sudo'
	fi
}


# ask user to select a item from a menu
# $1 tip message
# $2 menu items
select_from_menu() {
	message=$1
	shift
	menu_items=$@
	menu_number=0
	# implement array in POSIX shell
	set -- $menu_items
	print_question "$message"
	for item in $menu_items
	do
		menu_number=$(expr $menu_number + 1)
		echo "    $menu_number:" "$item"
	done
	while true; do
		get_input "Input an item number from the list above."
		result=$(eval "echo \$$input")
		if [ -z "$result" ]; then
			print_error "Bad input!"
		else
			break
		fi
	done
}

# vim: set filetype=sh ts=4 sw=4 noexpandtab:
