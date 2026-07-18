Command-line tools
==================

Kconfiglib's installed commands are lightweight front ends over the library.
Their usage and option lists below are generated directly from the same
``argparse`` parsers used by ``--help``. Extended workflows are covered in
:doc:`../guides/workflows`, and the interactive editors have a dedicated
:doc:`../guides/interactive-interfaces` guide.

Configuration generation and maintenance
----------------------------------------

``genconfig``
^^^^^^^^^^^^^

Generate a C configuration header and, optionally, copy the
``kconfig_macros.h`` extra macros or embed them in the configuration header.
Normalized configuration, CMake, dependency, sourced-file, and environment-
variable outputs are also available. Input values come from ``.config`` or the
path selected by ``KCONFIG_CONFIG``.

.. argparse::
   :module: genconfig
   :func: _get_parser
   :prog: genconfig
   :nodescription:
   :nodefault:

``defconfig``
^^^^^^^^^^^^^

Load a specified configuration—usually a minimal configuration—and write the
resolved full configuration to ``.config`` or ``KCONFIG_CONFIG``.

.. argparse::
   :module: defconfig
   :func: _get_parser
   :prog: defconfig
   :nodescription:
   :nodefault:

``oldconfig``
^^^^^^^^^^^^^

Load an existing configuration, prompt for every newly modifiable symbol or
choice, and save the updated configuration. Entering ``?`` at a prompt shows
the item's Kconfig help.

.. argparse::
   :module: oldconfig
   :func: _get_parser
   :prog: oldconfig
   :nodescription:
   :nodefault:

``olddefconfig``
^^^^^^^^^^^^^^^^

Update an existing configuration without prompting, assigning default values
to new symbols. If no configuration exists, create one from defaults.

.. argparse::
   :module: olddefconfig
   :func: _get_parser
   :prog: olddefconfig
   :nodescription:
   :nodefault:

``savedefconfig``
^^^^^^^^^^^^^^^^^

Write a minimal configuration containing only symbol values that differ from
their defaults. Loading the result reconstructs the same resolved
configuration.

.. argparse::
   :module: savedefconfig
   :func: _get_parser
   :prog: savedefconfig
   :nodescription:
   :nodefault:

``listnewconfig``
^^^^^^^^^^^^^^^^^

List user-modifiable symbols that have no value in the current configuration.
Use this to review newly introduced options without changing the file.

.. argparse::
   :module: listnewconfig
   :func: _get_parser
   :prog: listnewconfig
   :nodescription:
   :nodefault:

``setconfig``
^^^^^^^^^^^^^

Assign one or more symbols in an existing configuration. Symbol names omit the
``CONFIG_`` prefix, and the command checks both that symbols exist and that the
requested values take effect unless those checks are disabled.

.. argparse::
   :module: setconfig
   :func: _get_parser
   :prog: setconfig
   :nodescription:
   :nodefault:

Configuration extremes
----------------------

``alldefconfig``
^^^^^^^^^^^^^^^^

Write a configuration in which symbols use their default values, with optional
overrides from ``KCONFIG_ALLCONFIG``.

.. argparse::
   :module: alldefconfig
   :func: _get_parser
   :prog: alldefconfig
   :nodescription:
   :nodefault:

``allnoconfig``
^^^^^^^^^^^^^^^

Set as many symbols as possible to ``n``, while respecting symbols marked with
``option allnoconfig_y`` and optional ``KCONFIG_ALLCONFIG`` overrides.

.. argparse::
   :module: allnoconfig
   :func: _get_parser
   :prog: allnoconfig
   :nodescription:
   :nodefault:

``allmodconfig``
^^^^^^^^^^^^^^^^

Set tristate symbols to ``m`` where possible and Boolean symbols to ``y``,
while respecting dependencies and optional ``KCONFIG_ALLCONFIG`` overrides.

.. argparse::
   :module: allmodconfig
   :func: _get_parser
   :prog: allmodconfig
   :nodescription:
   :nodefault:

``allyesconfig``
^^^^^^^^^^^^^^^^

Set as many symbols as possible to ``y``, while respecting dependencies and
optional ``KCONFIG_ALLCONFIG`` overrides.

.. argparse::
   :module: allyesconfig
   :func: _get_parser
   :prog: allyesconfig
   :nodescription:
   :nodefault:

Interactive interfaces
----------------------

``menuconfig``
^^^^^^^^^^^^^^

Open the curses configuration editor. See
:doc:`../guides/interactive-interfaces` for keyboard controls, display modes,
themes, and platform requirements.

.. argparse::
   :module: menuconfig
   :func: _get_parser
   :prog: menuconfig
   :nodescription:
   :nodefault:

``guiconfig``
^^^^^^^^^^^^^

Open the Tkinter graphical configuration editor. See
:doc:`../guides/interactive-interfaces` for display modes, keyboard shortcuts,
and platform requirements.

.. argparse::
   :module: guiconfig
   :func: _get_parser
   :prog: guiconfig
   :nodescription:
   :nodefault:
