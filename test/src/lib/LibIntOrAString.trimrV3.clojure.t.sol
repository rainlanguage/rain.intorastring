// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";

contract LibIntOrAStringTrimrV3ClojureTest is ClojureStringOracleTest {
    function trimrV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.trimrV3(intOrAString);
    }

    /// Expected from `clojure.string/trimr`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimrV3ClojureAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimrV3External, "trimr", fuzzString(data0, data1, length, true));
    }

    /// Expected from `clojure.string/trimr`.
    /// forge-config: default.fuzz.runs = 1000
    function testTrimrV3ClojureAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.trimrV3External, "trimr", fuzzString(data0, data1, length, false));
    }
}
