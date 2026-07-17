Contributing documentation
==========================

Documentation is built with `Sphinx <https://www.sphinx-doc.org/>`_ and the
`Furo <https://pradyunsg.me/furo/>`_ theme. The documentation toolchain
requires Python 3.10 or later; this is independent of the library's Python 3.9
runtime requirement. Create the documentation virtual environment and build
locally:

.. code-block:: console

   $ make -C docs venv
   $ make -C docs html
   $ make -C docs check

Open ``docs/_build/html/index.html`` to review the result. Use ``make -C docs
clean`` to remove generated build output. ``make -C docs serve`` builds the
site if needed and starts a local server at ``http://127.0.0.1:8000``. Set
``PORT`` or ``BIND`` to use another port or bind address. Set ``PYTHON`` when
the default interpreter is too old, for example ``make -C docs
PYTHON=python3.10 venv``. Run ``make -C docs check`` before submitting changes;
it performs a fresh build and treats every warning as an error.

Keep public API documentation in docstrings wherever practical. The Python API
reference uses Sphinx autodoc, so those docstrings use reStructuredText. The
command-line reference is generated from ``argparse`` instead: command syntax,
arguments, options, and concise terminal descriptions belong in each parser,
while extended explanations and examples belong in ``docs/``. Keep argparse
help readable as plain text and avoid RST-sensitive fragments such as unmatched
asterisks or trailing underscores.

Each command should expose a side-effect-free ``_get_parser()`` function that
returns its configured ``argparse.ArgumentParser``. Commands with only the
standard optional Kconfig argument delegate that function to
``kconfiglib._get_standard_arg_parser``. Reference the command-local factory
with the ``argparse`` directive; do not use ``automodule`` for CLI modules.
Parser factories must not parse arguments, load Kconfig files, or initialize a
user interface.

Add conceptual explanations, tutorials, and cross-cutting workflows under
``docs/guides/``.

When adding a page, include it in ``docs/index.rst``. Keep code snippets
small, runnable where possible, and use ``console``, ``python``, ``kconfig``,
or ``cmake`` syntax highlighting as appropriate.
