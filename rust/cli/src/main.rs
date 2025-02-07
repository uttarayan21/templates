mod cli;
pub fn main() {
    let args = <cli::Cli as clap::Parser>::parse();
}
