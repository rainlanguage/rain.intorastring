// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";

contract LibIntOrAStringTrimV3RustTest is RustStringOracleTest {
    function trimV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.trimV3(intOrAString);
    }

    /// Expected from Rust `[u8]::trim_ascii`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimV3RustAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimV3External, "trim", fuzzString(data0, data1, length, true));
    }

    /// Expected from Rust `[u8]::trim_ascii`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimV3RustAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimV3External, "trim", fuzzString(data0, data1, length, false));
    }
}
