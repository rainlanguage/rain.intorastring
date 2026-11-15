// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";
import {LibStringFuzz, AFFIX_SUFFIX} from "test/lib/LibStringFuzz.sol";

contract LibIntOrAStringStripSuffixV3ClojureTest is ClojureStringOracleTest {
    function stripSuffixV3External(IntOrAString intOrAString, IntOrAString affix) external pure returns (IntOrAString) {
        return LibIntOrAString.stripSuffixV3(intOrAString, affix);
    }

    function checkStripSuffix(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed, bool ascii)
        internal
    {
        bytes memory s = fuzzString(data[0], data[1], sLength, ascii);
        bytes memory x =
            LibStringFuzz.fuzzAffix(s, fuzzString(data[2], data[3], xLength, ascii), AFFIX_SUFFIX, seed, ascii);
        checkString(this.stripSuffixV3External, "strip-suffix", s, x);
    }

    /// Expected from cuerdas `strip-suffix`.
    /// forge-config: default.fuzz.runs = 1000
    function testStripSuffixV3ClojureAscii(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkStripSuffix(data, sLength, xLength, seed, true);
    }

    /// Expected from cuerdas `strip-suffix`.
    /// forge-config: default.fuzz.runs = 1000
    function testStripSuffixV3ClojureAnyBytes(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkStripSuffix(data, sLength, xLength, seed, false);
    }
}
