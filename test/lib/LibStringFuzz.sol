// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IntOrAString} from "src/lib/LibIntOrAString.sol";

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
