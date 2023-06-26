// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function _approve(address owner, address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() 
    {   _status = _NOT_ENTERED;     }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract DRDBuyRouter is Ownable, ReentrancyGuard{

    using SafeMath for uint256;
    IERC20 public DRD;
    IERC20 public BUSD;

    IPancakeRouter01 public Router;

    uint256 public DRDToken;
    uint256 public BUSDToken;
    uint256 public PoolBUSDamount;
    uint256 public PoolPercentage = 50;
    uint256 public SWAPTokenPercentage = 20;
    uint256 public count;
    uint256 public SwapandLiquifyCount = 2;
    address public LpReceiver;
    address public BUSDReceiver;
    uint256 HalfToken;
    uint256 ContractBalance;
    uint256 public returnToken;

    constructor()
    {
       DRD = IERC20(0x6BeA8E272B0E9722ef3432Da1B366e2015542c1f);
       BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
       Router = IPancakeRouter01(0x10ED43C718714eb63d5aA57B78B54704E256024E);
       LpReceiver = 0xFdADeeB65793781ff97b39fb3754290CC6C504D8;
       BUSDReceiver = 0x45BC98d04Db12410cC4bC2F410DE5d2404b0e65e;
    }
    

    uint256 mintDeposit = 50; 
     
    uint256 public firstHalf = 50;  
    uint256 public secondHalf = 50;

    function getPercentages(uint256 amount) public view returns(uint256, uint256){
        uint256 token0 = amount.mul(firstHalf).div(100);
        uint256 token1 = amount.mul(secondHalf).div(100);
        return(token0, token1);
    }


    function getPrice(uint256 packageamount) public view returns(uint256, uint256){

        (uint256 value0, uint256 value1) = getPercentages(packageamount);
        require(packageamount.mod(mintDeposit) == 0 && packageamount >= mintDeposit, "mod err");

        // no. of tokens in one dollar 
        address[] memory path0 = new address[](2);
        path0[0] = address(BUSD);
        path0[1] = address(DRD);
        uint256[] memory amounts0 = Router.getAmountsOut(1 ether,path0);

        return (amounts0[1].mul(value0), value1.mul(1 ether));
    }


    function buyRouter(uint256 packageamount)
    public 
    nonReentrant
    {
        require(msg.sender == tx.origin," External Error ");
        (uint256 token0, uint256 token1) = getPrice(packageamount);
        require(DRD.balanceOf(msg.sender) >= token0);
        require(BUSD.balanceOf(msg.sender) >= token1);

        require(DRD.transferFrom(_msgSender(),address(this),token0)," Approve DRD First ");
        require(BUSD.transferFrom(_msgSender(),address(this),token1)," Approve BUSD First ");
        PoolBUSDamount += (token1.mul(PoolPercentage)).div(100);

        count++;
        bool pool;
        if(count == SwapandLiquifyCount){

        uint256 half = PoolBUSDamount/2;
        BUSD.approve(address(Router), half);
        uint256[] memory returnValues = swapExactTokensForToken(half, address(DRD));
        returnToken = Percentage(returnValues[1]);
        DRD.approve(address(Router), returnValues[1]);
        BUSD.approve(address(Router), half);
        addingLiquidity(returnValues[1], half);
        
       DRD.approve(address(Router), returnToken);
        swapTokensForToken(returnToken);
        pool = true;
        }
        if(pool) {
            count = 0;
            PoolBUSDamount = 0;
        }
    }

    function Percentage(uint256 _swapToken) internal view returns(uint256)
    {
        uint256 swapToken;
        swapToken = (_swapToken.mul(SWAPTokenPercentage)).div(100);
        return swapToken;
    }

    function swapExactTokensForToken(uint256 value, address token) private 
    returns (uint[] memory amounts)  
    {
        address[] memory path = new address[](2);
        path[0] = address(BUSD);
        path[1] = token;
        return Router.swapExactTokensForTokens(
        value,
        0,    
        path,
        address(this), 
        block.timestamp
        );
    }

    function addingLiquidity(uint256 _amount,uint256 _half) private 
    {
        Router.addLiquidity(
            address(DRD),
            address(BUSD),
            _amount,
            _half,
             0,
             0,
            LpReceiver,
            block.timestamp
        );
    }

    function swapTokensForToken(uint256 _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(DRD);
        path[1] = address(BUSD);
        Router.swapExactTokensForTokens(
            _tokenAmount,
            0,
            path,
            BUSDReceiver,
            block.timestamp
        );
    }


    function updateFirstHalf(uint256 token0) public onlyOwner{
        firstHalf = token0;
    }

    function updateSecondHalf(uint256 token1) public onlyOwner{
        secondHalf = token1;
    }

    function UpdateLpReceiver(address LpReceiver_)
    public
    onlyOwner
    {     LpReceiver = LpReceiver_;        }

    function UpdateBUSDReceiver(address BUSDReceiver_)
    public
    onlyOwner
    {    BUSDReceiver = BUSDReceiver_;         }

    function UpdateROUTER(IPancakeRouter01 _Router)
    public
    onlyOwner
    {      Router = _Router;        }

    function UpdatePercentage(uint256 _SWAPTokenPercentage)
    public
    onlyOwner
    {      SWAPTokenPercentage = _SWAPTokenPercentage;      }

    function UpdateCondition(uint256 SwapandLiquifyCount_)
    public
    onlyOwner
    {      SwapandLiquifyCount = SwapandLiquifyCount_;      }



    function withdrawableDRDToken()
    private
    view returns(uint256 amount)
    {
        amount = DRD.balanceOf(address(this));
        return amount = amount.sub((amount.mul(30)).div(100));
    }

    function withdrawToken()
    public
    onlyOwner
    {   DRD.transfer(owner(),withdrawableDRDToken());   }

    function emergencyWithdrawToken()
    public
    onlyOwner
    {   DRD.transfer(owner(),(DRD.balanceOf(address(this))));   }


    function withdrawableBusd()
    private
    view returns(uint256 amount)
    {
        amount = BUSD.balanceOf(address(this));
        return amount = amount - PoolBUSDamount; 
    }

    function withdrawBusd()
    public
    onlyOwner
    {   BUSD.transfer(owner(),withdrawableBusd());   }

    function emergencyWithdrawBusdToken()
    public
    onlyOwner
    {   BUSD.transfer(owner(),(BUSD.balanceOf(address(this))));   }


}