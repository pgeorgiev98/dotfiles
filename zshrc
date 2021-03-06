# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true
setopt COMPLETE_ALIASES

# Prompt
autoload -Uz promptinit
promptinit

# Misc
unsetopt beep			# Beeps are annoying
setopt autocd			# cd without writing 'cd'
bindkey -v				# Vi mode for line editing
ttyctl -f

# History
SAVEHIST=10000
HISTSIZE=10000
HISTFILE=~/.zsh_history
setopt hist_ignore_dups
setopt inc_append_history
setopt share_history
setopt HIST_IGNORE_SPACE

# History
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Keybindings
bindkey '^r' history-incremental-search-backward        # [Ctrl+R] - Incremental backward history search
bindkey '^a' beginning-of-line                          # [Ctrl+A] - Beginning of line
bindkey '^e' end-of-line                                # [Ctrl+E] - End f line

bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey '^k' up-line-or-beginning-search
bindkey '^j' down-line-or-beginning-search

bindkey '^?' backward-delete-char                       # [Backspace] - delete backward
bindkey "${terminfo[kdch1]}" delete-char                # [Delete] - delete forward

# Aliases
alias diff='colordiff'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ls='ls --color=auto'

alias sl='ls' # hehe
alias l='ls -1N'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'

alias c=' tput reset'
alias e=' exit'
alias s='sudo'
alias mk="make -j$(nproc)"

alias reboot='systemctl reboot'
alias poweroff='systemctl poweroff'
alias suspend='systemctl suspend'
alias hibernate='systemctl hibernate'

alias vi='vim'
alias svim='sudo vim'
alias svi='sudo vim'
alias edit='vim'
alias sudoedit='sudo vim'
alias cd..='cd ..'

alias wget='wget -c'
alias bc='bc -q'
alias gdb='gdb -q'
alias ffprobe='ffprobe -hide_banner'
alias ffmpeg='ffmpeg -hide_banner'

alias toclip='xclip -selection clipboard'
alias path='echo -e ${PATH//:/\\n}'
alias vsp='socat -d -d pty,raw,echo=0 pty,raw,echo=0'

# A simple way to repeat a single command
function loop() { while true; do $@; done }

# Some '.' magic
function rationalise-dot() {
	local MATCH
	if [[ $LBUFFER =~ '(^|/| |      |'$'\n''|\||;|&)\.\.$' && ! $LBUFFER = p4* ]]; then
		LBUFFER+=/..
	else
		zle self-insert
	fi
}
zle -N rationalise-dot
bindkey . rationalise-dot
bindkey -M isearch . self-insert

# Double Esc for sudo
sudo-command-line() {
	[[ -z $BUFFER ]] && zle up-history
	if [[ $BUFFER == sudo\ * ]]; then
		LBUFFER="${LBUFFER#sudo }"
	else
		LBUFFER="sudo $LBUFFER"
	fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

# Custom Prompt
setopt promptsubst
function prompt_char {
	if [ $UID -eq 0 ]; then printf '#'; else printf '$'; fi
}
function git_prompt {
	local ref
	ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
		ref=$(command git rev-parse --short HEAD 2> /dev/null)
	local not_in_git_repo=$?
	if [ -n "$(git status --porcelain 2>/dev/null)" ]; then ref="$ref*"; fi
	if [ $not_in_git_repo -eq 0 ]; then printf "(${ref#refs/heads/}) "; fi
}
function get_rprompt {
	local err=$?
	if [ $err -ne 0 ]; then printf '%s' "[%F{red}$err%f] "; fi
	printf '%s' "<%B$(date +%H:%M:%S)%b>"
}

# cd back, forward and cdhist commands
_back_index=1
_back_arr=("$PWD")
function back {
	if [ $_back_index -eq 1 ]; then
		echo "Can't go back"
		return 1
	fi
	new_index=$((_back_index - 1))
	if builtin cd "${_back_arr[new_index]}"; then
		_back_index=$new_index
	fi
}
function fwd {
	if [ $_back_index -eq ${#_back_arr} ]; then
		echo "Can't go forward"
		return 1
	fi
	new_index=$((_back_index + 1))
	if builtin cd "${_back_arr[new_index]}"; then
		_back_index=$new_index
	fi
}
function cd {
	builtin cd $@
	while [ $_back_index -lt "${#_back_arr}" ]; do
		_back_arr[${#_back_arr}]=()
	done
	_back_index=$((_back_index + 1))
	_back_arr[$_back_index]=$PWD
}
function cdhist {
	i=1
	while [ $i -le ${#_back_arr} ]; do
		if [ $i -eq $_back_index ]; then
			echo "${_back_arr[i]} <--"
		else
			echo "${_back_arr[i]}"
		fi
		i=$((i+1))
	done
}

PROMPT='%(!.%B%F{red}.%B%n@)%m%f %b%1~ $(git_prompt)%_%#%f '
RPROMPT='$(get_rprompt)'
