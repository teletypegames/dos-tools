# Shared by the dos-* commands: reading metadata.json's "dos" block.
#
#   "dos": {
#     "folder": "DOSINST",                       the folder the program is installed as
#     "files": ["DOSINST.EXE", "DOSINST.CFG", "README.md", "LICENSE"],
#     "settings": ["DOSINST.CFG"],               in the release zip, never in a store update (the shelf's)
#     "store_name": "DOSInst Store",             INFO.INI name= in the FTP store (the WarpEngine writes it)
#     "store_description": "...",                INFO.INI description=
#     "win32_folder": "DOSINSTW",                optional: the Win32 build, the same keys
#     "win32_files": [...], "win32_store_name": "...", "win32_store_description": "..."
#   }

say() { echo "[$DOS_STEP] $*"; }
die() { echo "[$DOS_STEP] error: $*" >&2; exit 1; }

[ -f metadata.json ] || die "no metadata.json in $(pwd)"

dos_key() { jq -r --arg k "$1" '.dos[$k] // empty | if type == "array" then .[] else . end' metadata.json; }

# The folders a release has, as "target folder": dos, and win32 when there is one.
dos_targets() {
  folder="$(dos_key folder)"
  [ -n "$folder" ] || die "metadata.json has no dos.folder"
  echo "dos $folder"
  win32="$(dos_key win32_folder)"
  [ -z "$win32" ] || echo "win32 $win32"
}

# A target's keys: dos.files for dos, dos.win32_files for win32.
dos_target_key() { if [ "$1" = dos ]; then dos_key "$2"; else dos_key "${1}_$2"; fi; }

# The .EXE files a target ships, from its files list.
dos_executables() { dos_target_key "$1" files | grep -i '\.exe$' || true; }
