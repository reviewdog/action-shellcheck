#!/bin/sh

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
  # erroformat: https://git.io/JeGMU
  grep -rIl '^#![[:blank:]]*/bin/\(bash\|sh\|zsh\)' --exclude-dir="${INPUT_EXCLUDE:-.git}" "${INPUT_PATH:-.}" \
    | xargs shellcheck -f json  "${INPUT_SHELLCHECK_FLAGS:---external-sources}" \
    | jq -r '.[] | "\(.file):\(.line):\(.column):\(.level):\(.message) [SC\(.code)](https://github.com/koalaman/shellcheck/wiki/SC\(.code))"' \
    | reviewdog -efm="%f:%l:%c:%t%*[^:]:%m" -name="shellcheck" -reporter=github-pr-review -level="${INPUT_LEVEL}"
else
  # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
  grep -rIl '^#![[:blank:]]*/bin/\(bash\|sh\|zsh\)' --exclude-dir="${INPUT_EXCLUDE:-.git}" "${INPUT_PATH:-.}" \
    | xargs shellcheck -f checkstyle "${INPUT_SHELLCHECK_FLAGS:---external-sources}" \
    | reviewdog -f="checkstyle" -name="shellcheck" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}"
fi
