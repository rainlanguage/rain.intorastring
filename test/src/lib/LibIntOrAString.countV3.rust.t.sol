// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";

contract LibIntOrAStringCountV3RustTest is RustStringOracleTest {
    function checkCount(bytes memory s) internal {
        (bool isV3, IntOrAString a) = toV3(s);
        if (!isV3) {
            return;
        }
        assertEq(LibIntOrAString.countV3(a), abi.decode(rust("count", s), (uint256)));
    }

    /// Expected from Rust `[u8]::len`.
    /// forge-config: default.fuzz.runs = 1000
    function testCountV3RustAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkCount(fuzzString(data0, data1, length, true));
    }

    /// Expected from Rust `[u8]::len`.
    /// forge-config: default.fuzz.runs = 1000
    function testCountV3RustAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkCount(fuzzString(data0, data1, length, false));
    }
}
