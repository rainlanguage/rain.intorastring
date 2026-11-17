// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibAffix} from "rain-string-0.3.10/src/lib/affix/LibAffix.sol";

/// Ports over `bytes` of the Rust `[u8]` and `heck` 0.5 functions that the V3
/// string ops follow. The heck ports read bytes from 0x80 as caseless
/// alphanumerics.
library LibStringReference {
    uint256 constant HECK_BOUNDARY = 0;
    uint256 constant HECK_LOWERCASE = 1;
    uint256 constant HECK_UPPERCASE = 2;

    /// Rust `s[start..end]`.
    function slice(bytes memory s, uint256 start, uint256 end) internal pure returns (bytes memory) {
        bytes memory out = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            out[i - start] = s[i];
        }
        return out;
    }

    /// Rust `[u8]::strip_prefix`, `s` unchanged on `None`.
    function stripPrefix(bytes memory s, bytes memory prefix) internal pure returns (bytes memory) {
        return LibAffix.startsWith(s, prefix) ? slice(s, prefix.length, s.length) : s;
    }

    /// Rust `[u8]::strip_suffix`, `s` unchanged on `None`.
    function stripSuffix(bytes memory s, bytes memory suffix) internal pure returns (bytes memory) {
        return LibAffix.endsWith(s, suffix) ? slice(s, 0, s.length - suffix.length) : s;
    }

    /// Rust `[u8]::windows` search, the empty needle included.
    function includes(bytes memory s, bytes memory needle) internal pure returns (bool) {
        for (uint256 i = 0; i + needle.length <= s.length; i++) {
            if (keccak256(slice(s, i, i + needle.length)) == keccak256(needle)) {
                return true;
            }
        }
        return false;
    }

    /// Rust `u8::is_ascii_whitespace`.
    function isAsciiWhitespace(bytes1 c) internal pure returns (bool) {
        return c == "\t" || c == "\n" || c == "\x0c" || c == "\r" || c == " ";
    }

    /// Rust `[u8]::trim_ascii_start`.
    function triml(bytes memory s) internal pure returns (bytes memory) {
        uint256 index = 0;
        while (index < s.length && isAsciiWhitespace(s[index])) {
            index++;
        }
        return slice(s, index, s.length);
    }

    /// Rust `[u8]::trim_ascii_end`.
    function trimr(bytes memory s) internal pure returns (bytes memory) {
        uint256 index = s.length;
        while (index > 0 && isAsciiWhitespace(s[index - 1])) {
            index--;
        }
        return slice(s, 0, index);
    }

    /// Rust `[u8]::trim_ascii`.
    function trim(bytes memory s) internal pure returns (bytes memory) {
        uint256 rindex = s.length;
        while (rindex > 0 && isAsciiWhitespace(s[rindex - 1])) {
            rindex--;
        }
        uint256 lindex = 0;
        while (lindex < rindex && isAsciiWhitespace(s[lindex])) {
            lindex++;
        }
        return slice(s, lindex, rindex);
    }

    /// Rust `[u8]::to_ascii_lowercase`.
    function lowerCase(bytes memory s) internal pure returns (bytes memory) {
        bytes memory out = new bytes(s.length);
        for (uint256 i = 0; i < s.length; i++) {
            out[i] = isUpper(s[i]) ? bytes1(uint8(s[i]) + 32) : s[i];
        }
        return out;
    }

    /// Rust `[u8]::to_ascii_uppercase`.
    function upperCase(bytes memory s) internal pure returns (bytes memory) {
        bytes memory out = new bytes(s.length);
        for (uint256 i = 0; i < s.length; i++) {
            out[i] = isLower(s[i]) ? bytes1(uint8(s[i]) - 32) : s[i];
        }
        return out;
    }

    /// heck `capitalize`.
    function capitalize(bytes memory s) internal pure returns (bytes memory) {
        if (s.length < 2) {
            return upperCase(s);
        }
        return bytes.concat(upperCase(slice(s, 0, 1)), lowerCase(slice(s, 1, s.length)));
    }

    function isLower(bytes1 c) internal pure returns (bool) {
        return c >= "a" && c <= "z";
    }

    function isUpper(bytes1 c) internal pure returns (bool) {
        return c >= "A" && c <= "Z";
    }

    /// Rust `char::is_alphanumeric`, with every byte from 0x80 alphanumeric.
    function isAlphanumeric(bytes1 c) internal pure returns (bool) {
        return isLower(c) || isUpper(c) || (c >= "0" && c <= "9") || uint8(c) >= 0x80;
    }

    /// The words heck `transform` passes to `with_word`, in order.
    function transform(bytes memory s) internal pure returns (bytes[] memory) {
        bytes[] memory words = new bytes[](s.length);
        uint256 count = 0;
        uint256 wordStart = 0;
        for (uint256 wordEnd = 0; wordEnd <= s.length; wordEnd++) {
            if (wordEnd < s.length && isAlphanumeric(s[wordEnd])) {
                continue;
            }
            bytes memory word = slice(s, wordStart, wordEnd);
            wordStart = wordEnd + 1;
            uint256 init = 0;
            uint256 mode = HECK_BOUNDARY;
            for (uint256 i = 0; i < word.length; i++) {
                bytes1 c = word[i];
                if (i + 1 == word.length) {
                    words[count++] = slice(word, init, word.length);
                    break;
                }
                bytes1 next = word[i + 1];
                uint256 nextMode = isLower(c) ? HECK_LOWERCASE : isUpper(c) ? HECK_UPPERCASE : mode;
                if (nextMode == HECK_LOWERCASE && isUpper(next)) {
                    words[count++] = slice(word, init, i + 1);
                    init = i + 1;
                    mode = HECK_BOUNDARY;
                } else if (mode == HECK_UPPERCASE && isUpper(c) && isLower(next)) {
                    words[count++] = slice(word, init, i);
                    init = i;
                    mode = HECK_BOUNDARY;
                } else {
                    mode = nextMode;
                }
            }
        }
        assembly ("memory-safe") {
            mstore(words, count)
        }
        return words;
    }

    /// heck `transform` with `firstFn` on the first word, `restFn` on the
    /// rest, and `boundary` between words.
    function convertCase(
        function(bytes memory) internal pure returns (bytes memory) firstFn,
        function(bytes memory) internal pure returns (bytes memory) restFn,
        bytes memory boundary,
        bytes memory s
    ) internal pure returns (bytes memory) {
        bytes[] memory words = transform(s);
        bytes memory out = "";
        for (uint256 i = 0; i < words.length; i++) {
            out = i == 0 ? firstFn(words[i]) : bytes.concat(out, boundary, restFn(words[i]));
        }
        return out;
    }

    /// heck `to_lower_camel_case`.
    function camelCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(lowerCase, capitalize, "", s);
    }

    /// heck `to_upper_camel_case`.
    function pascalCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(capitalize, capitalize, "", s);
    }

    /// heck `to_snake_case`.
    function snakeCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(lowerCase, lowerCase, "_", s);
    }

    /// heck `to_shouty_snake_case`.
    function screamingSnakeCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(upperCase, upperCase, "_", s);
    }

    /// heck `to_kebab_case`.
    function kebabCase(bytes memory s) internal pure returns (bytes memory) {
        return convertCase(lowerCase, lowerCase, "-", s);
    }
}
