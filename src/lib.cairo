mod core {
    mod parser;
    mod script;
    mod error;
    mod stack;
    mod opcode {
        pub mod opcode;
        pub mod op_0;
    }
}

mod utils;
