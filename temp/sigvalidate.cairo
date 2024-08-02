use shinigami::engine::{Engine, EngineTraitImpl};
use starknet::SyscallResultTrait;
use starknet::secp256_trait::{Secp256Trait, Secp256PointTrait};
use starknet::secp256k1::{Secp256k1Impl, Secp256k1Point};
use starknet::secp256_trait::Signature;
use shinigami::scriptflags::ScriptFlags;
use shinigami::utils::u256_from_byte_array_with_offset;

const SIG_HASH_DEFAULT: u32 = 0x0;
const SIG_HASH_ALL: u32 = 0x1;
const SIG_HASH_NONE: u32 = 0x2;
const SIG_HASH_SINGLE: u32 = 0x3;
const SIG_HASH_ANYONECANPAY: u32 = 0x80;

const BASE_SEGWIT_WITNESS_VERSION: u32 = 0x0;

const MIN_SIG_LEN: usize = 8;
const MAX_SIG_LEN: usize = 72;

const MAX_U128: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

pub struct BaseSigVerifier {
	vm: Engine,

	pk_key: Secp256k1Point,

	sig: Signature,

	sig_bytes: ByteArray,

	pk_bytes: ByteArray,

	sub_script: ByteArray,

	hash_type: u32,

}

pub trait BaseSigVerifierTrait {
}

impl BaseSigVerifierImpl of BaseSigVerifierTrait {

}

fn check_hash_type_encoding(ref vm: Engine, mut hash_type: u32) {
	if !vm.has_flag(ScriptFlags::ScriptVerifyStrictEncoding) {
		return;
	}

	if hash_type > SIG_HASH_ANYONECANPAY {
		hash_type -= SIG_HASH_ANYONECANPAY;
	}

	if hash_type < SIG_HASH_ALL || hash_type > SIG_HASH_SINGLE {
		panic!("Invalid hash type");
	}
}

fn check_signature_encoding(ref vm: Engine, ref sig_bytes: ByteArray) {
	if (!vm.has_flag(ScriptFlags::ScriptVerifyStrictEncoding) && !vm.has_flag(ScriptFlags::ScriptVerifyDERSignatures) && !vm.has_flag(ScriptFlags::ScriptVerifyLowS))
	{
		return;
	}

	let asn1_sequence_id: u8 = 0x30;
	let asn1_integer_id: u8 = 0x02;


	let sequence_offset: usize = 0;
	let data_len_offset: usize = 1;
	let data_offset: usize = 1;
	let r_type_offset: usize = 2;
	let r_len_offset: usize = 3;
	let r_offset: usize = 4;
	let hash_type_len: usize = 1;

	let sig_len = sig_bytes.len() - hash_type_len;

	if sig_len < MIN_SIG_LEN {
		panic!("invalid signature format: too short");
	}

	if sig_len > MAX_SIG_LEN {
		panic!("invalid signature format: too long");
	}

	if sig_bytes[sequence_offset] != asn1_sequence_id {
		panic!("invalid signature format: wrong type");
	}

	if  sig_bytes[data_len_offset] != (sig_len - data_offset).try_into().unwrap() {
		panic!("invalid signature format: bad length");
	}

	let r_len: usize = sig_bytes[r_len_offset].into();
	let s_type_offset = r_offset + r_len;
	let s_len_offset = s_type_offset + 1;

	if s_type_offset > sig_len {
		panic!("invalid signature format: S type indicator missing");
	}

	if s_len_offset > sig_len {
		panic!("invalid signature format: S length missing");
	}

	let s_offset = s_len_offset + 1;
	let s_len = sig_bytes[s_len_offset];
	//
	if sig_bytes[r_type_offset] != asn1_integer_id {
		panic!("invalid signature format: wrong R integer identifier");
	}

	if r_len == 0 {
		panic!("invalid signature format: R length is zero");
	}

	if sig_bytes[r_offset] & 0x80 != 0 {
		panic!("invalid signature format: negative R");
	}

	if r_len > 1 && sig_bytes[r_offset] == 0  && sig_bytes[r_offset + 1] & 0x80 == 0 {
		panic!("invalid signature format: R value has too much padding");
	}

	if r_len == 0 {
		panic!("invalid signature format: R length is zero");
	}

	if sig_bytes[s_type_offset] != asn1_integer_id {
		panic!("invalid signature format: wrong S integer identifier");
	}

	if s_len == 0 {
		panic!("invalid signature format: S length is zero");
	}

	if sig_bytes[s_offset] & 0x80 != 0 {
		panic!("invalid signature format: negative S");
	}

	if s_len > 1 && sig_bytes[s_offset] == 0  && sig_bytes[s_offset + 1] & 0x80 == 0 {
		panic!("invalid signature format: S value has too much padding");
	}

	//TODO verify LowS if flag activates
	if vm.has_flag(ScriptFlags::ScriptVerifyLowS) {
		let s_value = u256_from_byte_array_with_offset(ref sig_bytes, s_offset + s_len);
		let half_order = Secp256k1Impl::get_curve_size();

		let carry = half_order.high % 2;
		half_order.low = (half_order.low / 2) + (carry * (MAX_U128 / 2 + 1));
		half_order.high /= 2;

		if s_value > half_order {
			panic!("signature is not canonical due to unnecessarily high S value")
		}
	}

}

