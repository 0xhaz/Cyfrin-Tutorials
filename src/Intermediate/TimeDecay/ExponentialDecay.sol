// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {ABDKMathQuad} from "abdk-libraries-solidity/ABDKMathQuad.sol";

/**
 * @notice Exponential decay function
 * @dev To simulate a time decay that decreases a value over time
 * @dev The Formula is : decayed_value = initial_value * e^( - decay_constant * time_elapsed)
 * @dev ABDKMathQuad: This library provides high-precision floating-point arithmetic using IEEE 754 quadruple precision (128-bit) numbers.
 */
contract ExponentialDecay {
    using ABDKMathQuad for bytes16;

    bytes16 constant DECAY_CONSTANT = 0x3FF00000000000000000000000000000; // 1.0 in quadruple precision
    uint256 public initialValue;
    uint256 public startTime;

    constructor(uint256 _initialValue) {
        initialValue = _initialValue;
        startTime = block.timestamp;
    }

    /**
     * @notice It calculates the time elapsed since the contract was deployed and returns the decayed value
     * @notice timeElapsed is then used in the exponential decay formula
     * @notice The initial value is multiplied by the decay factor to get the decayed value
     * @return decayedValue : The value after the exponential decay in uint256
     */
    function getDecayedValue() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startTime;

        // Convert timeElapsed (seconds) to a quadruple precision number
        bytes16 timeElapsedQuad = ABDKMathQuad.fromUInt(timeElapsed);

        // Calculate the decay factor : e^( - decay_constant * time_elapsed)
        bytes16 decayFactor = ABDKMathQuad.exp(
            ABDKMathQuad.mul(
                ABDKMathQuad.neg(DECAY_CONSTANT), // Negative decay constant for the formula
                timeElapsedQuad
            )
        );

        // Convert initialValue to a quadruple precision number
        bytes16 initialValueQuad = ABDKMathQuad.fromUInt(initialValue);

        // Decayed vlalue = initialValue * e^( - decay_constant * time_elapsed)
        bytes16 decayedValueQuad = ABDKMathQuad.mul(initialValueQuad, decayFactor);

        // Convert back to uint for returning
        return ABDKMathQuad.toUInt(decayedValueQuad);
    }
}
