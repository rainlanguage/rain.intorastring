// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";

contract LibIntOrAStringConcatV3Test is Test {
    function concatV3External(IntOrAString a, IntOrAString b) external pure returns (IntOrAString) {
        return LibIntOrAString.concatV3(a, b);
    }

    function checkConcat(bytes memory a, bytes memory b, uint256 aGarbage, uint256 bGarbage) internal {
        bytes memory expected = bytes.concat(a, b);
        IntOrAString x = LibIntOrAString.fromStringV3(string(a));
        IntOrAString y = LibIntOrAString.fromStringV3(string(b));
        IntOrAString xDirty = LibStringFuzz.dirtyV3(x, aGarbage);
        IntOrAString yDirty = LibStringFuzz.dirtyV3(y, bGarbage);
        if (expected.length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.concatV3External(x, y);
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.concatV3External(xDirty, yDirty);
        } else {
            uint256 canonical = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected)));
            assertEq(IntOrAString.unwrap(LibIntOrAString.concatV3(x, y)), canonical);
            assertEq(IntOrAString.unwrap(LibIntOrAString.concatV3(xDirty, yDirty)), canonical);
        }
    }

    function testConcatV3Reference(
        bytes32 aData,
        uint256 aLength,
        bytes32 bData,
        uint256 bLength,
        uint256 aGarbage,
        uint256 bGarbage
    ) external {
        checkConcat(
            LibStringFuzz.fuzzBytes(aData, bound(aLength, 0, 31), ""),
            LibStringFuzz.fuzzBytes(bData, bound(bLength, 0, 31), ""),
            aGarbage,
            bGarbage
        );
    }

    function testConcatV3Empty() external {
        checkV3("", "", "");
        checkV3("a", "", "a");
        checkV3("", "a", "a");
    }

    function testConcatV3ThirtyOneBytes() external {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "", "abcdefghijklmnopqrstuvwxyz01234");
        checkV3("", "abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234");
        checkV3("abcdefghijklmnopqrstuvwxyz0123", "4", "abcdefghijklmnopqrstuvwxyz01234");
        checkV3("a", "bcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234");
    }

    function testConcatV3TooLong() external {
        bytes memory s = "abcdefghijklmnopqrstuvwxyz01234";
        checkTooLong(s, "5", 32);
        checkTooLong("5", s, 32);
        checkTooLong(s, s, 62);
        checkTooLong("abcdefghijklmnop", "qrstuvwxyz012345", 32);
    }

    function checkV3(bytes memory a, bytes memory b, bytes memory expected) internal {
        assertEq(bytes.concat(a, b), expected);
        checkConcat(a, b, 0, 0);
    }

    function checkTooLong(bytes memory a, bytes memory b, uint256 length) internal {
        vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, length));
        this.concatV3External(LibIntOrAString.fromStringV3(string(a)), LibIntOrAString.fromStringV3(string(b)));
    }
}

contract LibIntOrAStringConcatV3ClojureTest is ClojureStringOracleTest {
    function concatV3External(IntOrAString a, IntOrAString b) external pure returns (IntOrAString) {
        return LibIntOrAString.concatV3(a, b);
    }

    /// Expected from Clojure `str`.
    /// forge-config: default.fuzz.runs = 1000
    function testConcatV3ClojureAscii(bytes32[4] memory data, uint256 aLength, uint256 bLength) external {
        checkString(
            this.concatV3External,
            "str",
            fuzzString(data[0], data[1], aLength, true),
            fuzzString(data[2], data[3], bLength, true)
        );
    }

    /// Expected from Clojure `str`.
    /// forge-config: default.fuzz.runs = 1000
    function testConcatV3ClojureAnyBytes(bytes32[4] memory data, uint256 aLength, uint256 bLength) external {
        checkString(
            this.concatV3External,
            "str",
            fuzzString(data[0], data[1], aLength, false),
            fuzzString(data[2], data[3], bLength, false)
        );
    }
}
