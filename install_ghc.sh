#!/bin/sh

# This script downloads the 'ghcup' binary into '~/.ghcup/bin/' and then runs an interactive
# installation that lets you choose various options. Below is a list of environment variables
# that affect the installation procedure.

# Main settings:
#   * BOOTSTRAP_HASKELL_NONINTERACTIVE - any nonzero value for noninteractive installation
#   * BOOTSTRAP_HASKELL_NO_UPGRADE - any nonzero value to not trigger the upgrade
#   * BOOTSTRAP_HASKELL_MINIMAL - any nonzero value to only install ghcup
#   * GHCUP_USE_XDG_DIRS - any nonzero value to respect The XDG Base Directory Specification
#   * BOOTSTRAP_HASKELL_VERBOSE - any nonzero value for more verbose installation
#   * BOOTSTRAP_HASKELL_GHC_VERSION - the ghc version to install
#   * BOOTSTRAP_HASKELL_CABAL_VERSION - the cabal version to install
#   * BOOTSTRAP_HASKELL_INSTALL_STACK - whether to install latest stack
#   * BOOTSTRAP_HASKELL_INSTALL_HLS - whether to install latest hls
#   * BOOTSTRAP_HASKELL_ADJUST_BASHRC - whether to adjust PATH in bashrc (prepend)
#   * BOOTSTRAP_HASKELL_ADJUST_CABAL_CONFIG - whether to adjust mingw paths in cabal.config on windows

# License: LGPL-3.0


# safety subshell to avoid executing anything in case this script is not downloaded properly
(

plat="$(uname -s)"
arch=$(uname -m)
ghver="0.1.17.4"
base_url="https://downloads.haskell.org/~ghcup"

export GHCUP_SKIP_UPDATE_CHECK=yes

case "${plat}" in
        MSYS*|MINGW*)
			: "${GHCUP_INSTALL_BASE_PREFIX:=/c}"
			GHCUP_DIR=$(cygpath -u "${GHCUP_INSTALL_BASE_PREFIX}/ghcup")
			GHCUP_BIN=$(cygpath -u "${GHCUP_INSTALL_BASE_PREFIX}/ghcup/bin")
			: "${GHCUP_MSYS2:=${GHCUP_DIR}/msys64}"
			;;
		*)
			: "${GHCUP_INSTALL_BASE_PREFIX:=$HOME}"

			if [ -n "${GHCUP_USE_XDG_DIRS}" ] ; then
				GHCUP_DIR=${XDG_DATA_HOME:=$HOME/.local/share}/ghcup
				GHCUP_BIN=${XDG_BIN_HOME:=$HOME/.local/bin}
			else
				GHCUP_DIR=${GHCUP_INSTALL_BASE_PREFIX}/.ghcup
				GHCUP_BIN=${GHCUP_INSTALL_BASE_PREFIX}/.ghcup/bin
			fi
			;;
esac

: "${BOOTSTRAP_HASKELL_GHC_VERSION:=recommended}"
: "${BOOTSTRAP_HASKELL_CABAL_VERSION:=recommended}"


die() {
    if [ -n "${NO_COLOR}" ] ; then
        (>&2 printf "%s\\n" "$1")
    else
        (>&2 printf "\\033[0;31m%s\\033[0m\\n" "$1")
    fi
    exit 2
}

warn() {
    if [ -n "${NO_COLOR}" ] ; then
        printf "%s\\n" "$1"
    else
        case "${plat}" in
                MSYS*|MINGW*)
                    # shellcheck disable=SC3037
                    echo -e "\\033[0;35m$1\\033[0m"
                    ;;
                *)
                    printf "\\033[0;35m%s\\033[0m\\n" "$1"
                    ;;
        esac
    fi
}

yellow() {
    if [ -n "${NO_COLOR}" ] ; then
        printf "%s\\n" "$1"
    else
        case "${plat}" in
                MSYS*|MINGW*)
                    # shellcheck disable=SC3037
                    echo -e "\\033[0;33m$1\\033[0m"
                    ;;
                *)
                    printf "\\033[0;33m%s\\033[0m\\n" "$1"
                    ;;
        esac
    fi
}

green() {
    if [ -n "${NO_COLOR}" ] ; then
        printf "%s\\n" "$1"
    else
        case "${plat}" in
                MSYS*|MINGW*)
                    # shellcheck disable=SC3037
                    echo -e "\\033[0;32m$1\\033[0m"
                    ;;
                *)
                    printf "\\033[0;32m%s\\033[0m\\n" "$1"
                    ;;
        esac
    fi
}

