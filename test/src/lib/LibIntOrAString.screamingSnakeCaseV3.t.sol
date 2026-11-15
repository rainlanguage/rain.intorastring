// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringScreamingSnakeCaseV3Test is Test {
    /// Every camel-snake-kebab character class, the bytes either side of each
    /// ASCII letter range, and bytes above ASCII.
    bytes constant CASE_ALPHABET = "aAzZbB09_- \t\n\x0b\x0c\r.@[`{\x1c\x00\x80\xc1\xe1\xff";

    function screamingSnakeCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.screamingSnakeCaseV3(intOrAString);
    }

    function checkScreamingSnakeCase(bytes memory s, uint256 garbage) internal {
        bytes memory expected = LibStringReference.screamingSnakeCase(s);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString dirty = LibStringFuzz.dirtyV3(a, garbage);
        if (expected.length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.screamingSnakeCaseV3External(a);
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.screamingSnakeCaseV3External(dirty);
        } else {
            uint256 canonical = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected)));
            assertEq(IntOrAString.unwrap(LibIntOrAString.screamingSnakeCaseV3(a)), canonical);
            assertEq(IntOrAString.unwrap(LibIntOrAString.screamingSnakeCaseV3(dirty)), canonical);
        }
    }

    function checkV3(bytes memory s, bytes memory expected) internal {
        assertEq(LibStringReference.screamingSnakeCase(s), expected);
        checkScreamingSnakeCase(s, 0);
    }

    function testScreamingSnakeCaseV3Reference(bytes32 data, uint256 length, uint256 garbage) external {
        checkScreamingSnakeCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), CASE_ALPHABET), garbage);
    }

    function testScreamingSnakeCaseV3ReferenceAnyBytes(bytes32 data, uint256 length, uint256 garbage) external {
        checkScreamingSnakeCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), ""), garbage);
    }

    function testScreamingSnakeCaseV3Empty() external {
        checkV3("", "");
    }

    function testScreamingSnakeCaseV3Separators() external {
        checkV3("   ", "");
        checkV3("-_ \t\n\x0b\x0c\r", "");
        checkV3(" x ", "X");
        checkV3("foo bar", "FOO_BAR");
        checkV3("foo\n\tbar", "FOO_BAR");
    }

    function testScreamingSnakeCaseV3WordBoundaries() external {
        checkV3("fooBar", "FOO_BAR");
        checkV3("FooBar", "FOO_BAR");
        checkV3("FOO_BAR", "FOO_BAR");
        checkV3("foo_bar", "FOO_BAR");
        checkV3("foo-bar", "FOO_BAR");
        checkV3("Foo_Bar", "FOO_BAR");
        checkV3("IPAddress", "IP_ADDRESS");
        checkV3("HTTPServer", "HTTP_SERVER");
        checkV3("Adler32", "ADLER_32");
        checkV3("Inet4Address", "INET_4_ADDRESS");
        checkV3("Arc2D", "ARC_2_D");
        checkV3("a123b", "A_123B");
        checkV3("A123B", "A_123_B");
        checkV3("flux-capacitor", "FLUX_CAPACITOR");
        checkV3("I am constant", "I_AM_CONSTANT");
        checkV3("object_id", "OBJECT_ID");
    }

    function testScreamingSnakeCaseV3NonLetters() external {
        checkV3("x.Y", "X._Y");
        checkV3("a\x1cb", "A\x1cB");
        checkV3("@A[", "@_A[");
        checkV3("`a{", "`A{");
        checkV3("\xc1\xe1", "\xc1\xe1");
        checkV3("\x80Z", "\x80_Z");
        checkV3("0123456789", "0123456789");
    }

    function testScreamingSnakeCaseV3ThirtyOneBytes() external {
        checkV3("abcdefghijklmnopqrstuvwxyzABCD", "ABCDEFGHIJKLMNOPQRSTUVWXYZ_ABCD");
    }

    function testScreamingSnakeCaseV3TooLong() external {
        checkTooLong("abcdefghijklmnopqrstuvwxyzABCDE", 32);
        checkTooLong("abcdefghijklmnopqrstuvwxyz01234", 32);
        checkTooLong("1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1", 61);
    }

    function checkTooLong(bytes memory s, uint256 length) internal {
        assertEq(LibStringReference.screamingSnakeCase(s).length, length);
        vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, length));
        this.screamingSnakeCaseV3External(LibIntOrAString.fromStringV3(string(s)));
    }
}

contract LibIntOrAStringScreamingSnakeCaseV3ClojureTest is ClojureStringOracleTest {
    function screamingSnakeCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.screamingSnakeCaseV3(intOrAString);
    }

    /// Expected from camel-snake-kebab `->SCREAMING_SNAKE_CASE`.
    /// forge-config: default.fuzz.runs = 1000
    function testScreamingSnakeCaseV3ClojureAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.screamingSnakeCaseV3External, "screaming-snake-case", fuzzString(data0, data1, length, true));
    }

    /// Expected from camel-snake-kebab `->SCREAMING_SNAKE_CASE`.
    /// forge-config: default.fuzz.runs = 1000
    function testScreamingSnakeCaseV3ClojureAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.screamingSnakeCaseV3External, "screaming-snake-case", fuzzString(data0, data1, length, false));
    }
}
