# GitHub Action: Run shellcheck with reviewdog

[![Docker Image CI](https://github.com/reviewdog/action-shellcheck/workflows/Docker%20Image%20CI/badge.svg)](https://github.com/reviewdog/action-shellcheck/actions)
[![depup](https://github.com/reviewdog/action-shellcheck/workflows/depup/badge.svg)](https://github.com/reviewdog/action-shellcheck/actions?query=workflow%3Adepup)
[![release](https://github.com/reviewdog/action-shellcheck/workflows/release/badge.svg)](https://github.com/reviewdog/action-shellcheck/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/reviewdog/action-shellcheck?logo=github&sort=semver)](https://github.com/reviewdog/action-shellcheck/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

This action runs [shellcheck](https://github.com/koalaman/shellcheck) with
[reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve
code review experience.

[![github-pr-check sample](https://user-images.githubusercontent.com/3797062/65701219-e828b980-e0bb-11e9-9051-2a1f400fe5e5.png)](https://github.com/reviewdog/action-shellcheck/pull/1)
[![github-pr-review sample](https://user-images.githubusercontent.com/3797062/65700741-1c4faa80-e0bb-11e9-8cbd-9a99aeb38594.png)](https://github.com/reviewdog/action-shellcheck/pull/1)

## Inputs

### `github_token`

Optional. `${{ github.token }}` is used by default.

### `level`

Optional. Report level for reviewdog [info,warning,error].
It's same as `-level` flag of reviewdog.

### `reporter`

Reporter of reviewdog command [github-pr-check,github-pr-review,github-check].
Default is github-pr-check.
github-pr-review can use Markdown and add a link to rule page in reviewdog reports.

### `filter_mode`

Optional. Filtering mode for the reviewdog command [added,diff_context,file,nofilter].
Default is `file`.

### `fail_on_error`

Optional.  Exit code for reviewdog when errors are found [true,false]
Default is `false`.

### `reviewdog_flags`

Optional. Additional reviewdog flags

### `path`

Optional. Base directory to run shellcheck. Same as `[path]` of `find` command. Default: `.`

Directories are separated by lines. e.g.:

```yml
path: |
  tools
  src
```

### `pattern`

Optional. File patterns of target files. Same as `-name [pattern]` of `find` command. Default: `*.sh`

Patterns are separated by lines. e.g.:

```yml
pattern: |
  *.bash
  *.sh
```

### `exclude`

Optional. Exclude patterns of target files. Same as `-not -path [exclude]` of `find` command. Default: `*/.git/*`

Patterns are separated by lines. e.g.:

```yml
exclude: |
  */.git/*
  ./.cache/*
```

### `check_all_files_with_shebangs`

Optional. Checks all files with shebangs in the repository even if they do not match `pattern`.
Default is `false`.

### `shellcheck_flags`

Optional. Flags of shellcheck command. Default: `--external-sources`

## Example usage

### [.github/workflows/reviewdog.yml](.github/workflows/reviewdog.yml)

```yml
name: reviewdog
on: [pull_request]
jobs:
  shellcheck:
    name: runner / shellcheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - name: shellcheck
        uses: reviewdog/action-shellcheck@v1
        with:
          github_token: ${{ secrets.github_token }}
          reporter: github-pr-review # Change reporter.
          path: "." # Optional.
          pattern: "*.sh" # Optional.
          exclude: "./.git/*" # Optional.
          check_all_files_with_shebangs: "false" # Optional.
```

## Known issue

> Running `shellcheck.exe` on Windows might fail with the following error:
>
>`SC1017: Literal carriage return. Run script through tr -d '\r'`
> 
> This is due to the presence of a carriage return character (`\r`) in the script.
> 
> To fix this, you can add a `.gitattributes` file to your repository with the following contents:
> ```
> *.sh text eol=lf
> ```
> This will ensure that the scripts are checked out with the correct line endings.
