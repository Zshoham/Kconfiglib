#!/usr/bin/env python3

# Copyright (c) 2018-2019, Ulf Magnusson
# SPDX-License-Identifier: ISC

"""
Generates a header file with ``#define`` directives from the configuration,
matching the format of ``include/generated/autoconf.h`` in the Linux kernel.

The companion ``kconfig_macros.h`` header can be copied into the build
directory with ``--kconfig-extra-macros``. This keeps projects from having to
locate Kconfiglib's installed data directory just to use the extra macros. It
can instead be appended to the generated configuration header with
``--embed-kconfig-extra-macros`` for a self-contained header.

Optionally, also writes the configuration output as a ``.config`` file. See
``--config-out``.

The configuration can also be written as a CMake include file. See
``--cmake-out``.

The ``--sync-deps``, ``--file-list``, and ``--env-list`` options generate
information that can be used to avoid needless rebuilds/reconfigurations.

Before writing a header or configuration file, Kconfiglib compares the old
contents of the file against the new contents. If there's no change, the write
is skipped. This avoids updating file metadata like the modification time, and
might save work depending on your build setup.

By default, the configuration is generated from ``.config``. A different
configuration file can be passed in the ``KCONFIG_CONFIG`` environment
variable.

A custom header string can be inserted at the beginning of generated
configuration and header files by setting the ``KCONFIG_CONFIG_HEADER`` and
``KCONFIG_AUTOHEADER_HEADER`` environment variables, respectively (this also
works for other scripts). The string is not automatically made a comment (this
is by design, to allow anything to be added), and no trailing newline is added,
so add ``/* ... */``, ``#``, and newlines as appropriate.

See `Defining Multi-Line Variables
<https://www.gnu.org/software/make/manual/make.html#Multi_002dLine>`_ in the
GNU Make manual for a handy way to define multi-line variables in makefiles
for use with custom headers. Remember to export the variable to the
environment.
"""
import argparse
import os
import sys
import sysconfig

import kconfiglib


DEFAULT_SYNC_DEPS_PATH = "deps/"


def _data_root_for_module_dir(module_dir, data_dir, module_install_dir):
    # Map an installed purelib/platlib directory back to its scheme's data
    # root. This covers pip --prefix installations, where sys.prefix still
    # refers to the Python interpreter rather than to pip's chosen prefix.
    if not data_dir or not module_install_dir:
        return None

    try:
        relative_dir = os.path.relpath(module_install_dir, data_dir)
    except ValueError:
        # The paths can be on different drives on Windows.
        return None

    if relative_dir == os.pardir or \
       relative_dir.startswith(os.pardir + os.sep):
        return None

    root = module_dir
    if relative_dir != os.curdir:
        for _ in relative_dir.split(os.sep):
            root = os.path.dirname(root)

    if os.path.normcase(os.path.abspath(
            os.path.join(root, relative_dir))) != \
       os.path.normcase(os.path.abspath(module_dir)):
        return None

    return root


def _find_kconfig_macros():
    import site

    # setup.py installs kconfig_macros.h below the active installation scheme's
    # data root. Check the source/CMake layout first, then every relevant
    # scheme root. Keep this in sync with setup.py's data_files destination.
    module_dir = os.path.dirname(os.path.abspath(__file__))
    inferred_roots = []
    fallback_roots = (
        sysconfig.get_path("data"),
        sys.prefix,
        sys.exec_prefix,
        getattr(site, "USER_BASE", None),
    )

    # sys.prefix does not change for "pip install --prefix". Infer that data
    # root by matching this module's directory against Python's known
    # purelib/platlib layouts. Try the active scheme first, then distro-added
    # schemes that might describe the module's installation layout.
    scheme_paths = [sysconfig.get_paths()]
    scheme_paths.extend(
        sysconfig.get_paths(scheme=scheme)
        for scheme in sysconfig.get_scheme_names())
    for paths in scheme_paths:
        for install_dir_name in ("purelib", "platlib"):
            root = _data_root_for_module_dir(
                module_dir, paths.get("data"), paths.get(install_dir_name))
            if root and root not in inferred_roots:
                inferred_roots.append(root)

    roots = list(inferred_roots)
    for root in fallback_roots:
        if root and root not in roots:
            roots.append(root)

    directories = [module_dir]
    directories.extend(
        os.path.join(root, "share", "kconfiglib") for root in roots)

    for directory in directories:
        path = os.path.join(directory, "kconfig_macros.h")
        if os.path.isfile(path):
            return path

    sys.exit("error: could not find kconfig_macros.h (looked in {})"
             .format(", ".join(directories)))


def _copy_if_changed(contents, destination):
    # Write the pre-read source bytes and, like Kconfiglib's generated
    # configuration writers, leave an identical destination untouched so its
    # timestamp does not trigger a redundant rebuild.

    try:
        with open(destination, "rb") as f:
            if f.read() == contents:
                return False
    except OSError:
        pass

    with open(destination, "wb") as f:
        f.write(contents)
    return True


