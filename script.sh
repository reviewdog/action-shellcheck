#!/bin/sh

echo '::group:: Installing shellcheck ... https://github.com/koalaman/shellcheck'
TEMP_PATH="$(mktemp -d)"
cd "${TEMP_PATH}" t ad || exit
wget -qO- "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" | tar -xJf -
mkdir bin
cp "shellcheck-v$SHELLCHECK_VERSION/shellcheck" ./bin
PATH="${TEMP_PATH}/bin:$PATH"
echo '::endgroup::'

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
  # erroformat: https://git.io/JeGMU
  shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} $(find "${INPUT_PATH:-'.'}" -not -path "${INPUT_EXCLUDE}" -type f -name "${INPUT_PATTERN:-'*.sh'}") \
    | jq -r '.[] | "\(.file):\(.line):\(.column):\(.level):\(.message) [SC\(.code)](https://github.com/koalaman/shellcheck/wiki/SC\(.code))"' \
    | reviewdog \
        -efm="%f:%l:%c:%t%*[^:]:%m" \
        -name="shellcheck" \
        -reporter=github-pr-review \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}" \
        ${INPUT_REVIEWDOG_FLAGS}
else
  # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
  shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} $(find "${INPUT_PATH:-'.'}" -not -path "${INPUT_EXCLUDE}" -type f -name "${INPUT_PATTERN:-'*.sh'}") \
    | reviewdog \
        -f="checkstyle" \
        -name="shellcheck" \
        -reporter="${INPUT_REPORTER:-github-pr-check}" \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}" \
        ${INPUT_REVIEWDOG_FLAGS}
fi
