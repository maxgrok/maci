<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Circuits](#circuits)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# Circuits

There are two zk-SNARK circuits in MACI: one which allows the coordinator to prove the correctness of each state root transition, and the other which proves that they have correctly tallied all the votes.

Note that the circuit pseudocode in this specification does not describe zk-SNARK outputs. The difference between inputs and outputs is only semantic. As such, we consider so-called outputs as values computed from inputs, and then verified via a public input designated as an `output` in the circom code.

See:

- [The state root transition proof circuit](./state_root_transition_circuit.md), and
- [The quadratic vote tallying circuit](./quadratic_vote_tallying_circuit.md)