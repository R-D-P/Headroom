# Headroom

A menu bar app that says where your Mac's memory is going, and lets you do something about it.

Activity Monitor lists processes. Headroom lists the things you actually think about:

- **Apps**, with all their helpers added up: Chrome's 29 processes are one "Google Chrome" row.
- **Dev servers**, pulled out of the terminal that started them: a Meteor server is one row
  with its project, port, and which Claude Code session started it.
- **Claude Code sessions**, each with its project and session ID.
- **Leftovers**: anything whose parent has exited, flagged *Orphaned*.
- **macOS itself**, as one row at the bottom, because nothing in it can be acted on.

A **CPU** tab, switched from the top of the panel, shows the same rows by CPU use, with
macOS's own work split into named jobs (Spotlight indexing, Photos analysis, Time Machine,
iCloud sync, WindowServer…), plus load average, core count and whether the Mac is hot enough to
be slowed down.

Each row says in plain English why it uses what it uses ("Electron app: ships its own copy of
Chrome"), and has a button: **Restart** and **Quit** for apps, **Stop** for dev servers,
sessions and leftovers. Buttons ask once before acting (click, then click again). Each row's
RAM figure is green, blue or red for light, typical or heavy for that kind of thing.

Either list can be sorted by RAM or CPU, largest or smallest first, and the summary at the top
folds away (the chevron in the title bar) to give the list more room.

## Build and run

Requires macOS 27 and Xcode 27.

```sh
xcodebuild -project Headroom.xcodeproj -target Headroom -configuration Debug SYMROOT="$PWD/build" build
open build/Debug/Headroom.app
```

Or open `Headroom.xcodeproj` in Xcode and press Run. Source files are picked up from the
`Headroom/` folder automatically; there is nothing to add to the project by hand.

## Install and share

```sh
xcodebuild -project Headroom.xcodeproj -target Headroom -configuration Release SYMROOT="$PWD/build" build
ditto build/Release/Headroom.app /Applications/Headroom.app
```

The copy in `/Applications` turns on **Open at login** the first time it runs (a checkbox in the
panel's footer turns it off). Development builds elsewhere never register themselves.

Release builds are signed with the **Developer ID Application: RUSSELL PHILLIPS (7EDVBP8444)**
certificate, with Hardened Runtime and a secure timestamp, so they can be notarized. The
certificate expires on 1 February 2027; copies notarized before then keep working.

To share a new version, notarize the app, staple it, then do the same for a disk image:

```sh
ditto -c -k --keepParent build/Release/Headroom.app Headroom.zip
xcrun notarytool submit Headroom.zip --keychain-profile headroom-notary --wait
xcrun stapler staple build/Release/Headroom.app

# Put Headroom.app, an Applications symlink and "How to open Headroom.txt" in a folder, then:
hdiutil create -volname Headroom -srcfolder <folder> -format UDZO Headroom-1.0.dmg
codesign --sign "Developer ID Application: RUSSELL PHILLIPS (7EDVBP8444)" --timestamp Headroom-1.0.dmg
xcrun notarytool submit Headroom-1.0.dmg --keychain-profile headroom-notary --wait
xcrun stapler staple Headroom-1.0.dmg
spctl -a -vv -t install Headroom-1.0.dmg   # expect "source=Notarized Developer ID"
```

`headroom-notary` is a notarytool login stored in the keychain (Apple ID plus an app-specific
password). Release builds set `CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO`, because Apple refuses to
notarize an app carrying the debugger entitlement Xcode otherwise adds.

## Launch options

| Option | What it does |
| --- | --- |
| `--open-window` | Opens the panel as a normal window at launch |
| `--print-groups` | Prints every row as text and quits |
| `--stop "<row title>"` | Runs Stop on the first row whose title starts with that text, prints the result, quits |

```sh
build/Debug/Headroom.app/Contents/MacOS/Headroom --print-groups
build/Debug/Headroom.app/Contents/MacOS/Headroom --stop "Meteor dev server"
```

## How it works

- **Memory per process** is `ri_phys_footprint` from `proc_pid_rusage`, the same number as
  Activity Monitor's Memory column. It is readable without admin rights for your own processes.
  Root-owned processes are not readable; they still count in the bar at the top.
- **The bar** comes from `host_statistics64`, split the way Activity Monitor splits it
  (app, wired, compressed, cached). Pressure is `kern.memorystatus_vm_pressure_level`.
- **Which row a process belongs to** (`Grouping/ProcessAncestry.swift`): macOS charges
  everything started in a terminal to the terminal app, so Headroom walks each process's parent
  chain. The outermost recognised dev tool becomes a row; otherwise the nearest Claude Code session
  claims it; otherwise a tree whose top process was adopted by launchd becomes a "left behind" row;
  otherwise it falls back to the app macOS holds responsible.
- **Recognised dev tools** are rules in `Grouping/DevToolClassifier.swift`. Add a rule there to
  teach Headroom a new one.
- **CPU** is measured by comparing two readings: whole-machine ticks from `host_processor_info`,
  and per-process CPU time from `/bin/ps`, which is setuid root and so reports root-owned
  processes (Spotlight's `mds`, `WindowServer`) that Headroom can't read itself. Shares are of the
  whole Mac, so all rows add up to the total. Whatever the named rows don't account for (the
  kernel, processes that came and went between readings) is shown as its own row.
- **Stop** sends SIGTERM, waits up to three seconds, then SIGKILL. Before every signal it checks
  the pid still belongs to the same process (start time), so a recycled pid is never hit.
- **Restart** quits the app the way the Dock does, so it can save its state, then relaunches it.

The app is unsandboxed (it has to see and signal other processes), so it cannot go on the App
Store. It is distributed outside the store, signed with Developer ID and notarized.

## License

MIT. See [LICENSE](LICENSE).
