#!/usr/bin/env python3
"""
Automatically installs AI Screenshot as a native macOS Quick Action / Service
and binds it to Cmd+Shift+1 without requiring manual GUI configuration.
"""

import os
import plistlib
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICES_DIR = os.path.expanduser("~/Library/Services")
WORKFLOW_NAME = "AI Screenshot.workflow"
WORKFLOW_PATH = os.path.join(SERVICES_DIR, WORKFLOW_NAME)
PBS_PLIST = os.path.expanduser("~/Library/Preferences/pbs.plist")


def create_workflow_bundle():
    """Generates the Automator Quick Action .workflow bundle in ~/Library/Services."""
    contents_dir = os.path.join(WORKFLOW_PATH, "Contents")
    os.makedirs(contents_dir, exist_ok=True)

    info_plist = {
        "CFBundleDevelopmentRegion": "English",
        "CFBundleGetInfoString": "AI Screenshot",
        "CFBundleIdentifier": "com.manojm321.AI-Screenshot",
        "CFBundleInfoDictionaryVersion": "6.0",
        "CFBundleName": "AI Screenshot",
        "CFBundlePackageType": "BNDL",
        "CFBundleShortVersionString": "1.0",
        "CFBundleSignature": "????",
        "CFBundleVersion": "1.0",
        "NSServices": [
            {
                "NSBackgroundColorName": "background",
                "NSIconName": "NSActionTemplate",
                "NSMenuItem": {"default": "AI Screenshot"},
                "NSMessage": "runWorkflowAsService",
                "NSRequiredContext": {},
            }
        ],
    }

    with open(os.path.join(contents_dir, "Info.plist"), "wb") as f:
        plistlib.dump(info_plist, f)

    # Launch AI Screenshot.app via LaunchServices so macOS TCC attributes screen capture
    # directly to 'AI Screenshot' rather than 'com.apple.automator.xpc.runner'
    cmd_string = (
        "/usr/bin/open -b com.manojm321.ai-screenshot "
        "|| /usr/bin/open -b com.user.ai-screenshot "
        "|| /usr/bin/open -a '/Applications/AI Screenshot.app' "
        f"|| /usr/bin/open -a '{os.path.expanduser('~/Applications/AI Screenshot.app')}'"
    )

    document_wflow = {
        "AMApplicationBuild": "520",
        "AMApplicationVersion": "2.10",
        "AMDocumentVersion": "2",
        "actions": [
            {
                "action": {
                    "AMAccepts": {
                        "Container": "List",
                        "Optional": True,
                        "Types": ["com.apple.cocoa.string"],
                    },
                    "AMActionVersion": "2.0.3",
                    "AMApplication": ["Automator"],
                    "AMParameterProperties": {
                        "COMMAND_STRING": {},
                        "CheckedForUserDefaultShell": {},
                        "inputMethod": {},
                        "shell": {},
                        "source": {},
                    },
                    "AMParameters": {
                        "COMMAND_STRING": cmd_string,
                        "CheckedForUserDefaultShell": True,
                        "inputMethod": 0,
                        "shell": "/bin/zsh",
                        "source": "",
                    },
                    "AMProvides": {
                        "Container": "List",
                        "Types": ["com.apple.cocoa.string"],
                    },
                    "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
                    "ActionName": "Run Shell Script",
                    "ActionParameters": {
                        "COMMAND_STRING": cmd_string,
                        "CheckedForUserDefaultShell": True,
                        "inputMethod": 0,
                        "shell": "/bin/zsh",
                        "source": "",
                    },
                    "BundleIdentifier": "com.apple.RunShellScript",
                    "CFBundleVersion": "2.0.3",
                    "CanShowSelectedItemsWhenRun": False,
                    "CanShowWhenRun": True,
                    "Category": ["AMCategoryUtilities"],
                    "Class Name": "RunShellScriptAction",
                    "InputUUID": "A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D",
                    "Keywords": ["Shell", "Script", "Command", "Run", "Unix"],
                    "OutputUUID": "B2C3D4E5-F6A7-4B5C-9D0E-1F2A3B4C5D6E",
                    "UUID": "C3D4E5F6-A7B8-4C5D-0E1F-2A3B4C5D6E7F",
                    "UnlocalizedApplications": ["Automator"],
                    "arguments": {},
                    "conversionLabel": 0,
                    "isViewVisible": True,
                }
            }
        ],
        "connectors": {},
        "workflowMetaData": {
            "serviceApplicationBundleID": "",
            "serviceApplicationPath": "",
            "serviceInputTypeIdentifier": "com.apple.Automator.nothing",
            "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
            "serviceProcessesInput": 0,
            "workflowTypeIdentifier": "com.apple.Automator.servicesMenu",
        },
    }

    with open(os.path.join(contents_dir, "document.wflow"), "wb") as f:
        plistlib.dump(document_wflow, f)

    print(f"✅ Created Service bundle: {WORKFLOW_PATH}")


def register_hotkey():
    """Sets key equivalent @$1 (Cmd+Shift+1) in pbs.plist and flushes cache."""
    data = {}
    if os.path.exists(PBS_PLIST):
        try:
            with open(PBS_PLIST, "rb") as f:
                data = plistlib.load(f)
        except Exception:
            data = {}

    nsservices = data.get("NSServicesStatus", {})
    # Register both the bundle-prefixed ID and fallback (null) ID to ensure macOS matches it
    service_keys = [
        "com.manojm321.AI-Screenshot - AI Screenshot - runWorkflowAsService",
        "com.user.AI-Screenshot - AI Screenshot - runWorkflowAsService",
        "(null) - AI Screenshot - runWorkflowAsService",
    ]

    for service_key in service_keys:
        nsservices[service_key] = {
            "key_equivalent": "@$1",  # @ = Command, $ = Shift, 1 = key 1
            "enabled_context_menu": True,
            "enabled_services_menu": True,
        }

    data["NSServicesStatus"] = nsservices
    data["ServicesShortcutsPresent"] = True

    with open(PBS_PLIST, "wb") as f:
        plistlib.dump(data, f)

    # Invalidate cfprefsd memory cache so it reads updated plist from disk
    subprocess.run(["killall", "cfprefsd"], check=False)
    # Flush and update Pasteboard Services cache
    subprocess.run(["/System/Library/CoreServices/pbs", "-flush"], check=False)
    subprocess.run(["/System/Library/CoreServices/pbs", "-update"], check=False)

    print("✅ Registered keyboard shortcut ⌘⇧1 (Cmd + Shift + 1) in macOS Services.")


def main():
    create_workflow_bundle()
    register_hotkey()
    print("\n🎉 AI Screenshot is installed! You can now press ⌘⇧1 from any application.")


if __name__ == "__main__":
    main()
