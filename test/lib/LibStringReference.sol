// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibAffix} from "rain-string-0.3.10/src/lib/affix/LibAffix.sol";

/// Ports over `bytes` of the clojure.string, cuerdas and camel-snake-kebab
/// functions that the V3 string ops follow, one byte per character.
library LibStringReference {
    uint256 constant CSK_NIL = 0;
    uint256 constant CSK_NUMBER = 1;
    uint256 constant CSK_WHITESPACE = 2;
    uint256 constant CSK_LOWER = 3;
    uint256 constant CSK_UPPER = 4;
    uint256 constant CSK_OTHER = 5;

    /// Java `String.substring(start, end)`.
    function slice(bytes memory s, uint256 start, uint256 end) internal pure returns (bytes memory) {
        bytes memory out = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            out[i - start] = s[i];
        }
        return out;
    }

    /// cuerdas `strip-prefix`.
    function stripPrefix(bytes memory s, bytes memory prefix) internal pure returns (bytes memory) {
        return LibAffix.startsWith(s, prefix) ? slice(s, prefix.length, s.length) : s;
    }

    /// cuerdas `strip-suffix`.
    function stripSuffix(bytes memory s, bytes memory suffix) internal pure returns (bytes memory) {
        return LibAffix.endsWith(s, suffix) ? slice(s, 0, s.length - suffix.length) : s;
    }

    /// `clojure.string/includes?`.
    function includes(bytes memory s, bytes memory needle) internal pure returns (bool) {
        for (uint256 i = 0; i + needle.length <= s.length; i++) {
            if (keccak256(slice(s, i, i + needle.length)) == keccak256(needle)) {
                return true;
            }
        }
        return false;
    }

    /// Java `Character/isWhitespace`.
    function isJavaWhitespace(bytes1 c) internal pure returns (bool) {
        bytes memory whitespace = "\t\n\x0b\x0c\r\x1c\x1d\x1e\x1f ";
        for (uint256 i = 0; i < whitespace.length; i++) {
            if (whitespace[i] == c) {
                return true;
            }
        }
        return false;
    }

    /// `clojure.string/triml`.
    function triml(bytes memory s) internal pure returns (bytes memory) {
        uint256 index = 0;
        while (index < s.length && isJavaWhitespace(s[index])) {
            index++;
        }
        return slice(s, index, s.length);
    }

    /// `clojure.string/trimr`.
    function trimr(bytes memory s) internal pure returns (bytes memory) {
        uint256 index = s.length;
        while (index > 0 && isJavaWhitespace(s[index - 1])) {
            index--;
        }
        return slice(s, 0, index);
    }

    /// `clojure.string/trim`.
    function trim(bytes memory s) internal pure returns (bytes memory) {
        uint256 rindex = s.length;
        while (rindex > 0 && isJavaWhitespace(s[rindex - 1])) {
            rindex--;
        }
        uint256 lindex = 0;
        while (lindex < rindex && isJavaWhitespace(s[lindex])) {
            lindex++;
        }
        return slice(s, lindex, rindex);
    }

    /// `clojure.string/lower-case` over ASCII.
    function lowerCase(bytes memory s) internal pure returns (bytes memory) {
        bytes memory out = new bytes(s.length);
        for (uint256 i = 0; i < s.length; i++) {
            out[i] = s[i] >= "A" && s[i] <= "Z" ? bytes1(uint8(s[i]) + 32) : s[i];
        }
        return out;
    }

    /// `clojure.string/upper-case` over ASCII.
    function upperCase(bytes memory s) internal pure returns (bytes memory) {
        bytes memory out = new bytes(s.length);
        for (uint256 i = 0; i < s.length; i++) {
            out[i] = s[i] >= "a" && s[i] <= "z" ? bytes1(uint8(s[i]) - 32) : s[i];
        }
        return out;
    }

    /// `clojure.string/capitalize` over ASCII.
    function capitalize(bytes memory s) internal pure returns (bytes memory) {
        if (s.length < 2) {
            return upperCase(s);
        }
        return bytes.concat(upperCase(slice(s, 0, 1)), lowerCase(slice(s, 1, s.length)));
    }

    /// camel-snake-kebab `classify-char`.
    function classifyChar(bytes1 c) internal pure returns (uint256) {
        if (c >= "0" && c <= "9") {
            return CSK_NUMBER;
        }
        if (c == "-" || c == "_" || c == " " || c == "\t" || c == "\n" || c == "\x0b" || c == "\x0c" || c == "\r") {
            return CSK_WHITESPACE;
        }
        if (c >= "a" && c <= "z") {
            return CSK_LOWER;
        }
        if (c >= "A" && c <= "Z") {
            return CSK_UPPER;
        }
        return CSK_OTHER;
    }

    /// camel-snake-kebab `generic-split`.
    function genericSplit(bytes memory ss) internal pure returns (bytes[] memory) {
        uint256[] memory cs = new uint256[](ss.length + 2);
        for (uint256 i = 0; i < ss.length; i++) {
            cs[i] = classifyChar(ss[i]);
        }
        bytes[] memory result = new bytes[](ss.length + 1);
        uint256 count = 0;
        uint256 start = 0;
        uint256 current = 0;
        while (current < ss.length) {
            uint256 next = current + 1;
            uint256 a = cs[current];
            uint256 b = cs[current + 1];
            uint256 c = cs[current + 2];
            if (a == CSK_WHITESPACE) {
                if (current > start) {
                    result[count++] = slice(ss, start, current);
                }
                start = next;
            } else if (
                (a != CSK_UPPER && b == CSK_UPPER) || (a != CSK_NUMBER && b == CSK_NUMBER)
                    || (a == CSK_UPPER && b == CSK_UPPER && c == CSK_LOWER)
            ) {
                if (next > start) {
                    result[count++] = slice(ss, start, next);
                }
                start = next;
            }
            current = next;
        }
        if (current > start) {
            result[count++] = slice(ss, start, current);
        }
        if (count == 0) {
            result[count++] = "";
        }
        assembly ("memory-safe") {
            mstore(result, count)
        }
        return result;
    }

    /// camel-snake-kebab `convert-case` with the generic separator.
    function convertCase(
        function(bytes memory) internal pure returns (bytes memory) firstFn,
        function(bytes memory) internal pure returns (bytes memory) restFn,
        bytes memory sep,
        bytes memory s
    ) internal pure returns (bytes memory) {
        bytes[] memory words = genericSplit(s);
        bytes memory out = firstFn(words[0]);
        for (uint256 i = 1; i < words.length; i++) {
            out = bytes.concat(out, sep, restFn(words[i]));
        }
        return out;
    }

    /// camel-snake-kebab `->camelCase`.
    function camelCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(lowerCase, capitalize, "", s);
    }

    /// camel-snake-kebab `->PascalCase`.
    function pascalCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(capitalize, capitalize, "", s);
    }

    /// camel-snake-kebab `->snake_case`.
    function snakeCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(lowerCase, lowerCase, "_", s);
    }

    /// camel-snake-kebab `->SCREAMING_SNAKE_CASE`.
    function screamingSnakeCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(upperCase, upperCase, "_", s);
    }

    /// camel-snake-kebab `->kebab-case`.
    function kebabCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(lowerCase, lowerCase, "-", s);
    }
}
