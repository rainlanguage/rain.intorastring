// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";

contract LibIntOrAStringTrimrV3RustTest is RustStringOracleTest {
    function trimrV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.trimrV3(intOrAString);
    }

    /// Expected from Rust `[u8]::trim_ascii_end`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimrV3RustAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimrV3External, "trimr", fuzzString(data0, data1, length, true));
    }

    /// Expected from Rust `[u8]::trim_ascii_end`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimrV3RustAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimrV3External, "trimr", fuzzString(data0, data1, length, false));
    }
}
