struct Transaction
    sender::String
    recipient::String
    amount::Float64
end

mutable struct Block
    index::Int64
    timestamp::Int64
    transaction_list::Array(Transaction)
    proof::String
    previous_hash::String
end


mutable struct Blockchain
    chain
    current_transaction
end

function init(blockchain::Blockchain)
    blockchain.chain = []
end

function new_block(;blockchain::Blockchain, proof, previous_hash = nothing)
end

function new_transaction(;blockchain::Blockchain, sender, recipient, amount)

end

function blockhash()
end

function last_block()
end
