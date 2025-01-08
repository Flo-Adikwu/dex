// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract DEX is ERC20Base {
    address public token;

//our constructor is going to deploy us our ERC20 token
    constructor(address _token, address _defaultAdmin, string memory _name, string memory _symbol) 
    ERC20Base(_defaultAdmin, _name, _symbol) {
        token = _token;
    }

    //function to get token balance in contract address
    function getTokenInContract() public view  returns (uint256){
        return ERC20Base(token).balanceOf(address(this));
    }

    //function to add liquidity to the dex contract
    function addLiquidity(uint256 _amount) public payable returns (uint256){
        uint256 _liquidity;
        uint256 balanceInEth = address(this).balance;
        uint256 tokenReserve = getTokenInContract();
        ERC20 _token = ERC20Base(token);

        //first time adding token to reserve
        if(tokenReserve == 0){
            _token.transferFrom(msg.sender, address(this), _amount);
            _liquidity = balanceInEth;
            _mint(msg.sender, _amount);// mint to the person adding liquidity to contract
        } 
        //for anyone adding after initial liquidity
        else {
            uint reservedEth = balanceInEth - msg.value;
            require(
                _amount >= (msg.value * tokenReserve) / reservedEth,
                "Amount of token sent is less than minimum token required"
            );
            _token.transferFrom(msg.sender, address(this), _amount);
            unchecked{
                _liquidity = (totalSupply() * msg.value) / reservedEth;
            }
            _mint(msg.sender, _liquidity);
        }
        return _liquidity;
    }

    //function to remove liquidity. Essentially, take your liquidity tokens, burn it and receive back FLOR token
    function removeLiquidity(uint256 _amount) public returns (uint256, uint256){
        require(_amount > 0, "Amount should be greater than zero");
        uint256 _reservedEth = address(this).balance;
        uint256 _totalSupply = totalSupply();

        uint256 _ethAmount = (_reservedEth * _amount) / totalSupply();
        uint256 _tokenAmount = (getTokenInContract() * _amount) / _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_ethAmount);
        ERC20Base(token).transfer(msg.sender, _tokenAmount);
        return (_ethAmount, _tokenAmount);
    }

    //function to get the amount of token you receive when you swap
    function getAmountOfTokens(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256){
        require(inputReserve > 0 && outputReserve > 0, "Invalid Reserves");
        uint256 numerator = inputAmount * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmount;
        unchecked {
            return numerator / denominator;
        }
    }

    //swap eth to token
    function swapEthToToken() public payable{
        uint256 _reservedToken = getTokenInContract();
        uint256 _tokensBought = getAmountOfTokens(
            msg.value, address(this).balance, _reservedToken
        );
         ERC20Base(token).transfer(msg.sender, _tokensBought);
    }

    //swap token to eth
    function swapTokenToEth(uint256 _tokenSold) public {
        uint256 _reservedToken = getTokenInContract();
        uint256 ethBought = getAmountOfTokens(
            _tokenSold, address(this).balance, _reservedToken
        );
         ERC20Base(token).transferFrom(msg.sender, address(this), _tokenSold);
         payable(msg.sender).transfer(ethBought);
    }
    
}