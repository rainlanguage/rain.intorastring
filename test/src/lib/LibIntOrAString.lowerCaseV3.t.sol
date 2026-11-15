// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringLowerCaseV3Test is Test {
    /// Every camel-snake-kebab character class, the bytes either side of each
    /// ASCII letter range, and bytes above ASCII.
    bytes constant CASE_ALPHABET = "aAzZbB09_- \t\n\x0b\x0c\r.@[`{\x1c\x00\x80\xc1\xe1\xff";

    function lowerCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.lowerCaseV3(intOrAString);
    }

    function checkLowerCase(bytes memory s, uint256 garbage) internal {
        bytes memory expected = LibStringReference.lowerCase(s);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString dirty = LibStringFuzz.dirtyV3(a, garbage);
        if (expected.length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.lowerCaseV3External(a);
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.lowerCaseV3External(dirty);
        } else {
            uint256 canonical = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected)));
            assertEq(IntOrAString.unwrap(LibIntOrAString.lowerCaseV3(a)), canonical);
            assertEq(IntOrAString.unwrap(LibIntOrAString.lowerCaseV3(dirty)), canonical);
        }
    }

    function checkV3(bytes memory s, bytes memory expected) internal {
        assertEq(LibStringReference.lowerCase(s), expected);
        checkLowerCase(s, 0);
    }

    function testLowerCaseV3Reference(bytes32 data, uint256 length, uint256 garbage) external {
        checkLowerCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), CASE_ALPHABET), garbage);
    }

    function testLowerCaseV3ReferenceAnyBytes(bytes32 data, uint256 length, uint256 garbage) external {
        checkLowerCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), ""), garbage);
    }

    function testLowerCaseV3Empty() external {
        checkV3("", "");
    }

    function testLowerCaseV3Letters() external {
        checkV3("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz");
        checkV3("abcdefghijklmnopqrstuvwxyz", "abcdefghijklmnopqrstuvwxyz");
        checkV3("fooBar", "foobar");
        checkV3("Foo_Bar-1", "foo_bar-1");
    }

    function testLowerCaseV3NonLetters() external {
        checkV3("@[`{", "@[`{");
        checkV3("0123456789 -_.\t", "0123456789 -_.\t");
        checkV3("\x00\x7f\x80\xc1\xe1\xff", "\x00\x7f\x80\xc1\xe1\xff");
    }

    function testLowerCaseV3ThirtyOneBytes() external {
        checkV3("ABCDEFGHIJKLMNOPQRSTUVWXYZ01234", "abcdefghijklmnopqrstuvwxyz01234");
    }
}
