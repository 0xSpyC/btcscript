#[derive(Drop, Clone)]
pub enum ScriptElement {
    Opcode: Opcode,
    Value: ByteArray,
}

#[derive(Drop, Clone)]
struct BtcScript {
    pub(crate) scriptElementArray: Array<ScriptElement>,
    pub(crate) disabledOpcodes: Span<Opcode>,
    pub(crate) isValid: bool,
}

trait BtcScriptTrait {
    fn new(data: ByteArray) -> Result<BtcScript, ScriptValidityError>;

    fn new_with_opcodes(
        data: ByteArray, ref opcodes: Array<Opcode>
    ) -> Result<BtcScript, ScriptValidityError>;

    fn set_allowed_opcode(ref self: BtcScript, ref opcodes: Array<Opcode>);

    fn set_disabled_opcode(ref self: BtcScript, ref opcodes: Array<Opcode>);

    fn load_script(ref self: BtcScript, data: ByteArray);

    fn check(ref self: BtcScript) -> Result<bool, ScriptValidityError>;

    fn get_script_element_array(ref self: BtcScript) -> Array<ScriptElement>;

    fn run(ref self: BtcScript) -> Result<ProgramOutput, RuntimeError>;
}

impl BtcScriptImpl of BtcScriptTrait {
    fn new(data: ByteArray) -> Result<BtcScript, ScriptValidityError> {
        let mut preprocessor: ScriptPreProcessor = ScriptPreProcessorTrait::new(data);
        match preprocessor.process() {
            Result::Ok(x) => {
                let mut rvalue = BtcScript {
                    scriptElementArray: x, disabledOpcodes: get_disabled_opcode(), isValid: false,
                };

                if let Result::Err(error) = rvalue.check() {
                    return Result::Err(error);
                }

                Result::Ok(rvalue)
            },
            Result::Err(error) => { return Result::Err(error); }
        }
    }

    fn new_with_opcodes(
        data: ByteArray, ref opcodes: Array<Opcode>
    ) -> Result<BtcScript, ScriptValidityError> {
        let mut preprocessor: ScriptPreProcessor = ScriptPreProcessorTrait::new(data);
        match preprocessor.process() {
            Result::Ok(x) => {
                let mut rvalue = BtcScript {
                    scriptElementArray: x, disabledOpcodes: get_disabled_opcode(), isValid: false,
                };

                rvalue.set_allowed_opcode(ref opcodes);

                if let Result::Err(error) = rvalue.check() {
                    return Result::Err(error);
                }

                Result::Ok(rvalue)
            },
            Result::Err(error) => { return Result::Err(error); }
        }
    }

    fn set_allowed_opcode(ref self: BtcScript, ref opcodes: Array<Opcode>) {
        let mut newDisabledOpcodes: Array<Opcode> = ArrayTrait::new();

        while opcodes
            .len() != 0 {
                if let Option::Some(x) = opcodes.pop_front() {
                    while self
                        .disabledOpcodes
                        .len() != 0 {
                            if let Option::Some(y) = self.disabledOpcodes.pop_front() {
                                let a: u8 = x.into();
                                let b: u8 = (*y).into();
                                if a != b {
                                    newDisabledOpcodes.append(y.clone());
                                }
                            }
                        };
                }
                self.disabledOpcodes = newDisabledOpcodes.span();
            };
    }

    fn set_disabled_opcode(ref self: BtcScript, ref opcodes: Array<Opcode>) {
        self.isValid = false;
    }

    fn check(ref self: BtcScript) -> Result<bool, ScriptValidityError> {
        let mut script_len: u32 = self.scriptElementArray.len();
        let mut validScript: bool = true;

        let mut scriptElement = self.scriptElementArray.span();

        while self
            .disabledOpcodes
            .len() != 0 {
                let mut scriptIndex: u32 = script_len;
                if let Option::Some(x) = self.disabledOpcodes.pop_front() {
                    while scriptIndex != 0 {
                        if let ScriptElement::Opcode(y) = scriptElement
                            .get(scriptIndex - 1)
                            .unwrap()
                            .unbox()
                            .clone() {
                            let a: u8 = (*x).into();
                            let b: u8 = y.into();

                            if a == b {
                                validScript = false;
                                break;
                            }
                        }
                        scriptIndex -= 1;
                    };
                    if !validScript {
                        break;
                    }
                }
            };
        if !validScript {
            return (Result::Err(ScriptValidityError::DisabledOpcode));
        }
        self.isValid = true;
        Result::Ok(validScript)
    }

    fn get_script_element_array(ref self: BtcScript) -> Array<ScriptElement> {
        self.scriptElementArray.clone()
    }

    fn load_script(ref self: BtcScript, data: ByteArray) {
        self.isValid = false;
        let mut preprocessor: ScriptPreProcessor = ScriptPreProcessorTrait::new(data);
        self.scriptElementArray = preprocessor.process().unwrap();
    }

    fn run(ref self: BtcScript) -> Result<ProgramOutput, RuntimeError> {
        Result::Ok(ProgramOutput::StackReturn(1))
    }
}
