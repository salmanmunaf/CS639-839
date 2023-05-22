# forked from https://github.com/dvf/blockchain

import hashlib
import json
import time
import threading
import logging

import requests
from flask import Flask, request

class Transaction(object):
    def __init__(self, sender, recipient, amount):
        self.sender = sender # constraint: should exist in state
        self.recipient = recipient # constraint: need not exist in state. Should exist in state if transaction is applied.
        self.amount = amount # constraint: sender should have enough balance to send this amount

    def __str__(self) -> str:
        return "T(%s -> %s: %s)" % (self.sender, self.recipient, self.amount)

    def encode(self) -> str:
        return self.__dict__.copy()

    @staticmethod
    def decode(data):
        return Transaction(data['sender'], data['recipient'], data['amount'])

    def __lt__(self, other):
        if self.sender < other.sender: return True
        if self.sender > other.sender: return False
        if self.recipient < other.recipient: return True
        if self.recipient > other.recipient: return False
        if self.amount < other.amount: return True
        return False
    
    def __eq__(self, other) -> bool:
        return self.sender == other.sender and self.recipient == other.recipient and self.amount == other.amount

class Block(object):
    def __init__(self, number, transactions, previous_hash, miner):
        self.number = number # constraint: should be 1 larger than the previous block
        self.transactions = transactions # constraint: list of transactions. Ordering matters. They will be applied sequentlally.
        self.previous_hash = previous_hash # constraint: Should match the previous mined block's hash
        self.miner = miner # constraint: The node_identifier of the miner who mined this block
        self.hash = self._hash()

    def _hash(self):
        return hashlib.sha256(
            str(self.number).encode('utf-8') +
            str([str(txn) for txn in self.transactions]).encode('utf-8') +
            str(self.previous_hash).encode('utf-8') +
            str(self.miner).encode('utf-8')
        ).hexdigest()

    def __str__(self) -> str:
        return "B(#%s, %s, %s, %s, %s)" % (self.hash[:5], self.number, self.transactions, self.previous_hash, self.miner)
    
    def encode(self):
        encoded = self.__dict__.copy()
        encoded['transactions'] = [t.encode() for t in self.transactions]
        return encoded
    
    @staticmethod
    def decode(data):
        txns = [Transaction.decode(t) for t in data['transactions']]
        return Block(data['number'], txns, data['previous_hash'], data['miner'])

class State(object):
    def __init__(self):
        # TODO - done: You might want to think how you will store balance per person.
        # You don't need to worry about persisting to disk. Storing in memory is fine.
        self.balances = {}
        # self.balances = []
        # pass

    def encode(self):
        dumped = {}
        # TODO - done: Add all person -> balance pairs into `dumped`.
        for person in self.balances:
            dumped[person] = self.balances[person]

        return dumped

    def validate_txns(self, txns):
        result = []
        # return txns
        # TODO - done: returns a list of valid transactions.
        # You receive a list of transactions, and you try applying them to the state.
        # If a transaction can be applied, add it to result. (should be included)
        current_state = dict(self.balances)
        for txn in txns:
            if txn.sender not in current_state:
                continue
            if current_state[txn.sender] < txn.amount:
                continue
            current_state[txn.sender] -= txn.amount
            if txn.recipient in current_state:
                current_state[txn.recipient] += txn.amount
            else:
                current_state[txn.recipient] = txn.amount
            result.append(txn)
        return result

    def apply_block(self, block):
        # TODO: apply the block to the state.
        # read previous state from last index
        # appending a dictionary to that list
        # which indicates the state after new block
        for txn in block.transactions:
            sender = txn.sender
            recipient = txn.recipient
            amount = txn.amount
            self.balances[sender] -= amount
            if recipient in self.balances:
                self.balances[recipient] += amount
            else:
                self.balances[recipient] = amount

        logging.info("Block (#%s) applied to state. %d transactions applied" % (block.hash, len(block.transactions)))

    def history(self, account):
        # TODO: return a list of (blockNumber, value changes) that this account went through 
        # Here is an example
        blockNumber = 3
        amount = 200

        blockNumber2 = 10
        amount2 = -25

        return [(blockNumber, amount), (blockNumber2, amount2)]
    
    def get_invalid_transactions(self, txns):
        # s = set(valid_txns)
        # invalid_txns = [t for t in all_txns if t not in s]
        # return invalid_txns
        invalid_txns = []
        for txn in txns:
            if txn.sender not in self.balances:
                invalid_txns.append(txn)
            elif txn.sender not in self.balances:
                invalid_txns.append(txn)
            elif txn.sender in self.balances and self.balances[txn.sender] < txn.amount:
                invalid_txns.append(txn)
        return invalid_txns
        # while i < len(all_txns):
        #     if all_txns[i]

