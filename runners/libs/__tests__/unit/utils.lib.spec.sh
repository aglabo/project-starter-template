#!/usr/bin/env bash
# runners/libs/__tests__/unit/utils.lib.spec.sh
# @(#) : BDD unit tests for utils.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# utils.lib.spec.sh — BDD spec for utils.lib.sh

# cspell:words TMPBASE

# --- テスト基盤 -------------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/__tests__/spec_helper.sh"

# --- テスト対象 -------------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/utils.lib.sh"

# --- 内部ヘルパー -----------------------------------------------------------

# 定数

# 疑似ディレクトリの根。ShellSpec が実行終了時にまとめて消す一時領域に置く
_RC_FIXTURE_ROOT="${SHELLSPEC_TMPBASE:-${TMPDIR:-/tmp}}/utils-resolve-config-fixture"

# 存在する XDG_CONFIG_HOME（T-RUN-RC-01 の入力かつ期待値）
_RC_XDG_DIR="${_RC_FIXTURE_ROOT}/xdg"

# `.config` を持つ HOME（T-RUN-RC-02/03/05 の入力）
_RC_HOME_WITH_CONFIG="${_RC_FIXTURE_ROOT}/home-with-config"

# _RC_HOME_WITH_CONFIG 配下の `.config`（T-RUN-RC-02/03/05 の期待値）
_RC_HOME_CONFIG_DIR="${_RC_HOME_WITH_CONFIG}/.config"

# `.config` を持たない HOME（T-RUN-RC-04 の入力）
_RC_HOME_WITHOUT_CONFIG="${_RC_FIXTURE_ROOT}/home-without-config"

# 存在しない XDG_CONFIG_HOME（T-RUN-RC-03/04 の入力）
_RC_MISSING_DIR="${_RC_FIXTURE_ROOT}/missing"

# 関数

#
# @description resolve_global_configdir() 用の疑似ディレクトリを組み立てる。
#              mkdir -p は冪等なので `--jobs 4` 下で重ねて呼ばれても壊れない
# @arg none
# @return 0 when the fixture directories exist
# @sideeffect Creates _RC_FIXTURE_ROOT and its contents on disk
#
_setup_resolve_global_configdir_fixture() {
  mkdir -p "$_RC_XDG_DIR" "$_RC_HOME_CONFIG_DIR" "$_RC_HOME_WITHOUT_CONFIG"
}

# --- テスト本体 -------------------------------------------------------------

#
# runner スクリプトが共有するユーティリティ lib。
#
Describe 'utils.lib.sh'
  #
  # ユーザー設定ディレクトリの決定。XDG_CONFIG_HOME を優先し、
  # 無ければ ${HOME}/.config、どちらも無ければ空文字を返す
  #
  Describe 'T-RUN-RC: resolve_global_configdir()'
    Before '_setup_resolve_global_configdir_fixture'

    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-RC-01: 存在する XDG_CONFIG_HOME をそのまま返す'
        export XDG_CONFIG_HOME="$_RC_XDG_DIR"
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_XDG_DIR"
        The status should be success
      End

      It 'Then: [Normal] T-RUN-RC-02: XDG_CONFIG_HOME が未設定なら HOME 配下の .config を返す'
        unset XDG_CONFIG_HOME
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End
    End

    Describe 'When: 異常系'
      It 'Then: [Error] T-RUN-RC-03: XDG_CONFIG_HOME が存在しなければ HOME 配下の .config へフォールバックする'
        export XDG_CONFIG_HOME="$_RC_MISSING_DIR"
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End

      It 'Then: [Error] T-RUN-RC-04: どちらのディレクトリも無ければ空文字を返す'
        export XDG_CONFIG_HOME="$_RC_MISSING_DIR"
        export HOME="$_RC_HOME_WITHOUT_CONFIG"
        When call resolve_global_configdir
        The output should equal ""
        The status should be success
      End
    End

    Describe 'When: エッジケース'
      It 'Then: [Edge] T-RUN-RC-05: 空文字の XDG_CONFIG_HOME は未設定として扱う'
        export XDG_CONFIG_HOME=''
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End
    End
  End
End
