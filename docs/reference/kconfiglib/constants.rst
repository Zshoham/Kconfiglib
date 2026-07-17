Version and constants
=====================

.. autodata:: kconfiglib.VERSION

The module also exposes symbolic constants for types (``BOOL``, ``TRISTATE``,
``STRING``, ``INT``, ``HEX``), expression operators (``AND``, ``OR``, ``NOT``
and comparison operators), menu item kinds (``MENU``, ``COMMENT``), and
tristate conversion maps (``TRI_TO_STR`` and ``STR_TO_TRI``). They are useful
when inspecting parsed data, but ordinary scripts can usually use the public
properties above instead.
