// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibBytes} from "rain.solmem/lib/LibBytes.sol";

library LibIntOrAStringSlow {
    function toStringV3Slow(IntOrAString intOrAString) internal pure returns (string memory) {
        // length is the rightmost 5 bits.
        uint256 length = IntOrAString.unwrap(intOrAString) & 0x1f;

        // String data is the upper 31 bytes.
        bytes memory output = new bytes(length);
        bytes memory input = abi.encodePacked(intOrAString);
        for (uint256 i = 0; i < length; i++) {
            output[i] = input[i + 0x20 - length - 1];
        }

        return string(output);
    }

    function fromStringV3Slow(string memory s) internal pure returns (IntOrAString intOrAString) {
        // output length is input length modulo 32.
        uint256 length = bytes(s).length % 32;

        // length is the rightmost byte.
        intOrAString = IntOrAString.wrap(length);

        // Include the truthy bits.
        intOrAString = IntOrAString.wrap(IntOrAString.unwrap(intOrAString) | 0xe0);

        // Truncate s to output length.
        LibBytes.truncate(bytes(s), length);

        uint256 data = uint256(bytes32(bytes(s)));

        // Shift data to the right to be flush with the length byte.
        data = data >> (8 * (0x20 - length - 1));

        // Include the data.
        intOrAString = IntOrAString.wrap(IntOrAString.unwrap(intOrAString) | data);
    }
}
