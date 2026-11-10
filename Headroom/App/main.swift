// The same binary is the menu bar app and, when launchd starts it as root, the helper.
if HelperDaemon.isHelperProcess {
  HelperDaemon.run()
} else {
  HeadroomApp.main()
}
