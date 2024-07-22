#[derive(Drop)]
pub enum ValidatingError {
    DisabledOpcode,
}

pub enum ParsingError {
    InvalidScript,
    InvalidOpcode,
    EmptyScript,
}

#[derive(Drop)]
pub enum RuntimeError {
    StackOperationError,
}

#[derive(Drop)]
pub enum ScriptError {
    ScriptValidityError: ScriptValidityError,
    RuntimeError: RuntimeError,
}
