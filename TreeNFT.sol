// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreePlantingNFT {

    uint new_forest_id; //The id of the forest 
    uint new_tree_id; //The id of the trees
    address admin; //The address who deployed the contract will be the admin

    // Things happening when deploying contract
    constructor() { 
    admin = msg.sender; //Set the admin of the contract to be the one who deploys the contract
    new_forest_id = 0; //Set the forest_id to 0
    new_tree_id = 0; //Set the tree_id to 0
    
    //Add a default forest of 100 trees
    addForest("Demo Forest", "HK", "www.demo.com/demoforest.jpg", 100);

    //Add a default tree
    addTree("Pine", "HK", 0, "www.demo.com/demotree1.jpg", "2021-01-01", 0, 1, 10);
    addTree("Oak", "HK", 0, "www.demo.com/demotree2.jpg", "2021-01-01", 0, 2, 20);
    }
    
    //Attributes stored in each tree
    struct tree {
        string species; //Species of tree
        string location; //The location of the tree inside the forest
        uint256 forest_id; //The forest the tree belongs to
        string image; //The image of the tree
        string date_planted; //The date the tree was planted
        uint256 age; // in years
        uint256 height; // in meters
        uint256 carbon_offset; // in kg/yr
        address owner; //The owner of the tree
    }

    //Attributes stored in each forest
    struct forest {
        string name; //Name of the forest
        string location; //The location of the forest
        string image; //The image of the forest
        address owner; //The owner of the forest
        uint256 max_number_of_trees; //The max number of trees in the forest

    }

    //Mapping of forest to forest_id
    mapping(uint256 => forest) public forests;

    //Mapping of tree to tree_id
    mapping(uint256 => tree) public trees;

    //Mapping of species to forest_id
    mapping(uint256 => string[]) public species_in_forest;

    //add a modifier to check if the msg.sender is the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    //add a modifier to check if the msg.sender is the owner of the tree
    modifier onlyOwner(uint256 _tree_id) {
        require(msg.sender == trees[_tree_id].owner, "Only owner can call this function.");
        _;
    }

    //add a modifier to check if the msg.sender is the owner of the forest
    modifier onlyForestOwner(uint256 _forest_id) {
        require(msg.sender == forests[_forest_id].owner, "Only owner can call this function.");
        _;
    }

    //add a modifier to check if the msg.sender is the owner of the forest or the admin
    modifier onlyForestOwnerOrAdmin(uint256 _forest_id) {
        require(msg.sender == forests[_forest_id].owner || msg.sender == admin, "Only owner or admin can call this function.");
        _;
    }

    //Calculate the carbon offset of a forest
    function calculateForestCarbonOffset(uint256 _forest_id) public view returns (uint256) {
        uint256 total_carbon_offset = 0;
        for (uint256 i = 0; i < new_tree_id; i++) {
            if (trees[i].forest_id == _forest_id) {
                total_carbon_offset += trees[i].carbon_offset;
            }
        }
        return total_carbon_offset;
    }

    //Calculate the number of tree in a forest
    function calculateForestNumberOfTrees(uint256 _forest_id) public view returns (uint256) {
        uint256 total_number_of_trees = 0;
        for (uint256 i = 0; i < new_tree_id; i++) {
            if (trees[i].forest_id == _forest_id) {
                total_number_of_trees += 1;
            }
        }
        return total_number_of_trees;
    }
 
    //Calculate Simpson's Diversity Index of a forest
    function calculateForestDiversityIndex(uint256 _forest_id) public view returns (uint256) {
        uint256 total_number_of_trees = calculateForestNumberOfTrees(_forest_id);
        uint256 diversity_index = 1000;
        for (uint256 i = 0; i < species_in_forest[_forest_id].length; i++) {
            uint256 number_of_trees_in_species = 0;
            for (uint256 j = 0; j < new_tree_id; j++) {
                if (trees[j].forest_id == _forest_id && keccak256(abi.encodePacked(trees[j].species)) == keccak256(abi.encodePacked(species_in_forest[_forest_id][i]))) {
                    number_of_trees_in_species += 1;
                }
            }
            diversity_index -= 1000*number_of_trees_in_species**2/total_number_of_trees**2;
        }
        return diversity_index;
    }

    //group trees by species in a forest and return the species and number of trees in each species 
    function groupTreesBySpecies(uint256 _forest_id) public view returns (string[] memory, uint256[] memory) {
        string[] memory species = new string[](species_in_forest[_forest_id].length);
        uint256[] memory number_of_trees = new uint256[](species_in_forest[_forest_id].length);
        for (uint256 i = 0; i < species_in_forest[_forest_id].length; i++) {
            species[i] = species_in_forest[_forest_id][i];
            number_of_trees[i] = 0;
            for (uint256 j = 0; j < new_tree_id; j++) {
                if (trees[j].forest_id == _forest_id && keccak256(abi.encodePacked(trees[j].species)) == keccak256(abi.encodePacked(species[i]))) {
                    number_of_trees[i] += 1;
                }
            }
        }
        return (species, number_of_trees);
    }
 

   //add a new forest
    function addForest(string memory _name, string memory _location, string memory _image, uint256 _max_number_of_trees) public onlyAdmin {
        forests[new_forest_id] = forest(_name, _location, _image, msg.sender, _max_number_of_trees); //Add the forest
        species_in_forest[new_forest_id] = new string[](0); //Add the species_in_forest
        new_forest_id += 1; //Increment the forest_id
    } 

    //add a new tree
    function addTree(string memory _species, string memory _location, uint256 _forest_id, string memory _image, string memory _date_planted, uint256 _age, uint256 _height, uint256 _carbon_offset) public onlyForestOwnerOrAdmin(_forest_id) {
        require(_forest_id < new_forest_id, "Forest does not exist"); //check if the forest_id is valid
        require(calculateForestNumberOfTrees(_forest_id) < forests[_forest_id].max_number_of_trees, "Forest is full"); //Check if the forest is full
        trees[new_tree_id] = tree(_species, _location, _forest_id, _image, _date_planted, _age, _height, _carbon_offset, msg.sender); //Add the tree
        new_tree_id += 1; //Increment the tree_id
        
        //Add the species to the species_in_forest if it is not in the species_in_forest
        bool species_exist = false;
        for (uint256 i = 0; i < species_in_forest[_forest_id].length; i++) {
            if (keccak256(abi.encodePacked(species_in_forest[_forest_id][i])) == keccak256(abi.encodePacked(_species))) {
                species_exist = true;
            }
        }
        if (species_exist == false) {
            species_in_forest[_forest_id].push(_species);
        }
    }

    //Add multiple trees with same species
    function addMultipleTrees(string memory _species, string memory _location, uint256 _forest_id, string memory _image, string memory _date_planted, uint256 _age, uint256 _height, uint256 _carbon_offset, uint256 _number_of_trees) public onlyForestOwnerOrAdmin(_forest_id) {
        for (uint256 i = 0; i < _number_of_trees; i++) {
            addTree(_species, _location, _forest_id, _image, _date_planted, _age, _height, _carbon_offset);
        }
    }

    //transfer ownership of a tree
    function transferTreeOwnership(uint256 _tree_id, address _new_owner) public onlyOwner(_tree_id) {
        trees[_tree_id].owner = _new_owner; //Transfer the ownership of the tree
    }

    //transfer ownership of a forest
    function transferForestOwnership(uint256 _forest_id, address _new_owner) public onlyForestOwner(_forest_id) {
        forests[_forest_id].owner = _new_owner; //Transfer the ownership of the forest
    }

    //update the tree information
    function updateTree(uint256 _tree_id, string memory _species, string memory _location, string memory _image, string memory _date_planted, uint256 _age, uint256 _height, uint256 _carbon_offset) public onlyAdmin {
        trees[_tree_id].species = _species; //Update the species
        trees[_tree_id].location = _location; //Update the location
        trees[_tree_id].image = _image; //Update the image
        trees[_tree_id].date_planted = _date_planted; //Update the date_planted
        trees[_tree_id].age = _age; //Update the age
        trees[_tree_id].height = _height; //Update the height
        trees[_tree_id].carbon_offset = _carbon_offset; //Update the carbion_offset
    }

    //update the forest information
    function updateForest(uint256 _forest_id, string memory _name, string memory _location, string memory _image, uint256 _max_number_of_trees) public onlyAdmin {
        forests[_forest_id].name = _name; //Update the name
        forests[_forest_id].location = _location; //Update the location
        forests[_forest_id].image = _image; //Update the image
        forests[_forest_id].max_number_of_trees = _max_number_of_trees; //Update the max_number_of_trees
    }
}