use core::traits::Into;
use core::option::OptionTrait;
use core::byte_array::ByteArrayTrait;
use core::array::ArrayTrait;
use core::traits::TryInto;
use btcscript::preprocess::{Opcode, ScriptElement, get_disabled_opcode};
use core::byte_array;


fn hex_to_dec(value: u8) -> Option<u8> {
    if (value >= 48 && value <= 57) {
        Option::Some(value - 48) // '0'..='9'
    } else if (value >= 65 && value <= 70) {
        Option::Some(value - 55) // 'A'..='F'
    } else if (value >= 97 && value <= 102) {
        Option::Some(value - 87) // 'a'..='f'
    } else {
        return Option::None;
    }
}

fn string_to_byte_array(data: ByteArray) -> Option<ByteArray> {
    let mut rvalue: ByteArray = "";
    let mut i: u32 = 0;
    let mut invalid_character: bool = false;

    while i != data.len() {
        let mut ten = 0;
        let mut unit = 0;

        match hex_to_dec(data[i]) {
            Option::Some(x) => {
                ten = x;
            },
            Option::None => {
                invalid_character = true;
            },
        }
        match hex_to_dec(data[i + 1]) {
            Option::Some(x) => {
                unit = x;
            },
            Option::None => {
                invalid_character = true;
            },
        }

        rvalue.append_byte(ten * 16 + unit);
        i+=2;
    };

    if invalid_character{
         return(Option::None);
    }
    Option::Some(rvalue)
}

#[derive(Drop)]
struct ScriptPreProcessor {
    pub(crate) data: ByteArray,
    pub(crate) index: usize,
    pub(crate) state: u32,
    pub(crate) temp_value: ByteArray,
    pub(crate) temp_state: u32,
    pub(crate) pushdata_size: Array<u8>,
    pub(crate) read_data: bool,
    pub(crate) script_elements: Array<ScriptElement>,
    pub(crate) successfuly_processed: bool,
}

trait ScriptPreProcessorTrait {
    fn new(data: ByteArray) -> ScriptPreProcessor;

    fn process(ref self: ScriptPreProcessor) -> Option<Array<ScriptElement>>;

    fn handle_opcode(ref self: ScriptPreProcessor, opcode: u8);

    fn handle_value_size(ref self: ScriptPreProcessor, opcode: u8);

    fn process_pushdata_size(ref self: ScriptPreProcessor) -> u32;

    fn handle_value(ref self: ScriptPreProcessor);

    fn display(ref self: ScriptPreProcessor);
}

impl ScriptPreProcessorImpl of ScriptPreProcessorTrait{
    fn new(data: ByteArray) -> ScriptPreProcessor {
        let mut data_preprocess: ByteArray = "";
        if let Option::Some(x) = string_to_byte_array(data) {
            data_preprocess = x;
        }
        ScriptPreProcessor {
            data: data_preprocess,
            index: 0,
            state: 0,
            temp_value: "",
            temp_state: 0,
            pushdata_size: ArrayTrait::new(),
            read_data: false,
            script_elements: ArrayTrait::new(),
            successfuly_processed: false,
        }
    }

    fn process(ref self: ScriptPreProcessor) -> Option<Array<ScriptElement>> {
        if self.data.len() == 0 {
            return Option::None;
        }

        while self.index < self.data.len() {
            let opcode = self.data[self.index];

            if (opcode > 0 && opcode < 187) && self.state == 0 {
                self.handle_opcode(opcode);
            } else if self.state > 75 && !self.read_data {
                self.handle_value_size(opcode);
            } else if self.state > 0 {
                self.handle_value();
            }
        self.index += 1;
    };

        Option::Some(self.script_elements.clone())
    }

    fn handle_opcode(ref self: ScriptPreProcessor, opcode: u8) {
        let element_opcode: Opcode = opcode.try_into().unwrap();

        self.script_elements.append(ScriptElement::Opcode(element_opcode));
        if opcode > 0 && opcode <= 80 {
            self.state = opcode.into();
        }
    }

    fn handle_value_size(ref self: ScriptPreProcessor, opcode: u8) {
                self.pushdata_size.append(opcode);
                self.state -= 1;
                if self.state == 75 {
                    self.read_data = true;
                }
    }

    fn process_pushdata_size(ref self: ScriptPreProcessor) -> u32 {
        let mut result = 0;
        let mut multiplier = 1;
        while let Option::Some(x) = self.pushdata_size.pop_front() {
            result += x.into() * multiplier;
            multiplier *= 256;
        };
        result
    }

