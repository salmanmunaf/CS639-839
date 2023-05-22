''' A simple implementation of battleship in Vyper '''

# NOTE: The provided code is only a suggestion
# You can change all of this code (as long as the ABI stays the same)

NUM_PIECES: constant(uint32) = 5
BOARD_SIZE: constant(uint32) = 5
NUM_PLAYERS: constant(uint32) = 2

# What phase of the game are we in ?
# Start with SET and end with END
PHASE_SET: constant(int32) = 0
PHASE_SHOOT: constant(int32) = 1
PHASE_END: constant(int32) = 2

# Each player has a 5-by-5 board
# The field track where the player's boats are located and what fields were hit
# Player should not be allowed to shoot the same field twice, even if it is empty
FIELD_EMPTY: constant(int32) = 0
FIELD_BOAT: constant(int32) = 1
FIELD_HIT: constant(int32) = 2
FIELD_SHOOT: constant(int32) = 3

players: immutable(address[NUM_PLAYERS])
winner: address

# Which player has the next turn? Only used during the SHOOT phase
next_player: uint32

# Which phase of the game is it?
phase: int32

boards: int32[BOARD_SIZE][BOARD_SIZE][NUM_PLAYERS]

pieces_set: uint32[NUM_PLAYERS]
pieces_hit: uint32[NUM_PLAYERS]

@external
def __init__(player1: address, player2: address):
    players = [player1, player2]
    self.next_player = 0
    self.phase = PHASE_SET
    self.pieces_set = [0, 0]
    self.pieces_hit = [0, 0]

    #TODO initialize whatever you need here
    for i in range(2):
        for j in range(BOARD_SIZE):
            for k in range(BOARD_SIZE):
                self.boards[i][j][k] = FIELD_EMPTY

@external
def set_field(pos_x: uint32, pos_y: uint32):
    '''
    Sets a ship at the specified coordinates
    This should only be allowed in the initial phase of the game

    Players are allowed to call this out of order,
    but at most NUM_PIECES times
    '''
    if self.phase != PHASE_SET:
        raise "Wrong phase"

    if pos_x >= BOARD_SIZE or pos_y >= BOARD_SIZE:
        raise "Position out of bounds"

    #TODO add the rest here
    from_player: uint32 = 0
    if msg.sender == players[0]:
        from_player = 0
    elif msg.sender == players[1]:
        from_player = 1
    else:
        raise "Invalid player"

    if self.pieces_set[from_player] >= NUM_PIECES:
        raise "Max number of ships are already set"

    if self.boards[from_player][pos_x][pos_y] != FIELD_EMPTY:
        raise "Field is not empty"

    # set piece
    self.boards[from_player][pos_x][pos_y] = FIELD_BOAT
    self.pieces_set[from_player] += 1

    if self.pieces_set[0] == NUM_PIECES and self.pieces_set[1] == NUM_PIECES:
        self.phase = PHASE_SHOOT

    

@external
def shoot(pos_x: uint32, pos_y: uint32):
    '''
    Shoot a specific field on the other players board
    This should only be allowed if it is the calling player's turn and only during the SHOOT phase
    '''

    if pos_x >= BOARD_SIZE or pos_y >= BOARD_SIZE:
        raise "Position out of bounds"

    if self.phase != PHASE_SHOOT:
        raise "Wrong phase"

    # Add shooting logic and victory logic here
    from_player: uint32 = 0
    if msg.sender == players[0]:
        from_player = 0
    elif msg.sender == players[1]:
        from_player = 1
    else:
        raise "Invalid player"

    if from_player != self.next_player:
        raise "Not your turn"

    # check if this position was shot
    board_player: uint32 = 1-from_player
    if (self.boards[board_player][pos_x][pos_y] == FIELD_SHOOT) or (self.boards[board_player][pos_x][pos_y] == FIELD_HIT):
        raise "This field is already shot"

    if self.boards[board_player][pos_x][pos_y] == FIELD_BOAT:
        self.boards[board_player][pos_x][pos_y] = FIELD_HIT
        self.pieces_hit[board_player] += 1
    else:
        self.boards[board_player][pos_x][pos_y] = FIELD_SHOOT
    
    self.next_player = 1-self.next_player

    if self.pieces_hit[0] == NUM_PIECES:
        self.winner = players[1]
        self.phase = PHASE_END
    elif self.pieces_hit[1] == NUM_PIECES:
        self.winner = players[0]
        self.phase = PHASE_END

@external
@view
def has_winner() -> bool:
    return self.phase == PHASE_END

@external
@view
def get_winner() -> address:
    ''' Returns the address of the winner's account '''

    #TODO figure out who won

    # Raise an error if no one won yet
    if self.phase != PHASE_END:
        raise "No one won yet"

    return self.winner
