pragma solidity ^0.5.0;
// Needed to pass in array-of-struct parameters
//pragma experimental ABIEncoderV2;

contract StructAccess {

    struct SimpleStruct {
        uint b; // c unaccessible if this is commented-out.
        uint c;
        //uint[] d; // This has no impact on ability to access c.
        //mapping (uint => uint) e; // This has no impact on ability to access c.
    }

    SimpleStruct public singleStruct;

    constructor() public {
        singleStruct.c = 5;
    }
}

contract StructMapping {

    struct SimpleStruct {
        uint b; // c unaccessible if this is commented-out.
        uint c;
        //uint[] d; // This has no impact on ability to access c.
    }

    mapping (uint => SimpleStruct) public mappingOfStruct;
    SimpleStruct public singleStruct;

    constructor() public {
        mappingOfStruct[0].c = 20;
        singleStruct.c = 20;
    }
}

contract StructMappingBarelyWorking {

    struct OtherStruct {
        uint x;
        uint y;
    }

    struct SimpleStruct {
        //uint a;
        uint b; // Interesting. If this is commented-out. It will fail.
        uint c;
        //uint[] d;
        OtherStruct[] j;
    }

    mapping (uint => SimpleStruct) public mappingOfStruct;

    constructor() public {
        mappingOfStruct[0].c = 20;
    }
}

contract StructMappingComplexWorking {

    struct OtherStruct {
        uint x;
        uint y;
    }

    struct SimpleStruct {
        uint a;
        uint b;
        uint c;
        uint[] d;
        OtherStruct[] j;
    }

    mapping (uint => SimpleStruct) public mappingOfStruct;

    constructor() public {
        mappingOfStruct[0].c = 20;
    }
}

contract StructMappingComplexFailing {

    struct SimpleStruct {
        uint a;
        uint b;
    }

    struct ParentStruct {
        uint c;
        //SimpleStruct[] arrayOfStruct;
    }

    mapping (uint => ParentStruct) public mappingOfStruct;

    constructor() public {
        mappingOfStruct[0].c = 20;
    }
}

contract StructMappingJustNeedsMoreFields {

    struct SimpleStruct {
        uint x;
        uint y;
    }

    struct ParentStruct {
        //uint a;
        uint c;
        //uint d;
        //SimpleStruct[] arrayOfStruct;
        //uint[] dummyArray;
    }

    mapping (uint => ParentStruct) public mappingOfStruct;

    constructor() public {
        mappingOfStruct[0].c = 20;
    }
}