pragma solidity ^0.5.4;

import "ds-test/test.sol";

import "./TokenFaucet.sol";

contract TokenFaucetTest is DSTest {
    TokenFaucet faucet;

    function setUp() public {
        faucet = new TokenFaucet();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