edo() {
    "$@" || die "\"$*\" failed!"
}

eghcup() {
	edo _eghcup "$@"
}

_eghcup() {
	if [ -n "${BOOTSTRAP_HASKELL_YAML}" ] ; then
		args="-s ${BOOTSTRAP_HASKELL_YAML}"
	fi
    if [ -z "${BOOTSTRAP_HASKELL_VERBOSE}" ] ; then
        # shellcheck disable=SC2086
        "${GHCUP_BIN}/ghcup" ${args} "$@"
    else
        # shellcheck disable=SC2086
        "${GHCUP_BIN}/ghcup" ${args} --verbose "$@"
    fi
}

_done() {
	echo
	echo "==============================================================================="
	case "${plat}" in
			MSYS*|MINGW*)
				green
				green "All done!"
				green
				green "In a new powershell or cmd.exe session, now you can..."
				green
				green "Start a simple repl via:"
				green "  ghci"
				green
				green "Start a new haskell project in the current directory via:"
				green "  cabal init --interactive"
				green
				green "Install other GHC versions and tools via:"
				green "  ghcup list"
				green "  ghcup install <tool> <version>"
				green
				green "To install system libraries and update msys2/mingw64,"
				green "open the \"Mingw haskell shell\""
				green "and the \"Mingw package management docs\""
				green "desktop shortcuts."
				green
				green "If you are new to Haskell, check out https://www.haskell.org/ghcup/install/#first-steps"
				;;
			*)
				green
				green "All done!"
				green
				green "To start a simple repl, run:"
				green "  ghci"
				green
				green "To start a new haskell project in the current directory, run:"
				green "  cabal init --interactive"
				green
				green "To install other GHC versions and tools, run:"
				green "  ghcup tui"
				green
				green "If you are new to Haskell, check out https://www.haskell.org/ghcup/install/#first-steps"
				;;

	esac


	exit 0
}

download_ghcup() {

    case "${plat}" in
        "linux"|"Linux")
			case "${arch}" in
				x86_64|amd64)
					# we could be in a 32bit docker container, in which
					# case uname doesn't give us what we want
					if [ "$(getconf LONG_BIT)" = "32" ] ; then
						_url=${base_url}/${ghver}/i386-linux-ghcup-${ghver}
					elif [ "$(getconf LONG_BIT)" = "64" ] ; then
						_url=${base_url}/${ghver}/x86_64-linux-ghcup-${ghver}
					else
						die "Unknown long bit size: $(getconf LONG_BIT)"
					fi
					;;
				i*86)
					_url=${base_url}/${ghver}/i386-linux-ghcup-${ghver}
					;;
				armv7*|*armv8l*)
					_url=${base_url}/${ghver}/armv7-linux-ghcup-${ghver}
					;;
				aarch64|arm64)
					# we could be in a 32bit docker container, in which
					# case uname doesn't give us what we want
					if [ "$(getconf LONG_BIT)" = "32" ] ; then
						_url=${base_url}/${ghver}/armv7-linux-ghcup-${ghver}
					elif [ "$(getconf LONG_BIT)" = "64" ] ; then
						_url=${base_url}/${ghver}/aarch64-linux-ghcup-${ghver}
					else
						die "Unknown long bit size: $(getconf LONG_BIT)"
					fi
					;;
				*) die "Unknown architecture: ${arch}"
					;;
			esac
			;;
        "FreeBSD"|"freebsd")
            if freebsd-version | grep -E '^12.*' ; then
                freebsd_ver=12
            elif freebsd-version | grep -E '^13.*' ; then
                freebsd_ver=13
            else
                die "Unsupported FreeBSD version! Please report a bug at https://gitlab.haskell.org/haskell/ghcup-hs/-/issues"
            fi

			case "${arch}" in
				x86_64|amd64)
					;;
				i*86)
					die "i386 currently not supported!"
					;;
				*) die "Unknown architecture: ${arch}"
					;;
			esac
			_url=${base_url}/${ghver}/x86_64-freebsd${freebsd_ver}-ghcup-${ghver}
            ;;
        "Darwin"|"darwin")
			case "${arch}" in
				x86_64|amd64)
					_url=${base_url}/${ghver}/x86_64-apple-darwin-ghcup-${ghver}
					;;
				aarch64|arm64|armv8l)
					_url=${base_url}/${ghver}/aarch64-apple-darwin-ghcup-${ghver}
					;;
				i*86)
					die "i386 currently not supported!"
					;;
				*) die "Unknown architecture: ${arch}"
					;;
			esac
			;;
        MSYS*|MINGW*)
			case "${arch}" in
				x86_64|amd64)
					_url=${base_url}/${ghver}/x86_64-mingw64-ghcup-${ghver}.exe
					;;
				*) die "Unknown architecture: ${arch}"
					;;
			esac
			;;
        *) die "Unknown platform: ${plat}"
			;;
    esac
    case "${plat}" in
        MSYS*|MINGW*)
			edo curl -Lf "${_url}" > "${GHCUP_BIN}"/ghcup.exe
			edo chmod +x "${GHCUP_BIN}"/ghcup.exe
			;;
		*)
			edo curl -Lf "${_url}" > "${GHCUP_BIN}"/ghcup
			edo chmod +x "${GHCUP_BIN}"/ghcup
			;;
	esac

	edo mkdir -p "${GHCUP_DIR}"

	# we may overwrite this in adjust_bashrc
	cat <<-EOF > "${GHCUP_DIR}"/env || die "Failed to create env file"
		case ":\$PATH:" in
		    *:"${GHCUP_BIN}":*)
		        ;;
		    *)
		        export PATH="${GHCUP_BIN}:\$PATH"
		        ;;
		esac
		case ":\$PATH:" in
		    *:"\$HOME/.cabal/bin":*)
		        ;;
		    *)
		        export PATH="\$HOME/.cabal/bin:\$PATH"
		        ;;
		esac
		EOF

	# shellcheck disable=SC1090
    edo . "${GHCUP_DIR}"/env
    eghcup upgrade
}

