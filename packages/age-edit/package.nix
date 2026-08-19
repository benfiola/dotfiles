{
  writeShellApplication,
  age,
  vim,

  identityPath,
  recipient,
}:

writeShellApplication {
  name = "age-edit";

  runtimeInputs = [
    age
    vim
  ];

  text = ''
    if [ "$#" -ne 1 ]; then
      echo "usage: age-edit <file>" >&2
      exit 1
    fi
    file="$1"

    tmp=$(mktemp)
    trap 'shred -u "$tmp" 2>/dev/null || rm -f "$tmp"' EXIT
    chmod 600 "$tmp"

    if [ -f "$file" ]; then
      age -d -i "${identityPath}" -o "$tmp" "$file"
    fi

    vim "$tmp"

    age -e -r "${recipient}" -o "$file.new" "$tmp"
    mv "$file.new" "$file"
  '';
}
