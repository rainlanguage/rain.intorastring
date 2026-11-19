// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibStringFuzz, AFFIX_SUFFIX} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringStripSuffixV3Test is Test {
    function checkStripSuffix(bytes memory s, bytes memory suffix, uint256 sGarbage, uint256 suffixGarbage)
        internal
        pure
    {
        uint256 expected = IntOrAString.unwrap(
            LibIntOrAString.fromStringV3(string(LibStringReference.stripSuffix(s, suffix)))
        );
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString b = LibIntOrAString.fromStringV3(string(suffix));
        assertEq(IntOrAString.unwrap(LibIntOrAString.stripSuffixV3(a, b)), expected);
        assertEq(
            IntOrAString.unwrap(
                LibIntOrAString.stripSuffixV3(
                    LibStringFuzz.dirtyV3(a, sGarbage), LibStringFuzz.dirtyV3(b, suffixGarbage)
                )
            ),
            expected
        );
    }

    function testStripSuffixV3Reference(
        bytes32 sData,
        uint256 sLength,
        bytes32 suffixData,
        uint256 suffixLength,
        uint256 sGarbage,
        uint256 suffixGarbage
    ) external pure {
        checkStripSuffix(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), "ab"),
            LibStringFuzz.fuzzBytes(suffixData, bound(suffixLength, 0, 31), "ab"),
            sGarbage,
            suffixGarbage
        );
    }

    function testStripSuffixV3ReferenceAnyBytes(
        bytes32 sData,
        uint256 sLength,
        bytes32 suffixData,
        uint256 suffixLength,
        uint256 sGarbage,
        uint256 suffixGarbage
    ) external pure {
        checkStripSuffix(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), ""),
            LibStringFuzz.fuzzBytes(suffixData, bound(suffixLength, 0, 31), ""),
            sGarbage,
            suffixGarbage
        );
    }

    /// The suffix is taken from `s` itself, sometimes with one byte changed.
    function testStripSuffixV3ReferenceOwnSuffix(
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
        checkStripSuffix(s, suffix, sGarbage, suffixGarbage);
    }

    function checkStripSuffixDifferential(
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
        checkStripSuffix(s, suffix, garbage[0], garbage[1]);
    }

    /// Strips when rain.string `LibAffix.endsWith`.
    function testStripSuffixV3DifferentialAscii(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 suffixLength,
        uint256 seed,
        uint256[2] memory garbage
    ) external pure {
        checkStripSuffixDifferential(data, sLength, suffixLength, seed, garbage, true);
    }

    /// Strips when rain.string `LibAffix.endsWith`.
    function testStripSuffixV3DifferentialAnyBytes(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 suffixLength,
        uint256 seed,
        uint256[2] memory garbage
    ) external pure {
        checkStripSuffixDifferential(data, sLength, suffixLength, seed, garbage, false);
    }

    function testStripSuffixV3Empty() external pure {
        checkV3("", "", "");
        checkV3("a", "", "a");
        checkV3("", "a", "");
        checkV3("a", "a", "");
    }

    function testStripSuffixV3ThirtyOneBytes() external pure {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", "");
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "", "abcdefghijklmnopqrstuvwxyz01234");
        checkV3("abcdefghijklmnopqrstuvwxyz0123", "abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz0123");
        checkV3("bcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", "bcdefghijklmnopqrstuvwxyz01234");
    }

    function testStripSuffixV3KnownAnswers() external pure {
        checkV3("tAAPL", "L", "tAAP");
        checkV3("tAAPL", "t", "tAAPL");
        checkV3("tAAPL", "xtAAPL", "tAAPL");
        // "bc" with "a" above its length: the result is canonical either way.
        IntOrAString s = IntOrAString.wrap(0x616263e2);
        assertEq(IntOrAString.unwrap(LibIntOrAString.stripSuffixV3(s, LibIntOrAString.fromStringV3("x"))), 0x6263e2);
        assertEq(IntOrAString.unwrap(LibIntOrAString.stripSuffixV3(s, LibIntOrAString.fromStringV3("abc"))), 0x6263e2);
        assertEq(IntOrAString.unwrap(LibIntOrAString.stripSuffixV3(s, LibIntOrAString.fromStringV3("c"))), 0x62e1);
    }

    function checkV3(bytes memory s, bytes memory suffix, bytes memory expected) internal pure {
        assertEq(LibStringReference.stripSuffix(s, suffix), expected);
        checkStripSuffix(s, suffix, 0, 0);
    }
}
