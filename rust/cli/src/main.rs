mod cli;
pub fn main() {
    let args = <cli::Cli as clap::Parser>::parse();
    match args.cmd {
        cli::SubCommand::Add(add) => {
            println!("Add: {:?}", add);
        }
        cli::SubCommand::List(list) => {
            println!("List: {:?}", list);
        }
        cli::SubCommand::Completions { shell } => {
            cli::Cli::completions(shell);
        }
    }
}
