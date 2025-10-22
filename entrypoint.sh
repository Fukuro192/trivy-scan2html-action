#!/bin/bash
set -euo pipefail

# Read TRIVY_* envs from file, previously they were written to the GITHUB_ENV file but GitHub Actions automatically 
# injects those into subsequent job steps which means inputs from one trivy-action invocation were leaking over to 
# any subsequent invocation which led to unexpected/undesireable behaviour from a user perspective
# See #422 for more context around this
if [ -f ./trivy_envs.txt ]; then
  source ./trivy_envs.txt
fi

# Set artifact reference
scanType="${INPUT_SCAN_TYPE:-image}"
scanRef="${INPUT_SCAN_REF:-.}"
if [ -n "${INPUT_IMAGE_REF:-}" ]; then
  scanRef="${INPUT_IMAGE_REF}" # backwards compatibility
fi

# Handle trivy ignores
if [ -n "${INPUT_TRIVYIGNORES:-}" ]; then
  ignorefile="./trivyignores"

  # Clear the ignore file if it exists, or create a new empty file
  : > "$ignorefile"

  for f in ${INPUT_TRIVYIGNORES//,/ }; do
    if [ -f "$f" ]; then
      echo "Found ignorefile '${f}':"
      cat "${f}"
      cat "${f}" >> "$ignorefile"
    else
      echo "ERROR: cannot find ignorefile '${f}'." >&2
      exit 1
    fi
  done
  export TRIVY_IGNOREFILE="$ignorefile"
fi

# Handle SARIF
if [ "${TRIVY_FORMAT:-}" = "sarif" ]; then
  if [ "${INPUT_LIMIT_SEVERITIES_FOR_SARIF:-false,,}" != "true" ]; then
    echo "Building SARIF report with all severities"
    unset TRIVY_SEVERITY
  else
    echo "Building SARIF report"
  fi
fi

# Run Trivy
if [ "${INPUT_USE_SCAN2HTML:-true}" = "true" ]; then
  # Build command with explicit flags for scan2html (doesn't use env vars)
  cmd=(trivy scan2html "$scanType" "$scanRef")

  # Add flags based on environment variables
  [ -n "${TRIVY_INPUT:-}" ] && cmd+=(--input "$TRIVY_INPUT")
  [ -n "${TRIVY_EXIT_CODE:-}" ] && cmd+=(--exit-code "$TRIVY_EXIT_CODE")
  [ "${TRIVY_IGNORE_UNFIXED:-}" = "true" ] && cmd+=(--ignore-unfixed)
  [ -n "${TRIVY_PKG_TYPES:-}" ] && cmd+=(--pkg-types "$TRIVY_PKG_TYPES")
  [ -n "${TRIVY_SEVERITY:-}" ] && cmd+=(--severity "$TRIVY_SEVERITY")
  [ -n "${TRIVY_FORMAT:-}" ] && cmd+=(--format "$TRIVY_FORMAT")
  [ -n "${TRIVY_TEMPLATE:-}" ] && cmd+=(--template "$TRIVY_TEMPLATE")
  [ -n "${TRIVY_OUTPUT:-}" ] && cmd+=(--output "$TRIVY_OUTPUT")
  [ -n "${TRIVY_SKIP_DIRS:-}" ] && cmd+=(--skip-dirs "$TRIVY_SKIP_DIRS")
  [ -n "${TRIVY_SKIP_FILES:-}" ] && cmd+=(--skip-files "$TRIVY_SKIP_FILES")
  [ -n "${TRIVY_TIMEOUT:-}" ] && cmd+=(--timeout "$TRIVY_TIMEOUT")
  [ -n "${TRIVY_IGNORE_POLICY:-}" ] && cmd+=(--ignore-policy "$TRIVY_IGNORE_POLICY")
  [ "${TRIVY_QUIET:-}" = "true" ] && cmd+=(--quiet)
  [ "${TRIVY_LIST_ALL_PKGS:-}" = "true" ] && cmd+=(--list-all-pkgs)
  [ -n "${TRIVY_SCANNERS:-}" ] && cmd+=(--scanners "$TRIVY_SCANNERS")
  [ -n "${TRIVY_CONFIG:-}" ] && cmd+=(--config "$TRIVY_CONFIG")
  [ -n "${TRIVY_TF_VARS:-}" ] && cmd+=(--tf-vars "$TRIVY_TF_VARS")
  [ -n "${TRIVY_DOCKER_HOST:-}" ] && cmd+=(--docker-host "$TRIVY_DOCKER_HOST")
  [ -n "${TRIVY_CACHE_DIR:-}" ] && cmd+=(--cache-dir "$TRIVY_CACHE_DIR")

  echo "Running Trivy with scan2html plugin: ${cmd[*]}"
else
  cmd=(trivy "$scanType" "$scanRef")
  echo "Running Trivy with options: ${cmd[*]}"
fi
"${cmd[@]}"
returnCode=$?

if [ "${TRIVY_FORMAT:-}" = "github" ]; then
  if [ -n "${INPUT_GITHUB_PAT:-}" ]; then
    printf "\n Uploading GitHub Dependency Snapshot"
    curl -H 'Accept: application/vnd.github+json' -H "Authorization: token ${INPUT_GITHUB_PAT}" \
         "https://api.github.com/repos/$GITHUB_REPOSITORY/dependency-graph/snapshots" -d @"${TRIVY_OUTPUT:-}"
  else
    printf "\n Failing GitHub Dependency Snapshot. Missing github-pat" >&2
  fi
fi

exit $returnCode
