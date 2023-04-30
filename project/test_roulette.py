#pylint: disable=missing-docstring,redefined-outer-name

import pytest
from eth_tester.exceptions import TransactionFailed

@pytest.fixture
def roulette_contract(w3, get_vyper_contract):
    with open("roulette.vy", encoding='utf-8') as infile:
        contract_code = infile.read()

    args = [w3.eth.accounts[0], w3.eth.accounts[1]]
    return get_vyper_contract(contract_code, *args)

def roulette_simple_one_player_one_bet(w3, roulette_contract):
    account0 = w3.eth.accounts[0]
    #account1 = w3.eth.accounts[1]

    # if winner why? no winner
    assert not roulette_contract.has_winner(transact={"from": account0})

    # odd bet
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": account0})

    # 17 in win, so this is a  winning bet
    roulette_contract.spin(transact={"from": account0})

    assert roulette_contract.has_winner(transact={"from": account0})
    
    assert account0 == roulette_contract.get_winner(transact={"from": account0})

    return roulette_contract








