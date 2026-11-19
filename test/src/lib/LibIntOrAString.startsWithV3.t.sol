// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {LibAffix} from "rain-string-0.3.11/src/lib/affix/LibAffix.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibStringFuzz, AFFIX_PREFIX} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringStartsWithV3Test is Test {
    function checkStartsWith(bytes memory s, bytes memory prefix, uint256 sGarbage, uint256 prefixGarbage)
        internal
        pure
    {
        bool expected = LibAffix.startsWith(s, prefix);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString b = LibIntOrAString.fromStringV3(string(prefix));
        assertEq(LibIntOrAString.startsWithV3(a, b), expected);
        assertEq(
            LibIntOrAString.startsWithV3(LibStringFuzz.dirtyV3(a, sGarbage), LibStringFuzz.dirtyV3(b, prefixGarbage)),
            expected
        );
    }

    function testStartsWithV3Reference(
        bytes32 sData,
        uint256 sLength,
        bytes32 prefixData,
        uint256 prefixLength,
        uint256 sGarbage,
        uint256 prefixGarbage
    ) external pure {
        checkStartsWith(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), "ab"),
            LibStringFuzz.fuzzBytes(prefixData, bound(prefixLength, 0, 31), "ab"),
            sGarbage,
            prefixGarbage
        );
    }

    function testStartsWithV3ReferenceAnyBytes(
        bytes32 sData,
        uint256 sLength,
        bytes32 prefixData,
        uint256 prefixLength,
        uint256 sGarbage,
        uint256 prefixGarbage
    ) external pure {
        checkStartsWith(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), ""),
            LibStringFuzz.fuzzBytes(prefixData, bound(prefixLength, 0, 31), ""),
            sGarbage,
            prefixGarbage
        );
    }

    /// The prefix is taken from `s` itself, sometimes with one byte changed.
    function testStartsWithV3ReferenceOwnPrefix(
        bytes32 data,
        uint256 length,
        uint256 affixLength,
        uint256 changeIndex,
        bytes1 change,
        uint256 sGarbage,
        uint256 prefixGarbage
    ) external pure {
        bytes memory s = LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), "");
        bytes memory prefix = LibStringReference.slice(s, 0, bound(affixLength, 0, s.length));
        if (prefix.length > 0) {
            prefix[changeIndex % prefix.length] ^= change;
        }
        checkStartsWith(s, prefix, sGarbage, prefixGarbage);
    }

    function checkStartsWithDifferential(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 prefixLength,
        uint256 seed,
        uint256[2] memory garbage,
        bool ascii
    ) internal pure {
        bytes memory s = LibStringFuzz.fuzzBytes(data[0], bound(sLength, 0, 31), ascii);
        bytes memory prefix = LibStringFuzz.fuzzAffix(
            s, LibStringFuzz.fuzzBytes(data[1], bound(prefixLength, 0, 31), ascii), AFFIX_PREFIX, seed, ascii
        );
        checkStartsWith(s, prefix, garbage[0], garbage[1]);
    }

    /// Expected from rain.string `LibAffix.startsWith`.
    function testStartsWithV3DifferentialAscii(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 prefixLength,
        uint256 seed,
        uint256[2] memory garbage
    ) external pure {
        checkStartsWithDifferential(data, sLength, prefixLength, seed, garbage, true);
    }

    /// Expected from rain.string `LibAffix.startsWith`.
    function testStartsWithV3DifferentialAnyBytes(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 prefixLength,
        uint256 seed,
        uint256[2] memory garbage
    ) external pure {
        checkStartsWithDifferential(data, sLength, prefixLength, seed, garbage, false);
    }

    function testStartsWithV3Empty() external pure {
        checkV3("", "", true);
        checkV3("a", "", true);
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "", true);
        checkV3("", "a", false);
    }

    function testStartsWithV3ThirtyOneBytes() external pure {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", true);
        checkV3("abcdefghijklmnopqrstuvwxyz0123", "abcdefghijklmnopqrstuvwxyz01234", false);
        checkV3("bcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", false);
    }

    function testStartsWithV3IgnoresBytesAboveLength() external pure {
        // "bc" with "a" above its length.
        IntOrAString s = IntOrAString.wrap(0x616263e2);
        assertFalse(LibIntOrAString.startsWithV3(s, LibIntOrAString.fromStringV3("abc")));
        assertFalse(LibIntOrAString.startsWithV3(s, LibIntOrAString.fromStringV3("a")));
        assertTrue(LibIntOrAString.startsWithV3(s, LibIntOrAString.fromStringV3("b")));
        assertTrue(LibIntOrAString.startsWithV3(s, LibIntOrAString.fromStringV3("bc")));
        // "t" with "x" above its length.
        assertTrue(LibIntOrAString.startsWithV3(LibIntOrAString.fromStringV3("tAAPL"), IntOrAString.wrap(0x7874e1)));
    }

    function checkV3(bytes memory s, bytes memory prefix, bool expected) internal pure {
        assertEq(LibAffix.startsWith(s, prefix), expected);
        checkStartsWith(s, prefix, 0, 0);
    }
}
