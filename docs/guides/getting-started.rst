Getting started
===============

Kconfig separates *what can be configured* from *the selected configuration*.
``Kconfig`` source files define symbols, their types, defaults, dependencies,
and menu layout. A ``.config`` file records user selections. Kconfiglib reads
both, resolves the dependency rules, and writes output for the build.

Install
-------

Kconfiglib supports Python 3.9 and later and has no runtime dependency beyond
the standard library. Install the library and command-line utilities with:

.. code-block:: console

   $ python3 -m pip install kconfiglib

For a source checkout, run scripts from the repository root or add that
directory to ``PYTHONPATH``. To build this documentation, run:

.. code-block:: console

   $ make -C docs html

The build creates its own virtual environment under ``docs/.venv`` and
installs the documentation requirements into it, so no separate install step
is needed. See :doc:`../contributing` for the other documentation targets.

Your first configuration
------------------------

Create a file named ``Kconfig`` with a small set of options:

.. code-block:: kconfig

   mainmenu "Example configuration"

   config GREETING
       string "Greeting to print"
       default "Hello"

   config LOUD
       bool "Print in uppercase"
       default y

   config RETRIES
       int "Number of retries"
       range 0 10
       default 3

``config`` introduces a symbol. The indented lines are properties of that
symbol. Here the prompts make every option user-configurable, while ``default``
provides a value when the user has not selected one.

Open an interactive interface:

.. code-block:: console

   $ menuconfig Kconfig

Save and exit to create ``.config``. ``menuconfig`` is terminal based; use
``guiconfig Kconfig`` for the Tk interface. On Windows, terminal menuconfig
requires a curses implementation such as ``windows-curses``. See
:doc:`interactive-interfaces` for controls, display modes, and color themes.

You can also make or update a configuration without an interactive UI:

.. code-block:: console

   $ alldefconfig Kconfig       # create .config from defaults
   $ setconfig GREETING=Hi RETRIES=5
   $ olddefconfig Kconfig       # give newly added symbols their defaults

The selected values are written in a Make-compatible format. For example,
``CONFIG_LOUD=y`` enables a Boolean option; a disabled Boolean is represented
as ``# CONFIG_LOUD is not set``.

Use the library
---------------

The same workflow is available from Python. This small script loads an
existing ``.config`` when present, adjusts values, then emits both a normalized
configuration and a C header:

.. code-block:: python

   import kconfiglib

   kconf = kconfiglib.Kconfig("Kconfig")

   # Loads .config, or the file named by $KCONFIG_CONFIG. A missing file is
   # not an error: symbols simply keep their default values. load_config()
   # returns a message describing what it did, which is worth surfacing.
   print(kconf.load_config())

   kconf.syms["GREETING"].set_value("Hi")
   kconf.syms["RETRIES"].set_value("5")

   kconf.write_config(".config")
   kconf.write_autoconf("config.h")

``Symbol.set_value()`` validates the input, but Kconfig rules still determine
the final value. In particular, a symbol without a visible prompt cannot be
set by a user selection, and an unmet dependency can reduce a tristate value.
Check ``sym.str_value``, ``sym.visibility``, and ``sym.assignable`` after
assigning when a script needs to diagnose such cases.

Where to go next
----------------

* Read :doc:`writing-kconfig` before designing a Kconfig tree.
* Use :doc:`workflows` for generated headers, CMake, minimal configurations,
  and configuration maintenance.
* Use :doc:`python-api` to inspect symbols, expressions, and the menu tree.
