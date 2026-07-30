# Privacy policy

Effective date: 26 July 2026

Chess-Master is designed as an offline-first, account-free chess application.
This policy describes the repository’s current source behavior. A distributor
that changes the app, configures a relay, or adds services must publish an
updated policy that describes those changes.

## Data stored on the device

The app can store settings, onboarding state, player names when the user enables
name remembering, saved and auto-saved games, tutorial and puzzle progress,
daily challenge state, local coin/hint balances and ledger entries, and import/
export history needed for validation. This information is stored in the app’s
local SQLite database or in files the user explicitly exports.

Android cloud backup is disabled by the project manifest and backup rules.
Uninstalling the app normally removes app-private data. Settings → Data
Management provides selective resets, export/import, and a typed delete-all
action.

## Data not collected by this project

The current source has no account system, advertising SDK, analytics SDK,
behavioral tracking, crash-reporting service, contacts/location access, or
advertising identifier collection. Offline play, computer play, local
multiplayer, practice, saves, and review do not require a network service.

## Optional friend multiplayer

Friend play is disabled unless a distributor or self-hoster configures a relay
URL. During an active friend match, the selected relay necessarily processes a
temporary room code, protocol/session identifiers, connection state, moves,
position hashes, and network transport metadata such as IP addresses available
to the host. The included relay keeps room state in memory, expires rooms and
reconnect sessions, and has no game/profile database or analytics.

A relay host, reverse proxy, cloud provider, or operating environment may keep
network/security logs independently. Users should read the host’s policy. Do
not enter secrets or personal information as player names or room codes.

## External links and email

Creator, repository, support, and development links open only after user action.
The destination service and device browser/email client then apply their own
policies. If opening fails, the app may copy the address to the clipboard.

## Exports, sharing, and deletion

Exported JSON, PGN, FEN, reward-ledger JSON, copied room codes, and clipboard
contents leave app-private storage under the user’s control. The app cannot
delete copies the user has shared or that another application has retained.
Imports are locally validated before merge or replacement.

## Children

The project does not knowingly collect personal information from children
because it operates without accounts or analytics. A configured third-party
relay or distribution channel may impose separate age and consent rules.

## Security and changes

Security reports should follow SECURITY.md. Material privacy changes must update
this file, the in-app summary, Android data-safety declarations, and release
notes before distribution.

Questions: supportramsandesh@gmail.com
