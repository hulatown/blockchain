struct Transaction
    sender::String
    recipient::String
    amount::Float64
end

mutable struct Block
    index::Int64
    timestamp::Int64
    transaction_list::Array{Transaction}
    proof::String
    previous_hash::String
end


mutable struct Blockchain
    chain::Array{Block}
    current_transaction::Array{Transaction}
end

function init(blockchain::Blockchain)
    blockchain.chain = []
    blockchain.current_transaciton = []
end

function new_block(;blockchain::Blockchain, proof, previous_hash = nothing)
end

function new_transaction(;blockchain::Blockchain, sender, recipient, amount)
    new_tx = Transaction(sender, recipient, amount)
    push!(blockchain.chain, new_tx)
end

function blockhash()
end

function last_block()
end
