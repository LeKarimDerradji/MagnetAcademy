//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./SchoolMagnet.sol";

contract MagnetAcademy is AccessControl, AccessControlEnumerable {
    using Counters for Counters.Counter;

    bytes32 public constant RECTOR_ROLE = keccak256("RECTOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SCHOOL_DIRECTOR_ROLE = keccak256("SCHOOL_DIRECTOR_ROLE");


    //address private _rector; // Rector is Admin
    address private _rector;
    Counters.Counter private _nbSchools;
    //mapping(address => bool) private _admins;
    mapping(address => address) private _schoolDirectors; // director to school, maybe using accesscontrol for that
    mapping(address => address) private _schools; // school to director, maybe using accesscontrol for that

    event AdminAdded(address indexed account);
    event AdminRevoked(address indexed account);
    event SchoolCreated(address indexed schoolAddress, address indexed directorAddress, string name);
    event SchoolDeleted(address indexed schoolAddress, address indexed directorAddress);
    event DirectorSet(address indexed directorAddress, address indexed schoolAddress);

    /*
    modifier OnlyRector() {
        require(msg.sender == _rector, "MagnetAcademy: Only rector can perform this action");
        _;
    }
    */

    /*
    modifier OnlyAdmin() {
        require(_admins[msg.sender] == true, "MagnetAcademy: Only administrators can perform this action");
        _;
    }
    */

    modifier OnlySchoolDirector(address account) {
        require(_schoolDirectors[account] != address(0), "MagnetAcademy: Not a school director");
        _;
    }

    modifier OnlyNotSchoolDirector(address account) {
        require(_schoolDirectors[account] == address(0), "MagnetAcademy: Already a school director");
        _;
    }

    modifier OnlySchoolAddress(address addr) {
        require(_schools[addr] != address(0), "MagnetAcademy: Only for created schools");
        _;
    }

    constructor(address rector_) {
        _rector = rector_;
        _setupRole(RECTOR_ROLE, rector_);
    }

    function addAdmin(address account_) public  {
        require(hasRole(RECTOR_ROLE, msg.sender), "MagnetAcademy: Only for Rector");
        _setupRole(ADMIN_ROLE, account_);
        emit AdminAdded(account_);
    }

    function revokeAdmin(address account_) public {
        revokeRole(ADMIN_ROLE, account_);
        emit AdminRevoked(account_);
    }

    function changeSchoolDirector(address oldDirector, address newDirector)
        public
        /*OnlyAdmin()*/
        OnlySchoolDirector(oldDirector)
        OnlyNotSchoolDirector(newDirector)
        returns (bool)
    {
        require(hasRole(ADMIN_ROLE, msg.sender), "Magnet Academy: Only for Admin");
        address schoolAddress = _schoolDirectors[oldDirector];
        _schoolDirectors[oldDirector] = address(0);
        _schoolDirectors[newDirector] = schoolAddress;
        _schools[schoolAddress] = newDirector;
        emit DirectorSet(newDirector, schoolAddress);
        return true;
    }

    function createSchool(address directorAddress, string memory name)
        public
        OnlyNotSchoolDirector(directorAddress)
        returns (bool)
    {   
        // With the new keyword you can create a SC from another SM instance, passing argument
        // We can use that to create new strucs, new NFT's for players
        require(hasRole(ADMIN_ROLE, msg.sender), "Magnet Academy: Only for Admin");
        SchoolMagnet school = new SchoolMagnet(directorAddress, name);
        _schoolDirectors[directorAddress] = address(school);
        _schools[address(school)] = directorAddress;
        emit DirectorSet(directorAddress, address(school));
        _nbSchools.increment();
        emit SchoolCreated(address(school), directorAddress, name);
        return true;
    }

    function deleteSchool(address schoolAddress) public OnlySchoolAddress(schoolAddress) returns (bool) {
        require(hasRole(ADMIN_ROLE, msg.sender), "Magnet Academy: Only for Admin");
        address directorAddress = _schools[schoolAddress];
        _schools[schoolAddress] = address(0);
        _schoolDirectors[directorAddress] = address(0);
        _nbSchools.decrement();
        emit SchoolDeleted(schoolAddress, directorAddress);
        return true;
    }

    function nbSchools() public view returns (uint256) {
        return _nbSchools.current();
    }

    function schoolOf(address account) public view returns (address) {
        return _schoolDirectors[account];
    }

    function directorOf(address school) public view returns (address) {
        return _schools[school];
    }

    function rector() public view returns (address) {
        return rector;
    }


    function isAdmin(address account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function isDirector(address account) public view returns (bool) {
        return _schoolDirectors[account] != address(0);
    }

    function isSchool(address addr) public view returns (bool) {
        return _schools[addr] != address(0);
    }
}
