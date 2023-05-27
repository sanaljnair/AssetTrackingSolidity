// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AssetManagement {
    struct Asset {
        uint256 assetId;
        string name;
        uint256 createDate;
        address owner;
        mapping(string => string) properties;
        mapping(uint256 => TrackingEvent) trackingEvents;
        uint256 eventCount;
    }

    struct TrackingEvent {
        uint256 eventId;
        string eventName;
        string eventDescription;
        string eventLocation;
        address createdBy;
        uint256 eventDate;
        mapping(address => bool) accessList;
        mapping(string => string) keyValuePairs;
    }

    uint256 private constant MAX_ADMINISTRATORS = 10;
    uint256 private constant MAX_PROPERTY_COUNT = 10;

    address[] private administrators;
    mapping(uint256 => Asset) private assets;
    uint256 private assetCount;

    modifier onlyAdministrators() {
        bool isAdmin = false;
        for (uint256 i = 0; i < administrators.length; i++) {
            if (administrators[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Only administrators can call this function");
        _;
    }

    modifier assetOwnerOrAdministrator(uint256 assetId) {
        require(
            assets[assetId].owner == msg.sender || isAdministrator(msg.sender),
            "You are not the owner or an administrator of this asset"
        );
        _;
    }

    constructor(address[] memory initialAdministrators) {
        require(
            initialAdministrators.length > 0 &&
                initialAdministrators.length <= MAX_ADMINISTRATORS,
            "Invalid number of administrators"
        );

        for (uint256 i = 0; i < initialAdministrators.length; i++) {
            administrators.push(initialAdministrators[i]);
        }
    }

    function addAsset(
        string memory name,
        uint256 createDate,
        address owner,
        string[] memory propertyKeys,
        string[] memory propertyValues
    ) public onlyAdministrators returns (uint256) {
        require(owner != address(0), "Invalid owner address");
        require(
            propertyKeys.length == propertyValues.length,
            "Invalid number of property keys and values"
        );
        require(assetCount < type(uint256).max, "Maximum asset count reached");

        uint256 newAssetId = assetCount;
        Asset storage newAsset = assets[newAssetId];

        newAsset.assetId = newAssetId;
        newAsset.name = name;
        newAsset.createDate = createDate;
        newAsset.owner = owner;

        for (uint256 i = 0; i < propertyKeys.length; i++) {
            newAsset.properties[propertyKeys[i]] = propertyValues[i];
        }

        assetCount++;

        return newAssetId;
    }

    function updateAssetProperties(
        uint256 assetId,
        string[] memory propertyKeys,
        string[] memory propertyValues
    ) public assetOwnerOrAdministrator(assetId) {
        require(
            propertyKeys.length == propertyValues.length,
            "Invalid number of property keys and values"
        );

        Asset storage asset = assets[assetId];

        for (uint256 i = 0; i < propertyKeys.length; i++) {
            asset.properties[propertyKeys[i]] = propertyValues[i];
        }
    }

    function getAssetDetails(uint256 assetId)
        public
        view
        returns (
            uint256,
            string memory,
            uint256,
            address
        )
    {
        Asset storage asset = assets[assetId];
        return (asset.assetId, asset.name, asset.createDate, asset.owner);
    }


    function updateAssetOwner(uint256 assetId, address newOwner)
        public
        assetOwnerOrAdministrator(assetId)
    {
        require(newOwner != address(0), "Invalid new owner address");

        Asset storage asset = assets[assetId];
        asset.owner = newOwner;
    }

    function recordTrackingEvent(
        uint256 assetId,
        string memory eventName,
        string memory eventDescription,
        string memory eventLocation,
        uint256 eventDate,
        address[] memory accessList,
        string[] memory keyArray,
        string[] memory valueArray
    ) public {
        require(accessList.length > 0, "Access list cannot be empty");
        require(
            keyArray.length == valueArray.length,
            "Invalid number of keys and values for tracking event"
        );

        Asset storage asset = assets[assetId];

        require(
            asset.owner == msg.sender ||
                isAdministrator(msg.sender) ||
                isAccessGranted(msg.sender, accessList),
            "You are not authorized to record a tracking event for this asset"
        );

        TrackingEvent storage eventObj = asset.trackingEvents[asset.eventCount];

        eventObj.eventId = asset.eventCount;
        eventObj.eventName = eventName;
        eventObj.eventDescription = eventDescription;
        eventObj.eventLocation = eventLocation;
        eventObj.createdBy = msg.sender;
        eventObj.eventDate = eventDate;

        for (uint256 i = 0; i < accessList.length; i++) {
            eventObj.accessList[accessList[i]] = true;
        }

        for (uint256 i = 0; i < keyArray.length; i++) {
            eventObj.keyValuePairs[keyArray[i]] = valueArray[i];
        }

        asset.eventCount++;
    }

    function getTrackingEvent(uint256 assetId, uint256 eventId)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            address,
            uint256
        )
    {
        Asset storage asset = assets[assetId];
        TrackingEvent storage eventObj = asset.trackingEvents[eventId];

        require(
            asset.owner == msg.sender ||
                isAdministrator(msg.sender) ||
                eventObj.accessList[msg.sender],
            "You are not authorized to view this tracking event"
        );

        return (
            eventObj.eventName,
            eventObj.eventDescription,
            eventObj.eventLocation,
            eventObj.createdBy,
            eventObj.eventDate
        );
    }

    function isAdministrator(address user) public view returns (bool) {
        for (uint256 i = 0; i < administrators.length; i++) {
            if (administrators[i] == user) {
                return true;
            }
        }
        return false;
    }

    function isAccessGranted(address user, address[] memory accessList)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < accessList.length; i++) {
            if (accessList[i] == user) {
                return true;
            }
        }
        return false;
    }
}
