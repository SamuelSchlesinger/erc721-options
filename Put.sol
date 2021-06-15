// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC20.sol";

// An American style put option
contract Put is IERC721Receiver {
  address _currencyContract;
  address _tokenContract;
  address _contractOwner;
  address _tokenBuyer;
  uint256 _strikePrice;
  uint _expiration;
  bool _exercised;
  uint256 _token;

  constructor(address currencyContract_, address tokenContract_, address contractOwner_, address tokenBuyer_, uint256 strikePrice_, uint expiration_, uint256 token_) {
    _currencyContract = currencyContract_;
    _tokenContract = tokenContract_;
    _tokenBuyer = tokenBuyer_;
    _contractOwner = contractOwner_;
    _strikePrice = strikePrice_;
    _expiration = expiration_;
    _token = token_;
    _exercised = false;
  }

  // The buyer must have already supplied the contract with the ERC20 funds to make the purchase,
  // and the contract owner must have already supplied the contract with the ERC721 token.
  function exercise() external {
    require(msg.sender == _contractOwner, "Only the owner can exercise the contract");
    require(!_exercised, "One can only exercise the call option once.");
    require(_expiration < block.timestamp, "Attempted to exercise after expiration");
    IERC721(_tokenContract).safeTransferFrom(address(this), _tokenBuyer, _token);
    require(IERC20(_currencyContract).transfer(_contractOwner, _strikePrice), "Could not transfer currency to contract owner");
    _exercised = true;
  }

  // The owner of the token or the currency can dissolve the contract, returning any currency to
  // the contract owner and the token to the token owner
  function dissolve() external {
    require((msg.sender == _contractOwner || msg.sender == _tokenBuyer) && _expiration < block.timestamp || _exercised, "The contract owner or the token owner can dissolve the contract after the expiration or after it has been exercised."); 
    if (IERC721(_tokenContract).ownerOf(_token) == address(this)) {
      IERC721(_tokenContract).safeTransferFrom(address(this), _tokenBuyer, _token);
    }
    // Pay the contract owner any funds which have been paid to this account
    IERC20(_currencyContract).transfer(_tokenBuyer, IERC20(_currencyContract).balanceOf(address(this)));
  }

  function onERC721Received(address, address, uint256 tokenId, bytes calldata) external view override returns (bytes4) {
    require(tokenId == _token, "I will only accept the token I'm concerned with.");
    return bytes4(0x00000000);
  }
}
