pragma solidity ^0.5.4;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./TokenFaucet.sol";

contract TokenFaucetTest is DSTest {
    TokenFaucet faucet;
    DSToken token;

    function setUp() public {
        faucet = new TokenFaucet(20);
        token = new DSToken("TEST");
        token.mint(address(faucet), 1000000);
    }

    function test_gulp() public {
        assertEq(token.balanceOf(address(this)), 0);
        faucet.gulp(address(token));
        assertEq(token.balanceOf(address(this)), 20);
    }

    function test_gulp_multiple() public {
        assertEq(token.balanceOf(address(123)), 0);
        assertEq(token.balanceOf(address(234)), 0);
        assertEq(token.balanceOf(address(567)), 0);
        assertEq(token.balanceOf(address(890)), 0);
        address[] memory addrs = new address[](4);
        addrs[0] = address(123);
        addrs[1] = address(234);
        addrs[2] = address(567);
        addrs[3] = address(890);
        faucet.gulp(address(token), addrs);
        assertEq(token.balanceOf(address(123)), 20);
        assertEq(token.balanceOf(address(234)), 20);
        assertEq(token.balanceOf(address(567)), 20);
        assertEq(token.balanceOf(address(890)), 20);
    }

    function testFail_gulp_multiple() public {
        faucet.gulp(address(token));
        address[] memory addrs = new address[](4);
        addrs[0] = address(this);
        addrs[1] = address(234);
        addrs[2] = address(567);
        addrs[3] = address(890);
        faucet.gulp(address(token), addrs);
    }

    function testFail_gulp_twice() public {
        faucet.gulp(address(token));
        faucet.gulp(address(token));
    }

    function() external payable {}
}
