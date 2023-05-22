from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

# TODO add state that tracks proposals here
# proposals:
# - uid, receipent, amount, current votes
struct Proposal:
    recipient: address
    amount: uint256
    votes: decimal
    expired: bool

proposals: public(HashMap[uint256, Proposal])
votes: public(HashMap[address, DynArray[uint256, 20]])
# votes:
# - from, list of uids

@external
def __init__():
    self.totalSupply = 0

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@external
@payable
@nonreentrant("lock")
def buyToken():
    # TODO implement
    assert msg.value > 0, "Value should be greater than 0"
    self.totalSupply += msg.value
    self.balanceOf[msg.sender] += msg.value
    # pass

@external
@nonpayable
@nonreentrant("lock")
def sellToken(_value: uint256):
    # TODO implement
    assert _value > 0, "Value should be greater than 0"
    assert self.balanceOf[msg.sender] > _value, "Not enough funds available"
    self.totalSupply -= _value
    self.balanceOf[msg.sender] -= _value
    # pass

# TODO add other ERC20 methods here

@external
@nonpayable
@nonreentrant("lock")
def createProposal(_uid: uint256, _recipient: address, _amount: uint256):
    # TODO implement
    assert _amount > 0, "Amount should be greater than 0"
    # check if proposal with same uid exist
    if self.proposals[_uid].amount > 0:
        raise "Proposal with same uid already exists"
    # create proposal
    self.proposals[_uid] = Proposal({recipient: _recipient, amount: _amount, votes: 0.0, expired: False})
    # pass

@external
@nonpayable
@nonreentrant("lock")
def approveProposal(_uid: uint256):
    # TODO implement
    assert self.balanceOf[msg.sender] > 0, "Only stakeholder can approve proposals"
    # check not voted already
    if _uid in self.votes[msg.sender]:
        raise "Not allowed to vote again for a proposal"
    # vote
    total: decimal = convert(self.totalSupply, decimal)
    usr_balance: decimal = convert(self.balanceOf[msg.sender], decimal)
    votePower: decimal = 0.0
    if total != 0.0:
        votePower = (usr_balance / total)

    if votePower > 0.0:
        self.votes[msg.sender].append(_uid)
        self.proposals[_uid].votes += votePower
    
    # check if passed so sendtokens
    if self.proposals[_uid].votes > 0.5 and self.proposals[_uid].expired == False:
        self.proposals[_uid].expired = True
        send(self.proposals[_uid].recipient, self.proposals[_uid].amount)