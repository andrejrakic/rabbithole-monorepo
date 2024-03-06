// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library PrimeLib {
    function isPrime(uint256 number) external pure returns (bool) {
        unchecked {
            // 0 and 1 are not prime numbers
            if (number < 2) {
                return false;
            }
            // 2 is a prime number
            if (number == 2) {
                return true;
            }
            // Even numbers greater than 2 are not prime; Using bitwise AND is cheaper than modulo
            if ((number & uint256(1)) == 0) {
                return false;
            }
            // Only need to check up to the square root of the number
            for (uint256 i = 3; i * i <= number; i += 2) {
                if (number % i == 0) {
                    return false;
                }
            }

            return true;
        }
    }
}
