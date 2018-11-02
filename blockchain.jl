using SHA, JSON

difficulty = Int8(4)

struct Transaction
    sender::String
    recipient::String
    amount::Float64
end

mutable struct Block
    index::Int64
    timestamp::Int64
    transaction_list::Array{Transaction}
    proof::Int64
    previous_hash::String
end

mutable struct Blockchain
    chain::Array{Block}
    current_transaction::Array{Transaction}
end

function init(blockchain::Blockchain)
    blockchain.chain = []
    blockchain.current_transaction = []
    new_block(block, proof=100, "genesis_block_hash")
end

function new_block(;blockchain::Blockchain, proof::Int64, previous_hash = nothing)
    if previous_hash == nothing
        previous_hash = blockhash(blockchain.chain[end])
    end
    block = Block(length+1, round(Int64, time()), blockchain.current_transaction, proof, previous_hash)

    push!(blockchain.block, block)
    blockchain.current_transaction = []
end

function new_transaction(;blockchain::Blockchain, sender, recipient, amount)
    new_tx = Transaction(sender, recipient, amount)
    push!(blockchain.current_transaction, new_tx)
end

function blockhash(block::Block)
    return bytes2hex(sha256(JSON.json(block)))
end

function proof_of_work(last_proof)
    proof = 0
    while valid_proof(last_proof, proof) == false
        global proof += 1
    end
    return proof
end

function valid_proof(last_proof, proof)
    header = "0"^difficulty
    guess = string(last_proof) * string(proof)
    guess_hash = bytes2hex(sha256(guess))
    return guess_hash[1:difficulty] == header
end
