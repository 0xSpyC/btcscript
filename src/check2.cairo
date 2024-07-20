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

fn string_to_byte_array(data: ByteArray) -> ByteArray {
    let mut rvalue: ByteArray = "";
    let mut i: u32 = 0;

    while i != data.len() {
        let mut ten = 0;
        let mut unit = 0;

        match hex_to_dec(data[i]) {
            Option::Some(x) => {
                ten = x;
            },
            Option::None => {
                panic!("wrong character");
            },
        }

        match hex_to_dec(data[i + 1]) {
            Option::Some(x) => {
                unit = x;
            },
            Option::None => {
                panic!("wrong character");
            },
        }

        rvalue.append_byte(ten * 16 + unit);
        i+=2;
    };

    // while i != data.len() {
    //     let mut value = 0;
    //     let mut ten = 0;
    //     let mut unit = 0;
    //     if ( data[i] >= 48 && data[i] <= 58) {
    //         ten = (data[i] - 48 )* 16;
    //     } else if ( data[i] >= 97 && data[i] <= 102) {
    //         ten = 160 + (data[i] - 97 )* 16;
    //     } else if ( data[i] >= 65 && data[i] <= 70) {
    //         ten = 160 + (data[i] - 65 )* 16;
    //     } else {
    //         panic!("wrong character");
    //     }

    //     if ( data[i + 1] >= 48 && data[i + 1] <= 58) {
    //         unit = data[i + 1] - 48;
    //     } else if ( data[i + 1] >= 97 && data[i + 1] <= 102) {
    //         unit = data[i + 1] - 87;
    //     } else if ( data[i + 1] >= 65 && data[i + 1] <= 70) {
    //         unit = data[i + 1] - 55;

    //     } else {
    //         panic!("wrong character unit");
    //     }

    //     value = ten + unit;
    //     rvalue.append_byte(value);
    //     i+=2;
    // };
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
    let mut read_data: bool = false;
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
        } else if state > 75 && !read_data{
            pushdata_size.append(temp_opcode);
            state -= 1;
            print!("pushed_data_size : {} ", state - 75);

        } else if state > 0 {
            print!(" state: {}", state);
            read_data = true;
            if state == 75 && pushdata_size.len() != 0 {
                let mut i:u32 = 0;
                // while pushdata_size.len() != 0 {
                //     match pushdata_size.pop_front() {
                //         Option::Some(x) => {
                //             if i == 0 {
                //                 temp_state += x.into();
                //             }
                //             else if i == 1 {
                //                 temp_state += x.into() * 256;
                //             }
                //             else if i == 2 {
                //                 temp_state += x.into() * 65536;
                //             }
                //             else if i == 3 {
                //                 temp_state += x.into() * 16777216;
                //             }
                //         },
                //         Option::None => {},
                //     }
                //     i +=1 ;
                // };

                while pushdata_size.len() != 0 {
                    if let Option::Some(x) = pushdata_size.pop_front() {
                            temp_state += x.into() * i;
                            i *= 256;
                        }
                };

                // while pushdata_size.len() != 0 {
                //     if let Option::Some(x) = pushdata_size.pop_front() {
                //             match i {
                //                 0 => temp_state += x.into(),
                //                 1 => temp_state += x.into() * 256,
                //                 2 => temp_state += x.into() * 65536,
                //                 3 => temp_state += x.into() * 16777216,
                //                 _ => {},
                //             }
                //             i += 1;
                //         }
                // };
                state = temp_state;
                pushdata_size = ArrayTrait::new();
            }
            temp_value.append_byte(data.at(i).unwrap());
            
            if state == 1 {
                rvalue.append(ScriptElement::Value(temp_value));
                temp_value = "";
                read_data = false;
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
    //let data: ByteArray = string_to_byte_array("4104faaf6ee17000225046f18fec61c6b9a0cb516bac546054c4f22fd7e6974c27f5519a9be203eacd01e842e8705e094cffc1e229ace53f8556acd9b95e1f4e30ceac");
    let data: ByteArray = string_to_byte_array("4d0001aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
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