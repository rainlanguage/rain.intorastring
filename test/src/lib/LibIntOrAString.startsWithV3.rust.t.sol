// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";
import {LibStringFuzz, AFFIX_PREFIX} from "test/lib/LibStringFuzz.sol";

contract LibIntOrAStringStartsWithV3RustTest is RustStringOracleTest {
    function checkStartsWith(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed, bool ascii)
        internal
    {
        bytes memory s = fuzzString(data[0], data[1], sLength, ascii);
        bytes memory x =
            LibStringFuzz.fuzzAffix(s, fuzzString(data[2], data[3], xLength, ascii), AFFIX_PREFIX, seed, ascii);
        checkPredicate(LibIntOrAString.startsWithV3, "starts-with?", s, x);
    }

    /// Expected from Rust `[u8]::starts_with`.
    /// forge-config: default.fuzz.runs = 1000
    function testStartsWithV3RustAscii(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkStartsWith(data, sLength, xLength, seed, true);
    }

    /// Expected from Rust `[u8]::starts_with`.
    /// forge-config: default.fuzz.runs = 1000
    function testStartsWithV3RustAnyBytes(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkStartsWith(data, sLength, xLength, seed, false);
    }
}