class Blockchain(object):
    def __init__(self):
        self.nodes = []
        self.node_identifier = 0
        self.block_mine_time = 5

        # in memory datastructures.
        self.current_transactions = [] # A list of `Transaction`
        self.chain = [] # A list of `Block`
        self.state = State()

    def is_new_block_valid(self, block, received_blockhash):
        """
        Determine if I should accept a new block.
        Does it pass all semantic checks? Search for "constraint" in this file.

        :param block: A new proposed block
        :return: True if valid, False if not
        """
        # TODO - done: check if received block is valid
        # 1. Hash should match content
        # 2. Previous hash should match previous block
        # 3. Transactions should be valid (all apply to block)
        # 4. Block number should be one higher than previous block
        # 5. miner should be correct (next RR)
        if block._hash() != received_blockhash:
            return False
        if len(self.state.validate_txns(block.transactions)) != len(block.transactions):
            return False
        
        if len(self.chain) > 0:
            prevBlock = self.chain[-1]
            if block.previous_hash != prevBlock.hash:
                return False
            if block.number != (prevBlock.number + 1):
                return False
            if block.miner != self.get_next_miner(prevBlock.miner):
                return False
        else:
            #genesis block prevHash should be constant
            if block.previous_hash != '0xfeedcafe':
                return False
            #genesis block miner should be first node
            if block.miner != self.nodes[0]:
                return False
            if block.number != 1:
                return False
        return True

    def trigger_new_block_mine(self, genesis=False):
        thread = threading.Thread(target=self.__mine_new_block_in_thread, args=(genesis,))
        thread.start()

    def __mine_new_block_in_thread(self, genesis=False):
        """
        Create a new Block in the Blockchain

        :return: New Block
        """
        logging.info("[MINER] waiting for new transactions before mining new block...")
        time.sleep(self.block_mine_time) # Wait for new transactions to come in
        miner = self.node_identifier

        if genesis:
            block = Block(1, [], '0xfeedcafe', miner)
            self.state.balances['A'] = 10000
        else:
            self.current_transactions.sort()

            # TODO - done: create a new *valid* block with available transactions. Replace the arguments in the line below.
            prevBlock = self.chain[-1]
            # print("--------start current transactions:")
            # for txn in self.current_transactions:
            #     print(txn)
            # print("--------end current transactions")
            valid_txns = self.state.validate_txns(self.current_transactions)
            # print("--------start valid transactions:")
            # print(valid_txns)
            # for txn in valid_txns:
            #     print(txn)
            # print("--------end valid transactions")
            block = Block(prevBlock.number + 1, valid_txns, prevBlock.hash, miner)
            # self.current_transactions = 
            # self.current_transactions = [txn for txn in self.current_transactions if txn not in set(valid_txns)]
            self.current_transactions = [txn for txn in self.current_transactions if txn not in valid_txns]
            # self.state.get_invalid_transactions(self.current_transactions)
            # print("--------start invalid transactions:")
            # print(self.current_transactions)
            # for txn in self.current_transactions:
            #     print(txn)
            # print("--------end invalid transactions")
            self.state.apply_block(block)
            # self.current_transactions = []
             
        # TODO: make changes to in-memory data structures to reflect the new block. Check Blockchain.__init__ method for in-memory datastructures
        self.chain.append(block)
        #apply block to state
        # self.state.apply_block(block)
        # if genesis:
            
            # pass
            # TODO-done: at time of genesis, change state to have 'A': 10000 (person A has 10000)
        
        # clear transactions
        # self.current_transactions = []
        # print("here3333333")
        logging.info("[MINER] constructed new block with %d transactions. Informing others about: #%s" % (len(block.transactions), block.hash[:5]))
        # broadcast the new block to all nodes.
        for node in self.nodes:
            if node == self.node_identifier: continue
            requests.post(f'http://localhost:{node}/inform/block', json=block.encode())

    def new_transaction(self, sender, recipient, amount):
        """ Add this transaction to the transaction mempool. We will try
        to include this transaction in the next block until it succeeds.
        """
        print("****************NEW TRANSACTION RECIEVED: ", self.node_identifier, Transaction(sender, recipient, amount))
        self.current_transactions.append(Transaction(sender, recipient, amount))

    def get_next_miner(self, miner):
        next_miner_index = self.nodes.index(miner) + 1
        if next_miner_index >= len(self.nodes):
            next_miner_index = 0
        return self.nodes[next_miner_index]
