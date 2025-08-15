# any .deb files here are installed using dpkg -i *.deb after
# running ../setup (if it exists) but before extracting ../overlay.tar.xz (if it exists)

## ampi

The following packages are needed early by ampi, to allow for spoken
status during provisioning before the internet is reachable.  Versions
used in the current release are listed.

- **libttspic0**: `libttspico0_1.0+git20130326-13_arm64.deb`
- **libttspico-data**: `libttspico-data_1.0+git20130326-13_all.deb`
- **libttspico-utils**: `libttspico-utils_1.0+git20130326-13_arm64.deb`

These provide the text-to-speech system that lets you listen to
headphones plugged into the Pi's audio jack for provisioning status.
They are provided as `.deb` files in the
`/opt/fleetsie/custom_pre/packages` folder on the SD card image, and
installed from there early during provisioning.