# Figures out the users login shell and sets
# GHCUP_PROFILE_FILE and MY_SHELL variables.
find_shell() {
	case $SHELL in
		*/zsh) # login shell is zsh
			GHCUP_PROFILE_FILE="$HOME/.zshrc"
			MY_SHELL="zsh" ;;
		*/bash) # login shell is bash
			GHCUP_PROFILE_FILE="$HOME/.bashrc"
			MY_SHELL="bash" ;;
		*/sh) # login shell is sh, but might be a symlink to bash or zsh
			if [ -n "${BASH}" ] ; then
				GHCUP_PROFILE_FILE="$HOME/.bashrc"
				MY_SHELL="bash"
			elif [ -n "${ZSH_VERSION}" ] ; then
				GHCUP_PROFILE_FILE="$HOME/.zshrc"
				MY_SHELL="zsh"
			else
				return
			fi
			;;
		*/fish) # login shell is fish
			GHCUP_PROFILE_FILE="$HOME/.config/fish/config.fish"
			MY_SHELL="fish" ;;
		*) return ;;
	esac
}

# Ask user if they want to adjust the bashrc.
ask_bashrc() {
	if [ -n "${BOOTSTRAP_HASKELL_ADJUST_BASHRC}" ] ; then
		return 1
	elif [ -z "${MY_SHELL}" ] ; then
		return 0
	fi

	while true; do
		if [ -z "${BOOTSTRAP_HASKELL_NONINTERACTIVE}" ] ; then
			echo "-------------------------------------------------------------------------------"

			warn ""
			warn "Detected ${MY_SHELL} shell on your system..."
			warn "Do you want ghcup to automatically add the required PATH variable to \"${GHCUP_PROFILE_FILE}\"?"
			warn ""
			warn "[P] Yes, prepend  [A] Yes, append  [N] No  [?] Help (default is \"P\")."
			warn ""

			read -r bashrc_answer </dev/tty
		else
			return 0
		fi
		case $bashrc_answer in
			[Pp]* | "")
				return 1
				;;
			[Aa]*)
				return 2
				;;
			[Nn]*)
				return 0;;
			*)
				echo "Possible choices are:"
				echo
				echo "P - Yes, prepend to PATH, taking precedence (default)"
				echo "A - Yes, append to PATH"
				echo "N - No, don't mess with my configuration"
				echo
				echo "Please make your choice and press ENTER."
				;;
		esac
	done

	unset bashrc_answer
}

