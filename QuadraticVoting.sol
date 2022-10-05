// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./minerrole.sol";


contract QVVoting is Ownable, MinterRole {
   
    using SafeMath for uint256;

    uint256 private _totalSupply;
    string public symbol;
    string public name;
    mapping(address => uint256) private _balances;


     enum ProjectStatus {IN_PROGRESS, ENDED}

    struct Project {
        address creator;
        ProjectStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        string description;
        address[] voters;
        uint expirationTime;
        mapping(address => Voter) voterInfo;
    }

     struct Voter {
        bool hasVoted;
        bool vote;
        uint256 weight;
    }

     mapping(uint256 => Project) public Projects;
    uint public ProjectCount;

  
function createProject(string calldata _description ,uint _voteExpirationTime) external onlyOwner returns (uint) {
        require(_voteExpirationTime > 0, "The voting period cannot be 0");
        ProjectCount++;

        Project storage curProject = Projects[ProjectCount];
        curProject.creator = msg.sender;
        curProject.status = ProjectStatus.IN_PROGRESS;
        curProject.expirationTime = block.timestamp+ 60 * _voteExpirationTime * 1 seconds;
        curProject.description = _description;

       
        return ProjectCount;
    }




function setProjectToEnded(uint _ProjectID)
        external
        validProject(_ProjectID)
        onlyOwner
    {
      
        require(
            block.timestamp >= getProjectExpirationTime(_ProjectID),
            "voting period has not expired"
        );
        Projects[_ProjectID].status = ProjectStatus.ENDED;
    }

function getProjectStatus(uint _ProjectID)
        public
        view
        validProject(_ProjectID)
        returns (ProjectStatus)
    {
        return Projects[_ProjectID].status;
    }

   
    function getProjectExpirationTime(uint _ProjectID)
        public
        view
        validProject(_ProjectID)
        returns (uint)
    {
        return Projects[_ProjectID].expirationTime;
    }

    

    function countVotes(uint256 _ProjectID) public view returns (uint, uint) {
        uint yesVotes = 0;
        uint noVotes = 0;

        address[] memory voters = Projects[_ProjectID].voters;
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            bool vote = Projects[_ProjectID].voterInfo[voter].vote;
            uint256 weight = Projects[_ProjectID].voterInfo[voter].weight;
            if (vote == true) {
                yesVotes += weight;
            } else {
                noVotes += weight;
            }
        }

        return (yesVotes, noVotes);

    }

     function castVote(uint _ProjectID, uint numTokens, bool _vote) external validProject(_ProjectID) {
        require(
            getProjectStatus(_ProjectID) == ProjectStatus.IN_PROGRESS,
            "Project has expired."
        );
        require(
            !userHasVoted(_ProjectID, msg.sender),
            "user already voted on this Project"
        );
        require(
            getProjectExpirationTime(_ProjectID) > block.timestamp,
            "for this Project, the voting time expired"
        );

        _balances[msg.sender] = _balances[msg.sender].sub(numTokens);

        uint256 weight = sqrt(numTokens); // QV Vote

        Project storage curProject = Projects[_ProjectID];

        curProject.voterInfo[msg.sender] = Voter({
            hasVoted: true,
            vote: _vote,
            weight: weight
        });

        curProject.voters.push(msg.sender);

       
    }

     function userHasVoted(uint _ProjectID, address _user) internal view validProject(_ProjectID) returns (bool) {

        return (Projects[_ProjectID].voterInfo[_user].hasVoted);
    }

   
    modifier validProject(uint _ProjectID) {
        require(
            _ProjectID > 0 && _ProjectID <= ProjectCount,
            "Not a valid Project Id"
        );
        _;
    }

   
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

   
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), " mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

  
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

}
