pragma solidity ^0.4.18;
contract ApproveAndCallReceiver {
    function receiveApproval(
    address _from,
    uint256 _amount,
    address _token,
    bytes _data
    ) public;
}
contract Controlled {
    modifier onlyController {
        require(msg.sender == controller);
        _;
    }
    address public controller;
    function Controlled() public {
        controller = msg.sender;
    }
    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}
contract ERC20Token {
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract TokenI is ERC20Token, Controlled {
    string public name;                
    uint8 public decimals;             
    string public symbol;              
    function approveAndCall(
    address _spender,
    uint256 _amount,
    bytes _extraData
    ) public returns (bool success);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount) public returns (bool);
}
contract Token is TokenI {
    struct FreezeInfo {
    address user;
    uint256 amount;
    }
    mapping (uint8 => mapping (uint8 => FreezeInfo)) public freezeOf; 
    mapping (uint8 => uint8) public lastFreezeSeq; 
    mapping (address => uint256) public airdropOf;
    address public owner;
    bool public paused=false;
    uint256 public minFunding = 1 ether;  
    uint256 public airdropQty=0;
    uint256 public airdropTotalQty=0;
    uint256 public tokensPerEther = 10000;
    address private vaultAddress;
    uint256 public totalCollected = 0;
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Payment(address sender, uint256 _ethAmount, uint256 _tokenAmount);
    function Token(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    address _vaultAddress
    ) public {
        require(_vaultAddress != 0);
        totalSupply = initialSupply * 10 ** uint256(decimalUnits);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
        vaultAddress=_vaultAddress;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier realUser(address user){
        if(user == 0x0){
            revert();
        }
        _;
    }
    modifier moreThanZero(uint256 _value){
        if (_value <= 0){
            revert();
        }
        _;
    }
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }
        assembly {
        size := extcodesize(_addr)
        }
        return size>0;
    }
    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);           
        require(balanceOf[_to] + _value > balanceOf[_to]); 
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;                     
        balanceOf[_to] = balanceOf[_to] + _value;                            
        emit Transfer(msg.sender, _to, _value);                   
        return true;
    }
    function approve(address _spender, uint256 _value) moreThanZero(_value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));
        ApproveAndCallReceiver(_spender).receiveApproval(
        msg.sender,
        _amount,
        this,
        _extraData
        );
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) realUser(_from) realUser(_to) moreThanZero(_value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from] - _value;                           
        balanceOf[_to] = balanceOf[_to] + _value;                             
        allowance[_from][msg.sender] = allowance[_from][msg.sender] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function transferMulti(address[] _to, uint256[] _value) public returns (uint256 amount){
        require(_to.length == _value.length);
        uint8 len = uint8(_to.length);
        for(uint8 j; j<len; j++){
            amount += _value[j]*10**uint256(decimals);
        }
        require(balanceOf[msg.sender] >= amount);
        for(uint8 i; i<len; i++){
            address _toI = _to[i];
            uint256 _valueI = _value[i]*10**uint256(decimals);
            balanceOf[_toI] += _valueI;
            balanceOf[msg.sender] -= _valueI;
            emit Transfer(msg.sender, _toI, _valueI);
        }
    }
    function freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) onlyController public returns (bool success) {
        _value=_value*10**uint256(decimals);
        return _freeze(_user,_value,_step);
    }
    function _freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) private returns (bool success) {
        require(balanceOf[_user] >= _value);
        balanceOf[_user] = balanceOf[_user] - _value;
        freezeOf[_step][lastFreezeSeq[_step]] = FreezeInfo({user:_user, amount:_value});
        lastFreezeSeq[_step]++;
        emit Freeze(_user, _value);
        return true;
    }
    function unFreeze(uint8 _step) onlyOwner public returns (bool unlockOver) {
        uint8 _end = lastFreezeSeq[_step];
        require(_end > 0);
        unlockOver=false;
        uint8  _start=0;
        for(; _end>_start; _end--){
            FreezeInfo storage fInfo = freezeOf[_step][_end-1];
            uint256 _amount = fInfo.amount;
            balanceOf[fInfo.user] += _amount;
            delete freezeOf[_step][_end-1];
            lastFreezeSeq[_step]--;
            emit Unfreeze(fInfo.user, _amount);
        }
    }
    function generateTokens(address _user, uint _amount) onlyController public returns (bool) {
        _amount=_amount*10**uint256(decimals);
        return _generateTokens(_user,_amount);
    }
    function _generateTokens(address _user, uint _amount)  private returns (bool) {
        require(balanceOf[owner] >= _amount);
        balanceOf[_user] += _amount;
        balanceOf[owner] -= _amount;
        emit Transfer(0, _user, _amount);
        return true;
    }
    function destroyTokens(address _user, uint256 _amount) onlyOwner public returns (bool) {
        _amount=_amount*10**uint256(decimals);
        return _destroyTokens(_user,_amount);
    }
    function _destroyTokens(address _user, uint256 _amount) private returns (bool) {
        require(balanceOf[_user] >= _amount);
        balanceOf[owner] += _amount;
        balanceOf[_user] -= _amount;
        emit Transfer(_user, 0, _amount);
        emit Burn(_user, _amount);
        return true;
    }
    function changeOwner(address newOwner) onlyOwner public returns (bool) {
        balanceOf[newOwner] += balanceOf[owner];
        balanceOf[owner] = 0;
        owner = newOwner;
        return true;
    }
    function changeTokensPerEther(uint256 _newRate) onlyController public {
        tokensPerEther = _newRate;
    }
    function changeAirdropQty(uint256 _airdropQty) onlyController public {
        airdropQty = _airdropQty;
    }
    function changeAirdropTotalQty(uint256 _airdropTotalQty) onlyController public {
        uint256 _token =_airdropTotalQty*10**uint256(decimals);
        require(balanceOf[owner] >= _token);
        airdropTotalQty = _airdropTotalQty;
    }
    function changePaused(bool _paused) onlyController public {
        paused = _paused;
    }
    function() payable public {
        require(!paused);
        address _user=msg.sender;
        uint256 tokenValue;
        if(msg.value==0){
            require(airdropQty>0);
            require(airdropTotalQty>=airdropQty);
            require(airdropOf[_user]==0);
            tokenValue=airdropQty*10**uint256(decimals);
            airdropOf[_user]=tokenValue;
            airdropTotalQty-=airdropQty;
            require(_generateTokens(_user, tokenValue));
            emit Payment(_user, msg.value, tokenValue);
        }else{
            require(msg.value >= minFunding);
            require(msg.value % 1 ether==0);
            totalCollected +=msg.value;
            require(vaultAddress.send(msg.value));
            tokenValue = (msg.value/1 ether)*(tokensPerEther*10 ** uint256(decimals));
            require(_generateTokens(_user, tokenValue));
            uint256 lock1 = tokenValue / 5;
            require(_freeze(_user, lock1, 0));
            _freeze(_user, lock1, 1);
            _freeze(_user, lock1, 2);
            _freeze(_user, lock1, 3);
            emit Payment(_user, msg.value, tokenValue);
        }
    }
}