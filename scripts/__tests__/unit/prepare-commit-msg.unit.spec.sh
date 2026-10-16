#shellcheck shell=bash

Describe 'prepare-commit-msg.sh'
  Include scripts/prepare-commit-msg.sh

  Describe 'get_model_command()'
    # AI_COMMAND はグローバル配列として設定されるため、展開して検証する
    command_string() {
      get_model_command "$@" || return $?
      printf '%s' "${AI_COMMAND[*]}"
    }

    Context 'with OpenAI models'
      It 'dispatches gpt-* to codex exec'
        When call command_string "gpt-5"
        The output should eq 'codex exec -s read-only --color never --model gpt-5'
        The status should be success
      End

      It 'dispatches o1-* to codex exec'
        When call command_string "o1-mini"
        The output should eq 'codex exec -s read-only --color never --model o1-mini'
        The status should be success
      End

      # コミットメッセージ生成は作業ツリーを書き換えてはならない。
      # また --color never はこの後のマーカー抽出を ANSI エスケープから守る。
      It 'runs codex with a read-only sandbox and no color'
        When call command_string "gpt-5"
        The output should include '-s read-only'
        The output should include '--color never'
        The status should be success
      End
    End

    Context 'with Anthropic models'
      Parameters
        "claude-sonnet-4-5"
        "haiku"
        "sonnet"
        "opus"
      End

      It 'dispatches "%1" to claude with MCP disabled'
        When call command_string "$1"
        The output should include 'claude -p'
        The output should include '--strict-mcp-config'
        The output should include '{"mcpServers":{}}'
        The output should include "--model $1"
        The status should be success
      End
    End

    Context 'with Copilot models'
      It 'strips the copilot/ prefix'
        When call command_string "copilot/gpt-4o"
        The output should eq 'copilot --model gpt-4o'
        The status should be success
      End
    End

    Context 'with OpenCode models'
      It 'dispatches provider/model to opencode run'
        When call command_string "anthropic/claude-3-5-sonnet"
        The output should eq 'opencode run --model anthropic/claude-3-5-sonnet'
        The status should be success
      End
    End

    Context 'with no argument'
      It 'falls back to DEFAULT_AI_MODEL (sonnet)'
        When call command_string
        The output should include "--model ${DEFAULT_AI_MODEL}"
        The status should be success
      End
    End

    Context 'with an unsupported model'
      It 'returns 1 and reports the model'
        When call get_model_command "totally-unknown"
        The error should include 'Unsupported model: totally-unknown'
        The status should eq 1
      End
    End
  End
End
