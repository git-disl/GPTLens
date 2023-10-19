pragma solidity ^0.4.19;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() internal {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
contract tokenInterface {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
}
contract rateInterface {
    function readRate(string _currency) public view returns (uint256 oneEtherValue);
}
contract ICOEngineInterface {
    function started() public view returns(bool);
    function ended() public view returns(bool);
    function startTime() public view returns(uint);
    function endTime() public view returns(uint);
    function totalTokens() public view returns(uint);
    function remainingTokens() public view returns(uint);
    function price() public view returns(uint);
}
contract KYCBase {
    using SafeMath for uint256;
    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;
    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);
    function KYCBase(address [] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }
    function releaseTokensTo(address buyer) internal returns(bool);
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }
    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }
    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }
    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        private returns (bool)
    {
        bytes32 hash = sha256("Eidoo icoengine authorization", address(0), buyerAddress, buyerId, maxAmount); 
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }
}
contract RC is ICOEngineInterface, KYCBase {
    using SafeMath for uint256;
    TokenSale tokenSaleContract;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public etherMinimum;
    uint256 public soldTokens;
    uint256 public remainingTokens;
    uint256 public oneTokenInUsdWei;
	mapping(address => uint256) public etherUser; 
	mapping(address => uint256) public pendingTokenUser; 
	mapping(address => uint256) public tokenUser; 
	uint256[] public tokenThreshold; 
    uint256[] public bonusThreshold; 
    function RC(address _tokenSaleContract, uint256 _oneTokenInUsdWei, uint256 _remainingTokens, uint256 _etherMinimum, uint256 _startTime , uint256 _endTime, address [] kycSigner, uint256[] _tokenThreshold, uint256[] _bonusThreshold ) public KYCBase(kycSigner) {
        require ( _tokenSaleContract != 0 );
        require ( _oneTokenInUsdWei != 0 );
        require( _remainingTokens != 0 );
        require ( _tokenThreshold.length != 0 );
        require ( _tokenThreshold.length == _bonusThreshold.length );
        bonusThreshold = _bonusThreshold;
        tokenThreshold = _tokenThreshold;
        tokenSaleContract = TokenSale(_tokenSaleContract);
        tokenSaleContract.addMeByRC();
        soldTokens = 0;
        remainingTokens = _remainingTokens;
        oneTokenInUsdWei = _oneTokenInUsdWei;
        etherMinimum = _etherMinimum;
        setTimeRC( _startTime, _endTime );
    }
    function setTimeRC(uint256 _startTime, uint256 _endTime ) internal {
        if( _startTime == 0 ) {
            startTime = tokenSaleContract.startTime();
        } else {
            startTime = _startTime;
        }
        if( _endTime == 0 ) {
            endTime = tokenSaleContract.endTime();
        } else {
            endTime = _endTime;
        }
    }
    modifier onlyTokenSaleOwner() {
        require(msg.sender == tokenSaleContract.owner() );
        _;
    }
    function setTime(uint256 _newStart, uint256 _newEnd) public onlyTokenSaleOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }
    function changeMinimum(uint256 _newEtherMinimum) public onlyTokenSaleOwner {
        etherMinimum = _newEtherMinimum;
    }
    function releaseTokensTo(address buyer) internal returns(bool) {
        if( msg.value > 0 ) takeEther(buyer);
        giveToken(buyer);
        return true;
    }
    function started() public view returns(bool) {
        return now > startTime || remainingTokens == 0;
    }
    function ended() public view returns(bool) {
        return now > endTime || remainingTokens == 0;
    }
    function startTime() public view returns(uint) {
        return startTime;
    }
    function endTime() public view returns(uint) {
        return endTime;
    }
    function totalTokens() public view returns(uint) {
        return remainingTokens.add(soldTokens);
    }
    function remainingTokens() public view returns(uint) {
        return remainingTokens;
    }
    function price() public view returns(uint) {
        uint256 oneEther = 10**18;
        return oneEther.mul(10**18).div( tokenSaleContract.tokenValueInEther(oneTokenInUsdWei) );
    }
	function () public payable{
	    require( now > startTime );
	    if(now < endTime) {
	        takeEther(msg.sender);
	    } else {
	        claimTokenBonus(msg.sender);
	    }
	}
	event Buy(address buyer, uint256 value, uint256 soldToken, uint256 valueTokenInUsdWei );
	function takeEther(address _buyer) internal {
	    require( now > startTime );
        require( now < endTime );
        require( msg.value >= etherMinimum); 
        require( remainingTokens > 0 );
        uint256 oneToken = 10 ** uint256(tokenSaleContract.decimals());
        uint256 tokenValue = tokenSaleContract.tokenValueInEther(oneTokenInUsdWei);
        uint256 tokenAmount = msg.value.mul(oneToken).div(tokenValue);
        uint256 unboughtTokens = tokenInterface(tokenSaleContract.tokenContract()).balanceOf(tokenSaleContract);
        if ( unboughtTokens > remainingTokens ) {
            unboughtTokens = remainingTokens;
        }
        uint256 refund = 0;
        if ( unboughtTokens < tokenAmount ) {
            refund = (tokenAmount - unboughtTokens).mul(tokenValue).div(oneToken);
            tokenAmount = unboughtTokens;
			remainingTokens = 0; 
            _buyer.transfer(refund);
        } else {
			remainingTokens = remainingTokens.sub(tokenAmount); 
        }
        etherUser[_buyer] = etherUser[_buyer].add(msg.value.sub(refund));
        pendingTokenUser[_buyer] = pendingTokenUser[_buyer].add(tokenAmount);	
        emit Buy( _buyer, msg.value, tokenAmount, oneTokenInUsdWei );
	}
	function giveToken(address _buyer) internal {
	    require( pendingTokenUser[_buyer] > 0 );
		tokenUser[_buyer] = tokenUser[_buyer].add(pendingTokenUser[_buyer]);
		tokenSaleContract.claim(_buyer, pendingTokenUser[_buyer]);
		soldTokens = soldTokens.add(pendingTokenUser[_buyer]);
		pendingTokenUser[_buyer] = 0;
		tokenSaleContract.wallet().transfer(etherUser[_buyer]);
		etherUser[_buyer] = 0;
	}
    function claimTokenBonus(address _buyer) internal {
        require( now > endTime );
        require( tokenUser[_buyer] > 0 );
        uint256 bonusApplied = 0;
        for (uint i = 0; i < tokenThreshold.length; i++) {
            if ( soldTokens > tokenThreshold[i] ) {
                bonusApplied = bonusThreshold[i];
			}
		}    
		require( bonusApplied > 0 );
		uint256 addTokenAmount = tokenUser[_buyer].mul( bonusApplied ).div(10**2);
		tokenUser[_buyer] = 0; 
		tokenSaleContract.claim(_buyer, addTokenAmount);
		_buyer.transfer(msg.value);
    }
    function refundEther(address to) public onlyTokenSaleOwner {
        to.transfer(etherUser[to]);
        etherUser[to] = 0;
        pendingTokenUser[to] = 0;
    }
    function withdraw(address to, uint256 value) public onlyTokenSaleOwner { 
        to.transfer(value);
    }
	function userBalance(address _user) public view returns( uint256 _pendingTokenUser, uint256 _tokenUser, uint256 _etherUser ) {
		return (pendingTokenUser[_user], tokenUser[_user], etherUser[_user]);
	}
}
contract TokenSale is Ownable {
    using SafeMath for uint256;
    tokenInterface public tokenContract;
    rateInterface public rateContract;
    address public wallet;
    address public advisor;
    uint256 public advisorFee; 
	uint256 public constant decimals = 18;
    uint256 public endTime;  
    uint256 public startTime;  
    mapping(address => bool) public rc;
    function TokenSale(address _tokenAddress, address _rateAddress, uint256 _startTime, uint256 _endTime) public {
        tokenContract = tokenInterface(_tokenAddress);
        rateContract = rateInterface(_rateAddress);
        setTime(_startTime, _endTime); 
        wallet = msg.sender;
        advisor = msg.sender;
        advisorFee = 0 * 10**3;
    }
    function tokenValueInEther(uint256 _oneTokenInUsdWei) public view returns(uint256 tknValue) {
        uint256 oneEtherInUsd = rateContract.readRate("usd");
        tknValue = _oneTokenInUsdWei.mul(10 ** uint256(decimals)).div(oneEtherInUsd);
        return tknValue;
    } 
    modifier isBuyable() {
        require( now > startTime ); 
        require( now < endTime ); 
        require( msg.value > 0 );
		uint256 remainingTokens = tokenContract.balanceOf(this);
        require( remainingTokens > 0 ); 
        _;
    }
    event Buy(address buyer, uint256 value, address indexed ambassador);
    modifier onlyRC() {
        require( rc[msg.sender] ); 
        _;
    }
    function buyFromRC(address _buyer, uint256 _rcTokenValue, uint256 _remainingTokens) onlyRC isBuyable public payable returns(uint256) {
        uint256 oneToken = 10 ** uint256(decimals);
        uint256 tokenValue = tokenValueInEther(_rcTokenValue);
        uint256 tokenAmount = msg.value.mul(oneToken).div(tokenValue);
        address _ambassador = msg.sender;
        uint256 remainingTokens = tokenContract.balanceOf(this);
        if ( _remainingTokens < remainingTokens ) {
            remainingTokens = _remainingTokens;
        }
        if ( remainingTokens < tokenAmount ) {
            uint256 refund = (tokenAmount - remainingTokens).mul(tokenValue).div(oneToken);
            tokenAmount = remainingTokens;
            forward(msg.value-refund);
			remainingTokens = 0; 
             _buyer.transfer(refund);
        } else {
			remainingTokens = remainingTokens.sub(tokenAmount); 
            forward(msg.value);
        }
        tokenContract.transfer(_buyer, tokenAmount);
        emit Buy(_buyer, tokenAmount, _ambassador);
        return tokenAmount; 
    }
    function forward(uint256 _amount) internal {
        uint256 advisorAmount = _amount.mul(advisorFee).div(10**3);
        uint256 walletAmount = _amount - advisorAmount;
        advisor.transfer(advisorAmount);
        wallet.transfer(walletAmount);
    }
    event NewRC(address contr);
    function addMeByRC() public {
        require(tx.origin == owner);
        rc[ msg.sender ]  = true;
        emit NewRC(msg.sender);
    }
    function setTime(uint256 _newStart, uint256 _newEnd) public onlyOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }
    function withdraw(address to, uint256 value) public onlyOwner {
        to.transfer(value);
    }
    function withdrawTokens(address to, uint256 value) public onlyOwner returns (bool) {
        return tokenContract.transfer(to, value);
    }
    function setTokenContract(address _tokenContract) public onlyOwner {
        tokenContract = tokenInterface(_tokenContract);
    }
    function setWalletAddress(address _wallet) public onlyOwner {
        wallet = _wallet;
    }
    function setAdvisorAddress(address _advisor) public onlyOwner {
            advisor = _advisor;
    }
    function setAdvisorFee(uint256 _advisorFee) public onlyOwner {
            advisorFee = _advisorFee;
    }
    function setRateContract(address _rateAddress) public onlyOwner {
        rateContract = rateInterface(_rateAddress);
    }
	function claim(address _buyer, uint256 _amount) onlyRC public returns(bool) {
        return tokenContract.transfer(_buyer, _amount);
    }
    function () public payable {
        revert();
    }
}