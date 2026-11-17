// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";
import {LibStringFuzz, AFFIX_SUFFIX} from "test/lib/LibStringFuzz.sol";

contract LibIntOrAStringEndsWithV3RustTest is RustStringOracleTest {
    function checkEndsWith(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed, bool ascii)
        internal
    {
        bytes memory s = fuzzString(data[0], data[1], sLength, ascii);
        bytes memory x =
            LibStringFuzz.fuzzAffix(s, fuzzString(data[2], data[3], xLength, ascii), AFFIX_SUFFIX, seed, ascii);
        checkPredicate(LibIntOrAString.endsWithV3, "ends-with?", s, x);
    }

    /// Expected from Rust `[u8]::ends_with`.
    /// forge-config: default.fuzz.runs = 1000
    function testEndsWithV3RustAscii(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed) external {
        checkEndsWith(data, sLength, xLength, seed, true);
    }

    /// Expected from Rust `[u8]::ends_with`.
    /// forge-config: default.fuzz.runs = 1000
    function testEndsWithV3RustAnyBytes(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkEndsWith(data, sLength, xLength, seed, false);
    }
}
