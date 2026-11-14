// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {IntOrAStringTooLong, IntOrAStringSubsOutOfRange} from "../error/ErrIntOrAString.sol";

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
    /// length is a simple bitwise AND operation.
    /// @param intOrAString The IntOrAString to convert to a string.
    /// @return s The resulting string.
    function toStringV3(IntOrAString intOrAString) internal pure returns (string memory s) {
        uint256 lengthMask = LENGTH_MASK_V3;
        assembly ("memory-safe") {
            let length := and(intOrAString, lengthMask)
            let data := shr(8, intOrAString)

            // Allocate two words: the length word and the data word.
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

    /// Converts a `string` to an `IntOrAString`, taking the length modulo 32
    /// in the process. The length and truthiness bits are stored in the low
    /// byte of the resulting `IntOrAString`. Any bytes beyond the length of
    /// the string will be zeroed out, to ensure that no potentially sensitive
    /// data in memory is copied into the `IntOrAString`. This version also
    /// ensures that all strings have the same truthiness in Rainlang float
    /// semantics, by setting the 3 high bits of the length byte to 1, so that
    /// even an empty string is considered truthy. If we set high bits of the
    /// main word then some strings would be considered 0 with some non-zero
    /// exponent, which is falsey for a float.
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

    /// V3 byte length of an `IntOrAString`, read from the low 5 bits.
    /// @param intOrAString The V3 `IntOrAString`.
    /// @return The byte length of the string.
    function countV3(IntOrAString intOrAString) internal pure returns (uint256) {
        return IntOrAString.unwrap(intOrAString) & LENGTH_MASK_V3;
    }

    /// V3 prefix check. Bytes above the length of either input are ignored.
    /// @param intOrAString The V3 `IntOrAString` to check.
    /// @param prefix The V3 `IntOrAString` prefix.
    /// @return True if `intOrAString` starts with `prefix`.
    function startsWithV3(IntOrAString intOrAString, IntOrAString prefix) internal pure returns (bool) {
        uint256 lengthMask = LENGTH_MASK_V3;
        bool result;
        assembly ("memory-safe") {
            let sLength := and(intOrAString, lengthMask)
            let pLength := and(prefix, lengthMask)
            let shift := sub(256, mul(8, pLength))
            let sLeft := shl(sub(256, mul(8, sLength)), shr(8, intOrAString))
            let pLeft := shl(shift, shr(8, prefix))
            result := and(iszero(gt(pLength, sLength)), eq(shr(shift, sLeft), shr(shift, pLeft)))
        }
        return result;
    }

    /// V3 suffix check. Bytes above the length of either input are ignored.
    /// @param intOrAString The V3 `IntOrAString` to check.
    /// @param suffix The V3 `IntOrAString` suffix.
    /// @return True if `intOrAString` ends with `suffix`.
    function endsWithV3(IntOrAString intOrAString, IntOrAString suffix) internal pure returns (bool) {
        uint256 lengthMask = LENGTH_MASK_V3;
        bool result;
        assembly ("memory-safe") {
            let sLength := and(intOrAString, lengthMask)
            let xLength := and(suffix, lengthMask)
            let mask := sub(shl(mul(8, xLength), 1), 1)
            result := and(iszero(gt(xLength, sLength)), eq(and(shr(8, intOrAString), mask), and(shr(8, suffix), mask)))
        }
        return result;
    }

    /// V3 `intOrAString` without `prefix`, or `intOrAString` unchanged when it
    /// does not start with `prefix`. The result is a canonical V3
    /// `IntOrAString`, as `fromStringV3` would produce.
    /// @param intOrAString The V3 `IntOrAString` to strip.
    /// @param prefix The V3 `IntOrAString` prefix.
    /// @return The stripped V3 `IntOrAString`.
    function stripPrefixV3(IntOrAString intOrAString, IntOrAString prefix) internal pure returns (IntOrAString) {
        uint256 lengthMask = LENGTH_MASK_V3;
        uint256 truthyBits = TRUTHY_BITS_V3;
        IntOrAString result;
        assembly ("memory-safe") {
            let sLength := and(intOrAString, lengthMask)
            let pLength := and(prefix, lengthMask)
            let shift := sub(256, mul(8, pLength))
            let sLeft := shl(sub(256, mul(8, sLength)), shr(8, intOrAString))
            let pLeft := shl(shift, shr(8, prefix))
            let stripped := mul(and(iszero(gt(pLength, sLength)), eq(shr(shift, sLeft), shr(shift, pLeft))), pLength)
            let length := sub(sLength, stripped)
            result := or(shl(8, shr(sub(256, mul(8, length)), shl(mul(8, stripped), sLeft))), or(truthyBits, length))
        }
        return result;
    }

    /// V3 `intOrAString` without `suffix`, or `intOrAString` unchanged when it
    /// does not end with `suffix`. The result is a canonical V3
    /// `IntOrAString`, as `fromStringV3` would produce.
    /// @param intOrAString The V3 `IntOrAString` to strip.
    /// @param suffix The V3 `IntOrAString` suffix.
    /// @return The stripped V3 `IntOrAString`.
    function stripSuffixV3(IntOrAString intOrAString, IntOrAString suffix) internal pure returns (IntOrAString) {
        uint256 lengthMask = LENGTH_MASK_V3;
        uint256 truthyBits = TRUTHY_BITS_V3;
        IntOrAString result;
        assembly ("memory-safe") {
            let sLength := and(intOrAString, lengthMask)
            let xLength := and(suffix, lengthMask)
            let sData := and(shr(8, intOrAString), sub(shl(mul(8, sLength), 1), 1))
            let mask := sub(shl(mul(8, xLength), 1), 1)
            let stripped :=
                mul(and(iszero(gt(xLength, sLength)), eq(and(sData, mask), and(shr(8, suffix), mask))), xLength)
            result := or(shl(8, shr(mul(8, stripped), sData)), or(truthyBits, sub(sLength, stripped)))
        }
        return result;
    }

    /// V3 substring check, as Clojure `clojure.string/includes?`. The empty
    /// string is included in every string.
    /// @param intOrAString The V3 `IntOrAString` to search.
    /// @param needle The V3 `IntOrAString` to find.
    /// @return True if `needle` occurs in `intOrAString`.
    function includesV3(IntOrAString intOrAString, IntOrAString needle) internal pure returns (bool) {
        uint256 sLength = countV3(intOrAString);
        uint256 nLength = countV3(needle);
        if (nLength > sLength) {
            return false;
        }
        uint256 mask = (1 << (8 * nLength)) - 1;
        uint256 sData = IntOrAString.unwrap(intOrAString) >> 8;
        uint256 nData = (IntOrAString.unwrap(needle) >> 8) & mask;
        for (uint256 i = 0; i <= sLength - nLength; i++) {
            if ((sData >> (8 * i)) & mask == nData) {
                return true;
            }
        }
        return false;
    }

    /// V3 substring of bytes `[start, end)`, as Clojure `subs`.
    /// @param intOrAString The V3 `IntOrAString`.
    /// @param start The first byte index, inclusive.
    /// @param end The last byte index, exclusive.
    /// @return The canonical V3 substring.
    function subsV3(IntOrAString intOrAString, uint256 start, uint256 end) internal pure returns (IntOrAString) {
        uint256 length = countV3(intOrAString);
        if (start > end || end > length) {
            revert IntOrAStringSubsOutOfRange(start, end, length);
        }
        return packV3(
            (IntOrAString.unwrap(intOrAString) >> (8 * (1 + length - end))) & ((1 << (8 * (end - start))) - 1),
            end - start
        );
    }

    /// V3 `intOrAString` without leading whitespace, as Clojure
    /// `clojure.string/triml` (Java `Character/isWhitespace`).
    /// @param intOrAString The V3 `IntOrAString`.
    /// @return The canonical V3 trimmed string.
    function trimlV3(IntOrAString intOrAString) internal pure returns (IntOrAString) {
        uint256 length = countV3(intOrAString);
        uint256 start = 0;
        while (start < length && isWhitespace(byteAtV3(intOrAString, length, start))) {
            start++;
        }
        return subsV3(intOrAString, start, length);
    }

    /// V3 `intOrAString` without trailing whitespace, as Clojure
    /// `clojure.string/trimr` (Java `Character/isWhitespace`).
    /// @param intOrAString The V3 `IntOrAString`.
    /// @return The canonical V3 trimmed string.
    function trimrV3(IntOrAString intOrAString) internal pure returns (IntOrAString) {
        uint256 length = countV3(intOrAString);
        uint256 end = length;
        while (end > 0 && isWhitespace(byteAtV3(intOrAString, length, end - 1))) {
            end--;
        }
        return subsV3(intOrAString, 0, end);
    }

    /// V3 `intOrAString` without leading or trailing whitespace, as Clojure
    /// `clojure.string/trim`.
    /// @param intOrAString The V3 `IntOrAString`.
    /// @return The canonical V3 trimmed string.
    function trimV3(IntOrAString intOrAString) internal pure returns (IntOrAString) {
        return trimlV3(trimrV3(intOrAString));
    }

    /// V3 concatenation of `a` then `b`, as Clojure `str`. Reverts with
    /// `IntOrAStringTooLong` when the result exceeds 31 bytes.
    /// @param a The V3 `IntOrAString` prefix.
    /// @param b The V3 `IntOrAString` suffix.
    /// @return The canonical V3 concatenation.
    function concatV3(IntOrAString a, IntOrAString b) internal pure returns (IntOrAString) {
        uint256 aLength = countV3(a);
        uint256 bLength = countV3(b);
        return packV3((dataV3(a, aLength) << (8 * bLength)) | dataV3(b, bLength), aLength + bLength);
    }

    /// Byte `i` of a V3 `IntOrAString` of byte length `length`.
    function byteAtV3(IntOrAString intOrAString, uint256 length, uint256 i) private pure returns (uint256) {
        return (IntOrAString.unwrap(intOrAString) >> (8 * (length - i))) & 0xff;
    }

    /// The low `length` bytes of string data of a V3 `IntOrAString`.
    function dataV3(IntOrAString intOrAString, uint256 length) private pure returns (uint256) {
        return (IntOrAString.unwrap(intOrAString) >> 8) & ((1 << (8 * length)) - 1);
    }

    /// Canonical V3 `IntOrAString` from right aligned `data` of `length`
    /// bytes. Reverts with `IntOrAStringTooLong` above 31 bytes.
    function packV3(uint256 data, uint256 length) private pure returns (IntOrAString) {
        if (length > LENGTH_MASK_V3) {
            revert IntOrAStringTooLong(length);
        }
        return IntOrAString.wrap((data << 8) | TRUTHY_BITS_V3 | length);
    }

    /// Java `Character/isWhitespace` over ASCII.
    function isWhitespace(uint256 c) private pure returns (bool) {
        return c == 0x20 || (c >= 0x09 && c <= 0x0d) || (c >= 0x1c && c <= 0x1f);
    }
}
