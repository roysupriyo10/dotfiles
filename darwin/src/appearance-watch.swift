// Run a command with "dark" or "light" whenever macOS appearance changes
// (Dark/Light toggle, or the scheduled "Auto" flip). Compiled to
// ~/.local/bin/appearance-watch by install.sh (run_hook_darwin_appearance);
// driven by the com.local.appearance-sync LaunchAgent.
//
//   appearance-watch <command> [args...]      # invoked as: command args... <dark|light>
//
// Source of truth is NSApplication.effectiveAppearance, observed via KVO.
// Unlike reading AppleInterfaceStyle from the defaults database, this value
// is (a) already updated when the observer fires — no race with the OS
// persisting the preference — and (b) never served from a stale per-process
// preference cache. Runs once at startup so state is correct after login.
//
// The process is a headless NSApplication (activationPolicy .prohibited):
// no Dock icon, no menu bar, but a real run loop that receives appearance
// changes like any GUI app.
import AppKit

let argv = Array(CommandLine.arguments.dropFirst())
if argv.isEmpty {
    FileHandle.standardError.write("usage: appearance-watch <command> [args...]\n".data(using: .utf8)!)
    exit(2)
}

func log(_ s: String) {
    FileHandle.standardError.write("appearance-watch: \(s)\n".data(using: .utf8)!)
}

func mode(of appearance: NSAppearance) -> String {
    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? "dark" : "light"
}

final class Watcher: NSObject, NSApplicationDelegate {
    private let cmd: String
    private let cmdArgs: [String]
    private var observation: NSKeyValueObservation?
    private var lastSent: String?

    init(command: [String]) {
        cmd = command[0]
        cmdArgs = Array(command.dropFirst())
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        // Initial sync, then react to every change. KVO with .new delivers the
        // post-change value; .initial makes the first delivery the startup sync.
        observation = NSApp.observe(\.effectiveAppearance, options: [.initial, .new]) { [weak self] app, _ in
            self?.sync(mode(of: app.effectiveAppearance))
        }
    }

    private func sync(_ m: String) {
        if m == lastSent { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: cmd)
        p.arguments = cmdArgs + [m]
        do {
            try p.run()
            p.waitUntilExit()
            if p.terminationStatus == 0 {
                lastSent = m
                log("synced \(m)")
            } else {
                lastSent = nil
                log("\(cmd) exited \(p.terminationStatus) for \(m)")
            }
        } catch {
            lastSent = nil
            log("failed to run \(cmd): \(error)")
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let delegate = Watcher(command: argv)
app.delegate = delegate
app.run()
