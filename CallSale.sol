// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC20.sol";
import "Call.sol";

// The sale of an American call option
contract CallSale {
  address _currencyOfContract;
  address _currencyOfSale;
  address _tokenContract;
  address _tokenOwner;
  uint256 _strikePrice;
  uint _expiration;
  uint256 _token;
  uint256 _salePrice;
  bool _sold;

  constructor(address currencyOfContract_, address currencyOfSale_, address tokenContract_, address tokenOwner_, uint256 strikePrice_, uint expiration_, uint256 token_, uint256 salePrice_) {
    _currencyOfContract = currencyOfContract_;
    _currencyOfSale = currencyOfSale_;
    _tokenContract = tokenContract_;
    _tokenOwner = tokenOwner_;
    _strikePrice = strikePrice_;
    _expiration = expiration_;
    _token = token_;
    _salePrice = salePrice_;
    _sold = false;
  }

  function funded() internal view returns (bool) {
    return IERC721(_tokenContract).ownerOf(_token) == address(this);
  }

  function buy() external returns (address) {
    require(funded(), "Contract must already be funded");
    require(!_sold, "Contract must not be already sold");
    IERC20(_currencyOfSale).transferFrom(msg.sender, address(this), _salePrice);
    Call option = new Call(_currencyOfContract, _tokenContract, msg.sender, _tokenOwner, _strikePrice, _expiration, _token);
    IERC721(_tokenContract).safeTransferFrom(address(this), address(option), _token);
    return address(option);
  }

  function withdraw() external {
    require(msg.sender == _tokenOwner, "Only the token owner can withdraw");
    IERC20(_currencyOfSale).transfer(_tokenOwner, IERC20(_currencyOfSale).balanceOf(address(this)));
  }
}
