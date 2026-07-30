# Android platform

Android supplies the app sandbox, lifecycle, accessibility service, SQLite
platform implementation, clipboard, URL intents, system UI, wake-lock flag, and
package distribution format.

The project targets Java 17 bytecode with a current Android Gradle toolchain.
Cleartext is disabled outside debug, cloud backup is disabled, exported
components are minimized, and no release signing material belongs in source.
Platform channels are deliberately narrow: display behavior is best-effort and
must fail safely on tests or unsupported hosts.

Release validation must inspect the merged manifest, permissions, network
security config, backup/data-extraction rules, resources, native libraries, ABI
splits, min/target SDK behavior, accessibility, app links/intents, and store
data-safety declarations. A successful Flutter unit suite is not an Android
artifact audit.
