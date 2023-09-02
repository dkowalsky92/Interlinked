fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac release

```sh
[bundle exec] fastlane mac release
```

Push a new release build to the App Store

### mac build_and_test

```sh
[bundle exec] fastlane mac build_and_test
```

Build and test a debug build

### mac test

```sh
[bundle exec] fastlane mac test
```

Test InterlinkedCore package

### mac provision_all_profiles_and_certificates

```sh
[bundle exec] fastlane mac provision_all_profiles_and_certificates
```

Provision all profiles & certificates

### mac nuke_all_profiles_and_certificates

```sh
[bundle exec] fastlane mac nuke_all_profiles_and_certificates
```

Nuke all profiles & certificates

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
