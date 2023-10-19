pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface Oracle {
    function getPriceUSD(address reserve) external view returns (uint);
}
interface ISushiswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface ISushiswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
library SushiswapV2Library {
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SushiswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SushiswapV2Library: ZERO_ADDRESS');
    }
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' 
            )))));
    }
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISushiswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SushiswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SushiswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }
}
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}
contract StableYieldCredit is ReentrancyGuard {
    using SafeERC20 for IERC20;
    string public constant name = "Stable Yield Credit";
    string public constant symbol = "yCREDIT";
    uint8 public constant decimals = 8;
    uint public totalSupply = 0;
    uint public stakedSupply = 0;
    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;
    mapping(address => uint) public stakes;
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");
    bytes32 public immutable DOMAINSEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");
    mapping (address => uint) public nonces;
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
    event Transfer(address indexed from, address indexed to, uint amount);
    event Staked(address indexed from, uint amount);
    event Unstaked(address indexed from, uint amount);
    event Earned(address indexed from, uint amount);
    event Fees(uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    Oracle public constant LINK = Oracle(0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a);
    ISushiswapV2Factory public constant FACTORY = ISushiswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    mapping (address => mapping(address => uint)) public collateral;
    mapping (address => mapping(address => uint)) public collateralCredit;
    address[] private _markets;
    mapping (address => bool) pairs;
    uint public rewardRate = 0;
    uint public periodFinish = 0;
    uint public DURATION = 7 days;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    event Deposit(address indexed creditor, address indexed collateral, uint creditOut, uint amountIn, uint creditMinted);
    event Withdraw(address indexed creditor, address indexed collateral, uint creditIn, uint creditOut, uint amountOut);
    constructor () {
        DOMAINSEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
    }
    uint public FEE = 50;
    uint public BASE = 10000;
    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }
    function rewardPerToken() public view returns (uint) {
        if (stakedSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
                ((lastTimeRewardApplicable() - 
                lastUpdateTime) * 
                rewardRate * 1e18 / stakedSupply);
    }
    function earned(address account) public view returns (uint) {
        return (stakes[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }
    function getRewardForDuration() external view returns (uint) {
        return rewardRate * DURATION;
    }
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        stakedSupply += amount;
        stakes[msg.sender] += amount;
        _transferTokens(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }
    function unstake(uint amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        stakedSupply -= amount;
        stakes[msg.sender] -= amount;
        _transferTokens(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _transferTokens(address(this), msg.sender, reward);
            emit Earned(msg.sender, reward);
        }
    }
    function exit() external {
        unstake(stakes[msg.sender]);
        getReward();
    }
    function notifyFeeAmount(uint reward) internal updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / DURATION;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / DURATION;
        }
        uint balance = balances[address(this)];
        require(rewardRate <= balance / DURATION, "Provided reward too high");
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
        emit Fees(reward);
    }
    function markets() external view returns (address[] memory) {
        return _markets;
    }
    function _mint(address dst, uint amount) internal {
        totalSupply += amount;
        balances[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
    function _burn(address dst, uint amount) internal {
        totalSupply -= amount;
        balances[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }
    function depositAll(IERC20 token) external {
        _deposit(token, token.balanceOf(msg.sender));
    }
    function deposit(IERC20 token, uint amount) external {
        _deposit(token, amount);
    }
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired
    ) internal virtual returns (address pair, uint amountA, uint amountB) {
        pair = FACTORY.getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = FACTORY.createPair(tokenA, tokenB);
            pairs[pair] = true;
            _markets.push(tokenA);
        } else if (!pairs[pair]) {
            pairs[pair] = true;
            _markets.push(tokenA);
        }
        (uint reserveA, uint reserveB) = SushiswapV2Library.getReserves(address(FACTORY), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SushiswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SushiswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function _deposit(IERC20 token, uint amount) internal {
        uint _value = LINK.getPriceUSD(address(token)) * amount / uint256(10)**token.decimals();
        require(_value > 0, "!value");
        (address _pair, uint amountA,) = _addLiquidity(address(token), address(this), amount, _value);
        token.safeTransferFrom(msg.sender, _pair, amountA);
        _mint(_pair, _value); 
        uint _liquidity = ISushiswapV2Pair(_pair).mint(address(this));
        collateral[msg.sender][address(token)] += _liquidity;
        collateralCredit[msg.sender][address(token)] += _value;
        uint _fee = _value * FEE / BASE;
        _mint(msg.sender, _value - _fee);
        _mint(address(this), _fee);
        notifyFeeAmount(_fee);
        emit Deposit(msg.sender, address(token), _value, amount, _value);
    }
    function withdrawAll(IERC20 token) external {
        _withdraw(token, IERC20(address(this)).balanceOf(msg.sender));
    }
    function withdraw(IERC20 token, uint amount) external {
        _withdraw(token, amount);
    }
    function _withdraw(IERC20 token, uint amount) internal {
        uint _credit = collateralCredit[msg.sender][address(token)];
        uint _collateral = collateral[msg.sender][address(token)];
        if (_credit < amount) {
            amount = _credit;
        }
        uint _burned = _collateral * amount / _credit;
        address _pair = FACTORY.getPair(address(token), address(this));
        IERC20(_pair).safeTransfer(_pair, _burned); 
        (uint _amount0, uint _amount1) = ISushiswapV2Pair(_pair).burn(msg.sender);
        (address _token0,) = SushiswapV2Library.sortTokens(address(token), address(this));
        (uint _amountA, uint _amountB) = address(token) == _token0 ? (_amount0, _amount1) : (_amount1, _amount0);
        collateralCredit[msg.sender][address(token)] -= amount;
        collateral[msg.sender][address(token)] -= _burned;
        _burn(msg.sender, _amountB+amount); 
        emit Withdraw(msg.sender, address(token), amount, _amountB, _amountA);
    }
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }
    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAINSEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "permit: signature");
        require(signatory == owner, "permit: unauthorized");
        require(block.timestamp <= deadline, "permit: expired");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }
    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];
        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;
            emit Approval(src, spender, newAllowance);
        }
        _transferTokens(src, dst, amount);
        return true;
    }
    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;
        emit Transfer(src, dst, amount);
        if (pairs[src]) {
            uint _fee = amount * FEE / BASE;
            _transferTokens(dst, address(this), _fee);
            notifyFeeAmount(_fee);
        }
    }
    function _getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}