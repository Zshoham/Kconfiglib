Kconfiglib
==========

.. Skip the README's own ``.. contents::`` block: furo already renders an
   on-page table of contents in the sidebar, so including it here would show a
   redundant, oddly-nested TOC. GitHub still shows it when viewing the README.
.. include:: ../README.rst
   :start-after: :backlinks: none

Documentation contents
----------------------

Start with :doc:`guides/getting-started` if you are new to Kconfig. The
:doc:`guides/writing-kconfig` guide explains the language and the decisions
that commonly surprise first-time users. The reference pages are generated
from the library docstrings and the command-line argument parsers, so they stay
close to the code.

.. toctree::
   :maxdepth: 2
   :caption: Guides

   guides/getting-started
   guides/writing-kconfig
   guides/workflows
   guides/interactive-interfaces
   guides/python-api

.. toctree::
   :maxdepth: 2
   :caption: Reference

   reference/kconfiglib/index
   reference/tools

.. toctree::
   :maxdepth: 1
   :caption: Project

   contributing
