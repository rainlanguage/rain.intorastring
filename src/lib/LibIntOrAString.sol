// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

/// @dev This masks out the top 3 bits of a uint256, leaving the lower 253 bits
/// intact. This ensures the length never exceeds 31 bytes when converting to
/// and from strings.
uint256 constant INT_OR_A_STRING_MASK = ~(uint256(7) << 253);

/// @dev Set the high bit of the uint256 that represents an `IntOrAString` to
/// ensure that strings are always interpreted as truthy, even if they are empty.
uint256 constant TRUTHY_HIGH_BIT = 1 << 0xFF;

/// Represents string data as an unsigned 32 byte integer. The highest 3 bits are
/// ignored when interpreting the integer as a string length, naturally limiting
/// the length of the string to 31 bytes. The lowest 31 bytes are the string
/// data, with the leftmost byte being the first byte of the string.
///
/// If lengths greater than 31 bytes are attempted to be stored, the string
/// conversion will exhibit the "weird" behaviour of truncating the output to
/// modulo 32 of the length. If the caller wishes to avoid this behaviour, they
/// should check and error on lengths greater than 31 bytes.
///
/// The high bit of an `IntOrString` is always set to `1`, to ensure that the
/// integer is always truthy, even if the string is empty.
type IntOrAString is uint256;

/// @title LibIntOrAString
/// @notice A library for converting between `IntOrAString` and `string`.
/// Note that unlike analogous libraries such as Open Zepplin's `ShortStrings`,
/// there is no intention to provide fallbacks for strings longer than 31 bytes.
/// The expectation is that `IntOrAString` will be used in contexts where there
/// really is no sensible fallback, because there is ONLY 32 bytes of space
/// available, such as a single storage slot or a single evm word on the stack or
/// in memory. By not supporting fallbacks, we can provide a simpler and more
/// efficient library, at the expense of requiring all strings to be shorter than
/// 32 bytes. If strings are longer than 31 bytes, the library will truncate the
/// output to modulo 32 of the length, which is probably not what you want, so
/// you should try to avoid ever working with longer strings, e.g. by checking
/// the length and erroring if it is too long, or otherwise providing the same
/// guarantee.
library LibIntOrAString {
    /// Converts an `IntOrAString` to a `string`, truncating the length to modulo
    /// 32 of the leftmost byte. Much in the same way as converting `bytes` to
    /// a string, there are NO checks or guarantees that the string is valid
    /// according to some encoding such as UTF-8 or ASCII. If the `intOrAString`
    /// contains garbage bytes beyond its string length, these will be copied
    /// into the output string, also beyond its string length. For most use cases
    /// this is fine, as strings aren't typically read beyond their length, but
    /// it is something to be aware of if those garbage bytes are sensitive
    /// somehow. The `fromString` function will always zero out these bytes
    /// beyond the string length, so if the `intOrAString` was created from a
    /// string using this library, there won't be any non-zero bytes beyond the
    /// length.
    function toString(IntOrAString intOrAString) internal pure returns (string memory) {
        string memory s;
        uint256 mask = INT_OR_A_STRING_MASK;
        assembly ("memory-safe") {
            // Point s to the free memory region.
            s := mload(0x40)
            // Allocate 64 bytes for the string, including the length field. As
            // the input data is 32 bytes always, this is always enough.
            mstore(0x40, add(s, 0x40))
            // Zero out the region allocated for the string so no garbage data
            // pre-allocation is present in the final string.
            mstore(s, 0)
            mstore(add(s, 0x20), 0)
            // Copy the input data to the string. As the length is masked to 5
            // bits, this is always safe in that the length of the output string
            // won't exceed the length of the original input data.
            mstore(add(s, 0x1F), and(intOrAString, mask))
        }
        return s;
    }

    /// Converts a `string` to an `IntOrAString`, truncating the length to modulo
    /// 32 in the process. Any bytes beyond the length of the string will be
    /// zeroed out, to ensure that no potentially sensitive data in memory is
    /// copied into the `IntOrAString`. The high bit of the `IntOrAString` is
    /// always set to `1`, to ensure that strings are always interpreted as
    /// truthy, even if they are empty.
    function fromString2(string memory s) internal pure returns (IntOrAString) {
        IntOrAString intOrAString;
        uint256 mask = INT_OR_A_STRING_MASK;
        uint256 truthyHighBit = TRUTHY_HIGH_BIT;
        assembly ("memory-safe") {
            intOrAString := and(mload(add(s, 0x1F)), mask)
            let garbageLength := sub(0x1F, byte(0, intOrAString))
            //slither-disable-next-line incorrect-shift
            let garbageMask := not(sub(shl(mul(garbageLength, 8), 1), 1))
            intOrAString := or(and(intOrAString, garbageMask), truthyHighBit)
        }
        return intOrAString;
    }
}