def _get_parser():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=__doc__)

    parser.add_argument(
        "--header-path",
        metavar="HEADER_FILE",
        help="""
Path to write the generated header file to. If not specified, the path in the
environment variable KCONFIG_AUTOHEADER is used if it is set, and 'config.h'
otherwise.
""")

    parser.add_argument(
        "--kconfig-extra-macros",
        metavar="MACROS_FILE",
        help="""
Copy the kconfig_macros.h extra macros header to MACROS_FILE. The copy is left
untouched when its contents have not changed. Put it in an include directory
and include it after the generated configuration header.
""")

    parser.add_argument(
        "--embed-kconfig-extra-macros",
        action="store_true",
        help="""
Append the contents of kconfig_macros.h to the generated configuration header,
after the CONFIG_* definitions. This produces a self-contained header that
does not need a separate #include <kconfig_macros.h>.
""")

    parser.add_argument(
        "--config-out",
        metavar="CONFIG_FILE",
        help="""
Write the configuration to CONFIG_FILE. This is useful if you include .config
files in Makefiles, as the generated configuration file will be a full .config
file even if .config is outdated. The generated configuration matches what
olddefconfig would produce. If you use sync-deps, you can include
deps/auto.conf instead. --config-out is meant for cases where incremental build
information isn't needed.
""")

    parser.add_argument(
        "--cmake-out",
        metavar="CMAKE_FILE",
        help="""
Write the configuration as CMake set() commands to CMAKE_FILE. Including this
file from CMake makes Kconfig symbols available as CONFIG_* variables. Boolean
values work directly in if(CONFIG_FOO) expressions.
""")

    parser.add_argument(
        "--sync-deps",
        metavar="OUTPUT_DIR",
        nargs="?",
        const=DEFAULT_SYNC_DEPS_PATH,
        help="""
Enable generation of symbol dependency information for incremental builds,
optionally specifying the output directory (default: {}). See the docstring of
Kconfig.sync_deps() in Kconfiglib for more information.
""".format(DEFAULT_SYNC_DEPS_PATH))

    parser.add_argument(
        "--file-list",
        metavar="OUTPUT_FILE",
        help="""
Write a list of all Kconfig files to OUTPUT_FILE, with one file per line. The
paths are relative to $srctree (or to the current directory if $srctree is
unset). Files appear in the order they're 'source'd.
""")

    parser.add_argument(
        "--env-list",
        metavar="OUTPUT_FILE",
        help="""
Write a list of all environment variables referenced in Kconfig files to
OUTPUT_FILE, with one variable per line. Each line has the format NAME=VALUE.
Only environment variables referenced with the preprocessor $(VAR) syntax are
included, and not variables referenced with the older $VAR syntax (which is
only supported for backwards compatibility).
""")

    parser.add_argument(
        "kconfig",
        metavar="KCONFIG",
        nargs="?",
        default="Kconfig",
        help="Top-level Kconfig file (default: Kconfig)")

    return parser


def main():
    args = _get_parser().parse_args()

    extra_macros_bytes = None
    extra_macros_contents = None
    if args.kconfig_extra_macros is not None or \
       args.embed_kconfig_extra_macros:
        # Resolve this before producing any outputs, so a broken installation
        # cannot leave a newly generated configuration header without its
        # requested extra macros.
        extra_macros_source = _find_kconfig_macros()
        with open(extra_macros_source, "rb") as f:
            extra_macros_bytes = f.read()
        if args.embed_kconfig_extra_macros:
            extra_macros_contents = extra_macros_bytes.decode("utf-8")

    kconf = kconfiglib.Kconfig(args.kconfig, suppress_traceback=True)
    kconf.load_config()

    if args.header_path is None:
        if "KCONFIG_AUTOHEADER" in os.environ:
            kconf.write_autoconf(footer=extra_macros_contents)
        else:
            # Kconfiglib defaults to include/generated/autoconf.h to be
            # compatible with the C tools. 'config.h' is used here instead for
            # backwards compatibility. It's probably a saner default for tools
            # as well.
            kconf.write_autoconf(
                "config.h", footer=extra_macros_contents)
    else:
        kconf.write_autoconf(
            args.header_path, footer=extra_macros_contents)

    if args.kconfig_extra_macros is not None:
        _copy_if_changed(extra_macros_bytes, args.kconfig_extra_macros)

    if args.config_out is not None:
        kconf.write_config(args.config_out, save_old=False)

    if args.cmake_out is not None:
        kconf.write_cmake_config(args.cmake_out)

    if args.sync_deps is not None:
        kconf.sync_deps(args.sync_deps)

    if args.file_list is not None:
        with open(args.file_list, "w", encoding="utf-8") as f:
            for path in kconf.kconfig_filenames:
                f.write(path + "\n")

    if args.env_list is not None:
        with open(args.env_list, "w", encoding="utf-8") as f:
            for env_var in kconf.env_vars:
                f.write("{}={}\n".format(env_var, os.environ[env_var]))


if __name__ == "__main__":
    main()
