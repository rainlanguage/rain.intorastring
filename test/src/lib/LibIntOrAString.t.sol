// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString, LENGTH_MASK_V3, TRUTHY_BITS_V3} from "src/lib/LibIntOrAString.sol";
import {LibBytes} from "rain-solmem-0.1.28/src/lib/LibBytes.sol";
import {LibMemCpy} from "rain-solmem-0.1.28/src/lib/LibMemCpy.sol";
import {LibIntOrAStringSlow} from "test/lib/LibIntOrAStringSlow.sol";

contract LibIntOrAStringTest is Test {
    /// We can't assume that the memory pointed to by 0x40 is zeroed, so we
    /// should fill it with garbage before running our conversions to ensure they
    /// are resilient to garbage data.
    function putGarbageInUnallocatedMemory() internal pure {
        uint256 garbage = type(uint256).max;
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            // Garbage in scratch space.
            mstore(0, garbage)
            mstore(0x20, garbage)
            // Garbage in free memory.
            mstore(ptr, garbage)
            mstore(add(ptr, 0x20), garbage)
        }
    }

    /// All strings 31 bytes or less should round trip cleanly.
    function testRoundTripString(string memory s) external pure {
        vm.assume(bytes(s).length <= 31);
        putGarbageInUnallocatedMemory();
        assertEq(LibIntOrAString.toStringV3(LibIntOrAString.fromStringV3(s)), s);
    }

    /// All strings of any length should round trip but be truncated to their
    /// length modulo 32.
    function testRoundTripStringTruncated(string memory s) external pure {
        putGarbageInUnallocatedMemory();
        bytes memory truncated = new bytes((bytes(s).length));
        LibMemCpy.unsafeCopyBytesTo(
            LibBytes.dataPointer(bytes(s)), LibBytes.dataPointer(bytes(truncated)), bytes(s).length
        );
        LibBytes.truncate(truncated, truncated.length % 32);

        assertEq(LibIntOrAString.toStringV3(LibIntOrAString.fromStringV3(s)), string(truncated));
    }

    /// Test directly that the length (rightmost byte) of an `IntOrAString` is
    /// the length of the string it was created from modulo 32.
    function testFromStringV3Length(string memory s) external pure {
        putGarbageInUnallocatedMemory();
        IntOrAString intOrAString = LibIntOrAString.fromStringV3(s);
        assertEq(IntOrAString.unwrap(intOrAString) & LENGTH_MASK_V3, bytes(s).length % 32);
    }

    /// Test that building an `IntOrAString` from a string never includes any
    /// bytes in memory beyond the length of the string.
    function testFromStringV3Garbage(string memory s, uint256 truncatedLength) external pure {
        putGarbageInUnallocatedMemory();
        vm.assume(bytes(s).length > 1);
        truncatedLength = bound(truncatedLength, 1, bytes(s).length - 1);
        // Set the length of the string to the truncated length without modifying
        // anything else in memory, so this will leave garbage bytes beyond the
        // new truncated length of the string.
        assembly ("memory-safe") {
            mstore(s, truncatedLength)
        }
        IntOrAString intOrAString = LibIntOrAString.fromStringV3(s);
        assertEq(0, IntOrAString.unwrap(intOrAString) >> (((truncatedLength % 32) + 1) * 8));
    }

    /// Test that building an `IntOrAString` from a 0 length string never
    /// includes any bytes in memory beyond the length of the string.
    function testFromStringV3ZeroLengthGarbage() external pure {
        putGarbageInUnallocatedMemory();
        // Put a new string directly into scratch space with 0 length and all
        // ones for the adjacent data (that should not be included in output).
        string memory s;
        uint256 garbage = type(uint256).max;
        assembly ("memory-safe") {
            s := 0
            mstore(0, 0)
            mstore(0x20, garbage)
        }
        IntOrAString intOrAString = LibIntOrAString.fromStringV3(s);
        assertEq(TRUTHY_BITS_V3, IntOrAString.unwrap(intOrAString));
    }

    /// Directly test that all possible `IntOrAString` values can be converted to
    /// a string that is less than 32 bytes long.
    function testToString(IntOrAString intOrAString) external pure {
        putGarbageInUnallocatedMemory();
        string memory s = LibIntOrAString.toStringV3(intOrAString);
        assertTrue(bytes(s).length < 0x20);
    }

    /// Test `toStringV3` against reference implementation.
    function testToStringAgainstSlow(IntOrAString intOrAString) external pure {
        putGarbageInUnallocatedMemory();
        string memory s = LibIntOrAString.toStringV3(intOrAString);
        string memory slow = LibIntOrAStringSlow.toStringV3Slow(intOrAString);
        assertEq(s, slow);
    }

    /// Test `fromStringV3` against reference implementation.
    function testFromStringV3AgainstSlow(string memory s) external pure {
        putGarbageInUnallocatedMemory();
        IntOrAString intOrAString = LibIntOrAString.fromStringV3(s);
        IntOrAString slow = LibIntOrAStringSlow.fromStringV3Slow(s);
        assertEq(IntOrAString.unwrap(intOrAString), IntOrAString.unwrap(slow));
    }

    /// Test `fromStringV3` always returns truthy numeric values according to
    /// float logic (i.e. != 0 when excluding the exponent bytes).
    function testFromStringV3Truthy(string memory s) external pure {
        putGarbageInUnallocatedMemory();
        IntOrAString intOrAString = LibIntOrAString.fromStringV3(s);
        assertTrue(int224(uint224(IntOrAString.unwrap(intOrAString))) != 0);
    }

    /// Every byte of the allocated data word beyond the string length is zero,
    /// whatever free memory held beforehand and whatever the high bytes of the
    /// input were.
    function testToStringV3TrailingBytesZeroed(IntOrAString intOrAString) external pure {
        putGarbageInUnallocatedMemory();
        string memory s = LibIntOrAString.toStringV3(intOrAString);
        uint256 length = bytes(s).length;
        uint256 dataWord;
        assembly ("memory-safe") {
            dataWord := mload(add(s, 0x20))
        }
        assertEq(dataWord << (length * 8), 0);
    }

    /// Layout as documented: string bytes sit immediately above the low byte,
    /// whose low 5 bits are the length and whose high 3 bits are set.
    function testFromStringV3KnownAnswers() external pure {
        putGarbageInUnallocatedMemory();
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("")), 0xe0);
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("a")), 0x61e1);
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("foo")), 0x666f6fe3);
        assertEq(
            IntOrAString.unwrap(LibIntOrAString.fromStringV3("abcdefghijklmnopqrstuvwxyz01234")),
            0x6162636465666768696a6b6c6d6e6f707172737475767778797a3031323334ff
        );
        // 32 bytes wraps to length 0 with no data.
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("abcdefghijklmnopqrstuvwxyz012345")), 0xe0);
        // 33 bytes wraps to length 1, keeping only the first byte.
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("abcdefghijklmnopqrstuvwxyz0123456")), 0x61e1);
    }

    /// Only the low 5 bits of the length byte and the bytes the length covers
    /// are read; every other bit of the input is ignored.
    function testToStringV3KnownAnswers() external pure {
        putGarbageInUnallocatedMemory();
        assertEq(LibIntOrAString.toStringV3(IntOrAString.wrap(0)), "");
        assertEq(LibIntOrAString.toStringV3(IntOrAString.wrap(0xe0)), "");
        assertEq(LibIntOrAString.toStringV3(IntOrAString.wrap(0x666f6fe3)), "foo");
        assertEq(LibIntOrAString.toStringV3(IntOrAString.wrap(0x666f6f03)), "foo");
        assertEq(LibIntOrAString.toStringV3(IntOrAString.wrap((type(uint256).max << 32) | 0x666f6fe3)), "foo");
        assertEq(
            LibIntOrAString.toStringV3(
                IntOrAString.wrap(0x6162636465666768696a6b6c6d6e6f707172737475767778797a3031323334ff)
            ),
            "abcdefghijklmnopqrstuvwxyz01234"
        );
    }

    function roundTripsV3(IntOrAString intOrAString) internal pure returns (bool) {
        return IntOrAString.unwrap(LibIntOrAString.fromStringV3(LibIntOrAString.toStringV3(intOrAString)))
            == IntOrAString.unwrap(intOrAString);
    }

    function checkIsStringV3(uint256 value, bool expected) internal pure {
        IntOrAString intOrAString = IntOrAString.wrap(value);
        assertEq(roundTripsV3(intOrAString), expected);
        assertEq(LibIntOrAString.isStringV3(intOrAString), expected);
    }

    function testIsStringV3TrueForFromStringV3Output(string memory s) external pure {
        vm.assume(bytes(s).length <= 31);
        putGarbageInUnallocatedMemory();
        assertTrue(LibIntOrAString.isStringV3(LibIntOrAString.fromStringV3(s)));
    }

    function testIsStringV3EqualsRoundTrip(IntOrAString intOrAString) external pure {
        putGarbageInUnallocatedMemory();
        assertEq(LibIntOrAString.isStringV3(intOrAString), roundTripsV3(intOrAString));
    }

    /// Uniform words are almost never V3 strings, so bias the fuzz to near encodings.
    function testIsStringV3EqualsRoundTripNearEncodings(uint256 data, uint256 dataLength, uint8 lowByte)
        external
        pure
    {
        dataLength = bound(dataLength, 0, 31);
        putGarbageInUnallocatedMemory();
        IntOrAString intOrAString = IntOrAString.wrap(((data >> ((32 - dataLength) * 8)) << 8) | lowByte);
        assertEq(LibIntOrAString.isStringV3(intOrAString), roundTripsV3(intOrAString));
    }

    function testIsStringV3TrueForIntegerEqualToStringEncoding() external pure {
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("A")), 16865);
        checkIsStringV3(16865, true);
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("")), 224);
        checkIsStringV3(224, true);
        checkIsStringV3(0x666f6fe3, true);
    }

    function testIsStringV3FalseForZeroAndOne() external pure {
        checkIsStringV3(0, false);
        checkIsStringV3(1, false);
    }

    function testIsStringV3FalseWhenAnyTruthyBitClear() external pure {
        uint256[4] memory encodings =
            [uint256(0xe0), 0x41e1, 0x6162636465666768696a6b6c6d6e6f707172737475767778797a3031323334ff, type(uint256).max];
        for (uint256 i = 0; i < encodings.length; i++) {
            checkIsStringV3(encodings[i], true);
            for (uint256 bit = 0x20; bit <= 0x80; bit <<= 1) {
                checkIsStringV3(encodings[i] & ~bit, false);
            }
            checkIsStringV3(encodings[i] & ~TRUTHY_BITS_V3, false);
        }
    }

    function testIsStringV3DataBoundaryIsLength() external pure {
        for (uint256 length = 0; length < 31; length++) {
            uint256 lowByte = TRUTHY_BITS_V3 | length;
            uint256 fullData = ((1 << (length * 8)) - 1) << 8;
            checkIsStringV3(lowByte, true);
            checkIsStringV3(fullData | lowByte, true);
            checkIsStringV3((1 << ((length + 1) * 8)) | lowByte, false);
            checkIsStringV3((1 << ((length + 1) * 8)) | fullData | lowByte, false);
            checkIsStringV3((1 << 255) | lowByte, false);
        }
    }

    /// Length 31 covers every byte above the low byte, so no high bit is stray.
    function testIsStringV3TrueForLength31WithAnyHighBits() external pure {
        checkIsStringV3(0xff, true);
        checkIsStringV3(0x01ff, true);
        checkIsStringV3((1 << 248) | 0xff, true);
        checkIsStringV3((1 << 255) | 0xff, true);
        checkIsStringV3(type(uint256).max, true);
    }

    function testIsStringV3TrueForEveryLength31Word(uint256 data) external pure {
        putGarbageInUnallocatedMemory();
        checkIsStringV3((data << 8) | 0xff, true);
    }
}
