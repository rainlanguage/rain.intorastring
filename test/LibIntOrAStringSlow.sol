// SPDX-License-Identifier: CAL
pragma solidity ^0.8.19;

import {IntOrAString} from "../src/lib/LibIntOrAString.sol";

library LibIntOrAStringSlow {
    function toStringSlow(IntOrAString intOrAString) internal pure returns (string memory) {
        // length is the leftmost byte.
        uint256 length = IntOrAString.unwrap(intOrAString) >> 248;
        // length is module 32.
        length = length % 32;

        // String data is the lower 31 bytes.
        bytes memory output = new bytes(length);
        bytes memory input = abi.encodePacked(intOrAString);
        for (uint256 i = 0; i < length; i++) {
            output[i] = input[i + 1];
        }

        return string(output);
    }

    function fromStringSlow(string memory s) internal pure returns (IntOrAString intOrAString) {
        // length is the leftmost byte.
        uint256 length = bytes(s).length;
        // length is module 32.
        length = length % 32;

        // Fill the output byte by byte.
        uint256 output = length;
        for (uint256 i = 0; i < length; i++) {
            output = output << 8;
            output = output | uint256(uint8(bytes(s)[i]));
        }
        // Pad right with zeros.
        output = output << (248 - (length * 8));
        // Set the high bit to ensure strings are always truthy.
        output = output | (1 << 255);

        return IntOrAString.wrap(output);
    }
}