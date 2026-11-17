// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";

contract LibIntOrAStringConcatV3RustTest is RustStringOracleTest {
    function concatV3External(IntOrAString a, IntOrAString b) external pure returns (IntOrAString) {
        return LibIntOrAString.concatV3(a, b);
    }

    /// Expected from Rust `[u8]::concat`.
    /// forge-config: default.fuzz.runs = 1000
    function testConcatV3RustAscii(bytes32[4] memory data, uint256 aLength, uint256 bLength) external {
        checkString(
            this.concatV3External,
            "str",
            fuzzString(data[0], data[1], aLength, true),
            fuzzString(data[2], data[3], bLength, true)
        );
    }

    /// Expected from Rust `[u8]::concat`.
    /// forge-config: default.fuzz.runs = 1000
    function testConcatV3RustAnyBytes(bytes32[4] memory data, uint256 aLength, uint256 bLength) external {
        checkString(
            this.concatV3External,
            "str",
            fuzzString(data[0], data[1], aLength, false),
            fuzzString(data[2], data[3], bLength, false)
        );
    }
}
