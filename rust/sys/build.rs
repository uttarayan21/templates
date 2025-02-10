#[path = "src/errors.rs"]
mod errors;
use ::tap::*;
use errors::*;
use std::path::{Path, PathBuf};

const MANIFEST_DIR: &str = env!("CARGO_MANIFEST_DIR");

pub fn main() -> Result<()> {
    let source_dir = Path::new(MANIFEST_DIR).join("vendor").pipe();
    // let builder = cc::Build::new().files();
    Ok(())
}

#[cfg(feature = "bindgen")]
pub fn bindgen(headers: Vec<String>) -> Result<()> {
    Ok(())
}
