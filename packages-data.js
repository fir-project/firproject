// One line per package. The path is repo/section/package-name.
// Folders in the tree are made from the path, so a new folder appears just by using it.
// These are sample entries: replace them with your real packages.
const PACKAGES = [
  { path: "main/base/fir-base",         version: "1.0.0", desc: "Base system files" },
  { path: "main/base/fir-keyring",      version: "1.0.0", desc: "Package signing keys" },
  { path: "main/base/fir-release",      version: "1.0.0", desc: "Release information" },
  { path: "main/desktop/fir-desktop",   version: "0.9.2", desc: "Default desktop environment" },
  { path: "main/desktop/fir-theme",     version: "0.4.1", desc: "Default theme and icons" },
  { path: "main/tools/fir-installer",   version: "0.7.0", desc: "System installer" },
  { path: "main/tools/fir-update",      version: "0.3.5", desc: "Update helper" },
  { path: "extra/dev/fir-devtools",     version: "0.2.0", desc: "Compilers and build tools" },
  { path: "extra/media/fir-codecs",     version: "1.1.0", desc: "Audio and video codecs" },
];
