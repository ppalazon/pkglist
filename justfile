check-versions package="":
    #!/usr/bin/env bash
    set -euo pipefail
    package={{ quote(package) }}

    if [[ -n $package ]]; then
        pkgctl version check "$package"
    else
        shopt -s nullglob
        configs=(*/.nvchecker.toml)
        ((${#configs[@]} > 0)) || {
            printf 'No packages with .nvchecker.toml found.\n' >&2
            exit 1
        }
        pkgctl version check "${configs[@]%/.nvchecker.toml}"
    fi

update-checksums package:
    #!/usr/bin/env bash
    set -euo pipefail
    package={{ quote(package) }}

    [[ $package != */* && $package != . && $package != .. ]] || {
        printf 'Package must be a top-level directory name.\n' >&2
        exit 2
    }
    [[ -f $package/PKGBUILD ]] || {
        printf 'Package not found: %s\n' "$package" >&2
        exit 2
    }

    cd "$package"
    updpkgsums

test-package package:
    ./scripts/test-package.sh {{ quote(package) }}
