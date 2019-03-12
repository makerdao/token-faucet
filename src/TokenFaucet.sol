pragma solidity >=0.5.0;

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external; // return bool?
}

contract TokenFaucet {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public auth { wards[guy] = 1; }
    function deny(address guy) public auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    uint256 public max;
    mapping (address => mapping (address => bool)) public done;

    constructor (uint256 max_) public {
        wards[msg.sender] = 1;
        max = max_;
    }

    function gulp(ERC20Like gem) external {
        uint256 bal = max;
        require(gem.balanceOf(address(this)) >= bal, "token-faucet: not enough balance");
        done[msg.sender][address(gem)] = true;
        gem.transfer(msg.sender, bal);
    }

    function shut(ERC20Like gem) external auth {
        gem.transfer(msg.sender, gem.balanceOf(address(this)));
    }

    function setMax(uint256 max_) external auth {
        max = max_;
    }
}