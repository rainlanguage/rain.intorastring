// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringTrimlV3Test is Test {
    /// Every ASCII whitespace byte, the bytes either side of each run, and the
    /// vertical tab and C0 separators, which are not ASCII whitespace.
    bytes constant WHITESPACE_ALPHABET = "\t\n\x0b\x0c\r\x1c\x1d\x1e\x1f \x00\x08\x0e\x1b!a\x85\xa0";

    function checkTriml(bytes memory s, uint256 garbage) internal pure {
        uint256 expected = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(LibStringReference.triml(s))));
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        assertEq(IntOrAString.unwrap(LibIntOrAString.trimlV3(a)), expected);
        assertEq(IntOrAString.unwrap(LibIntOrAString.trimlV3(LibStringFuzz.dirtyV3(a, garbage))), expected);
    }

    function testTrimlV3Reference(bytes32 data, uint256 length, uint256 garbage) external pure {
        checkTriml(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), WHITESPACE_ALPHABET), garbage);
    }

    function testTrimlV3ReferenceAnyBytes(bytes32 data, uint256 length, uint256 garbage) external pure {
        checkTriml(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), ""), garbage);
    }

    function testTrimlV3Empty() external pure {
        checkV3("", "");
        checkV3(" ", "");
        checkV3("\t\n\x0c\r ", "");
    }

    function testTrimlV3ThirtyOneBytes() external pure {
        checkV3("                               ", "");
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234");
    }

    function testTrimlV3KeepsInnerWhitespace() external pure {
        checkV3(" a b ", "a b ");
    }

    function testTrimlV3EachWhitespaceByte() external pure {
        bytes memory whitespace = "\t\n\x0c\r ";
        for (uint256 i = 0; i < whitespace.length; i++) {
            checkV3(abi.encodePacked(whitespace[i]), "");
        }
    }

    function testTrimlV3KeepsNonWhitespaceBytes() external pure {
        bytes memory other = "\x00\x08\x0b\x0e\x1b\x1c\x1d\x1e\x1f!a\x7f\x85\xa0\xff";
        for (uint256 i = 0; i < other.length; i++) {
            checkV3(abi.encodePacked(other[i]), abi.encodePacked(other[i]));
        }
        checkV3(" \x0b \x1f ", "\x0b \x1f ");
    }

    function checkV3(bytes memory s, bytes memory expected) internal pure {
        assertEq(LibStringReference.triml(s), expected);
        checkTriml(s, 0);
    }
}
