# .dotfiles

My configuration files.
(Un)installation scripts require `stow`.
Everything is always work in progress here.

## Submodules

When cloning the repository,
make sure to include submodules to get nvim configs:

```shell
# first time
git submodule update --init --recursive

# update later
git submodule update --recursive --remote
```

## Install

```shell
./install

# dry run (see commands)
./install dry
```

## Uninstall

```shell
./uninstall

# dry run (see commands)
./uninstall dry
```


