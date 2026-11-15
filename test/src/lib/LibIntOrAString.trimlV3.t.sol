// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringTrimlV3Test is Test {
    /// Every Java whitespace byte and the bytes either side of each run.
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
        checkV3("\t\n\x0b\x0c\r\x1c\x1d\x1e\x1f ", "");
    }

    function testTrimlV3ThirtyOneBytes() external pure {
        checkV3("                               ", "");
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234");
    }

    function testTrimlV3KeepsInnerWhitespace() external pure {
        checkV3(" a b ", "a b ");
    }

    function testTrimlV3EachWhitespaceByte() external pure {
        bytes memory whitespace = "\t\n\x0b\x0c\r\x1c\x1d\x1e\x1f ";
        for (uint256 i = 0; i < whitespace.length; i++) {
            checkV3(abi.encodePacked(whitespace[i]), "");
        }
    }

    function testTrimlV3KeepsNonWhitespaceBytes() external pure {
        bytes memory other = "\x00\x08\x0e\x1b!a\x7f\x85\xa0\xff";
        for (uint256 i = 0; i < other.length; i++) {
            checkV3(abi.encodePacked(other[i]), abi.encodePacked(other[i]));
        }
    }

    function checkV3(bytes memory s, bytes memory expected) internal pure {
        assertEq(LibStringReference.triml(s), expected);
        checkTriml(s, 0);
    }
}

contract LibIntOrAStringTrimlV3ClojureTest is ClojureStringOracleTest {
    function trimlV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.trimlV3(intOrAString);
    }

    /// Expected from `clojure.string/triml`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimlV3ClojureAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimlV3External, "triml", fuzzString(data0, data1, length, true));
    }

    /// Expected from `clojure.string/triml`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimlV3ClojureAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimlV3External, "triml", fuzzString(data0, data1, length, false));
    }
}
