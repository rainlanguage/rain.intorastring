// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test, Vm} from "forge-std-1.16.1/src/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {IntOrAStringTooLong} from "src/error/ErrIntOrAString.sol";

/// Differential fuzzing against the real Rust `[u8]` and `heck` 0.5 functions,
/// run from the flake's `rust-string-oracle` over `vm.ffi`.
abstract contract RustStringOracleTest is Test {
    uint256 constant MAX_FUZZ_LENGTH = 40;

    string internal sOracle;

    function setUp() public virtual {
        string[] memory command = new string[](5);
        command[0] = "nix";
        command[1] = "build";
        command[2] = "--no-link";
        command[3] = "--print-out-paths";
        command[4] = ".#rust-string-oracle";
        sOracle = string.concat(string(ffiOk(command)), "/bin/rust-string-oracle");
    }

    function ffiOk(string[] memory command) internal returns (bytes memory) {
        Vm.FfiResult memory result = vm.tryFfi(command);
        assertEq(result.exitCode, 0, string(result.stderr));
        return result.stdout;
    }

    function rust(string memory op, bytes memory a) internal returns (bytes memory) {
        string[] memory command = new string[](3);
        command[0] = sOracle;
        command[1] = op;
        command[2] = vm.toString(a);
        return ffiOk(command);
    }

    function rust(string memory op, bytes memory a, bytes memory b) internal returns (bytes memory) {
        string[] memory command = new string[](4);
        command[0] = sOracle;
        command[1] = op;
        command[2] = vm.toString(a);
        command[3] = vm.toString(b);
        return ffiOk(command);
    }

    function rustSubs(bytes memory s, uint256 start, uint256 end) internal returns (bool, bytes memory) {
        string[] memory command = new string[](5);
        command[0] = sOracle;
        command[1] = "subs";
        command[2] = vm.toString(s);
        command[3] = vm.toString(start);
        command[4] = vm.toString(end);
        return abi.decode(ffiOk(command), (bool, bytes));
    }

    function rustString(string memory op, bytes memory a) internal returns (bytes memory) {
        (bool ok, bytes memory result) = abi.decode(rust(op, a), (bool, bytes));
        assertTrue(ok, "Rust returned no string");
        return result;
    }

    function rustString(string memory op, bytes memory a, bytes memory b) internal returns (bytes memory) {
        (bool ok, bytes memory result) = abi.decode(rust(op, a, b), (bool, bytes));
        assertTrue(ok, "Rust returned no string");
        return result;
    }

    function rustPredicate(string memory op, bytes memory a, bytes memory b) internal returns (bool) {
        return abi.decode(rust(op, a, b), (bool));
    }

    /// The first `length` (up to `MAX_FUZZ_LENGTH`) bytes of `data0` then
    /// `data1`, masked to ASCII when `ascii`.
    function fuzzString(bytes32 data0, bytes32 data1, uint256 length, bool ascii) internal pure returns (bytes memory) {
        bytes memory data = abi.encodePacked(data0, data1);
        bytes memory s = new bytes(bound(length, 0, MAX_FUZZ_LENGTH));
        for (uint256 i = 0; i < s.length; i++) {
            s[i] = ascii ? data[i] & 0x7f : data[i];
        }
        return s;
    }

    function fromStringV3External(string memory s) external pure returns (IntOrAString) {
        return LibIntOrAString.fromStringV3(s);
    }

    /// `s` as a V3 value, or `false` once `fromStringV3` is shown to revert
    /// for `s` over 31 bytes.
    function toV3(bytes memory s) internal returns (bool, IntOrAString) {
        bool isV3 = s.length <= 31;
        if (!isV3) {
            vm.expectRevert(abi.encodeWithSelector(IntOrAStringTooLong.selector, s.length));
            this.fromStringV3External(string(s));
            return (isV3, IntOrAString.wrap(0));
        }
        return (isV3, LibIntOrAString.fromStringV3(string(s)));
    }

    function checkString(
        function(IntOrAString) external pure returns (IntOrAString) op,
        string memory rustOp,
        bytes memory s
    ) internal {
        (bool isV3, IntOrAString a) = toV3(s);
        if (!isV3) {
            return;
        }
        bytes memory expected = rustString(rustOp, s);
        try op(a) returns (IntOrAString actual) {
            assertResult(expected, actual);
        } catch (bytes memory err) {
            assertTooLong(expected, err);
        }
    }

    function checkString(
        function(IntOrAString, IntOrAString) external pure returns (IntOrAString) op,
        string memory rustOp,
        bytes memory s,
        bytes memory x
    ) internal {
        (bool sIsV3, IntOrAString a) = toV3(s);
        (bool xIsV3, IntOrAString b) = toV3(x);
        if (!sIsV3 || !xIsV3) {
            return;
        }
        bytes memory expected = rustString(rustOp, s, x);
        try op(a, b) returns (IntOrAString actual) {
            assertResult(expected, actual);
        } catch (bytes memory err) {
            assertTooLong(expected, err);
        }
    }

    function checkPredicate(
        function(IntOrAString, IntOrAString) internal pure returns (bool) op,
        string memory rustOp,
        bytes memory s,
        bytes memory x
    ) internal {
        (bool sIsV3, IntOrAString a) = toV3(s);
        (bool xIsV3, IntOrAString b) = toV3(x);
        if (!sIsV3 || !xIsV3) {
            return;
        }
        assertEq(op(a, b), rustPredicate(rustOp, s, x));
    }

    function assertResult(bytes memory expected, IntOrAString actual) internal pure {
        assertLe(expected.length, 31, "Rust result over 31 bytes but no revert");
        assertEq(
            bytes32(IntOrAString.unwrap(actual)),
            bytes32(IntOrAString.unwrap(LibIntOrAString.fromStringV3(string(expected))))
        );
    }

    function assertTooLong(bytes memory expected, bytes memory err) internal pure {
        assertEq(err, abi.encodeWithSelector(IntOrAStringTooLong.selector, expected.length));
    }
}
