// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";

contract LibIntOrAStringSnakeCaseV3RustTest is RustStringOracleTest {
    function snakeCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.snakeCaseV3(intOrAString);
    }

    /// Expected from heck `to_snake_case`.
    /// forge-config: default.fuzz.runs = 1000
    function testSnakeCaseV3RustAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.snakeCaseV3External, "snake-case", fuzzString(data0, data1, length, true));
    }
}
