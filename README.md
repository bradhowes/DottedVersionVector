# DottedVersionVector Library

This is a Swift implementation of the _dotted version vector_ as described in the paper
[http://gsd.di.uminho.pt/members/vff/dotted-version-vectors-2012.pdf](Dotted Version Vectors: Efficient Causality Tracking for Distributed Key-Value Stores) by 
Gonçalves R, Almeida PS, Moreno CB, Fonte V, Preguiça N. (2012). 
This code used the [https://github.com/ricardobcl/Dotted-Version-Vectors](reference implementation in Erlang) for guidance (and test cases).

Additional background information: https://en.wikipedia.org/wiki/Version_vector

# Implementation Details

The basic class is `DVV` which contains a version vector and a `Dot` which is just a named counter. The version vection itself is
simply an ordered collection of `Dot` instances, but with slightly different semantics. The `Dot` instance in the `DVV` refers to a 
write counter for a given server, while the `Dot` instances in the version history record the relationships between versions.

The Erlang reference implementation incorporates a timestamp in the `Dot` defintion that is used to order `Dot` instances when the 
server or replica key is the same. This Swift implementation does not do this -- it assumes that the server or replica managing the 
`Dot` counter can guarantee that it is properly incremented at every update.

Just like the Erlang implementation, a DVV is immutable. The DVV API will generate a new DVV instance instead of changing a value
in-place.
