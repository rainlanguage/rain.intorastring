// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringPascalCaseV3Test is Test {
    /// Every camel-snake-kebab character class, the bytes either side of each
    /// ASCII letter range, and bytes above ASCII.
    bytes constant CASE_ALPHABET = "aAzZbB09_- \t\n\x0b\x0c\r.@[`{\x1c\x00\x80\xc1\xe1\xff";

    function pascalCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.pascalCaseV3(intOrAString);
    }

    function checkPascalCase(bytes memory s, uint256 garbage) internal {
        bytes memory expected = LibStringReference.pascalCase(s);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString dirty = LibStringFuzz.dirtyV3(a, garbage);
        if (expected.length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.pascalCaseV3External(a);
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.pascalCaseV3External(dirty);
        } else {
            uint256 canonical = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected)));
            assertEq(IntOrAString.unwrap(LibIntOrAString.pascalCaseV3(a)), canonical);
            assertEq(IntOrAString.unwrap(LibIntOrAString.pascalCaseV3(dirty)), canonical);
        }
    }

    function checkV3(bytes memory s, bytes memory expected) internal {
        assertEq(LibStringReference.pascalCase(s), expected);
        checkPascalCase(s, 0);
    }

    function testPascalCaseV3Reference(bytes32 data, uint256 length, uint256 garbage) external {
        checkPascalCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), CASE_ALPHABET), garbage);
    }

    function testPascalCaseV3ReferenceAnyBytes(bytes32 data, uint256 length, uint256 garbage) external {
        checkPascalCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), ""), garbage);
    }

    function testPascalCaseV3Empty() external {
        checkV3("", "");
    }

    function testPascalCaseV3Separators() external {
        checkV3("   ", "");
        checkV3("-_ \t\n\x0b\x0c\r", "");
        checkV3(" x ", "X");
        checkV3("foo bar", "FooBar");
        checkV3("foo\n\tbar", "FooBar");
    }

    function testPascalCaseV3WordBoundaries() external {
        checkV3("fooBar", "FooBar");
        checkV3("FooBar", "FooBar");
        checkV3("FOO_BAR", "FooBar");
        checkV3("foo_bar", "FooBar");
        checkV3("foo-bar", "FooBar");
        checkV3("Foo_Bar", "FooBar");
        checkV3("IPAddress", "IpAddress");
        checkV3("HTTPServer", "HttpServer");
        checkV3("Adler32", "Adler32");
        checkV3("Inet4Address", "Inet4Address");
        checkV3("Arc2D", "Arc2D");
        checkV3("a123b", "A123b");
        checkV3("A123B", "A123B");
        checkV3("flux-capacitor", "FluxCapacitor");
        checkV3("I am constant", "IAmConstant");
        checkV3("object_id", "ObjectId");
    }

    function testPascalCaseV3NonLetters() external {
        checkV3("x.Y", "X.Y");
        checkV3("a\x1cb", "A\x1cb");
        checkV3("@A[", "@A[");
        checkV3("`a{", "`a{");
        checkV3("\xc1\xe1", "\xc1\xe1");
        checkV3("\x80Z", "\x80Z");
        checkV3("0123456789", "0123456789");
    }

    function testPascalCaseV3ThirtyOneBytes() external {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "Abcdefghijklmnopqrstuvwxyz01234");
        checkV3("ABCDEFGHIJKLMNOPQRSTUVWXYZ01234", "Abcdefghijklmnopqrstuvwxyz01234");
        checkV3("1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1", "1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1");
    }
}
