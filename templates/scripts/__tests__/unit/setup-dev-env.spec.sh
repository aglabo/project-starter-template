#shellcheck shell=sh

Describe 'setup-dev-env.sh'
  Include scripts/setup-dev-env.sh

  setup() { tools_dir=$(mktemp -d); }
  cleanup() { rm -rf "$tools_dir"; }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'is_agla_tool_installed()'
    Context 'when the tool is checked out'
      It 'returns success'
        mkdir -p "$tools_dir/agla-dev-tools/bin"
        When call is_agla_tool_installed "agla-dev-tools" "$tools_dir"
        The status should be success
      End
    End

    Context 'when the tool is not checked out'
      It 'returns failure if bin directory is missing'
        mkdir -p "$tools_dir/agla-dev-tools"
        When call is_agla_tool_installed "agla-dev-tools" "$tools_dir"
        The status should be failure
      End

      It 'returns failure if repository directory is missing'
        When call is_agla_tool_installed "agla-dev-tools" "$tools_dir"
        The status should be failure
      End
    End
  End

  Describe 'setup_agla_tool()'
    Context 'when the tool is not installed'
      It 'clones the repository into the tools directory'
        When call setup_agla_tool "agla-dev-tools" "$tools_dir"
        The output should include "Installing agla-dev-tools"
        The output should include "installed successfully"
        The output should include "Add to PATH:"
        The status should be success
        The path "$tools_dir/agla-dev-tools/bin" should be directory
      End
    End

    Context 'when the tool is already installed'
      It 'skips installation'
        mkdir -p "$tools_dir/agla-doc-tools/bin"
        When call setup_agla_tool "agla-doc-tools" "$tools_dir"
        The output should include "already installed"
        The output should include "agla-doc-tools"
        The status should be success
      End
    End
  End
End
