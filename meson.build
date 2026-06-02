project('singularity-session', version: '0.1.0', meson_version: '>= 0.59.0')

install_data(
  'src/singularity-labwc-session',
  'src/singularity-desktop-session',
  install_dir: get_option('bindir'),
  install_mode: 'rwxr-xr-x',
)

install_data(
  'config/labwc/rc.xml',
  'config/labwc/themerc',
  install_dir: get_option('datadir') / 'singularity' / 'labwc',
)
