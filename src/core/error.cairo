#[derive(Drop)]
pub enum ScriptError {
	ParsingError: ParsingError,
    ValidatingError: ValidatingError,
    RuntimeError: RuntimeError,
}

#[derive(Drop)]
pub enum ParsingError {
    InvalidScript,
    InvalidOpcode,
    EmptyScript,
}

#[derive(Drop)]
pub enum ValidatingError {
    DisabledOpcode,
}

#[derive(Drop)]
pub enum RuntimeError {
    StackOperationError,
}
