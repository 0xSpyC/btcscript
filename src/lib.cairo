mod core {
    mod parser;
    mod script;
    mod error;
    mod stack;
    mod opcode {
        pub mod opcode;
        pub mod op_0;
        pub mod op_1;
		pub mod op_add;
    }
}

mod utils;
