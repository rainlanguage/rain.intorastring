// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";

contract LibIntOrAStringCountV3Test is Test {
    function testCountV3Reference(bytes32 data, uint256 length, uint256 garbage) external pure {
        bytes memory s = LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), "");
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        assertEq(LibIntOrAString.countV3(a), s.length);
        assertEq(LibIntOrAString.countV3(LibStringFuzz.dirtyV3(a, garbage)), s.length);
    }

    function testCountV3Raw(IntOrAString a) external pure {
        assertEq(LibIntOrAString.countV3(a), bytes(LibIntOrAString.toStringV3(a)).length);
    }

    function testCountV3Empty() external pure {
        assertEq(LibIntOrAString.countV3(LibIntOrAString.fromStringV3("")), 0);
        assertEq(LibIntOrAString.countV3(IntOrAString.wrap(0)), 0);
        assertEq(LibIntOrAString.countV3(IntOrAString.wrap(type(uint256).max << 5)), 0);
    }

    function testCountV3ThirtyOneBytes() external pure {
        assertEq(LibIntOrAString.countV3(LibIntOrAString.fromStringV3("abcdefghijklmnopqrstuvwxyz01234")), 31);
        assertEq(LibIntOrAString.countV3(IntOrAString.wrap(type(uint256).max)), 31);
    }
}
