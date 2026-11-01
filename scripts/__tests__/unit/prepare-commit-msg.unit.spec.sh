#shellcheck shell=bash

Include "${SHELLSPEC_PROJECT_ROOT}/scripts/__tests__/spec_helper.sh"

Describe 'prepare-commit-msg.sh'
  Include scripts/prepare-commit-msg.sh

  Describe 'T-SCR-GMC: get_model_command()'
    # AI_COMMAND is set as a global array, so expand it to verify
    command_string() {
      get_model_command "$@" || return $?
      printf '%s' "${AI_COMMAND[*]}"
    }

    Describe 'When: Normal cases'
      It '[Normal] T-SCR-GMC-01: dispatches OpenAI gpt-* to codex exec'
        When call command_string "gpt-5"
        The output should eq 'codex exec -s read-only --color never --model gpt-5'
        The status should be success
      End

      It '[Normal] T-SCR-GMC-02: dispatches OpenAI o1-* to codex exec'
        When call command_string "o1-mini"
        The output should eq 'codex exec -s read-only --color never --model o1-mini'
        The status should be success
      End

      # Generating a commit message must not modify the working tree.
      # Also, --color never protects the later marker extraction from ANSI escapes.
      It '[Normal] T-SCR-GMC-03: runs codex with a read-only sandbox and no color'
        When call command_string "gpt-5"
        The output should include '-s read-only'
        The output should include '--color never'
        The status should be success
      End

      It '[Normal] T-SCR-GMC-04: strips the copilot/ prefix from Copilot models'
        When call command_string "copilot/gpt-4o"
        The output should eq 'copilot --model gpt-4o'
        The status should be success
      End

      It '[Normal] T-SCR-GMC-05: dispatches OpenCode provider/model to opencode run'
        When call command_string "anthropic/claude-3-5-sonnet"
        The output should eq 'opencode run --model anthropic/claude-3-5-sonnet'
        The status should be success
      End

      Parameters
        "claude-sonnet-4-5"
        "haiku"
        "sonnet"
        "opus"
      End

      It '[Normal] T-SCR-GMC-06: dispatches Anthropic model "%1" to claude with MCP disabled'
        When call command_string "$1"
        The output should include 'claude -p'
        The output should include '--strict-mcp-config'
        The output should include '{"mcpServers":{}}'
        The output should include "--model $1"
        The status should be success
      End
    End

    Describe 'When: Error cases'
      It '[Error] T-SCR-GMC-07: returns 1 and reports an unsupported model'
        When call get_model_command "totally-unknown"
        The error should include 'Unsupported model: totally-unknown'
        The status should eq 1
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-SCR-GMC-08: falls back to DEFAULT_AI_MODEL (sonnet) with no argument'
        When call command_string
        The output should include "--model ${DEFAULT_AI_MODEL}"
        The status should be success
      End
    End
  End
End
