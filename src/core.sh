regist_config() {
	print_warning "No configuration file found."
	if confirm_y "Do you want to autogenerate a default configuration file?"; then
		save_config
	else
		select_from_menu "Choose your prefer domain" $domains
		domain=$result
		http=https
		confirm_y "Do you want to use https rather than http?" || \
			http=http
		confirm_y "Do you want to save the configuration?" && \
			save_config
	fi
}

load_config() {
	print_status "Reading configuration file..."
	source_config || regist_config
}

# $1 disable output when is not zero string
set_mirror_list() {
	print_status "Checking the environment and mirrors to install..."
	for software in $supported_softwares; do
		# check if the software is ready to deploy
		if has_command _${software}_check && _${software}_check; then
			if has_command _${software}_is_deployed && _${software}_is_deployed; then
				continue
			fi
			ready_to_install="$ready_to_install ${software}"
		elif ! has_command _${software}_check; then
			unsure_to_install="$unsure_to_install ${software}"
		fi
	done

	# direct return to disable output
	if [ -n "$1" ]; then return 0; fi

	if [ -z "$ready_to_install" ] && [ -z "$unsure_to_install" ]; then
		print_warning "No software is ready to install."
		print_supported
		confirm "Do you want to continue to use other function?" || exit 0
	fi

	if [ -n "$ready_to_install" ]; then
		print_info "The following software(s) are available to install:"
		echo "   $ready_to_install"
	fi

	if [ -n "$unsure_to_install" ]; then
		print_info "The following software(s) are not suggested to install:"
		echo "   $unsure_to_install"
	fi
}

# $1 disable output when is not zero string
set_mirror_recover_list() {
	ready_to_uninstall=""
	for software in $supported_softwares; do
		# check if the software is ready to recover
		if has_command _${software}_can_recover && _${software}_can_recover; then
			ready_to_uninstall="$ready_to_uninstall ${software}"
		fi
	done

	if [ -z "$ready_to_uninstall" ]; then
		print_warning "No software is ready to recover."
		confirm "Do you want to continue to use other function?" || exit 0
	fi

	if [ -n "$1" ]; then return 0; fi

	if [ -n "$ready_to_uninstall" ]; then
		print_info "The following software(s) are ready to recover:"
		echo "   $ready_to_uninstall"
	fi
}

# install hust-mirror
install() {
	install_path="$HOME/.local/bin"
	install_target="$install_path/hustmirror"
	if [ ! -d "$install_path" ]; then
		mkdir -p "$install_path"
	fi
	has_command curl || { 
		print_error "curl is required." 
		exit 1
	}
	print_status "Downloading latest hust-mirror..."
	curl -sL "${http}://${domain}/get.sh" > "$install_target" || {
		print_error "Failed to download hust-mirror."
		exit 1
	}
	chmod +x "$install_target"
	print_success "Successfully install hust-mirror."
	has_command hustmirror || print_warning "It seems ~/.local/bin is not in your path."
	print_success "Now, you can use \`hustmirror\` in your command line"
}

# $1 software to recover
recover() {
	software=$1
	if has_command _${software}_can_recover && _${software}_can_recover; then
		print_success "${software} can be recoverd."
	else 
		print_error "${software} can not be recoverd."
		return 1
	fi

	if has_command _${software}_uninstall; then
		print_status "recover ${software}..."
		result=0
		_${software}_uninstall || result=$?
		if [ $result -eq 0 ]; then
			print_success "Successfully uninstalled ${software}."
		else
			print_error "Failed to uninstall ${software}."
			return 1
		fi
	else
		print_error "No uninstallation method for ${software}."
	fi
}

# $1 software to deploy
deploy() {
	software=$1
	if has_command _${software}_install; then
		print_status "Deploying ${software}..."
		result=0
		_${software}_install || result=$?
		if [ $result -eq 0 ]; then
			print_success "Successfully deployed ${software}."
		else
			print_error "Failed to deploy ${software}."
			return 1
		fi
	else
		print_error "No installation method for ${software}."
	fi
}

# vim: set filetype=sh ts=4 sw=4 noexpandtab:
