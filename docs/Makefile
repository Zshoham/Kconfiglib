# Sphinx build wrapper. Run `make html` from this directory.

PYTHON      ?= python3
VENV        ?= .venv
VENV_PYTHON := $(VENV)/bin/python
VENV_STAMP  := $(VENV)/.requirements-stamp
SPHINXBUILD ?= $(VENV)/bin/sphinx-build
SOURCEDIR    = .
BUILDDIR     = _build
PORT         ?= 8000
BIND         ?= 127.0.0.1

.PHONY: help venv html check serve clean

help: $(VENV_STAMP)
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)"

$(VENV_PYTHON):
	$(PYTHON) -m venv "$(VENV)"
	$(VENV_PYTHON) -m pip install --upgrade pip

# Stamped so that pip only runs when requirements.txt is newer than the last
# install. Keeps `make html` offline-friendly once the venv exists.
$(VENV_STAMP): requirements.txt | $(VENV_PYTHON)
	$(VENV_PYTHON) -m pip install -r requirements.txt
	@touch "$@"

venv: $(VENV_STAMP)

html: $(VENV_STAMP)
	@$(SPHINXBUILD) -M html "$(SOURCEDIR)" "$(BUILDDIR)"

check: $(VENV_STAMP)
	@$(SPHINXBUILD) -E -W --keep-going -b html "$(SOURCEDIR)" "$(BUILDDIR)/check"

serve: html
	@echo "Serving $(BUILDDIR)/html at http://$(BIND):$(PORT)"
	$(VENV_PYTHON) -m http.server "$(PORT)" --bind "$(BIND)" --directory "$(BUILDDIR)/html"

clean:
	@$(SPHINXBUILD) -M clean "$(SOURCEDIR)" "$(BUILDDIR)"
