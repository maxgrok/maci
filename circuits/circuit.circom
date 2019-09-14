include "./leaf_existence.circom";
include "./verify_eddsamimc.circom";
include "./get_merkle_root.circom";
include "./decrypt.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

template ProcessUpdate(k){
    // k is depth of accounts tree

    // accounts tree info
    signal input tree_root;
    signal private input accounts_pubkeys[2**k, 2];

    // vote update info
    signal private input sender_pubkey[2];
    signal private input sender_detail;
    signal private input sender_updated_pubkey[2];
    signal private input sender_updated_detail;
    signal private input signature_R8x;
    signal private input signature_R8y;
    signal private input signature_S;
    signal private input sender_proof[k];
    signal private input sender_proof_pos[k];

    // output
    signal output new_tree_root;

    // verify sender account exists in tree_root
    component senderExistence = LeafExistence(k, 3);
    senderExistence.preimage[0] <== sender_pubkey[0];
    senderExistence.preimage[1] <== sender_pubkey[1];
    senderExistence.preimage[2] <== sender_detail;
    senderExistence.root <== tree_root;
    for (var i = 0; i < k; i++){
        senderExistence.paths2_root_pos[i] <== sender_proof_pos[i];
        senderExistence.paths2_root[i] <== sender_proof[i];
    }

    // check that vote update was signed by voter
    component signatureCheck = VerifyEdDSAMiMC(5);
    signatureCheck.from_x <== sender_pubkey[0];
    signatureCheck.from_y <== sender_pubkey[1];
    signatureCheck.R8x <== signature_R8x;
    signatureCheck.R8y <== signature_R8y;
    signatureCheck.S <== signature_S;
    
    signatureCheck.preimage[0] <== sender_pubkey[0];
    signatureCheck.preimage[1] <== sender_pubkey[1];
    signatureCheck.preimage[2] <== sender_updated_detail;
    signatureCheck.preimage[3] <== sender_updated_pubkey[0];
    signatureCheck.preimage[4] <== sender_updated_pubkey[1];

    // change voter leave and hash
    component newSenderLeaf = MultiMiMC7(3,91){
        newSenderLeaf.in[0] <== sender_updated_pubkey[0];
        newSenderLeaf.in[1] <== sender_updated_pubkey[1];
	    newSenderLeaf.in[2] <== sender_updated_detail;
    }

    // update tree_root
    component computed_final_root = GetMerkleRoot(k);
    computed_final_root.leaf <== newSenderLeaf.out;
    for (var i = 0; i < k; i++){
         computed_final_root.paths2_root_pos[i] <== sender_proof_pos[i];
         computed_final_root.paths2_root[i] <== sender_proof[i];
    }

    // verify voter leaf has been updated
    component senderExistence2 = LeafExistence(k, 3);
    senderExistence2.preimage[0] <== sender_updated_pubkey[0];
    senderExistence2.preimage[1] <== sender_updated_pubkey[1];
    senderExistence2.preimage[2] <== sender_updated_detail;
    senderExistence2.root <== computed_final_root.out;
    for (var i = 0; i < k; i++){
        senderExistence2.paths2_root_pos[i] <== sender_proof_pos[i];
        senderExistence2.paths2_root[i] <== sender_proof[i];
    }

    // output final tree_root
    new_tree_root <== computed_final_root.out;
}

template DecryptAndVerifyMessage(N) {
    // N is the length of the messages
    signal input message[N+1];
    signal input sharedPrivateKey;
    signal input decmessage[N];

    component decrypt = Decrypt(N);

    decrypt.sharedPrivateKey <== sharedPrivateKey;

    for (var i=0; i<N+1; i++) {
        decrypt.message[i] <== message[i];
    }

    for (var i=0; i<N; i++) {
        decrypt.out[i] === decmessage[i];
    }

    // Verify the signature of the decrypted message
    component signature = VerifyEdDSAMiMC(3);

    signature.from_x <== decmessage[1]; // public key x
    signature.from_y <== decmessage[2]; // public key y
    signature.R8x <== decmessage[3]; // sig R8x
    signature.R8y <== decmessage[4]; // sig R8y
    signature.S <== decmessage[5]; // sig S

    signature.preimage[0] <== decmessage[0];
    signature.preimage[1] <== decmessage[1];
    signature.preimage[2] <== decmessage[2];
}

component main = ProcessUpdate(1);
// Message contains 6 parts:
// [0]: Action
// [1]: pub key x
// [2]: pub key y
// [3]: sig r8 x
// [4]: sig r8 y
// [5]: sig s
// encrypted message contains [6+1] parts due to the iv component
// which is at the 0th index
// component main = ProcessUpdate(6);