fn is_compressed_pub_key(ref pk_bytes: ByteArray) -> bool {
	if pk_bytes.len() == 33 && pk_bytes[0] == 0x02 || pk_bytes[0] == 0x03 {
		return true;
	}
	return false;
}

fn is_supported_pub_key_type(ref pk_bytes: ByteArray) -> bool{
	if is_compressed_pub_key(ref pk_bytes) {
		return true;
	}
	if pk_bytes.len() == 65 && pk_bytes[0] == 0x04 {
		return true;
	}

	return false;
}

fn check_pub_key_encoding(ref vm: Engine, ref pk_bytes: ByteArray) {

	if vm.has_flag(ScriptFlags::ScriptVerifyWitnessPubKeyType) && vm.is_witness_version_active(BASE_SEGWIT_WITNESS_VERSION) && !is_compressed_pub_key(ref pk_bytes) {
		panic!("only compressed keys are accepted post-segwit");
	}

	if !vm.has_flag(ScriptFlags::ScriptVerifyStrictEncoding) {
		return;
	}

	if !is_supported_pub_key_type(ref pk_bytes) {
		panic!("unsupported public key type");
	}
}

fn parse_pub_key(ref pk_bytes: ByteArray) -> Secp256k1Point{
	let mut pk_bytes_uncompressed = pk_bytes.clone();

	if is_compressed_pub_key(ref pk_bytes) {
		let mut parity:bool = false;
		let pub_key: u256 = u256_from_byte_array_with_offset(ref pk_bytes, 1);

		if pk_bytes[0] == 0x03 {
			parity = true;
		}
		return  Secp256Trait::secp256_ec_get_point_from_x_syscall(pub_key, parity).unwrap_syscall().expect('Secp256k1Point: Invalid point.');
	} else {
		let pub_key: u256 = u256_from_byte_array_with_offset(ref pk_bytes_uncompressed, 1);
		let parity = pk_bytes_uncompressed[64] & 1 == 0;

		return  Secp256Trait::secp256_ec_get_point_from_x_syscall(pub_key, parity).unwrap_syscall().expect('Secp256k1Point: Invalid point.');
	}
}

