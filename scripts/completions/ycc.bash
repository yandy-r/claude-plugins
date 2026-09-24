# bash completion for ycc (install.sh) — install: ycc completion --shell bash --install

_ycc() {
    local cur="${COMP_WORDS[COMP_CWORD]}" prev="${COMP_WORDS[COMP_CWORD-1]}"
    local sub="" values=""
    [[ ${COMP_CWORD} -gt 1 ]] && sub="${COMP_WORDS[1]}"

    case "${prev}" in
        --target) values="claude cursor codex opencode all" ;;
        --intent) values="base settings rules mcp hooks plugins" ;;
        --only)   values="base settings rules mcp hooks" ;;
        --mode)   mapfile -t COMPREPLY < <(compgen -W "local repo" -- "${cur}"); return ;;
        --shell)  mapfile -t COMPREPLY < <(compgen -W "bash zsh fish" -- "${cur}"); return ;;
        --dir)    mapfile -t COMPREPLY < <(compgen -d -- "${cur}"); return ;;
    esac

    # Comma lists: complete the item after the last comma, keep the prefix.
    if [[ -n "${values}" ]]; then
        local head="" item="${cur}"
        if [[ "${cur}" == *,* ]]; then
            head="${cur%,*},"
            item="${cur##*,}"
        fi
        mapfile -t COMPREPLY < <(compgen -P "${head}" -W "${values}" -- "${item}")
        compopt -o nospace 2>/dev/null
        return
    fi

    local words
    if [[ ${COMP_CWORD} -eq 1 && "${cur}" != -* ]]; then
        words="sync remove cli completion"
    else
        case "${sub}" in
            cli)        words="--dir --force --help" ;;
            completion) words="--shell --install --force --help" ;;
            *)          words="--target --intent --only --mode --settings --rules --mcp --hooks --project --global --force --help" ;;
        esac
    fi
    mapfile -t COMPREPLY < <(compgen -W "${words}" -- "${cur}")
}

complete -F _ycc ycc
