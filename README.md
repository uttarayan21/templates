# Templates

Nix flake templates for a few languages and use cases.

## Usage

### With `om init` (recommended)

[omnix](https://omnix.page) fills in the placeholder names for you, so there is
no search-replacing `hello` after scaffolding:

```sh
om init -o ./myproject github:uttarayan21/templates#rust-cli
```

It prompts for each parameter. Omit the `#rust-cli` to pick from a list:

```sh
om init -o ./myproject github:uttarayan21/templates
```

To script it, pass the values directly:

```sh
om init -o ./myproject github:uttarayan21/templates#rust-cli \
  --params '{"package-name":"myproject","github-ci":true}' \
  --non-interactive
```

### With `nix flake init`

Still supported, but you get the raw template and have to rename `hello`
yourself:

```sh
nix flake init -t github:uttarayan21/templates#rust.cli
```

## Templates

| `om init`      | `nix flake init -t` | Description                                        |
| -------------- | ------------------- | -------------------------------------------------- |
| `rust-cli`     | `rust.cli`          | Rust binary, crane + rust-overlay                   |
| `rust-crates`  | `rust.crates`       | As above, using crates.nix for the registry         |
| `rust-lib`     | `rust.lib`          | Rust library with GitHub Actions CI                 |
| `rust-wasm`    | `rust.wasm`         | Rust wasm                                           |
| `rust-bevy`    | `rust.bevy`         | Bevy                                                |
| `rust-sys`     | `rust.sys`          | `*-sys` crate with bindgen                          |
| `rust-dioxus`  | `rust.dioxus`       | Dioxus                                              |
| `frontend`     | `frontend`          | yarn + nodejs devshell                              |
| `clang`        | `clang`             | clang devshell                                      |
| `shell`        | `shell`             | Plain devshell                                      |
| `python`       | `python`            | Python                                              |
| `atopile`      | `atopile`           | atopile                                             |

## Parameters

The rust templates take:

- `package-name` — replaces `hello` in `Cargo.toml`, `Cargo.lock` and the
  workflow files. The flake reads the name back out of `Cargo.toml`, so this
  also renames every derivation and the built binary.
- `github-ci` — answer `no` to drop `.github/`.

`rust-dioxus` takes `package-name` only (its name is hardcoded in its
`flake.nix` as `darksailor.dev`, and it ships no `.github/`). The non-rust
templates take no parameters.

## Development

The template registry lives in [`flake.nix`](./flake.nix) under `om.templates`.
After changing it, check that scaffolding still works:

```sh
nix eval --json .#om   # registry evaluates
om init --test .       # every template scaffolds and asserts
```
