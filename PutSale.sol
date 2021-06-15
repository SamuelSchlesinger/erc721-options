// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC20.sol";
import "Put.sol";

// The sale of an American call option
contract PutSale {
  address _currencyOfContract;
  address _currencyOfSale;
  address _tokenContract;
  address _tokenBuyer;
  uint256 _strikePrice;
  uint _expiration;
  uint256 _token;
  uint256 _salePrice;
  bool _sold;

  constructor(address currencyOfContract_, address currencyOfSale_, address tokenContract_, address tokenBuyer_, uint256 strikePrice_, uint expiration_, uint256 token_, uint256 salePrice_) {
    _currencyOfContract = currencyOfContract_;
    _currencyOfSale = currencyOfSale_;
    _tokenContract = tokenContract_;
    _tokenBuyer = tokenBuyer_;
    _strikePrice = strikePrice_;
    _expiration = expiration_;
    _token = token_;
    _salePrice = salePrice_;
    _sold = false;
  }

  function funded() internal view returns (bool) {
    return IERC20(_tokenContract).balanceOf(address(this)) == _strikePrice;
  }

  function buy() external returns (address) {
    require(funded(), "Contract must already be funded");
    require(!_sold, "Contract must not be already sold");
    IERC20(_currencyOfSale).transferFrom(msg.sender, address(this), _salePrice);
    Put option = new Put(_currencyOfContract, _tokenContract, msg.sender, _tokenBuyer, _strikePrice, _expiration, _token);
    require(IERC20(_tokenContract).transferFrom(address(this), address(option), _token), "Must be able to transfer the cash to secure the put");
    return address(option);
  }

  function withdraw() external {
    require(msg.sender == _tokenBuyer, "Only the token owner can withdraw");
    IERC20(_currencyOfSale).transfer(_tokenBuyer, IERC20(_currencyOfSale).balanceOf(address(this)));
  }
}
