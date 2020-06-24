# movesense_flutter

A flutter plugin to communicate with the Whiteboard on a Suunto Movesense.

## supported platforms

Right now the platform-specific side of the plugin is only implemented for
Android. I will work on the iOS side after most of the bugs are worked out,
the interface is fairly stable, and I get a XCode/iOS toolchain set up.

In the meantime, please feel free to fork, hack, and submit PRs.

## dependencies

This plugin wraps the [movesense-mobile-lib][1] from Suunto. It uses
`mdslib-...-release.aar` for Android, and will use `libmds.a` for iOS.

These pre-built release libraries are available in the Suunto repository on
[bitbucket][1], and subject to the license in that repository.

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

## extra steps

Until I figure out how to package the `aar` into the published flutter
plugin, you need to add it to mavenLocal before you can build an Android
project using this plugin. To do this, add `build.gradle` to your clone of
the movesense-mobile-lib, then publish to your mavenLocal repository, e.g.:

```shell
pushd /path/to/movesense-mobile-lib/android/Movesense
curl -SLO https://bitbucket.org/bluesquall/movesense-mobile-lib/raw/2613490/android/Movesense/build.gradle
gradle publishToMavenLocal
popd
```

*note:* Downloading `build.gradle` from my bitbucket fork may be skipped in
the future if Suunto accepts a pull request to add it upstream.

[1]: https://bitbucket.org/suunto/movesense-mobile-lib
