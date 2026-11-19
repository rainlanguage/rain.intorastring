// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibStringFuzz} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringIncludesV3Test is Test {
    function checkIncludes(bytes memory s, bytes memory needle, uint256 sGarbage, uint256 needleGarbage) internal pure {
        bool expected = LibStringReference.includes(s, needle);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString b = LibIntOrAString.fromStringV3(string(needle));
        assertEq(LibIntOrAString.includesV3(a, b), expected);
        assertEq(
            LibIntOrAString.includesV3(LibStringFuzz.dirtyV3(a, sGarbage), LibStringFuzz.dirtyV3(b, needleGarbage)),
            expected
        );
    }

    function testIncludesV3Reference(
        bytes32 sData,
        uint256 sLength,
        bytes32 needleData,
        uint256 needleLength,
        uint256 sGarbage,
        uint256 needleGarbage
    ) external pure {
        checkIncludes(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), "ab"),
            LibStringFuzz.fuzzBytes(needleData, bound(needleLength, 0, 8), "ab"),
            sGarbage,
            needleGarbage
        );
    }

    function testIncludesV3ReferenceAnyBytes(
        bytes32 sData,
        uint256 sLength,
        bytes32 needleData,
        uint256 needleLength,
        uint256 sGarbage,
        uint256 needleGarbage
    ) external pure {
        checkIncludes(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), ""),
            LibStringFuzz.fuzzBytes(needleData, bound(needleLength, 0, 31), ""),
            sGarbage,
            needleGarbage
        );
    }

    /// The needle is taken from `s` itself, sometimes with one byte changed.
    function testIncludesV3ReferenceOwnSubstring(
        bytes32 data,
        uint256 length,
        uint256 start,
        uint256 end,
        uint256 changeIndex,
        bytes1 change,
        uint256 sGarbage,
        uint256 needleGarbage
    ) external pure {
        bytes memory s = LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), "");
        end = bound(end, 0, s.length);
        bytes memory needle = LibStringReference.slice(s, bound(start, 0, end), end);
        if (needle.length > 0) {
            needle[changeIndex % needle.length] ^= change;
        }
        checkIncludes(s, needle, sGarbage, needleGarbage);
    }

    function testIncludesV3Empty() external pure {
        checkV3("", "", true);
        checkV3("a", "", true);
        checkV3("", "a", false);
    }

    function testIncludesV3ThirtyOneBytes() external pure {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", true);
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "a", true);
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "4", true);
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "z01", true);
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "z02", false);
        checkV3("abcdefghijklmnopqrstuvwxyz0123", "abcdefghijklmnopqrstuvwxyz01234", false);
    }

    function testIncludesV3IgnoresBytesAboveLength() external pure {
        // "bc" with "a" above its length.
        IntOrAString s = IntOrAString.wrap(0x616263e2);
        assertFalse(LibIntOrAString.includesV3(s, LibIntOrAString.fromStringV3("ab")));
        assertFalse(LibIntOrAString.includesV3(s, LibIntOrAString.fromStringV3("a")));
        assertTrue(LibIntOrAString.includesV3(s, LibIntOrAString.fromStringV3("bc")));
        // "c" with "b" above its length.
        assertTrue(LibIntOrAString.includesV3(LibIntOrAString.fromStringV3("abc"), IntOrAString.wrap(0x6263e1)));
    }

    function checkV3(bytes memory s, bytes memory needle, bool expected) internal pure {
        assertEq(LibStringReference.includes(s, needle), expected);
        checkIncludes(s, needle, 0, 0);
    }
}
