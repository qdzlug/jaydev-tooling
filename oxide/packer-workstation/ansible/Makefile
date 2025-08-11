.PHONY: venv activate install clean

venv:
	python3 -m venv .venv

activate:
	echo "Run 'source .venv/bin/activate' to activate the virtual environment."

install: venv
	. .venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt

clean:
	rm -rf .venv
