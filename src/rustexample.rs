// SPDX-License-Identifier: GPL-2.0

// Module Declarations
mod driver;

/// Virtual Device Module
use kernel::prelude::*;
use crate::driver::*;

module! {
    type: RustExample,
    name: "rustexample",
    author: "EightB1ts",
    description: "A rusty Kernel Module",
    license: "GPL",
}

struct RustExample;

impl kernel::Module for RustExample {

    fn init(_module: &'static ThisModule) -> Result<Self> {
        // Banner
        driver::hello();
        Ok(RustExample)
    }

}

impl Drop for RustExample {
    fn drop(&mut self) {
        pr_info!("Rust Example (exit)\n");
    }
}