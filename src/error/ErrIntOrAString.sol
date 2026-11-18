// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// Thrown when a string operation's result is longer than the 31 bytes a V3
/// `IntOrAString` can hold.
/// @param length The byte length of the result.
error IntOrAStringTooLong(uint256 length);

/// Thrown when a substring range is not `start <= end <= length`.
/// @param start The start index.
/// @param end The end index.
/// @param length The byte length of the input.
error IntOrAStringSubsOutOfRange(uint256 start, uint256 end, uint256 length);
