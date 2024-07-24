use shinigami::core::stack::{ExecStack, ExecStackTrait};
use shinigami::core::error::ScriptError;

pub fn op_1(ref stack: ExecStack) -> Result<(), ScriptError> {
    let mut push_value: ByteArray = "";
    push_value.append_byte(1);
    stack.push(push_value);
    Result::Ok(())
}

#[test]
fn op_1_test() {
    let mut stack: ExecStack = Default::default();
    let _result = op_1(ref stack);
    assert!(stack.len() == 1, "OP_1: Stack lenght error");
    let stack_value = stack.pop().unwrap();
    assert!(stack_value.at(0) == Option::Some(1), "OP_1: Value error");
}
