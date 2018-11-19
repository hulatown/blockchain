using SHA, JSON
using Restful, Logging
using UUIDs
using HTTP, URIParser

import Restful: json

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
    nodes::Array{String}
end

function init(blockchain::Blockchain)
    blockchain.chain = []
    blockchain.current_transaction = []
    blockchain.nodes = []
    new_block(blockchain=blockchain, proof=100, previous_hash="genesis_block_hash")
end

function new_block(;blockchain::Blockchain, proof::Int64, previous_hash = nothing)
    if previous_hash == nothing
        previous_hash = blockhash(blockchain.chain[end])
    end
    block = Block(length(blockchain.chain)+1, round(Int64, time()), blockchain.current_transaction, proof, previous_hash)

    push!(blockchain.chain, block)
    blockchain.current_transaction = []
    return block
end

function new_transaction(;blockchain::Blockchain, sender::String, recipient::String, amount::Float64)
    new_tx = Transaction(sender, recipient, amount)
    push!(blockchain.current_transaction, new_tx)
    return length(blockchain.chain) + 1
end

function blockhash(block::Block)
    return bytes2hex(sha256(JSON.json(block)))
end

function proof_of_work(last_proof)
    proof = 0
    while valid_proof(last_proof, proof) == false
        proof += 1
    end
    return proof
end

function valid_proof(last_proof, proof)
    header = "0"^difficulty
    guess = string(last_proof) * string(proof)
    guess_hash = bytes2hex(sha256(guess))
    return guess_hash[1:difficulty] == header
end

function register_node(blockchain::Blockchain, address::String)
    push!(blockchain.nodes, address)
end

function valid_chain(chain::Array{Block})
    last_block = chain[end]
    current_index = 1
    while current_index < length(chain)
        block = chain[current_index]
        if block.previous_hash != blockhash(last_block)
            return false
        end

        if valid_proof(last_block.proof, block.proof) == false
            return false
        end

        last_block = block
        current_index += 1
    end

    return true
end

function resolve_conflict(blockchain::Blockchain)
    neighbours = blockchain.nodes
    new_chain = nothing

    my_height = length(blockchain.chain)

    for node in neighbours
        response = HTTP.request("GET", "http://" * node * "/chain")

        if response.status == 200
            response_body = JSON.Parser.parse(String(response.body))
            height = response_body[1]["length"]
            chain = response_body[2]["chain"]

            if height > my_height && valid_chain(chain)
                my_height = height
                new_chain = chain
            end
        end
    end

    if new_chain != nothing
        blockchain.chain = new_chain
        return true
    end

    return false
end

const app = Restful.app()

function main(args)
    blockchain = Blockchain([], [], [])
    node_identifier = replace(string(uuid4()), "-" => "")
    init(blockchain)

    app.get("/mine", json) do req, res, route
        last_block = blockchain.chain[end]
        last_proof = last_block.proof
        proof = proof_of_work(last_proof)

        new_transaction(blockchain=blockchain, sender="0", recipient=node_identifier, amount=1.0)

        previous_hash = blockhash(last_block)
        block = new_block(blockchain=blockchain, proof=proof, previous_hash=previous_hash)
        res.json(Dict("message" => "New Block Forged",
        "index" => block.index,
        "transaction" => block.transaction_list,
        "proof" => block.proof,
        "previous_hash" => block.previous_hash) |> collect)
    end

    app.post("/transactions/new", json) do req, res, route
        required = ["sender", "recipient", "amount"]
        data = JSON.parse(req.body)

        if all(i->(i in keys(data)), required) == false
            res.code(400)
        else
            block_id = new_transaction(blockchain=blockchain, sender=data["sender"], recipient=data["recipient"], amount=data["amount"])
            res.json(Dict("message" => "Transaction will be added to Block " * string(block_id)) |> collect)
        end
    end

    app.get("/chain", json) do req, res, route
        res.json(Dict("chain"=>blockchain.chain, "length"=>length(blockchain.chain)) |> collect)
    end

    app.post("/nodes/register", json) do req, res, route
        data = JSON.parse(req.body)
        nodes = data["nodes"]

        if nodes == nothing
            res.code(400)
        end

        for node in nodes
            register_node(blockchain, node)
        end

        res.json(Dict("message" => "Nodes will be added to Blockchain") |> collect)
    end

    app.get("/nodes/resolve", json) do req, res, route
        replaced = blockchain.resolve_conflict()
        if replaced == true
            res.json(Dict("message" => "Our chain was replaced") |> collect)
        else
            res.json(Dict("message" => "Our chain is main chain") |> collect)
        end
    end

    @async with_logger(SimpleLogger(stderr, Logging.Warn)) do
        app.listen("127.0.0.1", args[1])
    end
end
