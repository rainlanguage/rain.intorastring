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