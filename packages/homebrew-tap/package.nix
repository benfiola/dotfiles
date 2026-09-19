{
  runCommand,
  lib,

  casks,
  namespace ? "dotfiles",
  repo ? "casks",
}:

runCommand "homebrew-tap" { } (
  ''
    mkdir -p "$out/Casks"
  ''
  + lib.concatStrings (
    lib.mapAttrsToList (name: path: ''
      cp ${path} "$out/Casks/${name}.rb"
    '') casks
  )
)
// {
  tapName = "${namespace}/homebrew-${repo}";
  tapTrustName = "${namespace}/${repo}";
  caskNames = map (name: "${namespace}/${repo}/${name}") (builtins.attrNames casks);

  meta.description = "Synthesized local Homebrew tap for custom casks";
}
