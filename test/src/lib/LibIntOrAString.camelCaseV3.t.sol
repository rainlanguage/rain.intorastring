// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringCamelCaseV3Test is Test {
    /// Every camel-snake-kebab character class, the bytes either side of each
    /// ASCII letter range, and bytes above ASCII.
    bytes constant CASE_ALPHABET = "aAzZbB09_- \t\n\x0b\x0c\r.@[`{\x1c\x00\x80\xc1\xe1\xff";

    function camelCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.camelCaseV3(intOrAString);
    }

    function checkCamelCase(bytes memory s, uint256 garbage) internal {
        bytes memory expected = LibStringReference.camelCase(s);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString dirty = LibStringFuzz.dirtyV3(a, garbage);
        if (expected.length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.camelCaseV3External(a);
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.camelCaseV3External(dirty);
        } else {
            uint256 canonical = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected)));
            assertEq(IntOrAString.unwrap(LibIntOrAString.camelCaseV3(a)), canonical);
            assertEq(IntOrAString.unwrap(LibIntOrAString.camelCaseV3(dirty)), canonical);
        }
    }

    function checkV3(bytes memory s, bytes memory expected) internal {
        assertEq(LibStringReference.camelCase(s), expected);
        checkCamelCase(s, 0);
    }

    function testCamelCaseV3Reference(bytes32 data, uint256 length, uint256 garbage) external {
        checkCamelCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), CASE_ALPHABET), garbage);
    }

    function testCamelCaseV3ReferenceAnyBytes(bytes32 data, uint256 length, uint256 garbage) external {
        checkCamelCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), ""), garbage);
    }

    function testCamelCaseV3Empty() external {
        checkV3("", "");
    }

    function testCamelCaseV3Separators() external {
        checkV3("   ", "");
        checkV3("-_ \t\n\x0b\x0c\r", "");
        checkV3(" x ", "x");
        checkV3("foo bar", "fooBar");
        checkV3("foo\n\tbar", "fooBar");
    }

    function testCamelCaseV3WordBoundaries() external {
        checkV3("fooBar", "fooBar");
        checkV3("FooBar", "fooBar");
        checkV3("FOO_BAR", "fooBar");
        checkV3("foo_bar", "fooBar");
        checkV3("foo-bar", "fooBar");
        checkV3("Foo_Bar", "fooBar");
        checkV3("IPAddress", "ipAddress");
        checkV3("HTTPServer", "httpServer");
        checkV3("Adler32", "adler32");
        checkV3("Inet4Address", "inet4Address");
        checkV3("Arc2D", "arc2D");
        checkV3("a123b", "a123b");
        checkV3("A123B", "a123B");
        checkV3("flux-capacitor", "fluxCapacitor");
        checkV3("I am constant", "iAmConstant");
        checkV3("object_id", "objectId");
    }

    function testCamelCaseV3NonLetters() external {
        checkV3("x.Y", "x.Y");
        checkV3("a\x1cb", "a\x1cb");
        checkV3("@A[", "@A[");
        checkV3("`a{", "`a{");
        checkV3("\xc1\xe1", "\xc1\xe1");
        checkV3("\x80Z", "\x80Z");
        checkV3("0123456789", "0123456789");
    }

    function testCamelCaseV3ThirtyOneBytes() external {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234");
        checkV3("ABCDEFGHIJKLMNOPQRSTUVWXYZ01234", "abcdefghijklmnopqrstuvwxyz01234");
        checkV3("1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1", "1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1");
    }
}
