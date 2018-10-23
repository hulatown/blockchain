mutable struct Blockchain
    chain
    current_transaction
end

function init(blockchain::Blockchain)
end

function new_block(;blockchain::Blockchain, proof, previous_hash = nothing)
end

function new_transaction()
end

function blockhash()
end

function last_block()
end
