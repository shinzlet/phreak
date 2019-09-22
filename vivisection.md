# How Phreak works under the hood
I'll write a detailed explanation as soon as I can, but for now:

`Phreak.parse!` is an alias to `Phreak.parse(ARGV)`. That method creates a
`Parser`, which is an extended `Subparser`. After initialization, `parse` yields
the `Parser`, which allows bindings to be created by the user.

Finally, `Phreak#parse` invokes `Parser#begin_parsing`,
a protected method that either calls the default action, or invokes the `process_token`
function on itself, which is inherited from `Subparser`, depending on the number of
arguments that were provided.

My apologies for such a short explanation, but I'm an engineering student, so my time is
quite limited. I'll do my best to fix this soon.
