// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibStringFuzz, AFFIX_PREFIX} from "test/lib/LibStringFuzz.sol";
import {LibStringReference} from "test/lib/LibStringReference.sol";

contract LibIntOrAStringStripPrefixV3Test is Test {
    function checkStripPrefix(bytes memory s, bytes memory prefix, uint256 sGarbage, uint256 prefixGarbage)
        internal
        pure
    {
        uint256 expected = IntOrAString.unwrap(
            LibIntOrAString.fromStringV3(string(LibStringReference.stripPrefix(s, prefix)))
        );
        IntOrAString a = LibIntOrAString.fromStringV3(string(s));
        IntOrAString b = LibIntOrAString.fromStringV3(string(prefix));
        assertEq(IntOrAString.unwrap(LibIntOrAString.stripPrefixV3(a, b)), expected);
        assertEq(
            IntOrAString.unwrap(
                LibIntOrAString.stripPrefixV3(
                    LibStringFuzz.dirtyV3(a, sGarbage), LibStringFuzz.dirtyV3(b, prefixGarbage)
                )
            ),
            expected
        );
    }

    function testStripPrefixV3Reference(
        bytes32 sData,
        uint256 sLength,
        bytes32 prefixData,
        uint256 prefixLength,
        uint256 sGarbage,
        uint256 prefixGarbage
    ) external pure {
        checkStripPrefix(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), "ab"),
            LibStringFuzz.fuzzBytes(prefixData, bound(prefixLength, 0, 31), "ab"),
            sGarbage,
            prefixGarbage
        );
    }

    function testStripPrefixV3ReferenceAnyBytes(
        bytes32 sData,
        uint256 sLength,
        bytes32 prefixData,
        uint256 prefixLength,
        uint256 sGarbage,
        uint256 prefixGarbage
    ) external pure {
        checkStripPrefix(
            LibStringFuzz.fuzzBytes(sData, bound(sLength, 0, 31), ""),
            LibStringFuzz.fuzzBytes(prefixData, bound(prefixLength, 0, 31), ""),
            sGarbage,
            prefixGarbage
        );
    }

    /// The prefix is taken from `s` itself, sometimes with one byte changed.
    function testStripPrefixV3ReferenceOwnPrefix(
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
        checkStripPrefix(s, prefix, sGarbage, prefixGarbage);
    }

    function checkStripPrefixDifferential(
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
        checkStripPrefix(s, prefix, garbage[0], garbage[1]);
    }

    /// Strips when rain.string `LibAffix.startsWith`.
    function testStripPrefixV3DifferentialAscii(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 prefixLength,
        uint256 seed,
        uint256[2] memory garbage
    ) external pure {
        checkStripPrefixDifferential(data, sLength, prefixLength, seed, garbage, true);
    }

    /// Strips when rain.string `LibAffix.startsWith`.
    function testStripPrefixV3DifferentialAnyBytes(
        bytes32[2] memory data,
        uint256 sLength,
        uint256 prefixLength,
        uint256 seed,
        uint256[2] memory garbage
    ) external pure {
        checkStripPrefixDifferential(data, sLength, prefixLength, seed, garbage, false);
    }

    function testStripPrefixV3Empty() external pure {
        checkV3("", "", "");
        checkV3("a", "", "a");
        checkV3("", "a", "");
        checkV3("a", "a", "");
    }

    function testStripPrefixV3ThirtyOneBytes() external pure {
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", "");
        checkV3("abcdefghijklmnopqrstuvwxyz01234", "", "abcdefghijklmnopqrstuvwxyz01234");
        checkV3("abcdefghijklmnopqrstuvwxyz0123", "abcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz0123");
        checkV3("bcdefghijklmnopqrstuvwxyz01234", "abcdefghijklmnopqrstuvwxyz01234", "bcdefghijklmnopqrstuvwxyz01234");
    }

    function testStripPrefixV3KnownAnswers() external pure {
        checkV3("tAAPL", "t", "AAPL");
        checkV3("AAPL", "t", "AAPL");
        checkV3("tAAPL", "tAAPLx", "tAAPL");
        // "bc" with "a" above its length: the result is canonical either way.
        IntOrAString s = IntOrAString.wrap(0x616263e2);
        assertEq(IntOrAString.unwrap(LibIntOrAString.stripPrefixV3(s, LibIntOrAString.fromStringV3("x"))), 0x6263e2);
        assertEq(IntOrAString.unwrap(LibIntOrAString.stripPrefixV3(s, LibIntOrAString.fromStringV3("a"))), 0x6263e2);
        assertEq(IntOrAString.unwrap(LibIntOrAString.stripPrefixV3(s, LibIntOrAString.fromStringV3("b"))), 0x63e1);
    }

    function checkV3(bytes memory s, bytes memory prefix, bytes memory expected) internal pure {
        assertEq(LibStringReference.stripPrefix(s, prefix), expected);
        checkStripPrefix(s, prefix, 0, 0);
    }
}
