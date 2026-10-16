#shellcheck shell=sh

Include "${SHELLSPEC_PROJECT_ROOT}/scripts/__tests__/spec_helper.sh"

Describe 'setup-dev-env.sh'
  Include scripts/setup-dev-env.sh

  setup() { tools_dir=$(mktemp -d); }
  cleanup() { rm -rf "$tools_dir"; }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  # Stub git: simulate a clone by creating bin/ in the destination (last argument)
  _stub_git_clone_success() {
    # shellcheck disable=SC2329 # called indirectly from setup_agla_tool()
    git() {
      for _dest in "$@"; do :; done
      mkdir -p "$_dest/bin"
    }
  }
  _stub_git_clone_failure() {
    # shellcheck disable=SC2329 # called indirectly from setup_agla_tool()
    git() { return 1; }
  }

  # Stub pnpm: simulate install by creating node_modules/.bin under --dir
  _stub_pnpm_install_success() {
    # shellcheck disable=SC2329 # called indirectly from setup_agla_tool()
    pnpm() {
      mkdir -p "$2/node_modules/.bin"
    }
  }
  _stub_pnpm_install_failure() {
    # shellcheck disable=SC2329 # called indirectly from setup_agla_tool()
    pnpm() { return 1; }
  }

  Describe 'is_agla_tool_installed()'
    Context 'when the tool is checked out and dependencies are installed'
      It 'returns success'
        mkdir -p "$tools_dir/agla-dev-tools/bin" "$tools_dir/agla-dev-tools/node_modules/.bin"
        When call is_agla_tool_installed "agla-dev-tools" "$tools_dir"
        The status should be success
      End
    End

    Context 'when the tool is not fully installed'
      It 'returns failure if node_modules/.bin is missing'
        mkdir -p "$tools_dir/agla-dev-tools/bin"
        When call is_agla_tool_installed "agla-dev-tools" "$tools_dir"
        The status should be failure
      End

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
      It 'clones the repository and installs dependencies'
        _stub_git_clone_success
        _stub_pnpm_install_success
        When call setup_agla_tool "agla-dev-tools" "$tools_dir"
        The output should include "Installing agla-dev-tools"
        The output should include "installed successfully"
        The output should include "Add to PATH:"
        The status should be success
        The path "$tools_dir/agla-dev-tools/bin" should be directory
        The path "$tools_dir/agla-dev-tools/node_modules/.bin" should be directory
      End
    End

    Context 'when the tool is checked out but dependencies are missing'
      It 'skips the clone and installs dependencies'
        mkdir -p "$tools_dir/agla-dev-tools/bin"
        _stub_git_clone_failure
        _stub_pnpm_install_success
        When call setup_agla_tool "agla-dev-tools" "$tools_dir"
        The output should include "installed successfully"
        The status should be success
        The path "$tools_dir/agla-dev-tools/node_modules/.bin" should be directory
      End
    End

    Context 'when the tool is already installed'
      It 'skips installation'
        mkdir -p "$tools_dir/agla-doc-tools/bin" "$tools_dir/agla-doc-tools/node_modules/.bin"
        _stub_git_clone_failure
        _stub_pnpm_install_failure
        When call setup_agla_tool "agla-doc-tools" "$tools_dir"
        The output should include "already installed"
        The output should include "agla-doc-tools"
        The status should be success
      End
    End

    Context 'when the clone fails'
      It 'returns failure'
        _stub_git_clone_failure
        _stub_pnpm_install_success
        When call setup_agla_tool "agla-dev-tools" "$tools_dir"
        The output should include "Installing agla-dev-tools"
        The stderr should include "agla-dev-tools installation failed"
        The status should be failure
      End
    End

    Context 'when pnpm install fails'
      It 'returns failure'
        _stub_git_clone_success
        _stub_pnpm_install_failure
        When call setup_agla_tool "agla-dev-tools" "$tools_dir"
        The output should include "Installing agla-dev-tools"
        The stderr should include "agla-dev-tools pnpm install failed"
        The status should be failure
      End
    End
  End
End
