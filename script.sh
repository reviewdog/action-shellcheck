#!/bin/sh

echo '::group:: Installing shellcheck ... https://github.com/koalaman/shellcheck'
TEMP_PATH="$(mktemp -d)"
cd "${TEMP_PATH}" || exit
wget -qO- "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" | tar -xJf -
mkdir bin
cp "shellcheck-v$SHELLCHECK_VERSION/shellcheck" ./bin
PATH="${TEMP_PATH}/bin:$PATH"
echo '::endgroup::'

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

FILES=$(find "${INPUT_PATH:-'.'}" -not -path "${INPUT_EXCLUDE}" -type f -name "${INPUT_PATTERN:-'*.sh'}")

# Exit early if no files have been found
if [ -z "${FILES}" ]; then
  echo "No matching files found to check."
  exit 0
fi

echo '::group:: Running shellcheck ...'
if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
  # erroformat: https://git.io/JeGMU
  # shellcheck disable=SC2086
  shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ${FILES} \
    | jq -r '.[] | "\(.file):\(.line):\(.column):\(.level):\(.message) [SC\(.code)](https://github.com/koalaman/shellcheck/wiki/SC\(.code))"' \
    | reviewdog \
        -efm="%f:%l:%c:%t%*[^:]:%m" \
        -name="shellcheck" \
        -reporter=github-pr-review \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}" \
        ${INPUT_REVIEWDOG_FLAGS} || EXIT_CODE=$?
else
  # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
  # shellcheck disable=SC2086
  shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} ${FILES} \
    | reviewdog \
        -f="checkstyle" \
        -name="shellcheck" \
        -reporter="${INPUT_REPORTER:-github-pr-check}" \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}" \
        ${INPUT_REVIEWDOG_FLAGS} || EXIT_CODE=$?
fi
echo '::endgroup::'

echo '::group:: Running shellcheck (suggestion) ...'
# -reporter must be github-pr-review for the suggestion feature.
# shellcheck disable=SC2086
shellcheck -f diff ${FILES} \
  | reviewdog \
      -name="shellcheck (suggestion)" \
      -f=diff \
      -f.diff.strip=1 \
      -reporter="github-pr-review" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      ${INPUT_REVIEWDOG_FLAGS} || EXIT_CODE_SUGGESTION=$?
echo '::endgroup::'

if [ -n "${EXIT_CODE}" ] || [ -n "${EXIT_CODE_SUGGESTION}" ]; then
  exit 1
fi
