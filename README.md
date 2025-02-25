# BitSailor

Bitwarden GUI client for Sailfish OS using the official Bitwarden CLI.

Localizations are here: https://explore.transifex.com/rikudou-sage/bitsailor/

App presentation is here: https://openrepos.net/content/rikudousennin/bitsailor

## Building in Sailfish SDK

The following needs to be installed to the SDK:

- sailfishsecretsdaemon-secretsplugin-common

For example:

- `ssh -p 2222 -i ~/SailfishOS/vmshare/ssh/private_keys/sdk mersdk@localhost`
- `sudo zypper in sailfishsecretsdaemon-secretsplugin-common`

The following repository needs to be on the emulator:

- `sudo pkcon install zypper`
- `zypper ar -f https://sailfish.openrepos.net/Rikudou_Sennin/personal-main.repo`
- `rpm --import https://sailfish.openrepos.net/openrepos.key`
