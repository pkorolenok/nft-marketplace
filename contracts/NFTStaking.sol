// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20Mintable.sol";

contract NFTStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20Mintable public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    // Sets NFT collection and Rewards token addresses
    constructor(IERC721 _nftCollection, IERC20Mintable _rewardsToken) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
    }

    struct StakerInfo {
        uint256[] stakedTokens;
        uint256 rewardsLastUpdateTime;
        uint256 unclaimedRewards;
    }

    // Rewards per day per token deposited in wei
    uint256 private rewardsPerDay = 1000000000000000000000; // 1000 ERC20 tokens per day

    // Mapping of User address to Staker Info
    mapping(address => StakerInfo) public stakers;

    // Mapping of token id to Staker address
    mapping(uint256 => address) public stakerAddress;

    // Stakes NFT token on the contract, specifically:
    // - check if address already has NFT tokens staked and calculate rewards earned so far
    // - transfers the token to the constrat
    // - update staker info (incl. unclaimed rewards) and map msg.sender to token id for future withdrowal
    function stake(uint256 _tokenId) external nonReentrant {
        // calculate the rewards before adding the new token
        uint256 rewards = 0;
        if (stakers[msg.sender].stakedTokens.length > 0) {
            rewards = calculateRewards(msg.sender);
        }

        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        stakerAddress[_tokenId] = msg.sender;

        stakers[msg.sender].stakedTokens.push(_tokenId);
        // update staker rewards and last update time
        stakers[msg.sender].unclaimedRewards += rewards;
        stakers[msg.sender].rewardsLastUpdateTime = block.timestamp;
    }

    // Withdraws NFT token from the contract, specifically:
    // - calculate and transfer rewards earned so far to a staker
    // - transfer token back to the owner and reset staker address map
    function withdraw(uint256 _tokenId) external nonReentrant {
        require(
            stakers[msg.sender].stakedTokens.length > 0,
            "You have no tokens staked"
        );
        require(
            stakerAddress[_tokenId] == msg.sender,
            "You don't own this token!"
        );

        // calculate and transfer the rewards before removing the token
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        transferRewards(msg.sender, rewards);

        // remove token id from staked tokens array
        uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (stakers[msg.sender].stakedTokens[i] == _tokenId) {
                index = i;
                break;
            }
        }
        stakers[msg.sender].stakedTokens[index] = stakers[msg.sender]
            .stakedTokens[stakers[msg.sender].stakedTokens.length - 1];
        stakers[msg.sender].stakedTokens.pop();

        // set to address(0) to indicate that the token is no longer staked
        stakerAddress[_tokenId] = address(0);

        nftCollection.transferFrom(address(this), msg.sender, _tokenId);
    }

    // Withdraws all NFT tokens owned by a staker from the contract, specifically:
    // - calculate and transfer rewards earned so far to a staker
    // - transfer all staked tokens back to the owner and reset staker address map
    function withdrawAll() external nonReentrant {
        require(
            stakers[msg.sender].stakedTokens.length > 0,
            "You have no tokens staked"
        );

        // calculate and transfer the rewards before removing the tokens
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        transferRewards(msg.sender, rewards);

        // remove all tokens from staked tokens array
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            uint256 tokenId = stakers[msg.sender].stakedTokens[i];
            // set to address(0) to indicate that the token is no longer staked
            stakerAddress[tokenId] = address(0);
            nftCollection.transferFrom(address(this), msg.sender, tokenId);
        }
        delete stakers[msg.sender].stakedTokens;
    }

    // Transfer unclaimed rewards to staker address
    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        transferRewards(msg.sender, rewards);
    }

    //////////
    // View //
    //////////

    function getAvailableRewards(address _staker)
        public
        view
        returns (uint256)
    {
        uint256 rewards = calculateRewards(_staker) +
            stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory)
    {
        if (stakers[_user].stakedTokens.length > 0) {
            uint256[] memory _stakedTokens = new uint256[](
                stakers[_user].stakedTokens.length
            );
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                _index++;
            }

            return _stakedTokens;
        } else {
            return new uint256[](0);
        }
    }

    /////////////
    // Internal//
    /////////////

    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {
        return
            ((
                ((block.timestamp - stakers[_staker].rewardsLastUpdateTime) *
                    stakers[_staker].stakedTokens.length)
            ) * rewardsPerDay) / 86400;
    }

    function transferRewards(address _staker, uint256 rewards) internal {
        stakers[_staker].rewardsLastUpdateTime = block.timestamp;
        stakers[_staker].unclaimedRewards = 0;
        rewardsToken.mintTo(_staker, rewards);
    }
}
