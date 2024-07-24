use shinigami::core::stack::{ExecStack, ExecStackTrait};
use shinigami::core::error::ScriptError;

pub fn op_add(ref stack: ExecStack) -> Result<(), ScriptError> {
	if stack.len() < 2 {
		return Result::Error(ScriptError::RuntimeError(RuntimeError::StackOperationError));
	}
	let value1 = stack.pop_int();
	let value2 = stack.pop_int();
	if value1 == Option::None() | value2 == Option::None() {
		return Result::Error(ScriptError::RuntimeError(RuntimeError::StackOperationError));
	}
	let push_value: i64 = value1.unwrap() + value2.unwrap();
	stack.push_int(push_value);
	Result::Ok(())
}

#[test]
fn op_add_test() {
    let mut stack: ExecStack = Default::default();
}
