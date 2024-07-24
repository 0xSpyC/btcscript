use shinigami::core::stack::{ExecStack, ExecStackTrait};
use shinigami::core::error::ScriptError;

pub fn op_0(ref stack: ExecStack) -> Result<(), ScriptError> {
    let push_value: ByteArray = "";
    stack.push(push_value);
    Result::Ok(())
}

#[test]
fn op_0_test() {
    let mut stack: ExecStack = Default::default();
    let _result = op_0(ref stack);
    assert!(stack.len() == 1, "OP_0: Stack lenght error");
    let stack_value = stack.pop().unwrap();
    assert!(stack_value.at(0) == Option::None(()), "OP_0: Value error");
}
