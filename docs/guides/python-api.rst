Using the Python API
====================

The library is designed for scripts that need the *resolved* Kconfig model,
not just text parsing. Instantiate :class:`kconfiglib.Kconfig`, then traverse
symbols, choices, and menu nodes or write generated outputs.

Inspect a symbol
----------------

.. code-block:: python

   import kconfiglib

   kconf = kconfiglib.Kconfig("Kconfig")
   kconf.load_config(".config")
   sym = kconf.syms["MY_FEATURE"]

   print(sym.str_value)       # resolved value as text
   print(sym.user_value)      # direct user assignment, if any
   print(sym.visibility)      # 0=n, 1=m, 2=y
   print(sym.assignable)      # values the user can currently select
   print(sym.nodes[0].help)   # help at one definition location

``Kconfig.syms`` includes referenced but undefined symbols; an undefined
symbol has no menu nodes. Use ``unique_defined_syms`` when processing each
defined symbol once in Kconfig order.

Evaluate expressions and walk menus
-----------------------------------

Properties such as ``direct_dep`` and ``defaults`` contain parsed expression
tuples. Render them with :func:`kconfiglib.expr_str`, evaluate them with
:func:`kconfiglib.expr_value`, or list referenced items with
:func:`kconfiglib.expr_items`. To parse an expression string in the current
configuration, call :meth:`kconfiglib.Kconfig.eval_string`.

The menu tree starts at ``kconf.top_node``. A node's ``list`` points to its
first child and ``next`` points to its next sibling. ``Kconfig.node_iter()``
performs a depth-first walk and is usually more convenient. Each
:class:`kconfiglib.MenuNode` item is a :class:`kconfiglib.Symbol`, a
:class:`kconfiglib.Choice`, or the ``MENU``/``COMMENT`` sentinel.

Choose the correct output method
--------------------------------

Use :meth:`kconfiglib.Kconfig.write_config` for a full ``.config``,
:meth:`kconfiglib.Kconfig.write_min_config` for a defconfig, and
:meth:`kconfiglib.Kconfig.write_autoconf` or
:meth:`kconfiglib.Kconfig.write_cmake_config` for build-system output.
All output methods avoid rewriting an unchanged file, which helps incremental
builds.

The detailed, code-generated contract for every public class, property, and
function is in :doc:`../reference/kconfiglib/index`.
