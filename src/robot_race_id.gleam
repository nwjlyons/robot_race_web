const size = 5
const alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

@external(erlang, "Elixir.Nanoid", "generate")
fn nanoid_generate(size: Int, alphabet: String) -> String

pub fn new() -> String {
  nanoid_generate(size, alphabet)
}
