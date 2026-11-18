// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString, LENGTH_MASK_V3, TRUTHY_BITS_V3} from "src/lib/LibIntOrAString.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
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

    function fromStringV3External(string memory s) external pure returns (IntOrAString) {
        return LibIntOrAString.fromStringV3(s);
    }

    /// Strings longer than 31 bytes revert instead of being truncated.
    function testFromStringV3TooLong(string memory s, bytes32 padding) external {
        putGarbageInUnallocatedMemory();
        string memory long = string.concat(s, string(abi.encodePacked(padding)));
        vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, bytes(long).length));
        this.fromStringV3External(long);
    }

    /// Test directly that the length (rightmost byte) of an `IntOrAString` is
    /// the length of the string it was created from.
    function testFromStringV3Length(string memory s) external {
        putGarbageInUnallocatedMemory();
        if (bytes(s).length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, bytes(s).length));
            this.fromStringV3External(s);
        } else {
            IntOrAString intOrAString = LibIntOrAString.fromStringV3(s);
            assertEq(IntOrAString.unwrap(intOrAString) & LENGTH_MASK_V3, bytes(s).length);
        }
    }

    /// Test that building an `IntOrAString` from a string never includes any
    /// bytes in memory beyond the length of the string.
    function testFromStringV3Garbage(string memory s, uint256 truncatedLength) external pure {
        putGarbageInUnallocatedMemory();
        vm.assume(bytes(s).length > 1);
        truncatedLength = bound(truncatedLength, 1, bytes(s).length - 1 < 31 ? bytes(s).length - 1 : 31);
        // Set the length of the string to the truncated length without modifying
        // anything else in memory, so this will leave garbage bytes beyond the
        // new truncated length of the string.
        assembly ("memory-safe") {
            mstore(s, truncatedLength)
        }
        IntOrAString intOrAString = LibIntOrAString.fromStringV3(s);
        assertEq(0, IntOrAString.unwrap(intOrAString) >> ((truncatedLength + 1) * 8));
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
    function testFromStringV3AgainstSlow(string memory s) external {
        putGarbageInUnallocatedMemory();
        if (bytes(s).length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, bytes(s).length));
            this.fromStringV3External(s);
        } else {
            IntOrAString intOrAString = LibIntOrAString.fromStringV3(s);
            IntOrAString slow = LibIntOrAStringSlow.fromStringV3Slow(s);
            assertEq(IntOrAString.unwrap(intOrAString), IntOrAString.unwrap(slow));
        }
    }

    /// Test `fromStringV3` always returns truthy numeric values according to
    /// float logic (i.e. != 0 when excluding the exponent bytes).
    function testFromStringV3Truthy(string memory s) external pure {
        vm.assume(bytes(s).length <= 31);
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
    function testFromStringV3KnownAnswers() external {
        putGarbageInUnallocatedMemory();
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("")), 0xe0);
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("a")), 0x61e1);
        assertEq(IntOrAString.unwrap(LibIntOrAString.fromStringV3("foo")), 0x666f6fe3);
        assertEq(
            IntOrAString.unwrap(LibIntOrAString.fromStringV3("abcdefghijklmnopqrstuvwxyz01234")),
            0x6162636465666768696a6b6c6d6e6f707172737475767778797a3031323334ff
        );
        vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, 32));
        this.fromStringV3External("abcdefghijklmnopqrstuvwxyz012345");
        vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, 33));
        this.fromStringV3External("abcdefghijklmnopqrstuvwxyz0123456");
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