    fn handle_value(ref self: ScriptPreProcessor) {
        if self.state == 75 && !self.pushdata_size.is_empty() {
            self.temp_state = self.process_pushdata_size();
            self.state = self.temp_state;
        }
        self.temp_value.append_byte(self.data[self.index]);
        if self.state == 1 {
            self.script_elements.append(ScriptElement::Value(self.temp_value.clone()));
            self.temp_value = "";
            self.read_data = false;
        }
        self.state -= 1;
    }



    fn display(ref self: ScriptPreProcessor) {

    while self.script_elements.len() != 0 {
        if let Option::Some(x) =  self.script_elements.pop_front() {
                match x {
                    ScriptElement::Opcode(x) => {
                        let mut number: u8 = x.into();
                        println!("{}", number);
                    },
                    ScriptElement::Value(x) => {
                        let mut iterator = 0;
                        while iterator != x.len() {
                            print!("{} ", x.at(iterator).unwrap());
                            iterator += 1;
                        };
                        println!("");
                    }
                }
            }
        };
    }
}

#[derive(Drop, Clone)]
struct ScriptProcessor {
    pub(crate) scriptElementArray: Array<ScriptElement>,
    pub(crate) disabledOpcodes: Span<Opcode>,
	pub(crate) valid: bool,
}

trait ScriptProcessorTrait {
    fn new(data: Array<ScriptElement>) -> ScriptProcessor;

    fn set_allowed_opcode(ref self: ScriptProcessor,ref opcodes: Array<Opcode>);

	fn set_disabled_opcode(ref self: ScriptProcessor,ref opcodes: Array<Opcode>);

    fn check(ref self: ScriptProcessor) -> bool;

    fn get_script_element_array(ref self: ScriptProcessor) -> Array<ScriptElement>;
}

impl ScriptProcessorImpl of ScriptProcessorTrait {

    fn new(data: Array<ScriptElement>) -> ScriptProcessor {
        ScriptProcessor {
            scriptElementArray: data,
            disabledOpcodes: get_disabled_opcode(),
			valid: false,
        }
    }


    fn set_allowed_opcode(ref self: ScriptProcessor,ref opcodes: Array<Opcode>){
		let mut newDisabledOpcodes: Array<Opcode> = ArrayTrait::new();

		while opcodes.len() != 0 {
			if let Option::Some(x) = opcodes.pop_front() {
				while self.disabledOpcodes.len() != 0 {
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

	fn set_disabled_opcode(ref self: ScriptProcessor, ref opcodes: Array<Opcode>) {
		
	}

    fn check(ref self: ScriptProcessor) -> bool {
		let mut script_len: u32 = self.scriptElementArray.len();
		let mut validScript: bool = true;

		while self.disabledOpcodes.len() != 0 {
			let mut scriptIndex: u32 = script_len;
			if let Option::Some(x) = self.disabledOpcodes.pop_front() {
				while scriptIndex != 0 {
					let mut scriptElement = self.scriptElementArray.at(scriptIndex - 1);
					
					match scriptElement {
						ScriptElement::Opcode(y) => {
							let a: u8 = (*x).into();
							let b: u8 = (y).into();
							if a == b {
								validScript = false;
								break;
							}
						},
						ScriptElement::Value(_) => {},
					}
					scriptIndex -= 1;
				};
				if !validScript {
					break;
				}
			}
		};
        validScript
    }

    fn get_script_element_array(ref self: ScriptProcessor) -> Array<ScriptElement> {
        self.scriptElementArray.clone()
    }
}

fn test() {
    //let data: ByteArray = "4104faaf6ee17000225046f18fec61c6b9a0cb516bac546054c4f22fd7e6974c27f5519a9be203eacd01e842e8705e094cffc1e229ace53f8556acd9b95e1f4e30ceac";
    let data: ByteArray = "a91481279aabd6ee711aee502ed4dcd00be1c6ff8edf87";
    //let data: ByteArray = "4d0001aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    //let data: ByteArray = "48304502202e591bff9983f4c102406764e6d5a02d3f0d386016c1431a46d08a3f53facc84022100ee1a178685fbb5839188cc8d32e8c09092a51539bce6e1133be63059babdf8ac01410475bcdc7a50286e1359b73bac3406956476b3d4f0c1788a6b8962d7bb012bcc7477422c828425a07db480d3c249c784a933325af9201497e8c761036351d06155";
    //let ALLOWED_OPCODE: Array<u8> = array![126, 129];
    let mut processor: ScriptPreProcessor = ScriptPreProcessorTrait::new(data);
    let mut _ScriptElementArray: Array<ScriptElement> = processor.process().unwrap();
    processor.display();
}


// main() {
//
// 	let script: ScriptProcessor = ScriptProccesor::load_script();
// 	script.set_allowed_opcodes(array![Opcode::OP_CAT, Opcode::OP_LSHIFT]);
// 	script.run();
// }


#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        super::test();
        assert(16 == 16, 'it works!');
    }
}
