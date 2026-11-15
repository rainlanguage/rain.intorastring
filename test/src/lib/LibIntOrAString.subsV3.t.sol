// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {IntOrAStringSubsOutOfRange} from "src/error/ErrIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringSubsV3Test is Test {
    function subsV3External(IntOrAString intOrAString, uint256 start, uint256 end)
        external
        pure
        returns (IntOrAString)
    {
        return LibIntOrAString.subsV3(intOrAString, start, end);
    }

    function checkSubs(bytes memory s, uint256 start, uint256 end, uint256 garbage) internal pure {
        uint256 expected =
            IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(LibStringReference.slice(s, start, end))));
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        assertEq(IntOrAString.unwrap(LibIntOrAString.subsV3(a, start, end)), expected);
        assertEq(IntOrAString.unwrap(LibIntOrAString.subsV3(LibStringFuzz.dirtyV3(a, garbage), start, end)), expected);
    }

    function checkSubsOutOfRange(bytes memory s, uint256 start, uint256 end, uint256 garbage) internal {
        IntOrAString a = LibStringFuzz.dirtyV3(LibIntOrAString.fromStringV3(string(s)), garbage);
        vm.expectRevert(abi.encodeWithSelector(IntOrAStringSubsOutOfRange.selector, start, end, s.length));
        this.subsV3External(a, start, end);
    }

    function testSubsV3Reference(bytes32 data, uint256 length, uint256 start, uint256 end, uint256 garbage)
        external
        pure
    {
        bytes memory s = LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), "");
        end = bound(end, 0, s.length);
        start = bound(start, 0, end);
        checkSubs(s, start, end, garbage);
    }

    function testSubsV3EndPastLength(bytes32 data, uint256 length, uint256 start, uint256 end, uint256 garbage)
        external
    {
        bytes memory s = LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), "");
        end = bound(end, s.length + 1, type(uint256).max);
        checkSubsOutOfRange(s, start, end, garbage);
    }

    function testSubsV3StartPastEnd(bytes32 data, uint256 length, uint256 start, uint256 end, uint256 garbage)
        external
    {
        bytes memory s = LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), "");
        end = bound(end, 0, s.length);
        start = bound(start, end + 1, type(uint256).max);
        checkSubsOutOfRange(s, start, end, garbage);
    }

    function testSubsV3Empty() external {
        checkSubs("", 0, 0, 0);
        checkSubs("a", 0, 0, 0);
        checkSubs("a", 1, 1, 0);
        checkSubsOutOfRange("", 0, 1, 0);
        checkSubsOutOfRange("", 1, 0, 0);
        checkSubsOutOfRange("", 1, 1, 0);
    }

    function testSubsV3ThirtyOneBytes() external {
        bytes memory s = "abcdefghijklmnopqrstuvwxyz01234";
        checkSubs(s, 0, 31, 0);
        checkSubs(s, 31, 31, 0);
        checkSubs(s, 30, 31, 0);
        checkSubs(s, 0, 1, 0);
        assertEq(
            LibIntOrAString.toStringV3(LibIntOrAString.subsV3(LibIntOrAString.fromStringV3(string(s)), 26, 31)), "01234"
        );
        checkSubsOutOfRange(s, 0, 32, 0);
        checkSubsOutOfRange(s, 32, 32, 0);
        checkSubsOutOfRange(s, 31, 30, 0);
        checkSubsOutOfRange(s, type(uint256).max, type(uint256).max, 0);
        checkSubsOutOfRange(s, 0, type(uint256).max, 0);
        checkSubsOutOfRange(s, type(uint256).max, 0, 0);
    }
}
