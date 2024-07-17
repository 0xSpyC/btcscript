use core::traits::TryInto;
use btcscript::preprocess::{Opcode, ScriptElement, get_disabled_opcode};

fn test() {
    let data: ByteArray = "4104faaf6ee17000225046f18fec61c6b9a0cb516bac546054c4f22fd7e6974c27f5519a9be203eacd01e842e8705e094cffc1e229ace53f8556acd9b95e1f4e30ceac";
    let ALLOWED_OPCODE: Array<u8> = array![126, 129];
    let mut convertedData: ByteArray = "";

    let mut i = 0;

    while i != data.len() {
        let mut value = 0;
        let mut dix = 0;
        let mut unit = 0;
        if ( data[i] >= 48 && data[i] <= 58) {
            dix = (data[i] - 48 )* 10;
        } else if ( data[i] >= 97 && data[i] <= 102) {
            dix = 160 + (data[i] - 97 )* 16;
        } else if ( data[i] >= 65 && data[i] <= 70) {
            dix = 160 + (data[i] - 65 )* 16;
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

        value = dix + unit;
        convertedData.append_byte(value);
        i+=2;
    };

    let mut ScriptElementArray:Array<ScriptElement> = ArrayTrait::<ScriptElement>::new();
    i = 0;

    while i != convertedData.len() {
        let mut state = 0;
        let mut temp_opcode: u8 = convertedData.at(i).unwrap();

        if ( temp_opcode > 0 && temp_opcode < 187 ) && state == 0 { 
        
        if temp_opcode == 0 || temp_opcode > 78 {
            let mut element_opcode: Opcode = temp_opcode.try_into().unwrap();
            
        } else {
            state = 1;
        }
        } else if state == 1 {

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
    };



}


#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        super::test();
        assert(16 == 16, 'it works!');
    }
}