# movesense_flutter

A flutter plugin to communicate with the Whiteboard on a Suunto Movesense
sensor. For more information on the Movesense platform, please refer to
[movesense.com](https://www.movesense.com).

This plugin wraps the [movesense-mobile-lib][lib] from Suunto, but is *not*
developed or supported by Suunto. Please direct plugin/flutter bug reports
and support inquiries to [the issues page for the plugin git repo][issues].

## supported platforms

Right now the platform-specific side of the plugin is only implemented for
Android. I will work on the iOS side after most of the bugs are worked out,
the interface is fairly stable, and I get a XCode/iOS toolchain set up.

In the meantime, please feel free to fork, hack, and submit PRs.

## dependencies

This plugin wraps the [movesense-mobile-lib][lib] from Suunto. It uses
`mdslib-...-release.aar` for Android, and will use `libmds.a` for iOS.

The compiled release libraries are available in the Suunto repository on
[bitbucket][lib], and subject to the license in that repository.

This also means you need to include the dependencies of the mobile lib. The
plugin should mostly take care of that, but for release builds and for apps
published on the Play Store, I've seen R8 strip out code that is necessary,
so you should use ProGuard rules to prevent that. Refer to the example app
for details. It should boil down to:

```
-keep class works.otter.movesense_flutter.** { *; } # keep everything in the movesense_flutter plugin
-keep class com.movesense.mds.** { *; } # keep everything in MDS
-keep class com.polidea.rxandroidble2.** { *; } # keep everything in the embedded BLE stack
```

[issues]: https://gitlab.com/bluesquall/movesense_flutter/-/issues
[lib]: https://bitbucket.org/suunto/movesense-mobile-lib
