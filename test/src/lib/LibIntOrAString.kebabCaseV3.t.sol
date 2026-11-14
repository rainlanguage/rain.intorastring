// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringKebabCaseV3Test is Test {
    /// Every camel-snake-kebab character class, the bytes either side of each
    /// ASCII letter range, and bytes above ASCII.
    bytes constant CASE_ALPHABET = "aAzZbB09_- \t\n\x0b\x0c\r.@[`{\x1c\x00\x80\xc1\xe1\xff";

    function kebabCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.kebabCaseV3(intOrAString);
    }

    function checkKebabCase(bytes memory s, uint256 garbage) internal {
        bytes memory expected = LibStringReference.kebabCase(s);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString dirty = LibStringFuzz.dirtyV3(a, garbage);
        if (expected.length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.kebabCaseV3External(a);
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.kebabCaseV3External(dirty);
        } else {
            uint256 canonical = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected)));
            assertEq(IntOrAString.unwrap(LibIntOrAString.kebabCaseV3(a)), canonical);
            assertEq(IntOrAString.unwrap(LibIntOrAString.kebabCaseV3(dirty)), canonical);
        }
    }

    function checkV3(bytes memory s, bytes memory expected) internal {
        assertEq(LibStringReference.kebabCase(s), expected);
        checkKebabCase(s, 0);
    }

    function testKebabCaseV3Reference(bytes32 data, uint256 length, uint256 garbage) external {
        checkKebabCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), CASE_ALPHABET), garbage);
    }

    function testKebabCaseV3ReferenceAnyBytes(bytes32 data, uint256 length, uint256 garbage) external {
        checkKebabCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), ""), garbage);
    }

    function testKebabCaseV3Empty() external {
        checkV3("", "");
    }

    function testKebabCaseV3Separators() external {
        checkV3("   ", "");
        checkV3("-_ \t\n\x0b\x0c\r", "");
        checkV3(" x ", "x");
        checkV3("foo bar", "foo-bar");
        checkV3("foo\n\tbar", "foo-bar");
    }

    function testKebabCaseV3WordBoundaries() external {
        checkV3("fooBar", "foo-bar");
        checkV3("FooBar", "foo-bar");
        checkV3("FOO_BAR", "foo-bar");
        checkV3("foo_bar", "foo-bar");
        checkV3("foo-bar", "foo-bar");
        checkV3("Foo_Bar", "foo-bar");
        checkV3("IPAddress", "ip-address");
        checkV3("HTTPServer", "http-server");
        checkV3("Adler32", "adler-32");
        checkV3("Inet4Address", "inet-4-address");
        checkV3("Arc2D", "arc-2-d");
        checkV3("a123b", "a-123b");
        checkV3("A123B", "a-123-b");
        checkV3("flux-capacitor", "flux-capacitor");
        checkV3("I am constant", "i-am-constant");
        checkV3("object_id", "object-id");
    }

    function testKebabCaseV3NonLetters() external {
        checkV3("x.Y", "x.-y");
        checkV3("a\x1cb", "a\x1cb");
        checkV3("@A[", "@-a[");
        checkV3("`a{", "`a{");
        checkV3("\xc1\xe1", "\xc1\xe1");
        checkV3("\x80Z", "\x80-z");
        checkV3("0123456789", "0123456789");
    }

    function testKebabCaseV3ThirtyOneBytes() external {
        checkV3("abcdefghijklmnopqrstuvwxyzABCD", "abcdefghijklmnopqrstuvwxyz-abcd");
    }

    function testKebabCaseV3TooLong() external {
        checkTooLong("abcdefghijklmnopqrstuvwxyzABCDE", 32);
        checkTooLong("abcdefghijklmnopqrstuvwxyz01234", 32);
        checkTooLong("1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1", 61);
    }

    function checkTooLong(bytes memory s, uint256 length) internal {
        assertEq(LibStringReference.kebabCase(s).length, length);
        vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, length));
        this.kebabCaseV3External(LibIntOrAString.fromStringV3(string(s)));
    }
}