# Needs 'find_shell' to be called beforehand.
adjust_bashrc() {
	case $1 in
		1)
			cat <<-EOF > "${GHCUP_DIR}"/env || die "Failed to create env file"
				case ":\$PATH:" in
				    *:"${GHCUP_BIN}":*)
				        ;;
				    *)
				        export PATH="${GHCUP_BIN}:\$PATH"
				        ;;
				esac
				case ":\$PATH:" in
				    *:"\$HOME/.cabal/bin":*)
				        ;;
				    *)
				        export PATH="\$HOME/.cabal/bin:\$PATH"
				        ;;
				esac
				EOF
			;;
		2)
			cat <<-EOF > "${GHCUP_DIR}"/env || die "Failed to create env file"
				case ":\$PATH:" in
				    *:"\$HOME/.cabal/bin":*)
				        ;;
				    *)
				        export PATH="\$PATH:\$HOME/.cabal/bin"
				        ;;
				esac
				case ":\$PATH:" in
				    *:"${GHCUP_BIN}":*)
				        ;;
				    *)
				        export PATH="\$PATH:${GHCUP_BIN}"
				        ;;
				esac
				EOF
			;;
		*) ;;
	esac

	case $1 in
		1 | 2)
			case $MY_SHELL in
				"")
					warn_path "Couldn't figure out login shell!"
					return
					;;
				fish)
					mkdir -p "${GHCUP_PROFILE_FILE%/*}"
					sed -i -e '/# ghcup-env$/ s/^#*/#/' "${GHCUP_PROFILE_FILE}"
					case $1 in
						1)
							echo "set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX \$HOME ; set -gx PATH \$HOME/.cabal/bin $GHCUP_BIN \$PATH # ghcup-env" >> "${GHCUP_PROFILE_FILE}"
							;;
						2)
							echo "set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX \$HOME ; set -gx PATH \$HOME/.cabal/bin \$PATH $GHCUP_BIN # ghcup-env" >> "${GHCUP_PROFILE_FILE}"
							;;
					esac
					;;
				bash)
					sed -i -e '/# ghcup-env$/ s/^#*/#/' "${GHCUP_PROFILE_FILE}"
					echo "[ -f \"${GHCUP_DIR}/env\" ] && source \"${GHCUP_DIR}/env\" # ghcup-env" >> "${GHCUP_PROFILE_FILE}"
					case "${plat}" in
						"Darwin"|"darwin")
							if ! grep -q "ghcup-env" "${HOME}/.bash_profile" ; then
								echo "[[ -f ~/.bashrc ]] && source ~/.bashrc # ghcup-env" >> "${HOME}/.bash_profile"
							fi
							;;
						MSYS*|MINGW*)
							if [ ! -e "${HOME}/.bash_profile" ] ; then
								echo '# generated by ghcup' > "${HOME}/.bash_profile"
								echo 'test -f ~/.profile && . ~/.profile' >> "${HOME}/.bash_profile"
								echo 'test -f ~/.bashrc && . ~/.bashrc' >> "${HOME}/.bash_profile"
							fi
							;;
					esac
					;;

				zsh)
					sed -i -e '/# ghcup-env$/ s/^#*/#/' "${GHCUP_PROFILE_FILE}"
					echo "[ -f \"${GHCUP_DIR}/env\" ] && source \"${GHCUP_DIR}/env\" # ghcup-env" >> "${GHCUP_PROFILE_FILE}"
					;;
			esac
			echo
			echo "==============================================================================="
			echo
			warn "OK! ${GHCUP_PROFILE_FILE} has been modified. Restart your terminal for the changes to take effect,"
			warn "or type \"source ${GHCUP_DIR}/env\" to apply them in your current terminal session."
			return
			;;
		*)
			warn_path
			;;
	esac
}

warn_path() {
	echo
	echo "==============================================================================="
	echo
	[ -n "$1" ] && warn "$1"
	yellow "In order to run ghc and cabal, you need to adjust your PATH variable."
	yellow "To do so, you may want to run 'source $GHCUP_DIR/env' in your current terminal"
	yellow "session as well as your shell configuration (e.g. ~/.bashrc)."

}

adjust_cabal_config() {
    if [ -n "${CABAL_DIR}" ] ; then
        cabal_bin="${CABAL_DIR}/bin"
    else
        cabal_bin="$HOME/AppData/Roaming/cabal/bin"
    fi
    edo cabal user-config -a "extra-prog-path: $(cygpath -w "$GHCUP_BIN"), $(cygpath -w "$cabal_bin"), $(cygpath -w "$GHCUP_MSYS2"/usr/bin), $(cygpath -w "$GHCUP_MSYS2"/mingw64/bin)" -a "extra-include-dirs: $(cygpath -w "$GHCUP_MSYS2"/mingw64/include)" -a "extra-lib-dirs: $(cygpath -w "$GHCUP_MSYS2"/mingw64/lib)" -f init
}

