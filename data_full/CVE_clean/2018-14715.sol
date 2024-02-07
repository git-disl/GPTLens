pragma solidity ^0.4.15;
contract NFT {
  function NFT() public { }
  mapping (uint256 => address) public tokenIndexToOwner;
  mapping (address => uint256) ownershipTokenCount;
  mapping (uint256 => address) public tokenIndexToApproved;
  function transfer(address _to,uint256 _tokenId) public {
      require(_to != address(0));
      require(_to != address(this));
      require(_owns(msg.sender, _tokenId));
      _transfer(msg.sender, _to, _tokenId);
  }
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
      ownershipTokenCount[_to]++;
      tokenIndexToOwner[_tokenId] = _to;
      if (_from != address(0)) {
          ownershipTokenCount[_from]--;
          delete tokenIndexToApproved[_tokenId];
      }
      Transfer(_from, _to, _tokenId);
  }
  event Transfer(address from, address to, uint256 tokenId);
  function transferFrom(address _from,address _to,uint256 _tokenId) external {
      require(_to != address(0));
      require(_to != address(this));
      require(_approvedFor(msg.sender, _tokenId));
      require(_owns(_from, _tokenId));
      _transfer(_from, _to, _tokenId);
  }
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return tokenIndexToOwner[_tokenId] == _claimant;
  }
  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return tokenIndexToApproved[_tokenId] == _claimant;
  }
  function _approve(uint256 _tokenId, address _approved) internal {
      tokenIndexToApproved[_tokenId] = _approved;
  }
  function approve(address _to,uint256 _tokenId) public returns (bool) {
      require(_owns(msg.sender, _tokenId));
      _approve(_tokenId, _to);
      Approval(msg.sender, _to, _tokenId);
      return true;
  }
  event Approval(address owner, address approved, uint256 tokenId);
  function balanceOf(address _owner) public view returns (uint256 count) {
      return ownershipTokenCount[_owner];
  }
  function ownerOf(uint256 _tokenId) external view returns (address owner) {
      owner = tokenIndexToOwner[_tokenId];
      require(owner != address(0));
  }
  function allowance(address _claimant, uint256 _tokenId) public view returns (bool) {
      return _approvedFor(_claimant,_tokenId);
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
contract Cryptogs is NFT, Ownable {
    string public constant name = "Cryptogs";
    string public constant symbol = "POGS";
    string public constant purpose = "ETHDenver";
    string public constant contact = "https:
    string public constant author = "Austin Thomas Griffith";
    uint8 public constant FLIPPINESS = 64;
    uint8 public constant FLIPPINESSROUNDBONUS = 16;
    uint8 public constant TIMEOUTBLOCKS = 180;
    uint8 public constant BLOCKSUNTILCLEANUPSTACK=1;
    string public ipfs;
    function setIpfs(string _ipfs) public onlyOwner returns (bool){
      ipfs=_ipfs;
      IPFS(ipfs);
      return true;
    }
    event IPFS(string ipfs);
    function Cryptogs() public {
      Item memory _item = Item({
        image: ""
      });
      items.push(_item);
    }
    address public slammerTime;
    function setSlammerTime(address _slammerTime) public onlyOwner returns (bool){
      require(slammerTime==address(0));
      slammerTime=_slammerTime;
      return true;
    }
    struct Item{
      bytes32 image;
    }
    Item[] private items;
    function mint(bytes32 _image,address _owner) public onlyOwner returns (uint){
      uint256 newId = _mint(_image);
      _transfer(0, _owner, newId);
      Mint(items[newId].image,tokenIndexToOwner[newId],newId);
      return newId;
    }
    event Mint(bytes32 _image,address _owner,uint256 _id);
    function mintBatch(bytes32 _image1,bytes32 _image2,bytes32 _image3,bytes32 _image4,bytes32 _image5,address _owner) public onlyOwner returns (bool){
      uint256 newId = _mint(_image1);
      _transfer(0, _owner, newId);
      Mint(_image1,tokenIndexToOwner[newId],newId);
      newId=_mint(_image2);
      _transfer(0, _owner, newId);
      Mint(_image2,tokenIndexToOwner[newId],newId);
      newId=_mint(_image3);
      _transfer(0, _owner, newId);
      Mint(_image3,tokenIndexToOwner[newId],newId);
      newId=_mint(_image4);
      _transfer(0, _owner, newId);
      Mint(_image4,tokenIndexToOwner[newId],newId);
      newId=_mint(_image5);
      _transfer(0, _owner, newId);
      Mint(_image5,tokenIndexToOwner[newId],newId);
      return true;
    }
    function _mint(bytes32 _image) internal returns (uint){
      Item memory _item = Item({
        image: _image
      });
      uint256 newId = items.push(_item) - 1;
      tokensOfImage[items[newId].image]++;
      return newId;
    }
    Pack[] private packs;
    struct Pack{
      uint256[10] tokens;
      uint256 price;
    }
    function mintPack(uint256 _price,bytes32 _image1,bytes32 _image2,bytes32 _image3,bytes32 _image4,bytes32 _image5,bytes32 _image6,bytes32 _image7,bytes32 _image8,bytes32 _image9,bytes32 _image10) public onlyOwner returns (bool){
      uint256[10] memory tokens;
      tokens[0] = _mint(_image1);
      tokens[1] = _mint(_image2);
      tokens[2] = _mint(_image3);
      tokens[3] = _mint(_image4);
      tokens[4] = _mint(_image5);
      tokens[5] = _mint(_image6);
      tokens[6] = _mint(_image7);
      tokens[7] = _mint(_image8);
      tokens[8] = _mint(_image9);
      tokens[9] = _mint(_image10);
      Pack memory _pack = Pack({
        tokens: tokens,
        price: _price
      });
      MintPack(packs.push(_pack) - 1, _price,tokens[0],tokens[1],tokens[2],tokens[3],tokens[4],tokens[5],tokens[6],tokens[7],tokens[8],tokens[9]);
      return true;
    }
    event MintPack(uint256 packId,uint256 price,uint256 token1,uint256 token2,uint256 token3,uint256 token4,uint256 token5,uint256 token6,uint256 token7,uint256 token8,uint256 token9,uint256 token10);
    function buyPack(uint256 packId) public payable returns (bool) {
      require( packs[packId].price > 0 );
      require( msg.value >= packs[packId].price );
      packs[packId].price=0;
      for(uint8 i=0;i<10;i++){
        tokenIndexToOwner[packs[packId].tokens[i]]=msg.sender;
        _transfer(0, msg.sender, packs[packId].tokens[i]);
      }
      delete packs[packId];
      BuyPack(msg.sender,packId,msg.value);
    }
    event BuyPack(address sender, uint256 packId, uint256 price);
    mapping (bytes32 => uint256) public tokensOfImage;
    function getToken(uint256 _id) public view returns (address owner,bytes32 image,uint256 copies) {
      image = items[_id].image;
      copies = tokensOfImage[image];
      return (
        tokenIndexToOwner[_id],
        image,
        copies
      );
    }
    uint256 nonce = 0;
    struct Stack{
      uint256[5] ids;
      address owner;
      uint32 block;
    }
    mapping (bytes32 => Stack) public stacks;
    mapping (bytes32 => bytes32) public stackCounter;
    function stackOwner(bytes32 _stack) public constant returns (address owner) {
      return stacks[_stack].owner;
    }
    function getStack(bytes32 _stack) public constant returns (address owner,uint32 block,uint256 token1,uint256 token2,uint256 token3,uint256 token4,uint256 token5) {
      return (stacks[_stack].owner,stacks[_stack].block,stacks[_stack].ids[0],stacks[_stack].ids[1],stacks[_stack].ids[2],stacks[_stack].ids[3],stacks[_stack].ids[4]);
    }
    function submitStack(uint256 _id,uint256 _id2,uint256 _id3,uint256 _id4,uint256 _id5, bool _public) public returns (bool) {
      require(slammerTime!=address(0));
      require(tokenIndexToOwner[_id]==msg.sender);
      require(tokenIndexToOwner[_id2]==msg.sender);
      require(tokenIndexToOwner[_id3]==msg.sender);
      require(tokenIndexToOwner[_id4]==msg.sender);
      require(tokenIndexToOwner[_id5]==msg.sender);
      require(approve(slammerTime,_id));
      require(approve(slammerTime,_id2));
      require(approve(slammerTime,_id3));
      require(approve(slammerTime,_id4));
      require(approve(slammerTime,_id5));
      bytes32 stack = keccak256(nonce++,msg.sender);
      uint256[5] memory ids = [_id,_id2,_id3,_id4,_id5];
      stacks[stack] = Stack(ids,msg.sender,uint32(block.number));
      SubmitStack(msg.sender,now,stack,_id,_id2,_id3,_id4,_id5,_public);
    }
    event SubmitStack(address indexed _sender,uint256 indexed timestamp,bytes32 indexed _stack,uint256 _token1,uint256 _token2,uint256 _token3,uint256 _token4,uint256 _token5,bool _public);
    function submitCounterStack(bytes32 _stack, uint256 _id, uint256 _id2, uint256 _id3, uint256 _id4, uint256 _id5) public returns (bool) {
      require(slammerTime!=address(0));
      require(tokenIndexToOwner[_id]==msg.sender);
      require(tokenIndexToOwner[_id2]==msg.sender);
      require(tokenIndexToOwner[_id3]==msg.sender);
      require(tokenIndexToOwner[_id4]==msg.sender);
      require(tokenIndexToOwner[_id5]==msg.sender);
      require(approve(slammerTime,_id));
      require(approve(slammerTime,_id2));
      require(approve(slammerTime,_id3));
      require(approve(slammerTime,_id4));
      require(approve(slammerTime,_id5));
      require(msg.sender!=stacks[_stack].owner);
      bytes32 counterstack = keccak256(nonce++,msg.sender,_id);
      uint256[5] memory ids = [_id,_id2,_id3,_id4,_id5];
      stacks[counterstack] = Stack(ids,msg.sender,uint32(block.number));
      stackCounter[counterstack] = _stack;
      CounterStack(msg.sender,now,_stack,counterstack,_id,_id2,_id3,_id4,_id5);
    }
    event CounterStack(address indexed _sender,uint256 indexed timestamp,bytes32 indexed _stack, bytes32 _counterStack, uint256 _token1, uint256 _token2, uint256 _token3, uint256 _token4, uint256 _token5);
    function cancelStack(bytes32 _stack) public returns (bool) {
      require(msg.sender==stacks[_stack].owner);
      require(mode[_stack]==0);
      require(stackCounter[_stack]==0x00000000000000000000000000000000);
      delete stacks[_stack];
      CancelStack(msg.sender,now,_stack);
    }
    event CancelStack(address indexed _sender,uint256 indexed timestamp,bytes32 indexed _stack);
    function cancelCounterStack(bytes32 _stack,bytes32 _counterstack) public returns (bool) {
      require(msg.sender==stacks[_counterstack].owner);
      require(stackCounter[_counterstack]==_stack);
      require(mode[_stack]==0);
      delete stacks[_counterstack];
      delete stackCounter[_counterstack];
      CancelCounterStack(msg.sender,now,_stack,_counterstack);
    }
    event CancelCounterStack(address indexed _sender,uint256 indexed timestamp,bytes32 indexed _stack,bytes32 _counterstack);
    mapping (bytes32 => bytes32) public counterOfStack;
    mapping (bytes32 => uint8) public mode;
    mapping (bytes32 => uint8) public round;
    mapping (bytes32 => uint32) public lastBlock;
    mapping (bytes32 => uint32) public commitBlock;
    mapping (bytes32 => address) public lastActor;
    mapping (bytes32 => uint256[10]) public mixedStack;
    function acceptCounterStack(bytes32 _stack, bytes32 _counterStack) public returns (bool) {
      require(msg.sender==stacks[_stack].owner);
      require(stackCounter[_counterStack]==_stack);
      require(mode[_stack]==0);
      SlammerTime slammerTimeContract = SlammerTime(slammerTime);
      require( slammerTimeContract.startSlammerTime(msg.sender,stacks[_stack].ids,stacks[_counterStack].owner,stacks[_counterStack].ids) );
      lastBlock[_stack]=uint32(block.number);
      lastActor[_stack]=stacks[_counterStack].owner;
      mode[_stack]=1;
      counterOfStack[_stack]=_counterStack;
      mixedStack[_stack][0] = stacks[_stack].ids[0];
      mixedStack[_stack][1] = stacks[_counterStack].ids[0];
      mixedStack[_stack][2] = stacks[_stack].ids[1];
      mixedStack[_stack][3] = stacks[_counterStack].ids[1];
      mixedStack[_stack][4] = stacks[_stack].ids[2];
      mixedStack[_stack][5] = stacks[_counterStack].ids[2];
      mixedStack[_stack][6] = stacks[_stack].ids[3];
      mixedStack[_stack][7] = stacks[_counterStack].ids[3];
      mixedStack[_stack][8] = stacks[_stack].ids[4];
      mixedStack[_stack][9] = stacks[_counterStack].ids[4];
      AcceptCounterStack(msg.sender,_stack,_counterStack);
    }
    event AcceptCounterStack(address indexed _sender,bytes32 indexed _stack, bytes32 indexed _counterStack);
    mapping (bytes32 => bytes32) public commit;
    function getMixedStack(bytes32 _stack) external view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
      uint256[10] thisStack = mixedStack[_stack];
      return (thisStack[0],thisStack[1],thisStack[2],thisStack[3],thisStack[4],thisStack[5],thisStack[6],thisStack[7],thisStack[8],thisStack[9]);
    }
    function startCoinFlip(bytes32 _stack, bytes32 _counterStack, bytes32 _commit) public returns (bool) {
      require(stacks[_stack].owner==msg.sender);
      require(stackCounter[_counterStack]==_stack);
      require(counterOfStack[_stack]==_counterStack);
      require(mode[_stack]==1);
      commit[_stack]=_commit;
      commitBlock[_stack]=uint32(block.number);
      mode[_stack]=2;
      StartCoinFlip(_stack,_commit);
    }
    event StartCoinFlip(bytes32 stack, bytes32 commit);
    function endCoinFlip(bytes32 _stack, bytes32 _counterStack, bytes32 _reveal) public returns (bool) {
      require(stacks[_stack].owner==msg.sender);
      require(stackCounter[_counterStack]==_stack);
      require(counterOfStack[_stack]==_counterStack);
      require(mode[_stack]==2);
      require(uint32(block.number)>commitBlock[_stack]);
      if(keccak256(_reveal)!=commit[_stack]){
        mode[_stack]=1;
        CoinFlipFail(_stack);
        return false;
      }else{
        mode[_stack]=3;
        round[_stack]=1;
        bytes32 pseudoRandomHash = keccak256(_reveal,block.blockhash(commitBlock[_stack]));
        if(uint256(pseudoRandomHash)%2==0){
          lastBlock[_stack]=uint32(block.number);
          lastActor[_stack]=stacks[_counterStack].owner;
          CoinFlipSuccess(_stack,stacks[_stack].owner,true);
        }else{
          lastBlock[_stack]=uint32(block.number);
          lastActor[_stack]=stacks[_stack].owner;
          CoinFlipSuccess(_stack,stacks[_counterStack].owner,false);
        }
        return true;
      }
    }
    event CoinFlipSuccess(bytes32 indexed stack,address whosTurn,bool heads);
    event CoinFlipFail(bytes32 stack);
    function raiseSlammer(bytes32 _stack, bytes32 _counterStack, bytes32 _commit) public returns (bool) {
      if(lastActor[_stack]==stacks[_stack].owner){
        require(stacks[_counterStack].owner==msg.sender);
      }else{
        require(stacks[_stack].owner==msg.sender);
      }
      require(stackCounter[_counterStack]==_stack);
      require(counterOfStack[_stack]==_counterStack);
      require(mode[_stack]==3);
      commit[_stack]=_commit;
      commitBlock[_stack]=uint32(block.number);
      mode[_stack]=4;
      RaiseSlammer(_stack,_commit);
    }
    event RaiseSlammer(bytes32 stack, bytes32 commit);
    function throwSlammer(bytes32 _stack, bytes32 _counterStack, bytes32 _reveal) public returns (bool) {
      if(lastActor[_stack]==stacks[_stack].owner){
        require(stacks[_counterStack].owner==msg.sender);
      }else{
        require(stacks[_stack].owner==msg.sender);
      }
      require(stackCounter[_counterStack]==_stack);
      require(counterOfStack[_stack]==_counterStack);
      require(mode[_stack]==4);
      require(uint32(block.number)>commitBlock[_stack]);
      uint256[10] memory flipped;
      if(keccak256(_reveal)!=commit[_stack]){
        mode[_stack]=3;
        throwSlammerEvent(_stack,msg.sender,address(0),flipped);
        return false;
      }else{
        mode[_stack]=3;
        address previousLastActor = lastActor[_stack];
        bytes32 pseudoRandomHash = keccak256(_reveal,block.blockhash(commitBlock[_stack]));
        if(lastActor[_stack]==stacks[_stack].owner){
          lastBlock[_stack]=uint32(block.number);
          lastActor[_stack]=stacks[_counterStack].owner;
        }else{
          lastBlock[_stack]=uint32(block.number);
          lastActor[_stack]=stacks[_stack].owner;
        }
        bool done=true;
        uint8 randIndex = 0;
        for(uint8 i=0;i<10;i++){
          if(mixedStack[_stack][i]>0){
            uint8 thisFlipper = uint8(pseudoRandomHash[randIndex++]);
            if(thisFlipper<(FLIPPINESS+round[_stack]*FLIPPINESSROUNDBONUS)){
               uint256 tempId = mixedStack[_stack][i];
               flipped[i]=tempId;
               mixedStack[_stack][i]=0;
               SlammerTime slammerTimeContract = SlammerTime(slammerTime);
               slammerTimeContract.transferBack(msg.sender,tempId);
            }else{
              done=false;
            }
          }
        }
        throwSlammerEvent(_stack,msg.sender,previousLastActor,flipped);
        if(done){
          FinishGame(_stack);
          mode[_stack]=9;
          delete mixedStack[_stack];
          delete stacks[_stack];
          delete stackCounter[_counterStack];
          delete stacks[_counterStack];
          delete lastBlock[_stack];
          delete lastActor[_stack];
          delete counterOfStack[_stack];
          delete round[_stack];
          delete commitBlock[_stack];
          delete commit[_stack];
        }else{
          round[_stack]++;
        }
        return true;
      }
    }
    event ThrowSlammer(bytes32 indexed stack, address indexed whoDoneIt, address indexed otherPlayer, uint256 token1Flipped, uint256 token2Flipped, uint256 token3Flipped, uint256 token4Flipped, uint256 token5Flipped, uint256 token6Flipped, uint256 token7Flipped, uint256 token8Flipped, uint256 token9Flipped, uint256 token10Flipped);
    event FinishGame(bytes32 stack);
    function throwSlammerEvent(bytes32 stack,address whoDoneIt,address otherAccount, uint256[10] flipArray) internal {
      ThrowSlammer(stack,whoDoneIt,otherAccount,flipArray[0],flipArray[1],flipArray[2],flipArray[3],flipArray[4],flipArray[5],flipArray[6],flipArray[7],flipArray[8],flipArray[9]);
    }
    function drainStack(bytes32 _stack, bytes32 _counterStack) public returns (bool) {
      require( stacks[_stack].owner==msg.sender || stacks[_counterStack].owner==msg.sender );
      require( stackCounter[_counterStack]==_stack );
      require( counterOfStack[_stack]==_counterStack );
      require( lastActor[_stack]==msg.sender );
      require( block.number - lastBlock[_stack] >= TIMEOUTBLOCKS);
      require( mode[_stack]<9 );
      for(uint8 i=0;i<10;i++){
        if(mixedStack[_stack][i]>0){
          uint256 tempId = mixedStack[_stack][i];
          mixedStack[_stack][i]=0;
          SlammerTime slammerTimeContract = SlammerTime(slammerTime);
          slammerTimeContract.transferBack(msg.sender,tempId);
        }
      }
      FinishGame(_stack);
      mode[_stack]=9;
      delete mixedStack[_stack];
      delete stacks[_stack];
      delete stackCounter[_counterStack];
      delete stacks[_counterStack];
      delete lastBlock[_stack];
      delete lastActor[_stack];
      delete counterOfStack[_stack];
      delete round[_stack];
      delete commitBlock[_stack];
      delete commit[_stack];
      DrainStack(_stack,_counterStack,msg.sender);
    }
    event DrainStack(bytes32 stack,bytes32 counterStack,address sender);
    function totalSupply() public view returns (uint) {
        return items.length - 1;
    }
    function tokensOfOwner(address _owner) external view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 id;
            for (id = 1; id <= total; id++) {
                if (tokenIndexToOwner[id] == _owner) {
                    result[resultIndex] = id;
                    resultIndex++;
                }
            }
            return result;
        }
    }
    function withdraw(uint256 _amount) public onlyOwner returns (bool) {
      require(this.balance >= _amount);
      assert(owner.send(_amount));
      return true;
    }
    function withdrawToken(address _token,uint256 _amount) public onlyOwner returns (bool) {
      StandardToken token = StandardToken(_token);
      token.transfer(msg.sender,_amount);
      return true;
    }
    function transferStackAndCall(address _to, uint _token1, uint _token2, uint _token3, uint _token4, uint _token5, bytes32 _data) public returns (bool) {
      transfer(_to, _token1);
      transfer(_to, _token2);
      transfer(_to, _token3);
      transfer(_to, _token4);
      transfer(_to, _token5);
      if (isContract(_to)) {
        contractFallback(_to,_token1,_token2,_token3,_token4,_token5,_data);
      }
      return true;
    }
    function contractFallback(address _to, uint _token1, uint _token2, uint _token3, uint _token4, uint _token5, bytes32 _data) private {
      StackReceiver receiver = StackReceiver(_to);
      receiver.onTransferStack(msg.sender,_token1,_token2,_token3,_token4,_token5,_data);
    }
    function isContract(address _addr) private returns (bool hasCode) {
      uint length;
      assembly { length := extcodesize(_addr) }
      return length > 0;
    }
}
contract StackReceiver {
  function onTransferStack(address _sender, uint _token1, uint _token2, uint _token3, uint _token4, uint _token5, bytes32 _data);
}
contract StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) { }
}
contract SlammerTime {
  function startSlammerTime(address _player1,uint256[5] _id1,address _player2,uint256[5] _id2) public returns (bool) { }
  function transferBack(address _toWhom, uint256 _id) public returns (bool) { }
}