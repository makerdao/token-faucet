pragma solidity ^0.5.4;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./RestrictedTokenFaucet.sol";

contract FaucetUser {
    DSToken token;
    RestrictedTokenFaucet faucet;

    constructor(DSToken token_, RestrictedTokenFaucet faucet_) public {
        token = token_;
        faucet = faucet_;
    }

    function doGulp() public {
        faucet.gulp(address(token));
    }

    function doUndo(address usr) public {
        faucet.undo(usr, address(token));
    }

    function doRely(address usr) public {
        faucet.rely(usr);
    }

    function doDeny(address usr) public {
        faucet.deny(usr);
    }

    function doShut() public {
        faucet.shut(ERC20Like(address(this)));
    }

    function doSetAmt(uint amt) public {
        faucet.setamt(amt);
    }
}

contract RestrictedTokenFaucetTest is DSTest {
    RestrictedTokenFaucet faucet;
    DSToken token;
    address user1;
    address user2;
    address self;

    function setUp() public {
        faucet = new RestrictedTokenFaucet(20 ether);
        token = new DSToken("TEST");
        token.mint(address(faucet), 1000000 ether);
        user1 = address(new FaucetUser(token, faucet));
        user2 = address(new FaucetUser(token, faucet));
        self = address(this);
    }

    function testSetupPrecondition() public {
        assertEq(faucet.wards(self), 1);
        assertEq(faucet.owner(), self);
        assertEq(faucet.wards(user1), 0);
        assertEq(faucet.wards(user2), 0);
    }

    function testFail_gulp_no_auth() public {
        FaucetUser(user2).doGulp();
    }

    function test_gulp_auth() public {
        faucet.rely(user1);
        assertEq(faucet.wards(user1), 1);
        assertEq(token.balanceOf(user1), 0);
        FaucetUser(user1).doGulp();
        assertEq(token.balanceOf(user1), 20 ether);
    }

    function testFail_rely_notOwner() public {
        FaucetUser(user1).doRely(address(123));
    }

    function testFail_deny_notOwner() public {
        FaucetUser(user1).doDeny(address(this));
    }

    function test_gulp_multiple() public {
        address payable[] memory addrs = new address payable[](4);
        addrs[0] = address(123);
        faucet.rely(addrs[0]);
        addrs[1] = address(234);
        faucet.rely(addrs[1]);
        addrs[2] = address(567);
        faucet.rely(addrs[2]);
        addrs[3] = address(890);
        faucet.rely(addrs[3]);
        assertEq(token.balanceOf(address(123)), 0);
        assertEq(token.balanceOf(address(234)), 0);
        assertEq(token.balanceOf(address(567)), 0);
        assertEq(token.balanceOf(address(890)), 0);
        faucet.gulp(address(token), addrs);
        assertEq(token.balanceOf(address(123)), 20 ether);
        assertEq(token.balanceOf(address(234)), 20 ether);
        assertEq(token.balanceOf(address(567)), 20 ether);
        assertEq(token.balanceOf(address(890)), 20 ether);
    }

    function testFail_gulp_multiple() public {
        address payable[] memory addrs = new address payable[](4);
        addrs[0] = address(this); // already rely'ed
        addrs[1] = address(234); // not rely'ed
        faucet.gulp(address(token), addrs);
    }

    function testFail_gulpTwice() public {
        faucet.gulp(address(token));
        faucet.gulp(address(token));
    }

    function test_undo() public {
        assertEq(token.balanceOf(address(this)), 0);
        faucet.gulp(address(token));
        assertEq(token.balanceOf(address(this)), 20 ether);
        assertTrue(faucet.done(address(this), address(token)));
        faucet.undo(address(this), address(token));
        assertTrue(!faucet.done(address(this), address(token)));
        faucet.gulp(address(token));
        assertEq(token.balanceOf(address(this)), 40 ether);
    }

    function testFail_undo_notOwner() public {
        faucet.gulp(address(token));
        assertTrue(faucet.done(address(this), address(token)));
        FaucetUser(address(user1)).doUndo(address(this));
    }

    function test_shut() public {
        assertEq(token.balanceOf(address(this)), 0);
        faucet.shut(ERC20Like(address(token)));
        assertEq(token.balanceOf(address(this)), 1000000 ether);
    }

    function testFail_shut_notOwner() public {
        FaucetUser(user1).doShut();
    }

    function test_setamt() public {
        assertEq(faucet.amt(), 20 ether);
        faucet.setamt(10 ether);
        assertEq(faucet.amt(), 10 ether);
    }

    function testFail_setamt_notOwner() public {
        FaucetUser(user1).doSetAmt(10 ether);
    }

    function() external payable {}
}