ask_cabal_config_init() {
	case "${plat}" in
			MSYS*|MINGW*)
				if [ -n "${BOOTSTRAP_HASKELL_ADJUST_CABAL_CONFIG}" ] ; then
					return 1
				fi

				if [ -z "${BOOTSTRAP_HASKELL_NONINTERACTIVE}" ] ; then
					echo "-------------------------------------------------------------------------------"
					warn "Create an initial cabal.config including relevant msys2 paths (recommended)?"
					warn "[Y] Yes  [N] No  [?] Help (default is \"Y\")."
					echo
					while true; do
						read -r mingw_answer </dev/tty

						case $mingw_answer in
							[Yy]* | "")
								return 1 ;;
							[Nn]*)
								return 0 ;;
							*)
								echo "Possible choices are:"
								echo
								echo "Y - Yes, create a cabal.config with pre-set paths to msys2/mingw64 (default)"
								echo "N - No, leave the current/default cabal config untouched"
								echo
								echo "Please make your choice and press ENTER."
								;;
						esac
					done
				else
					return 1
				fi
				;;
	esac

	unset mingw_answer

    return 0
}

do_cabal_config_init() {
	case "${plat}" in
			MSYS*|MINGW*)
		case $1 in
			1)
				adjust_cabal_config
				;;
			0)
				echo "Make sure that your global cabal.config references the correct mingw64 paths (extra-prog-path, extra-include-dirs and extra-lib-dirs)."
				echo "And set the environment variable GHCUP_MSYS2 to the root path of your msys2 installation."
				sleep 5
				return ;;
			*) ;;
		esac
	esac
}

ask_hls() {
	return 1
}

ask_stack() {
	return 1
}

ask_bashrc
ask_bashrc_answer=$?
ask_cabal_config_init
ask_cabal_config_init_answer=$?
if [ -z "${BOOTSTRAP_HASKELL_MINIMAL}" ] ; then
	ask_hls
	ask_hls_answer=$?
	ask_stack
	ask_stack_answer=$?
fi

edo mkdir -p "${GHCUP_BIN}"

if command -V "ghcup" >/dev/null 2>&1 ; then
    if [ -z "${BOOTSTRAP_HASKELL_NO_UPGRADE}" ] ; then
        _eghcup upgrade || download_ghcup
    fi
else
	download_ghcup
fi

echo
if [ -n "${BOOTSTRAP_HASKELL_YAML}" ] ; then (>&2 ghcup -s "${BOOTSTRAP_HASKELL_YAML}" tool-requirements) ; else (>&2 ghcup tool-requirements) ; fi
echo

if [ -z "${BOOTSTRAP_HASKELL_MINIMAL}" ] ; then
	eghcup --cache install ghc "${BOOTSTRAP_HASKELL_GHC_VERSION}"

	eghcup set ghc "${BOOTSTRAP_HASKELL_GHC_VERSION}"
	eghcup --cache install cabal "${BOOTSTRAP_HASKELL_CABAL_VERSION}"

	do_cabal_config_init $ask_cabal_config_init_answer

	edo cabal new-update --ignore-project
else # don't install ghc and cabal
	case "${plat}" in
			MSYS*|MINGW*)
				# need to bootstrap cabal to initialize config on windows
				# we'll remove it afterwards
				tmp_dir="$(mktemp -d)"
				eghcup --cache install cabal -i "${tmp_dir}" "${BOOTSTRAP_HASKELL_CABAL_VERSION}"
				PATH="${tmp_dir}:$PATH" do_cabal_config_init $ask_cabal_config_init_answer
				rm "${tmp_dir}/cabal"
				unset tmp_dir
				;;
			*)
				;;
	esac
fi

case $ask_hls_answer in
	1)
		_eghcup --cache install hls || warn "HLS installation failed, continuing anyway"
		;;
	*) ;;
esac

case $ask_stack_answer in
	1)
		_eghcup --cache install stack || warn "Stack installation failed, continuing anyway"
		;;
	*) ;;
esac


adjust_bashrc $ask_bashrc_answer


_done

)

# vim: tabstop=4 shiftwidth=4 expandtab
