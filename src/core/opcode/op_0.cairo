use btcscript::core::stack::{ExecStack, ExecStackTrait};
use btcscript::core::error::ScriptError;

pub fn op_0(ref stack: ExecStack) -> Result<(), ScriptError> {
    let to_push: ByteArray = "";
    stack.push(to_push);
    Result::Ok(())
}

#[cfg(test)]
mod tests {
    #[test]
    fn op_0_test() {
        // WRITE A BETTER TEST HERE
        assert(1 == 1, 'not a test');
    }
}