// fn parse_sig(ref sig_bytes: ByteArray, der: bool) -> Signature {
// 	
// 	let asn1_sequence_id: u8 = 0x30;
// 	let asn1_integer_id: u8 = 0x02;
//
// 	let sequence_offset: usize = 0;
// 	let data_len_offset: usize = 1;
// 	let data_offset: usize = 1;
// 	let r_type_offset: usize = 2;
// 	let r_len_offset: usize = 3;
// 	let r_offset: usize = 4;
// 	let hash_type_len: usize = 1;
//
// 	let sig_len = sig_bytes.len() - hash_type_len;
//
// 	if !der && sig_len < MIN_SIG_LEN {
// 		panic!("invalid signature format: too short");
// 	}
//
// 	if sig_bytes[sequence_offset] != asn1_sequence_id {
// 		panic!("invalid signature format: wrong type");
// 	}
//
// 	if  sig_bytes[data_len_offset] != (sig_len - data_offset).try_into().unwrap() {
// 		panic!("invalid signature format: bad length");
// 	}
//
// 	let r_len: usize = sig_bytes[r_len_offset].into();
// 	let s_type_offset = r_offset + r_len;
// 	let s_len_offset = s_type_offset + 1;
//
// 	if s_type_offset > sig_len {
// 		panic!("invalid signature format: S type indicator missing");
// 	}
//
// 	if s_len_offset > sig_len {
// 		panic!("invalid signature format: S length missing");
// 	}
//
// 	let s_offset = s_len_offset + 1;
// 	let s_len = sig_bytes[s_len_offset];
// 	//
// 	if sig_bytes[r_type_offset] != asn1_integer_id {
// 		panic!("invalid signature format: wrong R integer identifier");
// 	}
//
// 	if r_len == 0 {
// 		panic!("invalid signature format: R length is zero");
// 	}
//
// 	if sig_bytes[r_offset] & 0x80 != 0 {
// 		panic!("invalid signature format: negative R");
// 	}
//
// 	if r_len > 1 && sig_bytes[r_offset] == 0  && sig_bytes[r_offset + 1] & 0x80 == 0 {
// 		panic!("invalid signature format: R value has too much padding");
// 	}
//
// 	if r_len == 0 {
// 		panic!("invalid signature format: R length is zero");
// 	}
//
// 	if sig_bytes[s_type_offset] != asn1_integer_id {
// 		panic!("invalid signature format: wrong S integer identifier");
// 	}
//
// 	if s_len == 0 {
// 		panic!("invalid signature format: S length is zero");
// 	}
//
// 	if sig_bytes[s_offset] & 0x80 != 0 {
// 		panic!("invalid signature format: negative S");
// 	}
//
// 	if s_len > 1 && sig_bytes[s_offset] == 0  && sig_bytes[s_offset + 1] & 0x80 == 0 {
// 		panic!("invalid signature format: S value has too much padding");
// 	}
// }

// fn parse_DER_signature(ref sig_bytes: ByteArray) -> Signature {
// 	parse_sig(ref sig_bytes, true)
// }
//
// fn parse_signature(ref sig_bytes: ByteArray) -> Signature {
// 	parse_sig(ref sig_bytes, false)
// }

pub fn parse_base_sig_and_pk(ref vm: Engine, 
	ref pk_bytes: ByteArray, 
	ref sig_bytes: ByteArray) {

	let mut strict_encoding: bool = vm.has_flag(ScriptFlags::ScriptVerifyStrictEncoding) || vm.has_flag(ScriptFlags::ScriptVerifyDERSignatures);

	let hash_type_offset: u32 = sig_bytes.len().into() - 1;
	let hash_type = sig_bytes[hash_type_offset].into();
	//self.signature_bytes = 
	check_hash_type_encoding(ref vm, hash_type);
	check_signature_encoding(ref vm, ref sig_bytes);
	check_pub_key_encoding(ref vm, ref pk_bytes);

	let pub_key = parse_pub_key(ref pk_bytes);

	// let sig = if strict_encoding {
	// 	parse_DER_signature(ref sig_bytes)
	// } else {
	// 	parse_signature(ref sig_bytes)
	// }






	// BaseSigVerifier {
	// vm: vm,
	//
	// pk_key: Default::default(),
	//
	// sig: Default::default(),
	//
	// sig_bytes: ByteArray,
	//
	// pk_bytes: ByteArray,
	//
	// sub_script: ByteArray,
	//
	// hash_type: u32,
	// }
}
