use btcscript::core::error::{ScriptError, ParsingError};
use btcscript::core::script::ScriptElement;
use btcscript::core::opcode::opcode::Opcode;
use btcscript::utils::raw_data_to_byte_array;

#[derive(Drop)]
pub struct BtcScriptParser {
    data: ByteArray,
    index: usize,
    state: u32,
    temp_value: ByteArray,
    temp_state: u32,
    pushdata_size: Array<u8>,
    read_data: bool,
}

pub trait BtcScriptParserTrait {
    fn new(data: ByteArray) -> BtcScriptParser;
    fn parse(ref self: BtcScriptParser) -> Result<Array<ScriptElement>, ScriptError>;
    fn handle_opcode(ref self: BtcScriptParser, opcode: u8) -> ScriptElement;
    fn handle_value_size(ref self: BtcScriptParser, opcode: u8);
    fn handle_pushdata_size(ref self: BtcScriptParser) -> u32;
    fn handle_value(ref self: BtcScriptParser) -> Option<ScriptElement>;
}

pub impl BtcScriptParserImpl of BtcScriptParserTrait {
    fn new(data: ByteArray) -> BtcScriptParser {
        let mut data_preprocess: ByteArray = "";
        if let Option::Some(x) = raw_data_to_byte_array(data) {
            data_preprocess = x;
        }
        BtcScriptParser {
            data: data_preprocess,
            index: 0,
            state: 0,
            temp_value: "",
            temp_state: 0,
            pushdata_size: ArrayTrait::new(),
            read_data: false,
        }
    }

    fn parse(ref self: BtcScriptParser) -> Result<Array<ScriptElement>, ScriptError> {
        let mut script_elements: Array<ScriptElement> = ArrayTrait::new();
        let mut valid_opcode: bool = true;

        if self.data.len() == 0 {
            return Result::Err(ScriptError::ParsingError(ParsingError::EmptyScript));
        }
        while self
            .index < self
            .data
            .len() {
                let mut opcode = self.data[self.index];

                if (opcode >= 0 && opcode < 187) && self.state == 0 {
                    script_elements.append(self.handle_opcode(opcode));
                } else if self.state > 75 && !self.read_data {
                    self.handle_value_size(opcode);
                } else if self.state > 0 {
                    if let Option::Some(x) = self.handle_value() {
                        script_elements.append(x);
                    }
                } else {
                    valid_opcode = false;
                    break;
                }
                self.index += 1;
            };
        if self.state > 0 {
            return Result::Err(ScriptError::ParsingError(ParsingError::InvalidScript));
        }
        if !valid_opcode {
            return Result::Err(ScriptError::ParsingError(ParsingError::InvalidOpcode));
        }
        Result::Ok(script_elements)
    }

    fn handle_opcode(ref self: BtcScriptParser, opcode: u8) -> ScriptElement {
        let element_opcode: Opcode = opcode.try_into().unwrap();

        if opcode > 0 && opcode <= 80 {
            self.state = opcode.into();
        }
        ScriptElement::Opcode(element_opcode)
    }

    fn handle_value_size(ref self: BtcScriptParser, opcode: u8) {
        self.pushdata_size.append(opcode);
        self.state -= 1;
        if self.state == 75 {
            self.read_data = true;
        }
    }

    fn handle_pushdata_size(ref self: BtcScriptParser) -> u32 {
        let mut result = 0;
        let mut multiplier = 1;

        while let Option::Some(x) = self
            .pushdata_size
            .pop_front() {
                result += x.into() * multiplier;
                multiplier *= 256;
            };
        result
    }

    fn handle_value(ref self: BtcScriptParser) -> Option<ScriptElement> {
        let mut rvalue: ByteArray = "";

        if self.state == 75 && !self.pushdata_size.is_empty() {
            self.temp_state = self.handle_pushdata_size();
            self.state = self.temp_state;
        }
        self.temp_value.append_byte(self.data[self.index]);
        if self.state == 1 {
            rvalue = self.temp_value.clone();
            self.temp_value = "";
            self.read_data = false;
            self.state -= 1;
            return Option::Some(ScriptElement::Value(rvalue));
        }
        self.state -= 1;
        Option::None
    }
}
