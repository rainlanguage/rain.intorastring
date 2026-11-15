// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";

contract LibIntOrAStringPascalCaseV3ClojureTest is ClojureStringOracleTest {
    function pascalCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.pascalCaseV3(intOrAString);
    }

    /// Expected from camel-snake-kebab `->PascalCase`.
    /// forge-config: default.fuzz.runs = 1000
    function testPascalCaseV3ClojureAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.pascalCaseV3External, "pascal-case", fuzzString(data0, data1, length, true));
    }

    /// Expected from camel-snake-kebab `->PascalCase`.
    /// forge-config: default.fuzz.runs = 1000
    function testPascalCaseV3ClojureAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.pascalCaseV3External, "pascal-case", fuzzString(data0, data1, length, false));
    }
}
