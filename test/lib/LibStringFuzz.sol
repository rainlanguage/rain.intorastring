// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IntOrAString} from "src/lib/LibIntOrAString.sol";

uint256 constant AFFIX_PREFIX = 1;
uint256 constant AFFIX_SUFFIX = 2;
uint256 constant AFFIX_INNER = 3;

library LibStringFuzz {
    /// The first `length` bytes of `data`, each mapped into `alphabet` unless
    /// `alphabet` is empty.
    function fuzzBytes(bytes32 data, uint256 length, bytes memory alphabet) internal pure returns (bytes memory) {
        bytes memory s = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            s[i] = alphabet.length == 0 ? data[i] : alphabet[uint8(data[i]) % alphabet.length];
        }
        return s;
    }

    /// The first `length` bytes of `data`, masked to ASCII when `ascii`.
    function fuzzBytes(bytes32 data, uint256 length, bool ascii) internal pure returns (bytes memory) {
        return fuzzBytes(ascii ? data & bytes32(type(uint256).max / 0xff * 0x7f) : data, length, "");
    }

    /// `x` itself, or a slice of `s` at `position` no longer than `x`,
    /// unchanged or with one byte changed, chosen by `seed`.
    function fuzzAffix(bytes memory s, bytes memory x, uint256 position, uint256 seed, bool ascii)
        internal
        pure
        returns (bytes memory)
    {
        if (seed % 3 == 0) {
            return x;
        }
        uint256 length = x.length < s.length ? x.length : s.length;
        uint256 start = position == AFFIX_PREFIX
            ? 0
            : position == AFFIX_SUFFIX ? s.length - length : (seed >> 64) % (s.length - length + 1);
        bytes memory affix = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            affix[i] = s[start + i];
        }
        if (seed % 3 == 2 && length > 0) {
            uint256 i = (seed >> 8) % length;
            affix[i] ^= bytes1(uint8(1 + (seed >> 128) % (ascii ? 0x7f : 0xff)));
        }
        return affix;
    }

    /// `intOrAString` with `garbage` in every bit above its string data and in
    /// the three truthy bits.
    function dirtyV3(IntOrAString intOrAString, uint256 garbage) internal pure returns (IntOrAString) {
        uint256 value = IntOrAString.unwrap(intOrAString);
        uint256 length = value & 0x1f;
        uint256 keep = length == 31 ? type(uint256).max : (uint256(1) << (8 * (length + 1))) - 1;
        keep &= ~uint256(0xe0);
        return IntOrAString.wrap((value & keep) | (garbage & ~keep));
    }
}
