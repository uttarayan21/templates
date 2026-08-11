#[path = "src/errors.rs"]
mod errors;
use errors::*;
use std::path::Path;

const MANIFEST_DIR: &str = env!("CARGO_MANIFEST_DIR");

pub fn main() -> Result<()> {
    let _source_dir = Path::new(MANIFEST_DIR).join("vendor");
    // let builder = cc::Build::new().files(sources);
    Ok(())
}

#[cfg(feature = "bindgen")]
pub fn bindgen(_headers: Vec<String>) -> Result<()> {
    Ok(())
}
