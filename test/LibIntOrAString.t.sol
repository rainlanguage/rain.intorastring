// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Test, console2} from "forge-std/Test.sol";

import {LibIntOrAString, IntOrAString} from "src/lib/LibIntOrAString.sol";
import {LibBytes} from "rain.solmem/lib/LibBytes.sol";
import {LibMemCpy} from "rain.solmem/lib/LibMemCpy.sol";

contract LibIntOrAStringTest is Test {
    /// We can't assume that the memory pointed to by 0x40 is zeroed, so we
    /// should fill it with garbage before running our conversions to ensure they
    /// are resilient to garbage data.
    function putGarbageInUnallocatedMemory() internal pure {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            let garbage := keccak256(0, 0x60)
            // Garbage in scratch space.
            mstore(0, garbage)
            mstore(0x20, garbage)
            // Garbage in free memory.
            mstore(ptr, garbage)
            mstore(add(ptr, 0x20), garbage)
        }
    }

    /// All strings 31 bytes or less should round trip cleanly.
    function testRoundTripString(string memory s) external {
        vm.assume(bytes(s).length <= 31);
        putGarbageInUnallocatedMemory();
        assertEq(LibIntOrAString.toString(LibIntOrAString.fromString(s)), s);
    }

    /// All strings of any length should round trip but be truncated to their
    /// length modulo 32.
    function testRoundTripStringTruncated(string memory s) external {
        putGarbageInUnallocatedMemory();
        bytes memory truncated = new bytes((bytes(s).length));
        LibMemCpy.unsafeCopyBytesTo(
            LibBytes.dataPointer(bytes(s)), LibBytes.dataPointer(bytes(truncated)), bytes(s).length
        );
        LibBytes.truncate(truncated, truncated.length % 32);

        assertEq(LibIntOrAString.toString(LibIntOrAString.fromString(s)), string(truncated));
    }
}
