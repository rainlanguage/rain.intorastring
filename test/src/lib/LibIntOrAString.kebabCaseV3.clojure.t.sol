// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";

contract LibIntOrAStringKebabCaseV3ClojureTest is ClojureStringOracleTest {
    function kebabCaseV3External(IntOrAString intOrAString) external pure returns (IntOrAString) {
        return LibIntOrAString.kebabCaseV3(intOrAString);
    }

    /// Expected from camel-snake-kebab `->kebab-case`.
    /// forge-config: default.fuzz.runs = 1000
    function testKebabCaseV3ClojureAscii(bytes32 data0, bytes32 data1, uint256 length) external {
        checkString(this.kebabCaseV3External, "kebab-case", fuzzString(data0, data1, length, true));
    }

    /// All ASCII input as camel-snake-kebab `->kebab-case`; bytes from 0x80 unchanged in place.
    /// forge-config: default.fuzz.runs = 1000
    function testKebabCaseV3ClojureAnyBytes(bytes32 data0, bytes32 data1, uint256 length) external {
        checkCase(this.kebabCaseV3External, "kebab-case", fuzzString(data0, data1, length, false));
    }
}
