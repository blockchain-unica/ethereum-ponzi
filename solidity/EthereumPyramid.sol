contract Pyramid {
    enum PayoutType { Ether, Bitcoin }

    struct Participant {
        PayoutType payoutType;
        bytes desc;
        address etherAddress;
        bytes bitcoinAddress;
    }

    Participant[] public participants;

    uint public payoutIdx = 0;
    uint public collectedFees;

    address public owner;
    address public bitcoinBridge;

    // used later to restrict some methods
    modifier onlyowner { if (msg.sender == owner) _ }

    // events make it easier to interface with the contract
    event NewParticipant(uint indexed idx);

    function Pyramid(address _bitcoinBridge) {
        owner = msg.sender;
        bitcoinBridge = _bitcoinBridge;
    }

    // fallback function - simple transactions trigger this
    function() {
        enter(msg.data, '');
    }

    function enter(bytes desc, bytes bitcoinAddress) {
        if (msg.value < 1 ether) {
            msg.sender.send(msg.value);
            return;
        }

        if (desc.length > 16 || bitcoinAddress.length > 35) {
            msg.sender.send(msg.value);
            return;
        }

        if (msg.value > 1 ether) {
            msg.sender.send(msg.value - 1 ether);
        }

        uint idx = participants.length;
        participants.length += 1;
        participants[idx].desc = desc;
        if (bitcoinAddress.length > 0) {
            participants[idx].payoutType = PayoutType.Bitcoin;
            participants[idx].bitcoinAddress = bitcoinAddress;
        } else {
            participants[idx].payoutType = PayoutType.Ether;
            participants[idx].etherAddress = msg.sender;
        }

        NewParticipant(idx);

        if (idx != 0) {
            collectedFees += 100 finney;
        } else {
            // first participant has no one above them,
            // so it goes all to fees
            collectedFees += 1 ether;
        }

        // for every three new participants we can
        // pay out to an earlier participant
        if (idx != 0 && idx % 3 == 0) {
            // payout is triple, minus 10 % fee
            uint amount = 3 ether - 300 finney;

            if (participants[payoutIdx].payoutType == PayoutType.Ether) {
                participants[payoutIdx].etherAddress.send(amount);
            } else {
                BitcoinBridge(bitcoinBridge).queuePayment.value(amount)(participants[payoutIdx].bitcoinAddress);
            }

            payoutIdx += 1;
        }
    }

    function getNumberOfParticipants() constant returns (uint n) {
        return participants.length;
    }

    function collectFees(address recipient) onlyowner {
        if (collectedFees == 0) return;

        recipient.send(collectedFees);
        collectedFees = 0;
    }

    function setBitcoinBridge(address _bitcoinBridge) onlyowner {
        bitcoinBridge = _bitcoinBridge;
    }

    function setOwner(address _owner) onlyowner {
        owner = _owner;
    }
}

contract BitcoinBridge {
    function queuePayment(bytes bitcoinAddress) returns(bool successful);
}
