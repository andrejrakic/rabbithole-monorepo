// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "./vendor/openzeppelin/contracts/v5.0.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/contracts/v5.0.0/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "./vendor/openzeppelin/contracts/v5.0.0/utils/math/SafeCast.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/contracts/v5.0.0/utils/ReentrancyGuard.sol";
import {Pausable} from "./vendor/openzeppelin/contracts/v5.0.0/utils/Pausable.sol";
import {Ownable} from "./utils/Ownable.sol";

contract UntrustedEscrow is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    struct Escrow {
        uint256 sharePercentage; //
        address tokenAddress; //
        address buyer; //
        address seller; // ──────────╮
        uint48 releaseTimestamp; // ─╯
    }

    /**
     * @dev In finance, Basis Points (BPS) are a unit of measurement equal to 1/100th of 1 percent
     *
     * This metric is commonly used for loans and bonds to signify percentage changes
     * or yield spreads in financial instruments,
     * especially when the difference in material interest rates is less than one percent
     *
     * 0.01%  =  1 BPS
     * 0.05%  =  5 BPS
     * 0.1%   =  10 BPS
     * 0.5%   =  50 BPS
     * 1%     =  100 BPS
     * 10%    =  1 000 BPS
     * 100%   =  10 000 BPS
     */
    uint256 internal constant HUNDRED_PERCENT_BPS = 10_000;
    uint256 internal constant UNFREEZE_PERIOD = 3 days;

    uint256 internal s_nonce;

    mapping(address tokenAddress => uint256 totalTokensIn) internal s_totalTokens;
    mapping(bytes32 escrowId => Escrow) internal s_escrows;

    event NewEscrow(
        bytes32 indexed escrowId,
        address buyer,
        address seller,
        address tokenAddress,
        uint256 amountDeposited,
        uint256 indexed releaseTimestamp
    );
    event EscrowWithdrawn(bytes32 indexed escrowId, uint256 indexed amountWithdrawn);

    error UnstructuredEscrow__InvalidDeposit();
    error UnstructuredEscrow__InvalidCaller(address expected, address actual);
    error UnstructuredEscrow__TooEarlyToCall();

    constructor(address _owner, address _pendingOwner) Ownable(_owner, _pendingOwner) {}

    function deposit(address seller, address tokenAddress, uint256 amount)
        external
        nonReentrant
        returns (bytes32 escrowId)
    {
        uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));

        uint256 actuallyDeposited = balanceAfter - balanceBefore;
        if (actuallyDeposited == 0) revert UnstructuredEscrow__InvalidDeposit();

        s_totalTokens[tokenAddress] += actuallyDeposited;

        uint256 releaseTimestamp;
        unchecked {
            releaseTimestamp = block.timestamp + UNFREEZE_PERIOD;
        }

        Escrow memory escrow = Escrow({
            sharePercentage: actuallyDeposited,
            tokenAddress: tokenAddress,
            buyer: msg.sender,
            seller: seller,
            releaseTimestamp: SafeCast.toUint48(releaseTimestamp)
        });

        escrowId = keccak256(abi.encode(escrow, s_nonce++));

        s_escrows[escrowId] = escrow;

        emit NewEscrow(escrowId, msg.sender, seller, tokenAddress, actuallyDeposited, releaseTimestamp);
    }

    function withdraw(bytes32 escrowId) external whenNotPaused nonReentrant {
        Escrow memory escrow = s_escrows[escrowId];
        if (msg.sender != escrow.seller) {
            revert UnstructuredEscrow__InvalidCaller(escrow.seller, msg.sender);
        }
        if (block.timestamp < escrow.releaseTimestamp) {
            revert UnstructuredEscrow__TooEarlyToCall();
        }

        uint256 share = (escrow.sharePercentage * HUNDRED_PERCENT_BPS) / s_totalTokens[escrow.tokenAddress];

        uint256 amountToWithdraw = (share * IERC20(escrow.tokenAddress).balanceOf(address(this))) / HUNDRED_PERCENT_BPS;

        s_totalTokens[escrow.tokenAddress] -= escrow.sharePercentage;

        delete s_escrows[escrowId];

        IERC20(escrow.tokenAddress).safeTransfer(escrow.seller, amountToWithdraw);

        emit EscrowWithdrawn(escrowId, amountToWithdraw);
    }

    function getEscrowDetails(bytes32 escrowId) external view returns (Escrow memory) {
        return s_escrows[escrowId];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
