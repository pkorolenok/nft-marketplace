//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IERC20Mintable.sol";

contract ExCoin is ERC20Capped, AccessControl, IERC20Mintable {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint256 capacity)
        ERC20("Exadel Coin", "EXCOIN")
        ERC20Capped(capacity)
    {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     *  Lets an authorized address mint tokens to a recipient.
     */
    function mintTo(address _to, uint256 _amount) public override virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "Not authorized to mint.");
        require(_amount != 0, "Minting zero tokens.");

        _mint(_to, _amount);
    }
}
