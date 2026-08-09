#shellcheck shell=sh

Describe 'run-shellspec.sh'
  Include runners/run-shellspec.sh

  # Fixture tree is generated at runtime outside the project tree so that
  # the real repository layout never affects these expectations and the
  # fixture specs are never collected by the production suite.
  setup_fixture() {
    FIXTURE_ROOT=$(mktemp -d)
    mkdir -p "${FIXTURE_ROOT}/scripts/__tests__/unit"
    mkdir -p "${FIXTURE_ROOT}/scripts/__tests__/functional"
    printf '%s\n' '--shell bash' '--pattern "*.spec.sh"' '--default-path "."' \
      >"${FIXTURE_ROOT}/.shellspec"
    # Holds a real example so that running the fixture root actually
    # executes it (never reports "0 examples").
    printf '%s\n' '#shellcheck shell=sh' \
      'Describe "sample"' \
      '  It "runs"' \
      '    When call true' \
      '    The status should be success' \
      '  End' \
      'End' \
      >"${FIXTURE_ROOT}/scripts/__tests__/unit/sample.spec.sh"
    # Decoy: matches the spec pattern but lives outside any __tests__
    # directory, so no test type may ever collect it.
    mkdir -p "${FIXTURE_ROOT}/scripts/vendor-tests"
    printf '%s\n' '#shellcheck shell=sh' \
      >"${FIXTURE_ROOT}/scripts/vendor-tests/decoy.spec.sh"
    # Redirect the runner at the fixture tree. SHELLSPEC was already resolved
    # against the real PROJECT_ROOT when the runner was included, so exporting
    # it as-is keeps the nested run pointed at the real shellspec binary.
    export SHELLSPEC
    export PROJECT_ROOT="${FIXTURE_ROOT}"
    export SPEC_SEARCH_ROOT="${FIXTURE_ROOT}"
  }

  cleanup_fixture() {
    [ -n "${FIXTURE_ROOT}" ] && rm -rf "${FIXTURE_ROOT}"
  }

  BeforeAll 'setup_fixture'
  AfterAll 'cleanup_fixture'

  Describe 'get_spec_files()'
    Context 'when a test type has spec files'
      Parameters
        unit
        all
      End

      It "returns the unit spec for the '$1' test type"
        When call get_spec_files "$1"
        The output should include "scripts/__tests__/unit/sample.spec.sh"
        The status should be success
      End

      It "excludes specs outside __tests__ for the '$1' test type"
        When call get_spec_files "$1"
        The output should not include "decoy.spec.sh"
        The status should be success
      End
    End

    Context 'when a test type has no spec files'
      It 'outputs nothing and still succeeds'
        When call get_spec_files functional
        The output should eq ""
        The stderr should eq ""
        The status should be success
      End
    End
  End

  Describe 'expand_spec_glob()'
    Context 'when the glob matches spec files'
      Parameters
        'scripts/__tests__/unit/*.spec.sh'
        'scripts\__tests__\unit\*.spec.sh'
      End

      It "expands '$1' to the matching spec"
        When call expand_spec_glob "$1"
        The output should include "scripts/__tests__/unit/sample.spec.sh"
        The status should be success
      End
    End

    Context 'when the glob matches nothing'
      It 'fails and names the unmatched pattern'
        When call expand_spec_glob "scripts/__tests__/nowhere/*.spec.sh"
        The status should equal 1
        The stderr should include "scripts/__tests__/nowhere/*.spec.sh"
      End
    End
  End

  Describe 'resolve_spec_files()'
    Context 'when the test type has no spec files'
      It 'fails and names the empty test type'
        When call resolve_spec_files functional
        The status should equal 1
        The stderr should include "functional"
      End
    End
  End

  Describe 'run-shellspec.sh (script)'
    Context 'when the requested specs resolve to nothing'
      It 'exits 1 for a test type with no specs'
        When run script runners/run-shellspec.sh functional
        The status should equal 1
        The stderr should include "functional"
      End

      It 'exits 1 for a glob matching no specs'
        When run script runners/run-shellspec.sh "scripts/__tests__/nowhere/*.spec.sh"
        The status should equal 1
        The stderr should include "scripts/__tests__/nowhere/*.spec.sh"
      End
    End

    Context 'when the argument is invalid or missing on disk'
      It 'exits 1 for an unknown test type'
        When run script runners/run-shellspec.sh unti
        The status should equal 1
        The stderr should include "unti"
      End

      It 'fails for a spec file that does not exist'
        When run script runners/run-shellspec.sh scripts/__tests__/unit/missing.spec.sh
        The status should not equal 0
        The stderr should be present
      End
    End

    Context 'when specs are found'
      # Guards the per-type filter: "all" and an explicit type take different
      # branches in get_spec_files, so "all" passing does not imply this does.
      It 'runs the unit specs found under __tests__/unit'
        When run script runners/run-shellspec.sh unit
        The status should be success
        The output should not include "0 examples"
        The output should include "1 example"
      End

      It 'succeeds for "all" even though one test type is empty'
        When run script runners/run-shellspec.sh all
        The status should be success
        The output should include "1 example"
      End

      It 'runs the default path without arguments'
        When run script runners/run-shellspec.sh
        The status should be success
        The output should not include "Not found a path: spec."
        The output should include "1 example"
      End

      # An options-only invocation selects no spec, so it must fall back to the
      # default path rather than silently succeeding without running anything.
      It 'runs the default path when only options are given'
        When run script runners/run-shellspec.sh --integration
        The status should be success
        The output should not include "Not found a path: spec."
        The output should include "1 example"
      End
    End
  End
End
