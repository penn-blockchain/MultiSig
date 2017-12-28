pragma solidity ^0.4.15;

contract MultiSignatureWallet {

    struct Transaction {
			bool executed;
      address destination;
      uint value;
      bytes data;
      mapping (address => bool) confirmations;
      uint numConfirmations;
      bytes32 tHash;
    }

    uint transactionID = 0;
    uint requiredConfirmations;
    mapping (address => bool) owners;
    mapping (uint => Transaction) transactions;
    mapping (bytes32 => bool) transactionHash;

    modifier isOwner (address _owner) {
      require(owners[_owner]);
      _;
    }
    /// @dev Fallback function, which accepts ether when sent to contract
    function() public payable {}

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSignatureWallet(address[] _owners, uint _required) public {
      requiredConfirmations = _required;
      uint length = _owners.length;
      for (uint i = 0; i < length; i++) {
        owners[_owners[i]] = true;
      }
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address _destination, uint _value, bytes _data) isOwner (msg.sender)
        public returns (uint transactionId) {
      transactionID ++;
      return addTransaction(_destination, _value, _data);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) isOwner (msg.sender) public {
      require(!transactions[transactionId].executed);
      require(!transactions[transactionId].confirmations[msg.sender]);
      transactions[transactionId].confirmations[msg.sender] = true;
      transactions[transactionId].numConfirmations ++;
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {
      require(!transactions[transactionId].executed);
      require(transactions[transactionId].confirmations[msg.sender]);
      transactions[transactionId].confirmations[msg.sender] = false;
      transactions[transactionId].numConfirmations --;
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public {
      require(!transactions[transactionId].executed);
      require(transactions[transactionId].numConfirmations >= requiredConfirmations);
      transactions[transactionId].executed = true;
      address destination = transactions[transactionId].destination;
      bytes data = transactions[transactionId].data;
      uint value = transactions[transactionId].value;
      transactionHash[transactions[transactionID].tHash] = false;
      destination.call.value(value) (data);
    }

		/*
		 * (Possible) Helper Functions
		 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) internal constant returns (bool) {
      return (transactions[transactionId].numConfirmations >= requiredConfirmations);
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data) internal returns (uint transactionId) {
      bytes32 currentHash = sha256 (destination, value, data);
      require(!transactionHash[currentHash]);
      transactions[transactionID].destination = destination;
      transactions[transactionID].value = value;
      transactions[transactionID].data = data;
      transactions[transactionID].tHash = currentHash;
      transactionHash[currentHash] = true;
      return transactionID;
    }
}
