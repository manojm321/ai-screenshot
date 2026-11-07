all: app

app:
	./build_app.sh

dmg: app
	./build_dmg.sh

install: app
	./install.sh

uninstall:
	killall "AI Screenshot" 2>/dev/null || true
	rm -rf "/Applications/AI Screenshot.app" "$$HOME/Applications/AI Screenshot.app"
	@echo "AI Screenshot uninstalled."

clean:
	rm -rf "AI Screenshot.app" AppIcon.icns "AI-Screenshot.zip" "AI-Screenshot.zip.sha256" "AI-Screenshot.dmg" "AI-Screenshot.dmg.sha256"

test: app
	codesign -vvv --deep --strict "AI Screenshot.app"

.PHONY: all app dmg install uninstall clean test
