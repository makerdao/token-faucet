pragma solidity >=0.5.0;

import "./lib.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external; // return bool?
}

contract TokenFaucet is DSNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address guy) public auth note { wards[guy] = 1; }
    function deny(address guy) public auth note { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    mapping (address => uint256) public amt;
    mapping (address => mapping (address => bool)) public done;

    constructor () public {
        wards[msg.sender] = 1;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function gulp(address gem) external {
        require(!done[msg.sender][address(gem)], "token-faucet: already used faucet");
        require(ERC20Like(gem).balanceOf(address(this)) >= amt[gem], "token-faucet: not enough balance");
        done[msg.sender][address(gem)] = true;
        ERC20Like(gem).transfer(msg.sender, amt[gem]);
    }

    function gulp(address gem, address[] calldata addrs) external {
        require(ERC20Like(gem).balanceOf(address(this)) >= mul(amt[gem], addrs.length), "token-faucet: not enough balance");

        for (uint256 i = 0; i < addrs.length; i++) {
            require(!done[addrs[i]][address(gem)], "token-faucet: already used faucet");
            done[addrs[i]][address(gem)] = true;
            ERC20Like(gem).transfer(addrs[i], amt[gem]);
        }
    }

    function shut(ERC20Like gem) external auth {
        gem.transfer(msg.sender, gem.balanceOf(address(this)));
    }

    function setAmt(address gem, uint256 amt_) external auth note {
        amt[gem] = amt_;
    }
}
