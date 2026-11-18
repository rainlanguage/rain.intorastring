// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";

contract LibIntOrAStringCamelCaseV3RustTest is RustStringOracleTest {
    function camelCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.camelCaseV3(intOrAString);
    }

    /// Expected from heck `to_lower_camel_case`.
    /// forge-config: default.fuzz.runs = 1000
    function testCamelCaseV3RustAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.camelCaseV3External, "camel-case", fuzzString(data0, data1, length, true));
    }
}
