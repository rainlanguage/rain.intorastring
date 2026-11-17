// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {RustStringOracleTest} from "test/abstract/RustStringOracleTest.sol";
import {LibStringFuzz, AFFIX_PREFIX} from "test/lib/LibStringFuzz.sol";

contract LibIntOrAStringStripPrefixV3RustTest is RustStringOracleTest {
    function stripPrefixV3External(IntOrAString intOrAString, IntOrAString affix) external pure returns (IntOrAString) {
        return LibIntOrAString.stripPrefixV3(intOrAString, affix);
    }

    function checkStripPrefix(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed, bool ascii)
        internal
    {
        bytes memory s = fuzzString(data[0], data[1], sLength, ascii);
        bytes memory x =
            LibStringFuzz.fuzzAffix(s, fuzzString(data[2], data[3], xLength, ascii), AFFIX_PREFIX, seed, ascii);
        checkString(this.stripPrefixV3External, "strip-prefix", s, x);
    }

    /// Expected from Rust `[u8]::strip_prefix`.
    /// forge-config: default.fuzz.runs = 1000
    function testStripPrefixV3RustAscii(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkStripPrefix(data, sLength, xLength, seed, true);
    }

    /// Expected from Rust `[u8]::strip_prefix`.
    /// forge-config: default.fuzz.runs = 1000
    function testStripPrefixV3RustAnyBytes(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkStripPrefix(data, sLength, xLength, seed, false);
    }
}
