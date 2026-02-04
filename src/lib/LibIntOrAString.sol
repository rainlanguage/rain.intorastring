// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @dev Mask for the 5 bit length from V3 IntOrAString.
/// 0x1f = 00011111
uint256 constant LENGTH_MASK_V3 = 0x1f;

/// @dev The truthy bits for V3 IntOrAString.
/// 0xe0 = 11100000
uint256 constant TRUTHY_BITS_V3 = 0xe0;

/// Represents string data as an unsigned 32 byte integer.
/// Can only store up to 31 bytes of string data, with the length encoded in the
/// same word as the string data.
/// The binary layout is implementation specific and has varied over time. To
/// avoid compatibility issues the to/from string functions in this library
/// are versioned and the layouts are documented in the respective functions.
/// The reason this type isn't versioned is that it is intended to be used in
/// contexts where the types are erased, ostensibly as Rainlang values which are
/// all just `bytes32` by the time they reach the Rainlang stack.
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
/// 32 bytes. If strings are longer than 31 bytes, the library behaviour is
/// implementation specific, most likely it will truncate somehow, which is
/// likely not what the caller intended. The caller is responsible for keeping
/// strings within the 31 byte limit.
library LibIntOrAString {
    /// V3 version of toString, matching fromStringV3. This version puts the
    /// length in the low 5 bits of the IntOrAString, which means reading the
    /// length is a simple bitwise AND operation. This version also ensures that
    /// all strings have the same truthiness in Rainlang float semantics, by
    /// setting the 3 high bits of the length byte to 1, so that even an empty
    /// string is considered truthy. If we set high bits of the main word then
    /// some strings would be considered 0 with some non-zero exponent, which is
    /// falsey for a float.
    /// @param intOrAString The IntOrAString to convert to a string.
    /// @return s The resulting string.
    function toStringV3(IntOrAString intOrAString) internal pure returns (string memory s) {
        uint256 lengthMask = LENGTH_MASK_V3;
        assembly ("memory-safe") {
            let length := and(intOrAString, lengthMask)
            let data := shr(8, intOrAString)

            // Allocate memory for the string. If memory is currently aligned, it
            // will remain aligned after allocating length + 32 bytes. If not,
            // it will retain the same misalignment.
            // Trailing bytes beyond the new string are zeroed.
            s := mload(0x40)
            mstore(0x40, add(s, 0x40))
            // Ensure trailing bytes beyond the new string are zeroed.
            mstore(add(s, 0x20), 0)

            mstore(add(s, length), data)
            // This will overwrite any garbage data that happened to be present
            // in the high bytes beyond `length` bytes of data in the input.
            mstore(s, length)
        }
    }

    /// Converts a `string` to an `IntOrAString`, truncating the length to 31
    /// bytes in the process. The length and truthiness bits are stored in the
    /// low byte of the resulting `IntOrAString`. Any bytes beyond the length of
    /// the string will be zeroed out, to ensure that no potentially sensitive
    /// data in memory is copied into the `IntOrAString`.
    /// @param s The string to convert.
    /// @return intOrAString The resulting IntOrAString.
    function fromStringV3(string memory s) internal pure returns (IntOrAString intOrAString) {
        uint256 lengthMask = LENGTH_MASK_V3;
        uint256 truthyBits = TRUTHY_BITS_V3;
        assembly ("memory-safe") {
            // 5 bits for length mods length by 32.
            let length := and(mload(s), lengthMask)
            // Use some scratch space.
            mstore(0, or(truthyBits, length))
            // Copy the string data into scratch space, starting at byte 1.
            // The rightmost byte of the scratch word is left zeroed to store
            // the length and truthy bit.
            mcopy(sub(0x20, add(length, 1)), add(s, 0x20), length)
            intOrAString := mload(0)
        }
    }
}
