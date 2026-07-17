"""Configuration for the Kconfiglib documentation."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

project = "Kconfiglib"
copyright = "2011–2026, Kconfiglib contributors"
author = "Kconfiglib contributors"

# Keep the displayed version in sync with the library without duplicating it.
import kconfiglib  # noqa: E402

version = ".".join(map(str, kconfiglib.VERSION[:2]))
release = ".".join(map(str, kconfiglib.VERSION))

extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.intersphinx",
    "sphinx.ext.viewcode",
    "sphinxarg.ext",
]

autodoc_default_options = {
    "member-order": "bysource",
}
autodoc_typehints = "description"
intersphinx_mapping = {"python": ("https://docs.python.org/3", None)}

# The build venv lives inside this directory, and Sphinx does not skip
# dot-directories on its own. Without these, every .rst shipped inside
# site-packages gets picked up as a source file.
exclude_patterns = ["_build", ".venv", "**/site-packages"]

html_theme = "furo"
html_title = "Kconfiglib"
html_theme_options = {
    "source_repository": "https://github.com/Zshoham/Kconfiglib/",
    "source_branch": "main",
    "source_directory": "docs/",
}
