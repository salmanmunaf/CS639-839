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
    
    self.bets: DynArray[Bet, 7]
    self.bets = []
    

@external 
def bet(bet_type: uint8, amount: uint256, numbers: DynArray[uint8, 6]):
    # - check if bidding time has not ended
    # - check if bid is correct sanity check (within bid min and max limit, the numbers chosen are correct, check if user has amount if needed)
    #    A bet is valid when:
    #    1 - the value of the bet is correct within min and max val
    #    2 - betType is known (between 0 and 10)
    #    3 - the option betted is valid (don't bet on 37! or different options for different bet_types) 
    # - store it in the bets data structure

    account = msg.sender

    # time is up
    if block.timestamp < self.start_time or block.timestamp > end_time:
        raise "ERROR: Time is up"
        pass

    # bet type invalid
    if bet_type < 0 or bet_type > 9:
        raise "ERROR: Bet type is invalid"
        pass

    # bet amount is invalid
    if amount < self.MIN_BET_AMOUNT or amount > self.MAX_BET_AMOUNT:
        raise "ERROR: Bet amount needs to be within 0.01 and 0.05 eth"
        pass

    # invalid, handle
    for num in numbers:
        if num < 0 or num > 36:
            raise "ERROR: One of the numbers entered in the bet locations is out of range (0-36)"
            pass

    # bet types 0 to 4 should have max 1 number, with apt encoding, throw error else
    if bet_type >= 0 and bet_type <= 4 and len(numbers) != 1:
        raise "ERROR: Too many/few numbers entered for bet type. Must be 1."
        pass

    # 6 nums
    if bet_type = 5 and len(numbers) != 6:
        raise "ERROR: Too many/few numbers entered for bet type. Must be 6."
        pass

    # 4 nums
    if bet_type = 6 and len(numbers) != 4:
        raise "ERROR: Too many/few numbers entered for bet type. Must be 4."
        pass

    # 3 nums
    if bet_type = 7 and len(numbers) != 3:
        raise "ERROR: Too many/few numbers entered for bet type. Must be 3."
        pass

    # 2 nums
    if bet_type = 8 and len(numbers) != 2:
        raise "ERROR: Too many/few numbers entered for bet type. Must be 2."
        pass

    # 1 nums
    if bet_type = 9 and len(numbers) != 1:
        raise "ERROR: Too many/few numbers entered for bet type. Must be 1."
        pass
    
    # if none of the above are fails, then load bet conditional on if number
    # of max players has not been reached
    if len(self.bets) != self.MAX_PLAYERS:
        temp_bet: Bet = Bet({player: msg.sender, amount: amount, bet_type: bet_type, numbers: numbers})
    else:
        raise "ERROR: Max player count reached"
    pass

@external 
def spin():
    # are there any bets?
    # are we allowed to spin the wheel
    # calculate 'random' number
    # send money to winner and store winner
    # delete data and terminate round
    pass