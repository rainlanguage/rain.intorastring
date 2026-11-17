// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd

//! `rust-string-oracle <op> <0x hex bytes>... [<decimal index>...]` prints the
//! ABI encoded result of the Rust string function named by `op` as 0x hex.

use heck::{ToKebabCase, ToLowerCamelCase, ToShoutySnakeCase, ToSnakeCase, ToUpperCamelCase};
use std::env;

fn hex_bytes(hex: &str) -> Vec<u8> {
    let digits = hex.strip_prefix("0x").expect("bytes arg must be 0x hex");
    assert!(digits.len().is_multiple_of(2), "bytes arg must be whole bytes");
    (0..digits.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&digits[i..i + 2], 16).expect("bytes arg must be hex"))
        .collect()
}

fn index(decimal: &str) -> usize {
    decimal.parse().expect("index arg must be decimal")
}

/// `heck` takes `&str`, so its ops reject bytes that are not UTF-8.
fn utf8(bytes: &[u8]) -> &str {
    std::str::from_utf8(bytes).expect("heck op input must be UTF-8")
}

fn word(n: usize) -> String {
    format!("{n:064x}")
}

fn abi_bytes(bytes: &[u8]) -> String {
    let mut out = word(bytes.len());
    for b in bytes {
        out.push_str(&format!("{b:02x}"));
    }
    out.push_str(&"00".repeat((32 - bytes.len() % 32) % 32));
    out
}

/// `abi.encode(ok, result)`.
fn bytes_result(ok: bool, result: &[u8]) -> String {
    word(usize::from(ok)) + &word(64) + &abi_bytes(result)
}

fn ok(result: &[u8]) -> String {
    bytes_result(true, result)
}

fn predicate(result: bool) -> String {
    word(usize::from(result))
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    let op = args[0].as_str();
    let a = || hex_bytes(&args[1]);
    let b = || hex_bytes(&args[2]);
    let encoded = match op {
        "count" => word(a().len()),
        "starts-with?" => predicate(a().starts_with(&b())),
        "ends-with?" => predicate(a().ends_with(&b())),
        "includes?" => {
            let (s, needle) = (a(), b());
            predicate(needle.is_empty() || s.windows(needle.len()).any(|w| w == needle))
        }
        "triml" => ok(a().trim_ascii_start()),
        "trimr" => ok(a().trim_ascii_end()),
        "trim" => ok(a().trim_ascii()),
        "lower-case" => ok(&a().to_ascii_lowercase()),
        "upper-case" => ok(&a().to_ascii_uppercase()),
        "camel-case" => ok(utf8(&a()).to_lower_camel_case().as_bytes()),
        "pascal-case" => ok(utf8(&a()).to_upper_camel_case().as_bytes()),
        "snake-case" => ok(utf8(&a()).to_snake_case().as_bytes()),
        "screaming-snake-case" => ok(utf8(&a()).to_shouty_snake_case().as_bytes()),
        "kebab-case" => ok(utf8(&a()).to_kebab_case().as_bytes()),
        "str" => ok(&[a(), b()].concat()),
        "strip-prefix" => {
            let (s, prefix) = (a(), b());
            ok(s.strip_prefix(prefix.as_slice()).unwrap_or(&s))
        }
        "strip-suffix" => {
            let (s, suffix) = (a(), b());
            ok(s.strip_suffix(suffix.as_slice()).unwrap_or(&s))
        }
        "subs" => match a().get(index(&args[2])..index(&args[3])) {
            Some(result) => ok(result),
            None => bytes_result(false, &[]),
        },
        _ => panic!("unknown op {op}"),
    };
    println!("0x{encoded}");
}
