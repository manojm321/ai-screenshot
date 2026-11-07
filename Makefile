all: app

app:
	./build_app.sh

install: app
	./install.sh

uninstall:
	killall "AI Screenshot" 2>/dev/null || true
	rm -rf "/Applications/AI Screenshot.app" "$$HOME/Applications/AI Screenshot.app"
	@echo "AI Screenshot uninstalled."

clean:
	rm -rf "AI Screenshot.app" AppIcon.icns "AI-Screenshot.zip" "AI-Screenshot.zip.sha256"

test: app
	codesign -vvv --deep --strict "AI Screenshot.app"

.PHONY: all app install uninstall clean test
