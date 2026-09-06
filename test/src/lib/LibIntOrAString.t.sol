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
}
