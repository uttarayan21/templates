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

- `package-name` — replaces `template-package-name` in `Cargo.toml` and
  `Cargo.lock`. That is the whole substitution: the flake reads the name back
  out of `Cargo.toml`, so it also renames every derivation and the built
  binary, and the workflows resolve it themselves (see below).
- `github-ci` — answer `no` to drop `.github/`.

`rust-dioxus` takes `package-name` only (its name is hardcoded in its
`flake.nix`, and it ships no `.github/`). The non-rust templates take no
parameters.

### How the workflows find the package name

They don't — they never mention it. Each rust flake exposes every check under
two names pointing at the same derivation:

```
checks.x86_64-linux.docs                          # bare
checks.x86_64-linux.<package-name>-docs           # prefixed
```

`nix flake check` and the CI matrix use the prefixed names, so job labels stay
readable. The `codecov` and `docs` jobs, which need one fixed attribute path,
use the bare ones and therefore work under any package name. The GitHub matrix
is filtered to the prefixed set so the aliases don't double every row.

The codecov upload label uses `${{ github.event.repository.name }}` rather than
the crate name, for the same reason.

### Why the placeholder looks like that

`om init` substitutes by plain substring replacement across every file — it has
no AST awareness, and no hook to add any. So the placeholder has to be a string
that cannot show up by accident. The templates used to be named `hello`, which
would have quietly rewritten "hello world" in any prose that ever got added.
`template-package-name` cannot collide, and tells anyone scaffolding by hand
what to replace.

## Development

The template registry lives in [`flake.nix`](./flake.nix) under `om.templates`.
After changing it:

```sh
nix eval --json .#om                    # registry evaluates
om init --test .                        # every template scaffolds
python3 scripts/check_placeholder.py    # substitution is complete
```

The last one scaffolds each template with a sentinel and fails if a
`Cargo.toml` name has drifted away from the declared placeholder — which would
silently produce crates with the wrong name. All three run in CI.
