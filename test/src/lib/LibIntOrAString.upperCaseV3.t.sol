// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringUpperCaseV3Test is Test {
    /// Every heck character class, the bytes either side of each ASCII letter
    /// and digit range, and bytes above ASCII.
    bytes constant CASE_ALPHABET = "aAzZbB09/:_- \t\n\x0b\x0c\r.@[`{\x1c\x00\x7f\x80\xc1\xe1\xff";

    function upperCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.upperCaseV3(intOrAString);
    }

    function checkUpperCase(bytes memory s, uint256 garbage) internal {
        bytes memory expected = LibStringReference.upperCase(s);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString dirty = LibStringFuzz.dirtyV3(a, garbage);
        if (expected.length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.upperCaseV3External(a);
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.upperCaseV3External(dirty);
        } else {
            uint256 canonical = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected)));
            assertEq(IntOrAString.unwrap(LibIntOrAString.upperCaseV3(a)), canonical);
            assertEq(IntOrAString.unwrap(LibIntOrAString.upperCaseV3(dirty)), canonical);
        }
    }

    function checkV3(bytes memory s, bytes memory expected) internal {
        assertEq(LibStringReference.upperCase(s), expected);
        checkUpperCase(s, 0);
    }

    function testUpperCaseV3Reference(bytes32 data, uint256 length, uint256 garbage) external {
        checkUpperCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), CASE_ALPHABET), garbage);
    }

    function testUpperCaseV3ReferenceAnyBytes(bytes32 data, uint256 length, uint256 garbage) external {
        checkUpperCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), ""), garbage);
    }

    function testUpperCaseV3Empty() external {
        checkV3("", "");
    }

    function testUpperCaseV3Letters() external {
        checkV3("abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        checkV3("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        checkV3("fooBar", "FOOBAR");
        checkV3("Foo_Bar-1", "FOO_BAR-1");
    }

    function testUpperCaseV3NonLetters() external {
        checkV3("@[`{", "@[`{");
        checkV3("0123456789 -_.\t", "0123456789 -_.\t");
        checkV3("\x00\x7f\x80\xc1\xe1\xff", "\x00\x7f\x80\xc1\xe1\xff");
    }

    function testUpperCaseV3ThirtyOneBytes() external {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "ABCDEFGHIJKLMNOPQRSTUVWXYZ01234");
    }
}
