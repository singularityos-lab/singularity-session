project('singularity-session', version: '0.1.0', meson_version: '>= 0.59.0')

# The desktop-session launcher needs to know where the polkit agent actually
# landed. get_option('libexecdir') is relative to the prefix by default but
# packagers are free to override it, so resolve it for real instead of having
# the launcher assume "$PREFIX/libexec" at runtime.
libexecdir = get_option('prefix') / get_option('libexecdir')

session_conf = configuration_data()
session_conf.set('LIBEXECDIR', libexecdir)

configure_file(
  input: 'src/singularity-desktop-session.in',
  output: 'singularity-desktop-session',
  configuration: session_conf,
  install: true,
  install_dir: get_option('bindir'),
  install_mode: 'rwxr-xr-x',
)

install_data(
  'src/singularity-labwc-session',
  install_dir: get_option('bindir'),
  install_mode: 'rwxr-xr-x',
)

install_data(
  'config/labwc/rc.xml',
  'config/labwc/themerc',
  install_dir: get_option('datadir') / 'singularity' / 'labwc',
)

install_data(
  'scripts/migrate-labwc-rc.py',
  install_dir: get_option('datadir') / 'singularity' / 'labwc',
  install_mode: 'rwxr-xr-x',
)

session_test_bash = find_program('bash')
test('session-safe-mode', session_test_bash,
  args: files('tests/session_safe_mode_test.sh'),
  # The launcher under test is generated, so point the test at the configured
  # copy in the build dir rather than at a source file that no longer exists.
  env: {
    'SINGULARITY_TEST_DESKTOP_SESSION':
      meson.current_build_dir() / 'singularity-desktop-session',
  })

# BindsTo=graphical-session.target so starting it pulls the target in as a
# side effect -- graphical-session.target itself is systemd-hardened against
# direct manual start (RefuseManualStart), by design: it must be reached via
# a bound unit. singularity-desktop-session starts this unit; that is the
# only thing that makes every WantedBy=graphical-session.target unit (our
# own xdg-desktop-portal-singularity.service among them) launch at all.
install_data(
  'config/systemd-user/singularity-session.target',
  install_dir: get_option('prefix') / 'lib' / 'systemd' / 'user',
)
