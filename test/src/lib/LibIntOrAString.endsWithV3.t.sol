// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {LibAffix} from "rain-string-0.3.11/src/lib/affix/LibAffix.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibStringFuzz, AFFIX_SUFFIX} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringEndsWithV3Test is Test {
    function checkEndsWith(bytes memory s, bytes memory suffix, uint256 sGarbage, uint256 suffixGarbage) internal pure {
        bool expected = LibAffix.endsWith(s, suffix);
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString b = LibIntOrAString.fromStringV3(string(suffix));
        assertEq(LibIntOrAString.endsWithV3(a, b), expected);
        assertEq(
            LibIntOrAString.endsWithV3(LibStringFuzz.dirtyV3(a, sGarbage), LibStringFuzz.dirtyV3(b, suffixGarbage)),
            expected
        );
    }

    function testEndsWithV3Reference(
        bytes32 sData,
        uint256 sLength,
        bytes32 suffixData,
        uint256 suffixLength,
        uint256 sGarbage,
        uint256 suffixGarbage
    ) external pure {
        checkEndsWith(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), "ab"),
            LibStringFuzz.fuzzBytes(suffixData, bound(suffixLength, 0, 31), "ab"),
            sGarbage,
            suffixGarbage
        );
    }

    function testEndsWithV3ReferenceAnyBytes(
        bytes32 sData,
        uint256 sLength,
        bytes32 suffixData,
        uint256 suffixLength,
        uint256 sGarbage,
        uint256 suffixGarbage
    ) external pure {
        checkEndsWith(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), ""),
            LibStringFuzz.fuzzBytes(suffixData, bound(suffixLength, 0, 31), ""),
            sGarbage,
            suffixGarbage
        );
    }

    /// The suffix is taken from `s` itself, sometimes with one byte changed.
    function testEndsWithV3ReferenceOwnSuffix(
        bytes32 data,
        uint256 length,
        uint256 affixLength,
        uint256 changeIndex,
        bytes1 change,
        uint256 sGarbage,
        uint256 suffixGarbage
    ) external pure {
        bytes memory s = LibStringFuzz.fuzzBytes(data, bound(length, 0, 31), "");
        bytes memory suffix = LibStringReference.slice(s, s.length - bound(affixLength, 0, s.length), s.length);
        if (suffix.length > 0) {
            suffix[changeIndex % suffix.length] ^= change;
        }
        checkEndsWith(s, suffix, sGarbage, suffixGarbage);
    }

    function checkEndsWithDifferential(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 suffixLength,
        uint256 seed,
        uint256[2] memory garbage,
        bool ascii
    ) internal pure {
        bytes memory s = LibStringFuzz.fuzzBytes(data[0], bound(sLength, 0, 31), ascii);
        bytes memory suffix = LibStringFuzz.fuzzAffix(
            s, LibStringFuzz.fuzzBytes(data[1], bound(suffixLength, 0, 31), ascii), AFFIX_SUFFIX, seed, ascii
        );
        checkEndsWith(s, suffix, garbage[0], garbage[1]);
    }

    /// Expected from rain.string `LibAffix.endsWith`.
    function testEndsWithV3DifferentialAscii(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 suffixLength,
        uint256 seed,
        uint256[2] memory garbage
    ) external pure {
        checkEndsWithDifferential(data, sLength, suffixLength, seed, garbage, true);
    }

    /// Expected from rain.string `LibAffix.endsWith`.
    function testEndsWithV3DifferentialAnyBytes(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 suffixLength,
        uint256 seed,
        uint256[2] memory garbage
    ) external pure {
        checkEndsWithDifferential(data, sLength, suffixLength, seed, garbage, false);
    }

    function testEndsWithV3Empty() external pure {
        checkV3("", "", true);
        checkV3("a", "", true);
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "", true);
        checkV3("", "a", false);
    }

    function testEndsWithV3ThirtyOneBytes() external pure {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", true);
        checkV3("abcdefghijklmnopqrstuvwxyz0123", "abcdefghijklmnopqrstuvwxyz01234", false);
        checkV3("bcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", false);
    }

    function testEndsWithV3IgnoresBytesAboveLength() external pure {
        // "bc" with "a" above its length.
        IntOrAString s = IntOrAString.wrap(0x616263e2);
        assertFalse(LibIntOrAString.endsWithV3(s, LibIntOrAString.fromStringV3("abc")));
        assertFalse(LibIntOrAString.endsWithV3(s, LibIntOrAString.fromStringV3("b")));
        assertTrue(LibIntOrAString.endsWithV3(s, LibIntOrAString.fromStringV3("c")));
        assertTrue(LibIntOrAString.endsWithV3(s, LibIntOrAString.fromStringV3("bc")));
        // "L" with "x" above its length.
        assertTrue(LibIntOrAString.endsWithV3(LibIntOrAString.fromStringV3("tAAPL"), IntOrAString.wrap(0x784ce1)));
    }

    function checkV3(bytes memory s, bytes memory suffix, bool expected) internal pure {
        assertEq(LibAffix.endsWith(s, suffix), expected);
        checkEndsWith(s, suffix, 0, 0);
    }
}
