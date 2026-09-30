#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/test-package.sh [--dry-run] PACKAGE

Build PACKAGE with pkgctl. Repository-local dependencies listed in
pkgctl-dependencies.json are reused when available and built when missing.

Options:
  --dry-run  Print the builds without running pkgctl
  -h, --help Show this help
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

valid_package_name() {
  [[ $1 =~ ^[a-zA-Z0-9@._+-]+$ ]]
}

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config=$root/pkgctl-dependencies.json
dry_run=false

while (($#)); do
  case $1 in
  --dry-run)
    dry_run=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  -*)
    die "unknown option: $1"
    ;;
  *)
    break
    ;;
  esac
done

(($# == 1)) || {
  usage >&2
  exit 2
}

target=$1
valid_package_name "$target" || die "PACKAGE must be a top-level package directory name"
[[ -f $root/$target/PKGBUILD ]] || die "package not found: $target"
[[ -f $config ]] || die "dependency configuration not found: $config"

for command in jq makepkg pkgctl realpath; do
  require_command "$command"
done

jq -e '
  type == "object" and
  (to_entries | all(.[];
    (.key | type == "string") and
    (.value | type == "array") and
    (.value | all(.[]; type == "string"))))
' "$config" >/dev/null || die "invalid dependency configuration: $config"

declare -A dependencies_by_package=()
declare -A visit_state=()
declare -A artifact_paths=()
declare -A selected_archives=()
declare -a build_order=()
declare -a install_archives=()

resolve_build_order() {
  local package=$1
  local dependency
  local state=${visit_state[$package]:-0}
  local -a dependencies=()

  case $state in
  1) die "dependency cycle detected at $package" ;;
  2) return ;;
  esac

  visit_state["$package"]=1
  mapfile -t dependencies < <(
    jq -r --arg package "$package" '.[$package] // [] | .[]' "$config"
  )

  for dependency in "${dependencies[@]}"; do
    valid_package_name "$dependency" ||
      die "invalid dependency name for $package: $dependency"
    [[ -f $root/$dependency/PKGBUILD ]] ||
      die "dependency package not found: $dependency"
    resolve_build_order "$dependency"
  done

  dependencies_by_package["$package"]="${dependencies[*]}"
  visit_state["$package"]=2
  build_order+=("$package")
}

expected_archives() {
  local package=$1
  local archive
  local output

  if ! output=$(cd "$root/$package" && makepkg --packagelist); then
    die "failed to determine package archives for $package"
  fi

  while IFS= read -r archive; do
    [[ -n $archive ]] || continue
    if [[ $archive != /* ]]; then
      archive=$root/$package/$archive
    fi
    realpath -m "$archive"
  done <<<"$output"
}

collect_install_archives() {
  local package=$1
  local dependency archive

  for dependency in ${dependencies_by_package[$package]-}; do
    collect_install_archives "$dependency"
    while IFS= read -r archive; do
      [[ -n $archive && -z ${selected_archives[$archive]:-} ]] || continue
      selected_archives["$archive"]=1
      install_archives+=("$archive")
    done <<<"${artifact_paths[$dependency]-}"
  done
}

print_command() {
  local argument

  printf '  '
  printf '%q' "$1"
  shift
  for argument in "$@"; do
    printf ' %q' "$argument"
  done
  printf '\n'
}

resolve_build_order "$target"

printf 'Build order:\n'
printf '  %s\n' "${build_order[@]}"

for package in "${build_order[@]}"; do
  mapfile -t archives < <(expected_archives "$package")
  ((${#archives[@]} > 0)) || die "no package archives found for $package"

  if [[ $package != "$target" ]]; then
    missing=false
    for archive in "${archives[@]}"; do
      if [[ ! -f $archive ]]; then
        missing=true
        break
      fi
    done

    if ! $missing; then
      printf '\nReusing %s:\n' "$package"
      printf '  %s\n' "${archives[@]}"
      artifact_paths["$package"]=$(printf '%s\n' "${archives[@]}")
      continue
    fi
  fi

  install_archives=()
  selected_archives=()
  collect_install_archives "$package"

  build_command=(pkgctl build)
  for archive in "${install_archives[@]}"; do
    build_command+=(-I "$archive")
  done
  build_command+=("$root/$package")

  if $dry_run; then
    printf '\nWould build %s:\n' "$package"
    print_command "${build_command[@]}"
  else
    printf '\nBuilding %s:\n' "$package"
    "${build_command[@]}"
  fi

  if [[ $package != "$target" ]]; then
    if ! $dry_run; then
      for archive in "${archives[@]}"; do
        [[ -f $archive ]] || die "expected package archive does not exist: $archive"
      done
    fi
    artifact_paths["$package"]=$(printf '%s\n' "${archives[@]}")
  fi
done
