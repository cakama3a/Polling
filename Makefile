VENV_NAME ?= venv
APP ?= Polling.py

PYTHON := $(VENV_NAME)/bin/python3
PIP := $(VENV_NAME)/bin/pip
ACTIVATE := $(VENV_NAME)/bin/activate

.PHONY: install update clean run

virtual: $(PIP) $(ACTIVATE)

requirements: requirements.txt $(PIP)
	$(PIP) --require-virtualenv install -Ur $<

install: install.py $(ACTIVATE) | requirements
	( source $(ACTIVATE); $(PYTHON) install.py; )

update: update.py $(ACTIVATE) | requirements
	( source $(ACTIVATE); $(PYTHON) update.py; )

run: $(APP) $(ACTIVATE) | requirements
	( source $(ACTIVATE); $(PYTHON) $(APP); )

clean:
	rm -Rf $(VENV_NAME)

$(VENV_NAME):
	virtualenv -p /usr/bin/python3 $(VENV_NAME)

$(PIP) $(ACTIVATE): $(VENV_NAME)
