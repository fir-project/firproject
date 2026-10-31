// One line per package. The path is repo/section/package-name.
// Folders in the tree are made from the path, so a new folder appears just by using it.
// These are placeholders: the real tree starts at fir-base and grows from there.
const PACKAGES = [
  { path: "main/base/fir-base",        version: "—", desc: "Base system: libc, busybox, OpenRC, filesystem layout" },
  { path: "main/base/fir-keyring",     version: "—", desc: "Package signing keys" },
  { path: "main/base/fir-release",     version: "—", desc: "Release information and os-release" },
  { path: "main/base/fir-bootstrap",   version: "—", desc: "Seed used to build the base system from source" },
  { path: "main/desktop/firwm",        version: "—", desc: "The window manager written for Fir" },
  { path: "main/desktop/fir-desktop",  version: "—", desc: "Session, bar and keybindings" },
  { path: "main/desktop/fir-theme",    version: "—", desc: "Default theme, fonts and icons" },
  { path: "main/desktop/fir-rice",     version: "—", desc: "The dotfiles that make up the premade rice" },
  { path: "main/tools/fir-build",      version: "—", desc: "Builds a recipe in a chroot and packages the result" },
  { path: "main/tools/fir-install",    version: "—", desc: "Installs and removes packages using their file manifests" },
  { path: "main/tools/fir-update",     version: "—", desc: "Finds packages that need rebuilding" },
  { path: "extra/dev/fir-devtools",    version: "—", desc: "Compiler, make and the rest of the build toolchain" },
  { path: "extra/media/firefox-bin",   version: "—", desc: "Browser, packaged as a binary because upstream is" },
  { path: "extra/media/fir-codecs",    version: "—", desc: "Audio and video codecs" },
];
