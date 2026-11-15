// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";
import {LibStringFuzz, AFFIX_INNER} from "test/lib/LibStringFuzz.sol";

contract LibIntOrAStringIncludesV3ClojureTest is ClojureStringOracleTest {
    function checkIncludes(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed, bool ascii)
        internal
    {
        bytes memory s = fuzzString(data[0], data[1], sLength, ascii);
        bytes memory x =
            LibStringFuzz.fuzzAffix(s, fuzzString(data[2], data[3], xLength, ascii), AFFIX_INNER, seed, ascii);
        checkPredicate(LibIntOrAString.includesV3, "includes?", s, x);
    }

    /// Expected from `clojure.string/includes?`.
    /// forge-config: default.fuzz.runs = 1000
    function testIncludesV3ClojureAscii(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkIncludes(data, sLength, xLength, seed, true);
    }

    /// Expected from `clojure.string/includes?`.
    /// forge-config: default.fuzz.runs = 1000
    function testIncludesV3ClojureAnyBytes(bytes32[4] memory data, uint256 sLength, uint256 xLength, uint256 seed)
        external
    {
        checkIncludes(data, sLength, xLength, seed, false);
    }
}
