// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract SelfmadeToken {
    //-----------------Errors---------------------\\
    // Using custom errors for gas efficiency and clarity, as per Solidity best practices
    error SelfmadeToken___constructor_InitialSupplyCannotBeZero();
    error SelfmadeToken___transfer_NotEnoughBalance();
    error SelfmadeToken___transferFrom_NotEnoughBalance();
    error SelfmadeToken___transferFrom_AllowanceNotEnough();
    error SelfmadeToken___approve_ApproveToZeroAddressNotAllowed();
    error SelfmadeToken___safeApprove_CurrentAllowanceNotMatching();
    error SelfmadeToken___increaseAllowance_AllowanceChangedUnexpectedly();
    error SelfmadeToken___decreaseAllowance_AllowanceChangedUnexpectedly();
    error SelfmadeToken___decreaseAllowance_AllowanceDecreasedBelowZero();
    error SelfmadeToken___mint_NotOwner();
    error SelfmadeToken___mint_MintAmountCannotBeZero();
    error SelfmadeToken___mint_ToZeroAddressNotAllowed();
    error SelfmadeToken___burn_BurnAmountExceedsBalance();
    error SelfmadeToken___burn_BurnAmountCannotBeZero();

    //----------------variables------------\\

    address public immutable i_owner;
    //-----------------Token metadata---------------------\\
    string public constant name = "SelfMade Token"; // Using constant for gas efficiency and clarity, as per ERC-20 standard, not following the naming convention as it need to match the erc20 functions name strictly
    /*
    we will not use the below as both provide the same and it is slightly higher and the above line string public constant name = "Selfmade Token"; is more cleaner and gas efficient and follows ERC-20 token standard

    function name() public pure returns (string memory) {
        return "Selfmade Token";
    }
    */

    string public constant symbol = "$MT"; //used this syntax as above for the same reason and protocol!
    uint8 public constant decimals = 18; // Standard for ERC-20 tokens, 18 decimals is common
    uint256 public totalSupply; // standard for ERC-20 tokens, total supply of the token which will be initiated in the constructor. Also didn't use the nameing convention as it need to match the erc20 functions name strictly

    //---------------------- Balance and allowance mappings--------------------\\
    //holding tokens in an erc20 just means if one has some balance in some mapping!
    mapping(address users => uint256 amount) public s_balance;
    mapping(address owner => mapping(address spender => uint256 amount)) public s_allowance;

    //--------------------- Events (as per ERC-20 standard)---------------------\\
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //--------------construtor-------------------\\
    constructor(uint256 _initialSupply) {
        i_owner = msg.sender; // Setting the contract creator as the owner

        s_balance[msg.sender] = _initialSupply; // Assigning the initial supply to the contract creator
        totalSupply = _initialSupply; // Setting the total supply of the token
        emit Transfer(address(0), msg.sender, _initialSupply); // Emitting a transfer
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert SelfmadeToken___mint_NotOwner();
        }
        _;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return s_balance[_user];
    }
    //-------------------- Allowance --------------------\\
    // This function returns the amount of tokens that an owner allowed to a spender.

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return s_allowance[_owner][_spender];
    }
    //-------------------- Transfer --------------------\\
    // This function transfers tokens from the caller's account to another account.
    // It checks if the caller has enough balance and updates the balances accordingly.
    // It emits a Transfer event on success.

    function transfer(address _to, uint256 _amount) public returns (bool) {
        // uint256 overallBalance = s_balance[msg.sender] + s_balance[_to];
        // the above line is not needed and is not gas efficient, we can check this in dev/test environment so no hustle needed same with the require lne whch was to be follow before - return true line!
        if (s_balance[msg.sender] < _amount) {
            revert SelfmadeToken___transfer_NotEnoughBalance();
        }
        s_balance[msg.sender] -= _amount;
        s_balance[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    //-------------------- Approve --------------------\\
    // This function allows the owner to approve a spender to spend a certain amount of tokens on their behalf.

    function approve(address _spender, uint256 _amount) public returns (bool) {
        if (_spender == address(0)) {
            revert SelfmadeToken___approve_ApproveToZeroAddressNotAllowed(); // Prevent approving to the zero address
        }
        s_allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    // -------------------- Safe Approve (to prevent race condition) --------------------\\

    function safeApprove(address _spender, uint256 _currentAllowance, uint256 _newAllowance) public returns (bool) {
        if (s_allowance[msg.sender][_spender] != _currentAllowance) {
            revert SelfmadeToken___safeApprove_CurrentAllowanceNotMatching();
        }
        s_allowance[msg.sender][_spender] = _newAllowance;
        emit Approval(msg.sender, _spender, _newAllowance);
        return true;
    }
    //-------------------- Transfer From --------------------\\

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        if (s_balance[_from] < _amount) {
            revert SelfmadeToken___transferFrom_NotEnoughBalance();
        }
        if (s_allowance[_from][msg.sender] < _amount) {
            revert SelfmadeToken___transferFrom_AllowanceNotEnough();
        }
        s_balance[_from] -= _amount;
        s_balance[_to] += _amount;
        s_allowance[_from][msg.sender] -= _amount; // Decrease the allowance
        emit Transfer(_from, _to, _amount);
        return true;
    }
    //-------------------- Increase Allowance -------------------- \\

    function increaseAllowance(address _spender, uint256 _addedValue, uint256 __expectedCurrentAllowance)
        public
        returns (bool)
    {
        uint256 currentAllowance = allowance(msg.sender, _spender);
        if (currentAllowance != __expectedCurrentAllowance) {
            revert SelfmadeToken___increaseAllowance_AllowanceChangedUnexpectedly();
        }

        s_allowance[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, s_allowance[msg.sender][_spender]);
        return true;
    }
    //-------------------- Decrease Allowance -------------------- \\

    function decreaseAllowance(address _spender, uint256 _decreasedValue, uint256 _expectedCurrentAllowance)
        public
        returns (bool)
    {
        uint256 currentAllowance = s_allowance[msg.sender][_spender];
        // Race condition protection: ensure caller sees what we see, modified decreaseAllowance with expected-value race protection, which is stricter than OpenZeppelin
        if (currentAllowance != _expectedCurrentAllowance) {
            revert SelfmadeToken___decreaseAllowance_AllowanceChangedUnexpectedly();
        }

        if (currentAllowance < _decreasedValue) {
            revert SelfmadeToken___decreaseAllowance_AllowanceDecreasedBelowZero();
        }
        s_allowance[msg.sender][_spender] -= _decreasedValue;
        emit Approval(msg.sender, _spender, s_allowance[msg.sender][_spender]);
        return true;
    }

    //-------------------- Mint -------------------- \\
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_amount == 0) {
            revert SelfmadeToken___mint_MintAmountCannotBeZero();
        }
        if (_to == address(0)) {
            revert SelfmadeToken___mint_ToZeroAddressNotAllowed(); // Prevent minting to the zero address
        }
        s_balance[_to] += _amount; // Minting tokens to the owners seleted balance
        totalSupply += _amount; // Increasing the total supply
        emit Transfer(address(0), _to, _amount); // Emitting a transfer event for minting
        return true;
    }

    //--------------------- Burn --------------------- \\
    function burn(uint256 _amount) external returns (bool) {
        if (_amount == 0) {
            revert SelfmadeToken___burn_BurnAmountCannotBeZero();
        }
        if (s_balance[msg.sender] < _amount) {
            revert SelfmadeToken___burn_BurnAmountExceedsBalance();
        }
        s_balance[msg.sender] -= _amount; // Decrease the balance of the caller
        totalSupply -= _amount; // Decrease the total supply
        emit Transfer(msg.sender, address(0), _amount); // Emit a transfer event for burning
        return true;
    }
}
