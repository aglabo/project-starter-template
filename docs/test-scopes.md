---
title: テスト ID スコープ宣言
description: テストコードのテスト ID (`T-<scope>-<target>-NN`) が使う scope と target 略語の宣言表
---

## テスト ID スコープ宣言

このリポジトリは Deckrd のモジュール構成を採らないため、テスト ID の `scope` をこの表で宣言する。
テスト ID の書式は `T-<scope>-<target>-<連番>` とし、グループ名が `T-<scope>-<target>` を、ケース名が連番付きの ID を宣言する。

| `test_scope` | 対象                           | `owns`                                                      |
| ------------ | ------------------------------ | ----------------------------------------------------------- |
| `RUN`        | ランナースクリプト             | `runners/*.sh`, `runners/__tests__/**`                      |
| `EXE`        | ShellSpec 実行スクリプト       | `runners/exec/**`                                           |
| `LIB`        | ランナー共有ライブラリ         | `runners/libs/**`                                           |
| `SCR`        | 開発用スクリプト               | `scripts/**`                                                |

## RUN

### テスト対象の略語

| 略語  | 対象                       |
| ----- | -------------------------- |
| `DSP` | `run-shellspec.sh` `dispatch()`       |
| `MAL` | `run-actionlint.sh` `main()`          |
| `MSC` | `run-shellcheck.sh` `main()`          |
| `MSF` | `run-shfmt.sh` `main()`               |
| `MSL` | `run-shellspec.sh` `main()`           |
| `SUW` | `run-shellspec.sh` `should_use_wsl()` |

## EXE

### テスト対象の略語

| 略語  | 対象                   |
| ----- | ---------------------- |
| `ESG` | `expand_spec_glob()`   |
| `GSF` | `get_spec_files()`     |
| `ISF` | `is_spec_file()`       |
| `ISG` | `is_spec_glob()`       |
| `ITT` | `is_test_type()`       |
| `MRS` | `main()`               |
| `PO`  | `parse_options()`      |
| `RSF` | `resolve_spec_files()` |

## LIB

### テスト対象の略語

| 略語   | 対象                                                   |
| ------ | ------------------------------------------------------ |
| `ATF`  | `get-filelist.lib.sh` `args_to_filter()`               |
| `EC`   | `utils.lib.sh` 終了コード定数                          |
| `EIW`  | `wsl.lib.sh` `exec_in_wsl()`                           |
| `FMW`  | `wsl.lib.sh` `find_missing_wsl_commands()`             |
| `GFL`  | `get-filelist.lib.sh` `get_filelist()`                 |
| `IGP`  | `get-filelist.lib.sh` `is_glob_pattern()`              |
| `IVPR` | `init-vars.lib.sh` `PROJECT_ROOT`                      |
| `IVSR` | `init-vars.lib.sh` `SCRIPT_ROOT`                       |
| `IWA`  | `wsl.lib.sh` `is_wsl_available()`                      |
| `IWH`  | `wsl.lib.sh` `is_windows_host()`                       |
| `NP`   | `get-filelist.lib.sh` `normalize_path()`               |
| `RC`   | `utils.lib.sh` `resolve_global_configdir()`            |
| `RCF`  | `utils.lib.sh` `resolve_config_file()`                 |

## SCR

### テスト対象の略語

| 略語   | 対象                                         |
| ------ | -------------------------------------------- |
| `GMC`  | `prepare-commit-msg.sh` `get_model_command()` |
| `GRT`  | `greeting.sh` `greeting()`                    |
| `IATI` | `setup-dev-env.sh` `is_agla_tool_installed()` |
| `SAT`  | `setup-dev-env.sh` `setup_agla_tool()`        |
