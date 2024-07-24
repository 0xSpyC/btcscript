use core::result::ResultTrait;
use btcscript::core::error::{ScriptError, ValidatingError, RuntimeError, ParsingError};
use btcscript::core::parser::{BtcScriptParser, BtcScriptParserTrait};
use btcscript::core::opcode::opcode::{Opcode, get_default_disabled_opcodes, execute_opcode};
use btcscript::core::stack::{ExecStack, ExecStackTrait};
use btcscript::utils::{raw_data_to_byte_array};

#[derive(Drop, Clone)]
pub enum ScriptElement {
    Opcode: Opcode,
    Value: ByteArray,
}

#[derive(Drop, Clone)]
pub struct BtcScript {
    script_elements: Array<ScriptElement>,
    disabled_opcodes: Span<Opcode>,
    is_runnable: bool,
}

pub trait BtcScriptTrait {
    fn new(data: ByteArray) -> Result<BtcScript, ScriptError>;
    fn new_with_allowed_opcodes(
        data: ByteArray, ref opcodes: Array<Opcode>
    ) -> Result<BtcScript, ScriptError>;
    fn allow_opcodes(ref self: BtcScript, ref opcodes: Array<Opcode>);
    fn disable_opcodes(ref self: BtcScript, ref opcodes: Array<Opcode>);
    fn load_script(ref self: BtcScript, data: ByteArray);
    fn check(ref self: BtcScript) -> Result<(), ScriptError>;
    fn get_script_elements(ref self: BtcScript) -> Array<ScriptElement>;
    fn run(ref self: BtcScript) -> Result<u128, ScriptError>;
}

pub impl BtcScriptImpl of BtcScriptTrait {
    fn new(data: ByteArray) -> Result<BtcScript, ScriptError> {
        let mut script: BtcScript = Default::default();

        script.load_script(data);
        //script.check()?;
        Result::Ok(script)
    }

    fn new_with_allowed_opcodes(
        data: ByteArray, ref opcodes: Array<Opcode>
    ) -> Result<BtcScript, ScriptError> {
        let mut script: BtcScript = Default::default();

        script.load_script(data);
        script.allow_opcodes(ref opcodes);
        script.check()?;
        Result::Ok(script)
    }

    fn allow_opcodes(ref self: BtcScript, ref opcodes: Array<Opcode>) {
        let mut newDisabledOpcodes: Array<Opcode> = ArrayTrait::new();

        while opcodes
            .len() != 0 {
                if let Option::Some(x) = opcodes.pop_front() {
                    while self
                        .disabled_opcodes
                        .len() != 0 {
                            if let Option::Some(y) = self.disabled_opcodes.pop_front() {
                                let a: u8 = x.into();
                                let b: u8 = (*y).into();
                                if a != b {
                                    newDisabledOpcodes.append(y.clone());
                                }
                            }
                        };
                }
                self.disabled_opcodes = newDisabledOpcodes.span();
            };
    }

    fn disable_opcodes(ref self: BtcScript, ref opcodes: Array<Opcode>) {
        self.is_runnable = false;
    }

    fn check(ref self: BtcScript) -> Result<(), ScriptError> {
        let mut script_len: u32 = self.script_elements.len();
        let mut valid_script: bool = true;
        let mut script_element = self.script_elements.span();

        while self
            .disabled_opcodes
            .len() != 0 {
                let mut scriptIndex: u32 = script_len;
                if let Option::Some(x) = self.disabled_opcodes.pop_front() {
                    while scriptIndex != 0 {
                        if let ScriptElement::Opcode(y) = script_element
                            .get(scriptIndex - 1)
                            .unwrap()
                            .unbox()
                            .clone() {
                            let a: u8 = (*x).into();
                            let b: u8 = y.into();
                            if a == b {
                                valid_script = false;
                                break;
                            }
                        }
                        scriptIndex -= 1;
                    };
                    if !valid_script {
                        break;
                    }
                }
            };
        if !valid_script {
            return (Result::Err(ScriptError::ValidatingError(ValidatingError::DisabledOpcode)));
        }
        self.is_runnable = true;
        Result::Ok(())
    }

    fn get_script_elements(ref self: BtcScript) -> Array<ScriptElement> {
        self.script_elements.clone()
    }

    fn load_script(ref self: BtcScript, data: ByteArray) {
        self.is_runnable = false;
        let mut parser: BtcScriptParser = BtcScriptParserTrait::new(data);
        let mut error = parser.parse();
        match error {
            Result::Ok(mut x) => {
                self.script_elements = x;
            },
            Result::Err(eror) => {
                if let ScriptError::ParsingError(x) = eror {
                    match x {
                        ParsingError::InvalidScript => {
                            panic!("InvalidScript");
                        },
                        ParsingError::InvalidOpcode => {
                            panic!("InvalidOpcode");
                        },
                        ParsingError::EmptyScript => {

                            panic!("EmptyScript");

                        },
                    }
                }

            }
        }
    }

    fn run(ref self: BtcScript) -> Result<u128, ScriptError> {
        let mut stack: ExecStack = Default::default();

        while (self.script_elements.len() != 0) {
            if let Option::Some(x) = self.script_elements.pop_front() {
                if let ScriptElement::Opcode(o) = x {
                    match execute_opcode(o, ref stack, ref self.script_elements) {
                        Result::Ok(_) => {},
                        Result::Err(_) => { break; },
                    };
                }
            }
        };
        if stack.len() != 1 {
            return Result::Err(ScriptError::RuntimeError(RuntimeError::ReturnedValueError));
        }
        return Result::Ok(1);
    }
}

impl BtcScriptDefault of Default<BtcScript> {
    fn default() -> BtcScript {
        let btcscript = BtcScript {
            script_elements: ArrayTrait::<ScriptElement>::new(),
            disabled_opcodes: get_default_disabled_opcodes(),
            is_runnable: false,
        };
        btcscript
    }
}

fn main() {
    let mut btcscript = BtcScriptTrait::new("000000000000");
    // match btcscript {
    //     Result::Ok(mut x) => {
    //         //let mut _error = x.run();
    //     },
    //     Result::Err(_error) => {
    //         panic!("Error");
    //     }
    // }
}

#[test]
fn test(){
    main();
}