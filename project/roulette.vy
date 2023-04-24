positions: HashMap[uint8, uint8[2]]
winner: address
num_players: uint8
MAX_PLAYERS: uint8
MIN_BET_AMOUNT: uint256
MAX_BET_AMOUNT: uint256
payouts: uint8[10]
bank_balance: uint256
start_time: timestamp
end_time: timestamp
bidding_time: timedelta

struct Bet:
    player: address
    amount: uint256
    bet_type: uint8
    numbers: DynArray[uint8, 6]

bets: DynArray[Bet, 7]

# BetTypes are as follow:
#   0: color
#   1: modulus
#   2: eighteen
#   3: column
#   4: dozen
#   5: 6-line (6 nums - 2 streets)
#   6: corner (4 nums)
#   7: street (3 nums)
#   8: split  (2 nums)
#   9: number (1 num)
    
# Depending on the BetType, number will be:
#   color: 0 for black, 1 for red
#   modulus: 0 for even, 1 for odd
#   eighteen: 0 for low, 1 for high
#   column: 0 for left, 1 for middle, 2 for right
#   dozen: 0 for first, 1 for second, 2 for third
#   street: 0 for first, ... , 11 for last
#   number: number

@external
def __init__():
    self.MAX_PLAYERS = 7
    self.MIN_BET_AMOUNT = 10000000000000000 # 0.01 eth
    self.MAX_BET_AMOUNT = 50000000000000000 # 0.05 eth
    self.payouts = [2,2,2,3,3,6,9,12,18,36]
    self.bank_balance = 0
    self.bidding_time = 120 # 2 mins
    self.start_time = block.timestamp
    self.end_time = block.timestamp + self.bidding_time
    # setting up board positions
    for i in range(12):
        for j in range(3):
            self.positions[i * 3 + j + 1] = [i, j]

@external 
def bet(bet_type: uint8, amount: uint256, numbers: DynArray[uint8, 6]):
    # - check if bidding time has not ended
    # - check if bid is correct sanity check (within bid min and max limit, the numbers chosen are correct, check if user has amount if needed)
    #    A bet is valid when:
    #    1 - the value of the bet is correct within min and max val
    #    2 - betType is known (between 0 and 10)
    #    3 - the option betted is valid (don't bet on 37! or different options for different bet_types) 
    # - store it in the bets data structure
    
    pass

@external 
def spin():
    # are there any bets?
    # are we allowed to spin the wheel
    # calculate 'random' number
    # send money to winner and store winner
    # delete data and terminate round
    pass