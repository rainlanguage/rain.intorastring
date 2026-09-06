# rain.intorastring

Provides an unsigned integer type `IntOrAString` that can be used to represent a
packed string in a single evm word.

Tries to do as little as possible, respecting the basic constraint, which is
that we only have 32 bytes of data to work with. There are no fallbacks, errors,
conditionals or unsupported edge cases and minimal jumps generally.

Every possible `IntOrAString` value will produce a string when `toString` is
called, and vice versa, every possible string will create an `IntOrAString`.

The packed layout is documented in the NatSpec in `src/lib/LibIntOrAString.sol`.

## Dev stuff

### Local environment & CI

Uses nixos.

Install `nix develop` - https://nixos.org/download.html.

Run `nix develop` in this repo to drop into the shell. Please ONLY use the nix
version of `foundry` for development, to ensure versions are all compatible.

Read the `flake.nix` file to find some additional commands included for dev and
CI usage.

## Legal stuff

Everything is under DecentraLicense 1.0 (DCL-1.0) which can be found in
`LICENSES/`.

This is basically `CAL-1.0` which is an open source license
https://opensource.org/license/cal-1-0

The non-legal summary of DCL-1.0 is that the source is open, as expected, but
also user data in the systems that this code runs on must also be made available
to those users as relevant, and that private keys remain private.

Roughly it's "not your keys, not your coins" aware, as close as we could get in
legalese.

This is the default situation on permissionless blockchains, so shouldn't
require any additional effort by dev-users to adhere to the license terms.

This repo is REUSE 3.2 compliant https://reuse.software/spec-3.2/ and compatible
with `reuse` tooling (also available in the nix shell here).

```
nix develop -c rainix-sol-legal
```

## Contributions

Contributions are welcome **under the same license** as above.

Contributors agree and warrant that their contributions are compliant.
