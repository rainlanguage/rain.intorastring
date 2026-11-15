// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringSnakeCaseV3Test is Test {
    /// Every camel-snake-kebab character class, the bytes either side of each
    /// ASCII letter range, and bytes above ASCII.
    bytes constant CASE_ALPHABET = "aAzZbB09_- \t\n\x0b\x0c\r.@[`{\x1c\x00\x80\xc1\xe1\xff";

    function snakeCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.snakeCaseV3(intOrAString);
    }

    function checkSnakeCase(bytes memory s, uint256 garbage) internal {
        bytes memory expected = LibStringReference.snakeCase(s);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString dirty = LibStringFuzz.dirtyV3(a, garbage);
        if (expected.length > 31) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.snakeCaseV3External(a);
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
            this.snakeCaseV3External(dirty);
        } else {
            uint256 canonical = IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected)));
            assertEq(IntOrAString.unwrap(LibIntOrAString.snakeCaseV3(a)), canonical);
            assertEq(IntOrAString.unwrap(LibIntOrAString.snakeCaseV3(dirty)), canonical);
        }
    }

    function checkV3(bytes memory s, bytes memory expected) internal {
        assertEq(LibStringReference.snakeCase(s), expected);
        checkSnakeCase(s, 0);
    }

    function testSnakeCaseV3Reference(bytes32 data, uint256 length, uint256 garbage) external {
        checkSnakeCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), CASE_ALPHABET), garbage);
    }

    function testSnakeCaseV3ReferenceAnyBytes(bytes32 data, uint256 length, uint256 garbage) external {
        checkSnakeCase(LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), ""), garbage);
    }

    function testSnakeCaseV3Empty() external {
        checkV3("", "");
    }

    function testSnakeCaseV3Separators() external {
        checkV3("   ", "");
        checkV3("-_ \t\n\x0b\x0c\r", "");
        checkV3(" x ", "x");
        checkV3("foo bar", "foo_bar");
        checkV3("foo\n\tbar", "foo_bar");
    }

    function testSnakeCaseV3WordBoundaries() external {
        checkV3("fooBar", "foo_bar");
        checkV3("FooBar", "foo_bar");
        checkV3("FOO_BAR", "foo_bar");
        checkV3("foo_bar", "foo_bar");
        checkV3("foo-bar", "foo_bar");
        checkV3("Foo_Bar", "foo_bar");
        checkV3("IPAddress", "ip_address");
        checkV3("HTTPServer", "http_server");
        checkV3("Adler32", "adler_32");
        checkV3("Inet4Address", "inet_4_address");
        checkV3("Arc2D", "arc_2_d");
        checkV3("a123b", "a_123b");
        checkV3("A123B", "a_123_b");
        checkV3("flux-capacitor", "flux_capacitor");
        checkV3("I am constant", "i_am_constant");
        checkV3("object_id", "object_id");
    }

    function testSnakeCaseV3NonLetters() external {
        checkV3("x.Y", "x._y");
        checkV3("a\x1cb", "a\x1cb");
        checkV3("@A[", "@_a[");
        checkV3("`a{", "`a{");
        checkV3("\xc1\xe1", "\xc1\xe1");
        checkV3("\x80Z", "\x80_z");
        checkV3("0123456789", "0123456789");
    }

    function testSnakeCaseV3ThirtyOneBytes() external {
        checkV3("abcdefghijklmnopqrstuvwxyzABCD", "abcdefghijklmnopqrstuvwxyz_abcd");
    }

    function testSnakeCaseV3TooLong() external {
        checkTooLong("abcdefghijklmnopqrstuvwxyzABCDE", 32);
        checkTooLong("abcdefghijklmnopqrstuvwxyz01234", 32);
        checkTooLong("1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1", 61);
    }

    function checkTooLong(bytes memory s, uint256 length) internal {
        assertEq(LibStringReference.snakeCase(s).length, length);
        vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, length));
        this.snakeCaseV3External(LibIntOrAString.fromStringV3(string(s)));
    }
}

contract LibIntOrAStringSnakeCaseV3ClojureTest is ClojureStringOracleTest {
    function snakeCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.snakeCaseV3(intOrAString);
    }

    /// Expected from camel-snake-kebab `->snake_case`.
    /// forge-config: default.fuzz.runs = 1000
    function testSnakeCaseV3ClojureAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.snakeCaseV3External, "snake-case", fuzzString(data0, data1, length, true));
    }

    /// Expected from camel-snake-kebab `->snake_case`.
    /// forge-config: default.fuzz.runs = 1000
    function testSnakeCaseV3ClojureAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.snakeCaseV3External, "snake-case", fuzzString(data0, data1, length, false));
    }
}
