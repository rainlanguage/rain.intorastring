// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {ClojureStringOracleTest} from "test/abstract/ClojureStringOracleTest.sol";
import {IntOrAStringSubsOutOfRange} from "src/error/ErrIntOrAString.sol";

contract LibIntOrAStringSubsV3ClojureTest is ClojureStringOracleTest {
    function subsV3External(IntOrAString intOrAString, uint256 start, uint256 end)
        external
        pure
        returns (IntOrAString)
    {
        return LibIntOrAString.subsV3(intOrAString, start, end);
    }

    function checkSubs(bytes memory s, uint256 start, uint256 end) internal {
        (bool isV3, IntOrAString a) = toV3(s);
        if (!isV3) {
            return;
        }
        (bool ok, bytes memory expected) = clojureSubs(s, start, end);
        try this.subsV3External(a, start, end) returns (IntOrAString actual) {
            assertTrue(ok, "Clojure subs threw");
            assertResult(expected, actual);
        } catch (bytes memory err) {
            assertFalse(ok, "Clojure subs returned");
            assertEq(err, abi.encodeWithSelector(IntOrAStringSubsOutOfRange.selector, start, end, s.length));
        }
    }

    /// Expected from Clojure `subs`, which throws out of range.
    /// forge-config: default.fuzz.runs = 1000
    function testSubsV3ClojureAscii(bytes32 data0, bytes32 data1, uint256 length, uint256 start, uint256 end) external {
        checkSubs(
            fuzzString(data0, data1, length, true), bound(start, 0, MAX_FUZZ_LENGTH), bound(end, 0, MAX_FUZZ_LENGTH)
        );
    }

    /// Expected from Clojure `subs`, which throws out of range.
    /// forge-config: default.fuzz.runs = 1000
    function testSubsV3ClojureAnyBytes(bytes32 data0, bytes32 data1, uint256 length, uint256 start, uint256 end)
        external
    {
        checkSubs(
            fuzzString(data0, data1, length, false), bound(start, 0, MAX_FUZZ_LENGTH), bound(end, 0, MAX_FUZZ_LENGTH)
        );
    }
}
