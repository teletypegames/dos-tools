# dos-tools

CI tooling for the DOS programs of Teletype Games (Open Watcom + DOSBox), in the
same spirit as [c64-tools](../c64-tools): a program's repo holds a one-line
`platform: dos` marker and a `metadata.json`, and everything the pipeline runs
lives in the builder image.

- `example-woodpecker.yaml` — the marker. The full pipeline (version → test →
  package → upload → publish → release) is served by the update server's
  Woodpecker configuration extension; preview it with
  `curl "https://teletypegames.org/build/config?platform=dos"`.
- `example-metadata.json` — catalog metadata plus the `dos` block that says what
  a release holds (below).
- `hello/` and `warp-template.json` — the Hello World a new project starts from
  (*WarpEngine: New Game* in the toolbox copies `hello/hello.c` and `hello/build.sh` to
  `SOURCE/`); it builds `<FOLDER>.EXE`, which prints `HELLO WORLD`.
- `example-makefile.make`, `example-tasks.json` — the `Makefile` and VS Code
  tasks a new project gets: the pipeline's steps (`build`, `test`) with the
  builder image's commands, and `run (DOSBox)`.
- `builder.Dockerfile` — the builder image,
  `git.teletypegames.org/build/dos-builder`, with the commands in `bin/`.

## Dev container

`warp-template.json` has a `devcontainer` key that the WarpEngine Toolbox reads
(an older toolbox ignores it): a new project gets `.devcontainer/` from
`example-devcontainer.json` and `example-devcontainer.Dockerfile` — the CI
builder image the host names (`{builderImage}`) plus git and a `dev` user —
so a computer with only Docker builds with the same toolchain as the pipeline.
The tasks of `example-devcontainer-tasks.json` are merged into
`.vscode/tasks.json`: `dev image` builds the container image, `play` builds the
game and plays it in the host's web runtime. The dev container adds `make` for the template's `Makefile`, whose targets are the pipeline's steps: `build` (`dos-check`, `dos-build`, then `dos-pack` into `dist/`, the zip `play` runs in EmulatorJS), `test` (`dos-test`) and `run` (a local DOSBox — `run (DOSBox)` builds in the container and runs here).
The container editor gets its extensions from `example-devcontainer.json`: the WarpEngine Toolbox, Makefile Tools (its configure prompts off; the Toolbox tasks build) and the C/C++ extension for the Open Watcom sources.
For an existing game repo, *WarpEngine: Add Dev Container* adds it and merges
the tasks, keeping yours.

## Usage in a program's repo

1. Copy `example-woodpecker.yaml` to `.woodpecker.yaml` (add `name:` when the
   software name differs from the repo name).
2. Copy `example-metadata.json` to `metadata.json` and fill it in.
3. Have `SOURCE/build.sh` build the executables into the repo root with the Open
   Watcom in `$WATCOM`, and put the tests where the commands look for them.
4. In Woodpecker, the global `application_token` and `gitea_token` secrets do the
   catalog upload and the forge release. Nothing else: the FTP store is a WarpEngine
   shelf, which the engine fills from the catalog on every publish.

The version is the tag: `v1.2.3` releases 1.2.3. When `SOURCE/app/version.h` has a
`Version`, it has to match the tag.

## metadata.json: the `dos` block

```json
"dos": {
  "folder": "DOSINST",
  "files": ["DOSINST.EXE", "DOSINST.CFG", "README.md", "LICENSE"],
  "settings": ["DOSINST.CFG"],
  "store_name": "DOSInst Store",
  "store_description": "Installs, updates and removes DOS programs from this store.",
  "win32_folder": "DOSINSTW",
  "win32_files": ["DOSINSTW.EXE", "DOSINST.CFG", "README.md", "LICENSE"],
  "win32_store_name": "DOSInst Store for Windows",
  "win32_store_description": "DOSINST for Windows 95 and later."
}
```

| Key | |
|---|---|
| `folder` | the folder the program is installed as (DOS 8.3, upper case) |
| `files` | what goes into it, from the repo root; files are copied, so `.BAT` and `.CFG` keep their CRLF line ends |
| `settings` | files that are in the release zip but never in a store update, so an update keeps an installed program's configuration |
| `store_name`, `store_description` | the `INFO.INI` the DOSINST list shows |
| `win32_*` | the same for a Win32 build (optional) |

Without a `dos` block (a new project, whose `metadata.json` the toolbox writes) the
commands fill one in from the name: `hello-world` becomes the folder `HELLOWOR` with
`HELLOWOR.EXE` and `README.md`. Edit it in `metadata.json` once the program needs more.

## The commands

| Command | Step | What it does |
|---|---|---|
| `dos-check` | test | the code style (`SOURCE/lib/tools/format.sh --check SOURCE`, DOSLIB's clang-format wrapper), the unit tests (`SOURCE/test/unit/run.sh`), the Python tests of a server side (`server/test`), each where the repo has it |
| `dos-build` | test | `SOURCE/build.sh`, then every `.EXE` of the file lists must be there |
| `dos-test` | test | `SOURCE/test/run.sh` (DOS, headless DOSBox Staging), `SOURCE/test/runw32.sh` (Win32 under Wine), `SOURCE/test/run.py` (DOSBox screen tests), each where the repo has it |
| `dos-pack` | package (tag) | `dist/<FOLDER>-<tag>.zip` and each `.EXE` alone in `dist/`, listed in `.release-assets` for the pipeline's release step |

The pipeline turns `dist/<FOLDER>-<tag>.zip` into the catalog's `cartridge` asset and
the Win32 zip into `win_x86`, keeping the `dos` block in the uploaded metadata. The
engine's shared release step attaches the files of `.release-assets` to the forge
release, with `RELEASE_NOTES.md` as its text. The FTP store
(`ftp://ftp.teletypegames.org/APPS`), where DOSINST installs and updates from, is the
engine's `folders` shelf: from the zip and the `dos` block it writes each folder
without the settings, with an `INFO.INI` (name, description, version, platform `DOS` or
`WIN32`) and a `FILES.LST` (`crc32 size path`) that DOSINST checks downloads against.

Try it on a program locally:

```sh
docker run --rm -v "$PWD:/workspace" git.teletypegames.org/build/dos-builder:latest \
  sh -c 'dos-check && dos-build && dos-test && TAG=v1.2.3 dos-pack'
```

## Builder image

Open Watcom v2, DOSBox Staging (in `/opt/dosbox-staging`, not on the `PATH`) and
Debian's DOSBox (on the `PATH`, for the screen tests), Wine 32-bit, g++, Python with
pyftpdlib, clang-format, zip, jq and curl, at the versions in `/opt/dos-ci/versions`:

```sh
docker build --platform linux/amd64 -f builder.Dockerfile \
  -t git.teletypegames.org/build/dos-builder:latest .
docker push git.teletypegames.org/build/dos-builder:latest
```
