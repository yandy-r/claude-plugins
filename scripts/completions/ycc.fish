# fish completion for ycc (install.sh) — install: ycc completion --shell fish --install

function __ycc_csv --argument-names values
    set -l tok (commandline -ct)
    set -l head (string replace -r '[^,]*$' '' -- $tok)
    for v in (string split ' ' -- $values)
        echo $head$v
    end
end

set -l subs sync remove cli completion
set -l sync_cond "not __fish_seen_subcommand_from cli completion"

complete -c ycc -f
complete -c ycc -n "not __fish_seen_subcommand_from $subs" -a sync -d 'Sync intents to targets'
complete -c ycc -n "not __fish_seen_subcommand_from $subs" -a remove -d 'Remove installer-managed config'
complete -c ycc -n "not __fish_seen_subcommand_from $subs" -a cli -d 'Link install.sh onto PATH as ycc'
complete -c ycc -n "not __fish_seen_subcommand_from $subs" -a completion -d 'Print or install shell completion'

complete -c ycc -n $sync_cond -l target -x -a '(__ycc_csv "claude cursor codex opencode all")' -d 'Targets'
complete -c ycc -n $sync_cond -l intent -x -a '(__ycc_csv "base settings rules mcp hooks plugins")' -d 'Intents'
complete -c ycc -n $sync_cond -l only -x -a '(__ycc_csv "base settings rules mcp hooks")' -d 'Steps'
complete -c ycc -n $sync_cond -l mode -x -a 'local repo' -d 'Marketplace source mode'
complete -c ycc -n $sync_cond -l settings -d 'Also merge settings'
complete -c ycc -n $sync_cond -l rules -d 'Also link rules'
complete -c ycc -n $sync_cond -l mcp -d 'Also merge MCP servers'
complete -c ycc -n $sync_cond -l hooks -d 'Also link hooks'
complete -c ycc -n $sync_cond -l project -d 'Write into the current project'
complete -c ycc -n $sync_cond -l global -d 'Write into user-global config'

complete -c ycc -n '__fish_seen_subcommand_from cli' -l dir -x -a '(__fish_complete_directories)' -d 'Install directory'
complete -c ycc -n '__fish_seen_subcommand_from completion' -l shell -x -a 'bash zsh fish' -d 'Shell'
complete -c ycc -n '__fish_seen_subcommand_from completion' -l install -d 'Install for the shell'

complete -c ycc -l force -d 'Replace existing / repo values win'
complete -c ycc -l help -d 'Show help'
