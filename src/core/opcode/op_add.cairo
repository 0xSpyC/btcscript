use shinigami::core::stack::{ExecStack, ExecStackTrait};
use shinigami::core::error::ScriptError;

pub fn op_add(ref stack: ExecStack) -> Result<(), ScriptError> {
	if (stack.len() < 2) {
		return Result::Error(ScriptError::RuntimeError(RuntimeError::StackOperationError));
	}
	let value1 = stack.pop().unwrap();
	let value2 = stack.pop().unwrap();
	let push_value: i64
	Result::Ok(())
}

#[test]
fn op_add_test() {
    let mut stack: ExecStack = Default::default();
}
