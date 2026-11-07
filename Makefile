all: app

app:
	./build_app.sh

install: app
	./install.sh

uninstall:
	rm -rf ~/Library/Services/"AI Screenshot.workflow"
	rm -rf "/Applications/AI Screenshot.app" "$$HOME/Applications/AI Screenshot.app"
	python3 -c "import plistlib, os, subprocess; p = os.path.expanduser('~/Library/Preferences/pbs.plist'); d = plistlib.load(open(p, 'rb')) if os.path.exists(p) else {}; s = d.get('NSServicesStatus', {}); s.pop('(null) - AI Screenshot - runWorkflowAsService', None); s.pop('com.manojm321.AI-Screenshot - AI Screenshot - runWorkflowAsService', None); s.pop('com.user.AI-Screenshot - AI Screenshot - runWorkflowAsService', None); plistlib.dump(d, open(p, 'wb')); subprocess.run(['killall', 'cfprefsd']); subprocess.run(['/System/Library/CoreServices/pbs', '-flush']); subprocess.run(['/System/Library/CoreServices/pbs', '-update'])"
	@echo "AI Screenshot uninstalled."

clean:
	rm -rf "AI Screenshot.app" AppIcon.icns "AI-Screenshot.zip" "AI-Screenshot.zip.sha256"

test: app
	codesign -vvv --deep --strict "AI Screenshot.app"

.PHONY: all app install uninstall clean test
