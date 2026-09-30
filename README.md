# ppalazon's AUR packages

This repository contains those packages that I maintain in the AUR (ArchLinux
User Repository). I am only responsible to keep the package usable and
installable in an ArchLinux workstation, but I'm not the owner of these packages.

## Packages

I keep this Github repository with all these packages to have a centralized way
to modify them, upgrade, and fix. But, to use this package you must use the
correspond package repo in the AUR.

| Package              | AUR page                                                                                               |
| -------------------- | ------------------------------------------------------------------------------------------------------ |
| `ecs-tasks-ops`      | [aur.archlinux.org/packages/ecs-tasks-ops](https://aur.archlinux.org/packages/ecs-tasks-ops)           |
| `fusesoc`            | [aur.archlinux.org/packages/fusesoc](https://aur.archlinux.org/packages/fusesoc)                       |
| `python-edalize`     | [aur.archlinux.org/packages/python-edalize](https://aur.archlinux.org/packages/python-edalize)         |
| `python-okonomiyaki` | [aur.archlinux.org/packages/python-okonomiyaki](https://aur.archlinux.org/packages/python-okonomiyaki) |
| `python-simplesat`   | [aur.archlinux.org/packages/python-simplesat](https://aur.archlinux.org/packages/python-simplesat)     |
| `python-sshpubkeys`  | [aur.archlinux.org/packages/python-sshpubkeys](https://aur.archlinux.org/packages/python-sshpubkeys)   |
| `slang-verilog`      | [aur.archlinux.org/packages/slang-verilog](https://aur.archlinux.org/packages/slang-verilog)           |
| `ttf-science-gothic` | [aur.archlinux.org/packages/ttf-science-gothic](https://aur.archlinux.org/packages/ttf-science-gothic) |

## Workflow

Just as reminder, I write down the steps that I follow to maintain this package.

1. Check new upstream version: `just check-versions [package_name]`.
2. Modify `PKGBUILD` with the new version and reset `pkgver` to `1`.
3. Update the package checksum to avoid impersonation: `just update-checksums package_name`
4. Test the package build process: `just test-package package_name`
5. Review everything works correctly, and it's correctly build.
6. Commit the changes on this repository
7. Publish the package: `aurpublish package_name`

## LICENSE

Unlicense - [LICENSE](LICENSE)
