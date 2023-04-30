#pylint: disable=missing-docstring,redefined-outer-name

import pytest
import time
from eth_tester.exceptions import TransactionFailed

@pytest.fixture
def roulette_contract(w3, get_vyper_contract):
    with open("roulette.vy", encoding='utf-8') as infile:
        contract_code = infile.read()

    args = [10] #10 secs bidding time
    return get_vyper_contract(contract_code, *args)

def test_1_roulette_cannot_bet_more_than_max_players(w3, roulette_contract):
    # if winner why? no winner
    # transact={"from": account0}
    assert not roulette_contract.has_winner()

    # odd bet
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[0]})
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[1]})
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[2]})
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[3]})
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[4]})
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[5]})
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[6]})

    assert roulette_contract.num_players() == roulette_contract.MAX_PLAYERS()
    with pytest.raises(TransactionFailed):
        roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[7]})

    return roulette_contract

def test_2_roulette_bet_amount_limits(w3, roulette_contract):
    # if winner why? no winner
    assert not roulette_contract.has_winner()

    # less than min bet
    with pytest.raises(TransactionFailed):
        roulette_contract.bet(1, 1000000000000000, [1], transact={"from": w3.eth.accounts[0]})

    # greater than max bet
    with pytest.raises(TransactionFailed):
        roulette_contract.bet(1, 60000000000000000, [1], transact={"from": w3.eth.accounts[1]})

    assert roulette_contract.num_players() == 0

    return roulette_contract

def test_3_roulette_invalid_bet_type(w3, roulette_contract):
    # if winner why? no winner
    assert not roulette_contract.has_winner()

    # invalid type
    with pytest.raises(TransactionFailed):
        roulette_contract.bet(10, 20000000000000000, [1], transact={"from": w3.eth.accounts[0]})

    assert roulette_contract.num_players() == 0

    return roulette_contract

def test_4_roulette_invalid_bet(w3, roulette_contract):
    # if winner why? no winner
    assert not roulette_contract.has_winner()

    # invalid bet type
    with pytest.raises(TransactionFailed):
        roulette_contract.bet(10, 20000000000000000, [1], transact={"from": w3.eth.accounts[0]})

    # too many numbers for bet type 9
    with pytest.raises(TransactionFailed):
        roulette_contract.bet(9, 20000000000000000, [1, 2], transact={"from": w3.eth.accounts[0]})

    # invalid bet number
    with pytest.raises(TransactionFailed):
        roulette_contract.bet(9, 20000000000000000, [37], transact={"from": w3.eth.accounts[0]})

    assert roulette_contract.num_players() == 0

    return roulette_contract

def test_5_roulette_diff_valid_bets(w3, roulette_contract):
    # if winner why? no winner
    assert not roulette_contract.has_winner()
    assert roulette_contract.is_bet_phase()

    # red color bet
    roulette_contract.bet(0, 20000000000000000, [0], transact={"from": w3.eth.accounts[0]})
    #even bet
    roulette_contract.bet(1, 20000000000000000, [0], transact={"from": w3.eth.accounts[1]})
    # 0-18
    roulette_contract.bet(2, 20000000000000000, [0], transact={"from": w3.eth.accounts[2]})
    # left column
    roulette_contract.bet(3, 20000000000000000, [0], transact={"from": w3.eth.accounts[3]})
    # 1-12
    roulette_contract.bet(4, 20000000000000000, [0], transact={"from": w3.eth.accounts[4]})
    # 6-line
    roulette_contract.bet(5, 20000000000000000, [13,14,15,16,17,18], transact={"from": w3.eth.accounts[5]})
    # corner
    roulette_contract.bet(6, 20000000000000000, [16,17,19,20], transact={"from": w3.eth.accounts[6]})

    assert roulette_contract.num_players() == roulette_contract.MAX_PLAYERS()
    assert roulette_contract.bank_balance() == (20000000000000000 * roulette_contract.MAX_PLAYERS())

    return roulette_contract

def test_6_roulette_not_time_for_spin(w3, roulette_contract):
    assert not roulette_contract.has_winner()
    assert roulette_contract.is_bet_phase()

    with pytest.raises(TransactionFailed):
        roulette_contract.spin(transact={"from": w3.eth.accounts[0]})

def test_7_roulette_simple_bet_timeout(w3, roulette_contract):
    # if winner why? no winner
    assert not roulette_contract.has_winner()

    # odd bet
    roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[0]})

    assert roulette_contract.is_bet_phase()

    time.sleep(20)

    with pytest.raises(TransactionFailed):
        roulette_contract.bet(1, 20000000000000000, [1], transact={"from": w3.eth.accounts[1]})

    return roulette_contract