Common workflows
================

Kconfiglib ships command-line tools built on the same library API. They use
``Kconfig`` as the default top-level input and ``.config`` as the default
configuration path. Set ``KCONFIG_CONFIG`` to use a different configuration
file; writing a configuration retains the previous file as ``.old``.

Create and maintain configurations
----------------------------------

``alldefconfig`` creates a configuration from defaults. ``olddefconfig``
updates an existing file and silently gives new symbols their defaults.
``oldconfig`` asks for selections for newly modifiable symbols, while
``listnewconfig`` reports them without changing the file.

For a small, reviewable starting point, use ``savedefconfig``. It writes a
minimal configuration containing only values that differ from their defaults.
``defconfig`` performs the reverse workflow: it loads an input configuration,
typically a minimal one, and writes the complete selected configuration.

The configuration extremes are useful for testing: ``allnoconfig`` sets as
many symbols as possible to ``n``; ``allyesconfig`` uses ``y``; and
``allmodconfig`` tries ``m`` where allowed. ``setconfig NAME=value`` changes
selected symbols in an existing file and checks that the selection took effect.

Generate build inputs
---------------------

``genconfig`` converts the resolved configuration into generated output:

.. code-block:: console

   $ genconfig --header-path build/config.h Kconfig
   $ genconfig --config-out build/auto.conf Kconfig
   $ genconfig --cmake-out build/kconfig.cmake Kconfig

The header uses ``CONFIG_*`` macros in the Linux ``autoconf.h`` style.
``--config-out`` is helpful when a Makefile needs a normalized, complete
configuration rather than a possibly outdated source ``.config``. The CMake
file contains ``set()`` commands and can be loaded directly:

.. code-block:: cmake

   include(${CMAKE_BINARY_DIR}/kconfig.cmake)
   if(CONFIG_MY_FEATURE)
     target_sources(my_target PRIVATE feature.c)
   endif()

For incremental builds, ``genconfig --sync-deps build/deps Kconfig`` writes
symbol dependency files and updates them only when values change. The library
method :meth:`kconfiglib.Kconfig.sync_deps` documents the format and integration
approach. ``--file-list`` and ``--env-list`` record sourced Kconfig files and
preprocessor environment values for build-system dependency tracking.

CMake integration
-----------------

The bundled ``cmake/Kconfig.cmake`` provides a higher-level integration. Add
the directory to ``CMAKE_MODULE_PATH``, include ``Kconfig``, then configure:

.. code-block:: cmake

   list(APPEND CMAKE_MODULE_PATH "${KCONFIGLIB_SOURCE_DIR}/cmake")
   include(Kconfig)
   kconfig_configure(
     KCONFIG "${CMAKE_CURRENT_SOURCE_DIR}/Kconfig"
     CONFIG "${CMAKE_BINARY_DIR}/.config")

It produces the header and CMake include file, tracks sourced Kconfig files,
and exposes targets such as ``kconfig_generate``, ``kconfig_menuconfig``, and
``kconfig_olddefconfig``. The library module docstring contains the complete
CMake walkthrough.

Environment and preprocessing
------------------------------

Kconfig source can use the macro preprocessor, including ``$(NAME)``
environment references. Define variables such as ``srctree`` before loading a
tree that expects them; this is particularly important for Linux kernel trees.
Kconfiglib records standard-style environment references in
``Kconfig.env_vars``, and ``genconfig --env-list`` can make them visible to a
build system.

The older ``$NAME`` environment syntax remains supported for compatibility but
is deprecated. See the generated :doc:`../reference/tools` and
:doc:`../reference/kconfiglib/index` pages for the full behavior and options.
