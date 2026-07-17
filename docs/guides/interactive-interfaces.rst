Interactive configuration interfaces
====================================

Kconfiglib provides two interactive editors. ``menuconfig`` is a curses-based
terminal interface familiar to users of ``make menuconfig``. ``guiconfig`` is
a Tkinter tree interface similar to ``make xconfig``. Both resolve values with
the same :class:`kconfiglib.Kconfig` model as the command-line tools.

Running an interface
--------------------

Pass the top-level Kconfig file as the optional argument. It defaults to
``Kconfig``:

.. code-block:: console

   $ menuconfig path/to/Kconfig
   $ guiconfig path/to/Kconfig

``KCONFIG_CONFIG`` selects the configuration file to load and save and defaults
to ``.config``. When an existing file is overwritten, its previous contents are
saved beside it as ``<filename>.old``. The ``srctree`` environment variable is
handled by Kconfiglib while loading the Kconfig tree.

The interfaces can also be called with an existing Kconfig instance:

.. code-block:: python

   import kconfiglib
   import menuconfig

   kconf = kconfiglib.Kconfig("Kconfig")
   menuconfig.menuconfig(kconf)

``guiconfig.menuconfig(kconf)`` provides the corresponding graphical entry
point. These functions still load and save the selected configuration file.

Terminal controls
-----------------

Arrow keys and the standard mconf controls work in ``menuconfig``. It also
supports these Vi-inspired bindings:

.. list-table::
   :header-rows: 1
   :widths: 24 76

   * - Keys
     - Action
   * - ``J`` / ``K``
     - Move down or up.
   * - ``L``
     - Enter a menu or toggle an item.
   * - ``H``
     - Leave the current menu.
   * - ``Ctrl-D`` / ``Ctrl-U``
     - Move one page down or up.
   * - ``G`` / ``End``
     - Jump to the end of the list.
   * - ``g`` / ``Home``
     - Jump to the beginning of the list.

``Space`` toggles a value when possible and otherwise enters a menu. ``Enter``
prefers entering a menu and otherwise toggles a value. The jump dialog searches
symbols, choices, menus, and comments throughout the tree, including invisible
symbols. Unlike mconf, typing an entry's first character does not jump within
the current menu; use the jump dialog to search the full tree instead.

Display modes are toggled with single keys:

``F``
   Show or hide the current item's help text at the bottom of the display.

``C``
   Show or hide symbol names before their menu entries.

``A``
   Show or hide invisible items and items without prompts. Invisible items use
   a distinct style.

The information screen improves on mconf by splitting top-level ``&&`` and
``||`` expressions, identifying undefined symbols, showing information for
menus and comments, printing Kconfig definitions, and listing the include path
that led to each definition. The interface also supports Unicode input and
terminal resizing.

Terminal color schemes
----------------------

Set ``MENUCONFIG_STYLE`` to select a built-in style or override individual
display elements. The built-in styles are:

``default``
   The classic Kconfiglib theme with a yellow accent.

``monochrome``
   A colorless theme using bold and standout attributes. It is selected
   automatically when the terminal does not support colors.

``aquatic``
   A blue-tinted style loosely resembling the lxdialog theme, contributed by
   Mitja Horvat (pinkfluid).

For example:

.. code-block:: console

   $ MENUCONFIG_STYLE=aquatic menuconfig Kconfig

The customizable elements are ``path``, ``separator``, ``list``,
``selection``, ``inv-list``, ``inv-selection``, ``help``, ``show-help``,
``frame``, ``body``, ``edit``, ``jump-edit``, and ``text``. Assign an element a
comma-separated style definition containing any of:

``fg:COLOR`` / ``bg:COLOR``
   Set the foreground or background. ``COLOR`` can be one of the basic or
   bright named colors, a terminal color number, or an HTML-style ``#RRGGBB``
   value. ``-1`` selects the terminal default.

``bold``
   Use bold text. Some terminals render bright colors through bold text.

``underline``
   Underline the text.

``standout``
   Use the terminal's standout, usually reverse-video, attribute.

An element can copy another element's definition, and a bare word selects a
built-in style template. For example, this starts with ``aquatic`` and changes
the selection bar:

.. code-block:: console

   $ MENUCONFIG_STYLE="aquatic selection=fg:white,bg:red" menuconfig Kconfig

The ``default`` template is applied first, so these settings are equivalent:

.. code-block:: text

   selection=fg:white,bg:red
   default selection=fg:white,bg:red

Invalid templates, elements, colors, or attributes are ignored with a warning.
If the terminal has no color support, ``monochrome`` is forced and
``MENUCONFIG_STYLE`` is ignored.

Graphical controls
------------------

``guiconfig`` can show the complete tree or one menu at a time. Single-menu
mode distinguishes ``config`` entries from ``menuconfig`` entries. Show-all
mode includes invisible items and draws them in red.

.. list-table::
   :header-rows: 1
   :widths: 24 76

   * - Keys
     - Action
   * - ``Ctrl-S``
     - Save the configuration.
   * - ``Ctrl-O``
     - Open a configuration.
   * - ``Ctrl-A``
     - Toggle show-all mode.
   * - ``Ctrl-N``
     - Toggle symbol-name display.
   * - ``Ctrl-M``
     - Toggle full-tree and single-menu modes.
   * - ``Ctrl-F`` / ``/``
     - Open the jump dialog.
   * - ``Escape``
     - Close the active dialog or interface.

Platform notes
--------------

The terminal interface uses Python's standard-library ``curses`` module. On
Windows, install a compatible implementation before running it:

.. code-block:: console

   > py -m pip install windows-curses

The graphical interface requires Python's Tk libraries. These are commonly
included with CPython but may be packaged separately by an operating system.
