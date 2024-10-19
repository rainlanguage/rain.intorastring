# rain.intorastring

Provides an unsigned integer type `IntOrAString` that can be used to represent
a packed string in a single evm word.

Tries to do as little as possible, respecting the basic constraint, which is
that we only have 32 bytes of data to work with. There are no fallbacks, errors,
conditionals or unsupported edge cases and minimal jumps generally.

Every possible `IntOrAString` value will produce a string when `toString` is
called, and vice versa, every possible string will create an `IntOrAString`.

The length of the string in the packed representation is read from the leftmost
byte, using the rightmost 5 bits of that byte. By using 5 bits for the length we
naturally achieve a 31 byte limit on the string data, with the "weird" side
effect that strings are truncated to `mod 32` whatever their original length was,
on both `toString` and `fromString`.

Probably the caller does not want strings truncating to a `mod` of their length,
so they should ensure that they don't feed anything that they don't want
truncated into this lib.

`LibIntOrAString` is careful to zero out data beyond input `string` values upon
creation, but will reproduce any garbage bytes from an `IntOrAString` into
memory on the round trip back to a `string`. Generally `string` values are bound
by their length, so any code that reads the produced `string` should not enter
these garbage bytes in memory anyway.

`LibIntOrAString` sets the high bit of `IntOrAString` values that it creates from
strings to `1` to ensure that they are always treated as truthy values. I.e. no
string input ever maps to `0`.

`LibIntOrAString` will interpret `0` and many other integer values that it cannot
produce as strings, if high/garbage bits are set/unset in ways it doesn't care
about when reading integers. It is strongly recommended to only roundtrip values
through compatible versions of this lib.

## Dev stuff

### Local environment & CI

Uses nixos.

Install `nix develop` - https://nixos.org/download.html.

Run `nix develop` in this repo to drop into the shell. Please ONLY use the nix
version of `foundry` for development, to ensure versions are all compatible.

Read the `flake.nix` file to find some additional commands included for dev and
CI usage.

## Legal stuff

Everything is under DecentraLicense 1.0 (DCL-1.0) which can be found in `LICENSES/`.

This is basically `CAL-1.0` which is an open source license
https://opensource.org/license/cal-1-0

The non-legal summary of DCL-1.0 is that the source is open, as expected, but
also user data in the systems that this code runs on must also be made available
to those users as relevant, and that private keys remain private.

Roughly it's "not your keys, not your coins" aware, as close as we could get in
legalese.

This is the default situation on permissionless blockchains, so shouldn't require
any additional effort by dev-users to adhere to the license terms.

This repo is REUSE 3.2 compliant https://reuse.software/spec-3.2/ and compatible
with `reuse` tooling (also available in the nix shell here).

```
nix develop -c rainix-sol-legal
```

## Contributions

Contributions are welcome **under the same license** as above.

Contributors agree and warrant that their contributions are compliant.