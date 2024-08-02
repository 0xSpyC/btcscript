pub fn u256_from_byte_array_with_offset(ref arr: ByteArray, offset: usize) -> u256 {
	let mut high: u128 = 0;
	let mut low: u128 = 0;
	let total_bytes = arr.len();
	let mut i: usize = 0;
	let mut high_bytes: usize = 0;
	let mut low_bytes: usize = 16;
	let mut arr_high = arr.clone();
	let mut arr_low = arr.clone();

	// Return 0 if offset out of bound
	if offset >= total_bytes {
		return u256{high: 0,low:0}; 
	}

	let available_bytes = total_bytes - offset;

	if available_bytes > 16 {
		high_bytes = total_bytes - 16;
	} else if available_bytes < 16 {
		low_bytes = total_bytes;
	}
	while i < high_bytes {
		let mut value = 
		high = high * 256 + arr_high[i + offset].into();
	};
	while i < available_bytes {
		low = low * 256 + arr_low[i + offset].into();
	};
	u256{high,low}
}
