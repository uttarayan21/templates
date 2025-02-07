#[derive(Debug, clap::Parser)]
pub struct Cli {
    #[clap(subcommand)]
    pub cmd: SubCommand,
}

#[derive(Debug, clap::Subcommand)]
pub enum SubCommand {
    #[clap(name = "add")]
    Add(Add),
    #[clap(name = "list")]
    List(List),
}

#[derive(Debug, clap::Args)]
pub struct Add {
    #[clap(short, long)]
    pub name: String,
}

#[derive(Debug, clap::Args)]
pub struct List {}
