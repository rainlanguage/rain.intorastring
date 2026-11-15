// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";

contract LibIntOrAStringTrimlV3ClojureTest is ClojureStringOracleTest {
    function trimlV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.trimlV3(intOrAString);
    }

    /// Expected from `clojure.string/triml`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimlV3ClojureAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimlV3External, "triml", fuzzString(data0, data1, length, true));
    }

    /// Expected from `clojure.string/triml`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimlV3ClojureAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimlV3External, "triml", fuzzString(data0, data1, length, false));
    }
}
