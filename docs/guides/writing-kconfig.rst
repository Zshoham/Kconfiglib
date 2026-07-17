Writing Kconfig files
=====================

This guide is a practical introduction to authoring a Kconfig tree. Kconfiglib
implements the Kconfig language and its preprocessor, and intentionally tracks
the Linux semantics closely. For the complete upstream grammar and detailed
language rules, see the `Linux Kconfig language documentation
<https://www.kernel.org/doc/html/latest/kbuild/kconfig-language.html>`_. The
`Zephyr Kconfig overview
<https://docs.zephyrproject.org/latest/build/kconfig/index.html>`_ is also a
useful explanation of how symbols, menus, and generated build output fit into
a project.

The mental model
----------------

A symbol has a type, zero or more definitions, and a final value calculated
from user input, defaults, dependencies, choices, and reverse dependencies.
Its prompt controls whether a person can select it in a configuration UI.
This distinction is essential:

* A symbol with no prompt is internal. It can receive defaults or be selected,
  but users cannot reliably set it in ``.config``.
* ``depends on`` is a constraint. It limits visibility and the maximum
  selectable Boolean/tristate value.
* ``default`` is used only when the user has no effective selection. The first
  active default wins.
* ``select`` is a forceful, reverse dependency. It establishes a lower value
  for another Boolean/tristate symbol without checking that symbol's direct
  dependencies.

Start with a visible feature and a private capability marker:

.. code-block:: kconfig

   config HAVE_FAST_IO
       bool

   config FAST_IO
       bool "Use fast I/O"
       depends on HAVE_FAST_IO && DMA
       default y if BOARD_DEFAULTS
       help
         Enable the DMA-backed I/O path on supported hardware.

An architecture or board can ``select HAVE_FAST_IO``. Keeping the user-facing
symbol's real requirements in ``depends on`` prevents ``select`` from creating
an invalid configuration by bypassing them.

Types and values
----------------

Kconfig supports ``bool``, ``tristate``, ``string``, ``int``, and ``hex``.
Booleans have ``n`` (disabled) and ``y`` (enabled); tristates add ``m``
(module). Expressions evaluate to ``n``, ``m``, or ``y``. Use ``&&``, ``||``,
``!``, parentheses, and equality or numeric comparisons to write conditions.

Use ``range`` for numeric input and quote string values:

.. code-block:: kconfig

   config LOG_LEVEL
       int "Log verbosity"
       range 0 5
       default 3

   config DEVICE_NAME
       string "Device name"
       default "sensor"

As a conservative default, new user-visible Boolean features normally default
to ``n``. This avoids silently enabling new code in existing configurations.
Choose ``default y`` only when preserving existing behavior or exposing a
gatekeeping option makes that appropriate.

Menus, choices, and composition
--------------------------------

Use blocks to give people a navigable tree and share constraints:

.. code-block:: kconfig

   menu "Networking"
       depends on NET

   menuconfig NET_TLS
       bool "TLS support"

   if NET_TLS
   choice
       prompt "TLS backend"
       default TLS_TINY

   config TLS_TINY
       bool "Tiny TLS"

   config TLS_FULL
       bool "Full TLS"
   endchoice
   endif

   endmenu

``if`` and ``menu ... depends on`` propagate conditions to their contents.
``choice`` permits one of its contained symbols to be selected. A
``menuconfig`` entry is a UI hint: for its children to appear beneath it, make
them depend on that entry (the ``if NET_TLS`` block does this above).

Avoiding common traps
---------------------

Do not use ``select`` as a general substitute for dependencies. It can force a
symbol to ``y`` even where that symbol's direct requirements are unmet. Select
small, hidden capability symbols with no dependencies; use ``depends on`` for
requirements. ``imply`` is a weaker alternative when a feature is desirable
but a user must be allowed to turn it off.

Dependencies can form cycles, especially when mixing ``depends on`` and
``select``. Kconfiglib reports dependency loops with locations. Remove an
unneeded edge or express the relationship consistently, rather than attempting
to make a recursive chain resolve itself.

Help text matters. Place ``help`` after other properties and indent its body
more than the ``help`` line. Explain the effect of enabling an option, its
costs, and when to select it—not just a restatement of its prompt.

Kconfiglib extensions
---------------------

Kconfiglib additionally supports the following extensions documented in its
module docstring and :doc:`../reference/kconfiglib/index`:

* ``rsource`` and ``orsource`` source files relative to the current Kconfig
  file; ``source``/``osource`` and their relative variants accept globbing.
* ``osource`` and ``orsource`` make an unmatched include optional.
* ``def_int``, ``def_hex``, and ``def_string`` combine a type and default,
  complementing the standard ``def_bool`` and ``def_tristate``.
* Python preprocessor functions let a Kconfig expression obtain a string from
  a project-specific Python function.

Prefer standard Kconfig syntax when a tree must be consumed by tools other
than Kconfiglib. Use the extensions deliberately and document that dependency
for your contributors.
