use core::traits::Into;
use core::option::OptionTrait;
use core::byte_array::ByteArrayTrait;
use core::array::ArrayTrait;
use core::traits::TryInto;
use btcscript::preprocess::{Opcode, ScriptElement, get_disabled_opcode};
use core::box::Box;
use core::bytes_31;
use core::byte_array;

// #[derive(Drop)]
// struct Foo{
//     data : u32,
// }

// trait FooTrait{
//     fn bar(ref self: Foo);
//     fn baz(ref self: Foo);
// }

// impl FooImpl of FooTrait{
//     fn bar(ref self: Foo) {
//         println!("Hellobar");
//     }
//     fn baz(ref self: Foo) {
//         println!("Hellobaz");
//     }
// }

// fn bar() {
//     println!("Hellobar");
// }

fn string_to_byte_array(data: ByteArray) -> ByteArray {
    let mut rvalue: ByteArray = "";
    let mut i: u32 = 0;

    while i != data.len() {
        let mut value = 0;
        let mut ten = 0;
        let mut unit = 0;
        if ( data[i] >= 48 && data[i] <= 58) {
            ten = (data[i] - 48 )* 16;
        } else if ( data[i] >= 97 && data[i] <= 102) {
            ten = 160 + (data[i] - 97 )* 16;
        } else if ( data[i] >= 65 && data[i] <= 70) {
            ten = 160 + (data[i] - 65 )* 16;
        } else {
            panic!("wrong character");
        }

        if ( data[i + 1] >= 48 && data[i + 1] <= 58) {
            unit = data[i + 1] - 48;
        } else if ( data[i + 1] >= 97 && data[i + 1] <= 102) {
            unit = data[i + 1] - 87;
        } else if ( data[i + 1] >= 65 && data[i + 1] <= 70) {
            unit = data[i + 1] - 55;

        } else {
            panic!("wrong character unit");
        }

        value = ten + unit;
        rvalue.append_byte(value);
        i+=2;
    };
    return rvalue;
}

fn byte_array_to_script_element_array(data: ByteArray) -> Array<ScriptElement> {
    let mut i = 0;
    let mut rvalue:Array<ScriptElement> = ArrayTrait::<ScriptElement>::new();
    //optimize Byte Array 
    let mut state: u32 = 0;
    println!("{}", data.len());
    let mut temp_value: ByteArray = "";
    let mut temp_state: u32 = 0;
    let mut pushdata_size: Array<u8> = ArrayTrait::new();
    while i != data.len(){
        print!("i: {} ", i);
        
        let mut temp_opcode: u8 = data.at(i).unwrap().into();
        

        print!("value: {} ", temp_opcode);
        if ( temp_opcode > 0 && temp_opcode < 187 ) && state == 0 { 
            let mut element_opcode: Opcode = temp_opcode.try_into().unwrap();
            rvalue.append(ScriptElement::Opcode(element_opcode));
        if temp_opcode == 0 || temp_opcode > 80 {
            
        } else {
            state = temp_opcode.into();

            print!("catched size: {} ", state);
        }
        } else if state > 75 {
            pushdata_size.append(temp_opcode);
            state -= 1;

        } else if state > 0 {
            print!(" state: {}", state);
            if state == 75 && pushdata_size.len() != 0 {
                let mut i:u32 = 0;
                while pushdata_size.len() != 0 {
                    match pushdata_size.pop_front() {
                        Option::Some(x) => {
                            if i == 0 {
                                temp_state += x.into();
                            }
                            else if i == 1 {
                                temp_state += x.into() * 256;
                            }
                            else if i == 2 {
                                temp_state += x.into() * 65536;
                            }
                            else if i == 3 {
                                temp_state += x.into() * 16777216;
                            }
                        },
                        Option::None => {},
                    }
                };
                state = temp_state + 1;
                pushdata_size = ArrayTrait::new();
            }
            temp_value.append_byte(data.at(i).unwrap());
            
            if state == 1 {
                rvalue.append(ScriptElement::Value(temp_value));
                temp_value = "";
            }
            state -= 1;
        }
            

        //     let temp_allowed_opcode = ALLOWED_OPCODE.span();

        //     let mut opcode_result = 0;

        //     while temp_allowed_opcode.len() != 0 {
        //         match temp_allowed_opcode.pop_front() {
        //             Option::Some(x) => {
        //                 opcode_result *= convertedData[i] - x;
        //             },
        //             Option::None => {},
        //         }
        //     }

        //     if opcode_result != 0
            

        // }
        i+=1;
            println!("");
    };

    return rvalue;
}
fn test() {
    let data: ByteArray = string_to_byte_array("4104faaf6ee17000225046f18fec61c6b9a0cb516bac546054c4f22fd7e6974c27f5519a9be203eacd01e842e8705e094cffc1e229ace53f8556acd9b95e1f4e30ceac");
    //let ALLOWED_OPCODE: Array<u8> = array![126, 129];
    let mut ScriptElementArray: Array<ScriptElement> = byte_array_to_script_element_array(data);
    
    println!("{}", ScriptElementArray.len());
    while ScriptElementArray.len() != 0 {
        match ScriptElementArray.pop_front() {
            Option::Some(x) => {
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
            },
            Option::None => {}
        }
    }

}


#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        super::test();
        assert(16 == 16, 'it works!');
    }
}