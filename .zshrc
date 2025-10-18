# 0. 性能
skip_global_compinit=1
DISABLE_MAGIC_FUNCTIONS=true
ZSH_DISABLE_COMPFIX=true

# 1. p10k 瞬时提示
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 2. zinit
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit && (( ${+_comps} )) && _comps[zinit]=_zinit

# 3. 主题
zinit ice depth=1
zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 4. 插件（Turbo）
zinit ice wait='0a' lucid blockf atload'zicompinit; zicdreplay'
zinit light zsh-users/zsh-completions

zinit ice wait='0b' lucid atinit'zpcompinit'
zinit light zdharma-continuum/fast-syntax-highlighting

zinit ice wait='0c' lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

zinit ice wait='0d' lucid
zinit light zsh-users/zsh-history-substring-search

zinit ice from'gh-r' as'command' pick'bin/fzf'
zinit light junegunn/fzf
zinit ice wait='0e' lucid
zinit light Aloxaf/fzf-tab

# 5. 其它好用
zinit ice wait='1' lucid
zinit light agkozak/zsh-z

zinit ice from'gh-r' as'command' pick'zoxide' \
      atload'eval "$(zoxide init zsh)"'
zinit light ajeetdsouza/zoxide

zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
zinit snippet OMZ::plugins/git/git.plugin.zsh

plugins=(git sudo)

# 6. keybind
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
source <(fzf --zsh)

# 7. 历史
HISTSIZE=100000 SAVEHIST=100000 HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# 8. 补全样式
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always -1 $realpath'

# 仅 kitty 生效的图标+图片预览
if [[ $TERM == "xterm-kitty" ]]; then
  # 通用预览函数：图片→icat，其他→bat
  _fzf_preview() {
    local file=$(printf '%s' "$1" | sed 's/^📄 //;s/^📁 //')   # 去掉图标前缀
    case "$(file --brief --mime-type "$file")" in
      image/*) kitten icat --clear --transfer-mode=stream --place=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0 "$file" ;;
      *)       bat --color=always --style=header,grid --line-range=:300 "$file" 2>/dev/null ;;
    esac
  }

  # Ctrl-T 多选
  export FZF_CTRL_T_COMMAND="fd --type f --type d . --color=always | sed 's/^/📄 /;s/^📁 /📁 /'"
  export FZF_CTRL_T_OPTS="
    --multi --preview '_fzf_preview {}'
    --preview-window right:50%:border-left:hidden
    --bind 'ctrl-/:toggle-preview'
  "

  # fzf-tab 补全
  zstyle ':fzf-tab:complete:*' fzf-preview '_fzf_preview $realpath'
  zstyle ':fzf-tab:*' fzf-flags $FZF_DEFAULT_OPTS
fi

# === Ctrl-T 文件多选 ==================================================
export FZF_CTRL_T_COMMAND="
  fd --type f --hidden --follow --exclude .git --exclude node_modules
"
export FZF_CTRL_T_OPTS="
  --multi
  --preview 'bat --color=always --style=header,grid --line-range=:300 {}'
"

# === Ctrl-R 历史 ======================================================
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window='down:3:wrap'
  --header='C-a 全选 | C-x 清空 | C-y 复制命令'
"

# === Alt-C 目录跳转 ===================================================
export FZF_ALT_C_COMMAND="
  fd --type d --hidden --follow --exclude .git --exclude node_modules
"
export FZF_ALT_C_OPTS="
  --preview 'eza --color=always --group-directories-first --icons=always {}'
"

# === fzf-tab （zsh 补全）===============================================
zstyle ':fzf-tab:*' fzf-pad 1
zstyle ':fzf-tab:*' fzf-flags $FZF_DEFAULT_OPTS
# 默认预览
zstyle ':fzf-tab:complete:*' fzf-preview '
  if [[ -f $realpath ]]; then
    bat --color=always --style=header,grid --line-range=:300 $realpath
  elif [[ -d $realpath ]]; then
    eza --color=always --group-directories-first --icons=always $realpath
  else
    echo ""
  fi'
# cd 补全单独加图标列表
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons --color=always $realpath'
# kill 进程预览
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -all --pid=$word -o pid,ppid,user,cmd'

export ANDROID_SDK_ROOT=~/android-sdk
export ANDROID_SDK_HOME=~/qemu/AVD
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator
export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH

export PATH=/opt/baidunetdisk:$PATH

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
