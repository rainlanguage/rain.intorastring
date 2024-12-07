// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {LibIntOrAString, IntOrAString, TRUTHY_HIGH_BIT} from "src/lib/LibIntOrAString.sol";
import {LibBytes} from "rain.solmem/lib/LibBytes.sol";
import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";
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
        assertEq(LibIntOrAString.toString(LibIntOrAString.fromString2(s)), s);
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

        assertEq(LibIntOrAString.toString(LibIntOrAString.fromString2(s)), string(truncated));
    }

    /// Test directly that the length (leftmost byte) of an `IntOrAString` is
    /// the length of the string it was created from modulo 32.
    function testFromString2Length(string memory s) external pure {
        putGarbageInUnallocatedMemory();
        IntOrAString intOrAString = LibIntOrAString.fromString2(s);
        assertEq((IntOrAString.unwrap(intOrAString) & ~TRUTHY_HIGH_BIT) >> 248, bytes(s).length % 32);
    }

    /// Test that building an `IntOrAString` from a string never includes any
    /// bytes in memory beyond the length of the string.
    function testFromString2Garbage(string memory s, uint256 truncatedLength) external pure {
        putGarbageInUnallocatedMemory();
        vm.assume(bytes(s).length > 1);
        truncatedLength = bound(truncatedLength, 1, bytes(s).length - 1);
        // Set the length of the string to the truncated length without modifying
        // anything else in memory, so this will leave garbage bytes beyond the
        // new truncated length of the string.
        assembly ("memory-safe") {
            mstore(s, truncatedLength)
        }
        IntOrAString intOrAString = LibIntOrAString.fromString2(s);
        assertEq(0, IntOrAString.unwrap(intOrAString) << ((truncatedLength + 1) * 8));
    }

    /// Test that building an `IntOrAString` from a 0 length string never
    /// includes any bytes in memory beyond the length of the string.
    function testFromString2ZeroLengthGarbage() external pure {
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
        IntOrAString intOrAString = LibIntOrAString.fromString2(s);
        assertEq(TRUTHY_HIGH_BIT, IntOrAString.unwrap(intOrAString));
    }

    /// Directly test that all possible `IntOrAString` values can be converted to
    /// a string that is less than 32 bytes long.
    function testToString(IntOrAString intOrAString) external pure {
        putGarbageInUnallocatedMemory();
        string memory s = LibIntOrAString.toString(intOrAString);
        assertTrue(bytes(s).length < 0x20);
    }

    /// Test `toString` against reference implementation.
    function testToStringAgainstSlow(IntOrAString intOrAString) external pure {
        putGarbageInUnallocatedMemory();
        string memory s = LibIntOrAString.toString(intOrAString);
        string memory slow = LibIntOrAStringSlow.toStringSlow(intOrAString);
        assertEq(s, slow);
    }

    /// Test `fromString2` against reference implementation.
    function testFromString2AgainstSlow(string memory s) external pure {
        putGarbageInUnallocatedMemory();
        IntOrAString intOrAString = LibIntOrAString.fromString2(s);
        IntOrAString slow = LibIntOrAStringSlow.fromStringSlow(s);
        assertEq(IntOrAString.unwrap(intOrAString), IntOrAString.unwrap(slow));
    }

    /// Test `fromString2` always returns truthy numeric values (never `0`).
    function testFromString2Truthy(string memory s) external pure {
        putGarbageInUnallocatedMemory();
        IntOrAString intOrAString = LibIntOrAString.fromString2(s);
        assertTrue(IntOrAString.unwrap(intOrAString) > 0);
    }

    /// Test `toString` returns an empty string for `0`. This is a special case
    /// for backwards compatibility before the high bit was set to `1` for truthy
    /// string enforcement.
    function testToStringZero() external pure {
        putGarbageInUnallocatedMemory();
        assertEq(LibIntOrAString.toString(IntOrAString.wrap(0)), "");
    }
}
