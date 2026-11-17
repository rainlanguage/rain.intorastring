// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";

contract LibIntOrAStringLowerCaseV3RustTest is RustStringOracleTest {
    function lowerCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.lowerCaseV3(intOrAString);
    }

    /// Expected from Rust `[u8]::to_ascii_lowercase`.
    /// forge-config: default.fuzz.runs = 1000
    function testLowerCaseV3RustAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.lowerCaseV3External, "lower-case", fuzzString(data0, data1, length, true));
    }

    /// Expected from Rust `[u8]::to_ascii_lowercase`.
    /// forge-config: default.fuzz.runs = 1000
    function testLowerCaseV3RustAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.lowerCaseV3External, "lower-case", fuzzString(data0, data1, length, false));
    }
}
