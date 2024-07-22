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

pub fn raw_data_to_byte_array(data: ByteArray) -> Option<ByteArray> {
    let mut rvalue: ByteArray = "";
    let mut i: u32 = 0;
    let mut invalid_character: bool = false;

    while i != data
        .len() {
            let mut ten = 0;
            let mut unit = 0;

            match hex_to_dec(data[i]) {
                Option::Some(x) => { ten = x; },
                Option::None => { invalid_character = true; },
            }
            match hex_to_dec(data[i + 1]) {
                Option::Some(x) => { unit = x; },
                Option::None => { invalid_character = true; },
            }

            rvalue.append_byte(ten * 16 + unit);
            i += 2;
        };

    if invalid_character {
        return (Option::None);
    }
    Option::Some(rvalue)
}
