use core::nullable::NullableTrait;
use core::byte_array::ByteArray;
use core::dict::Felt252DictEntryTrait;

#[derive(Destruct, Default)]
pub struct ExecStack {
    data: Felt252Dict<Nullable<ByteArray>>,
    len: usize,
}

#[generate_trait()]
pub impl ExecStackImpl of ExecStackTrait {
    fn push(ref self: ExecStack, value: ByteArray) {
        self.data.insert(self.len.into(), NullableTrait::new(value));
        self.len += 1;
    }

    fn pop(ref self: ExecStack) -> Option<ByteArray> {
        if self.is_empty() {
            return Option::None;
        }
        self.len -= 1;
        let (entry, arr) = self.data.entry(self.len.into());
        self.data = entry.finalize(NullableTrait::new(""));
        Option::Some(arr.deref())
    }

	fn pop_int(ref self: ExecStack) -> Option<i64> {
		let bytes = match self.pop() {
			Option::Some(x) => x,
			Option::None() => return Option::None(),
		}
		if bytes.len() > 4 {
			return Option::None();
		}
	}

    fn is_empty(self: @ExecStack) -> bool {
        *self.len == 0
    }

    fn len(self: @ExecStack) -> usize {
        *self.len
    }
}
