/// SPDX-License-Information: MIT
pragma solidity >=0.5.0 <0.6.0-0||>=0.6.0 <0.7.0-0||>=0.7.0 <0.8.0-0;
pragma experimental "ABIEncoderV2";

/// @author https://github.com/Ohalo-Ltd/ethereum_contracts/tree/master/strings
/// @title Validate UTF8 String Encoding

library ValidateUTF8 {
    // Key bytes.
    // http://www.unicode.org/versions/Unicode10.0.0/UnicodeStandard-10.0.pdf
    // Table 3-7, p 126, Well-Formed UTF-8 Byte Sequences

    // Default 80..BF range
    uint256 internal constant DL = 0x80;
    uint256 internal constant DH = 0xBF;

    // Row - number of bytes

    // R1 - 1
    uint256 internal constant B11L = 0x00;
    uint256 internal constant B11H = 0x7F;

    // R2 - 2
    uint256 internal constant B21L = 0xC2;
    uint256 internal constant B21H = 0xDF;

    // R3 - 3
    uint256 internal constant B31 = 0xE0;
    uint256 internal constant B32L = 0xA0;
    uint256 internal constant B32H = 0xBF;

    // R4 - 3
    uint256 internal constant B41L = 0xE1;
    uint256 internal constant B41H = 0xEC;

    // R5 - 3
    uint256 internal constant B51 = 0xED;
    uint256 internal constant B52L = 0x80;
    uint256 internal constant B52H = 0x9F;

    // R6 - 3
    uint256 internal constant B61L = 0xEE;
    uint256 internal constant B61H = 0xEF;

    // R7 - 4
    uint256 internal constant B71 = 0xF0;
    uint256 internal constant B72L = 0x90;
    uint256 internal constant B72H = 0xBF;

    // R8 - 4
    uint256 internal constant B81L = 0xF1;
    uint256 internal constant B81H = 0xF3;

    // R9 - 4
    uint256 internal constant B91 = 0xF4;
    uint256 internal constant B92L = 0x80;
    uint256 internal constant B92H = 0x8F;

    // Checks if a string is valid UTF-8. The function reverts if the string is invalid.
    function validate(string memory self) internal pure {
        uint256 addr;
        uint256 len;
        assembly {
            addr := add(self, 0x20)
            len := mload(self)
        }
        if (len == 0) {
            return;
        }
        uint256 bytePos = 0;
        while (bytePos < len) {
            bytePos += parseRune(addr + bytePos);
        }
        assert(bytePos == len);
    }

    // Parses a single character, or "rune" stored at address 'bytePos' in memory.
    // Returns the length of the character in bytes.
    // solhint-disable-next-line code-complexity
    function parseRune(uint256 bytePos) internal pure returns (uint256 len) {
        uint256 val;
        assembly {
            val := mload(bytePos)
        }
        val >>= 224; // Remove all but the first four bytes.
        uint256 v0 = val >> 24; // Get the first byte.
        if (v0 <= B11H) {
            // Check a 1 byte character.
            len = 1;
        } else if (B21L <= v0 && v0 <= B21H) {
            // Check a 2 byte character.
            uint256 v1 = (val & 0x00FF0000) >> 16;
            require(DL <= v1 && v1 <= DH);
            len = 2;
        } else if (v0 == B31) {
            // Check a 3 byte character in the following three.
            validateWithNextDefault((val & 0x00FFFF00) >> 8, B32L, B32H);
            len = 3;
        } else if (v0 == B51) {
            validateWithNextDefault((val & 0x00FFFF00) >> 8, B52L, B52H);
            len = 3;
        } else if ((B41L <= v0 && v0 <= B41H) || v0 == B61L || v0 == B61H) {
            validateWithNextDefault((val & 0x00FFFF00) >> 8, DL, DH);
            len = 3;
        } else if (v0 == B71) {
            // Check a 4 byte character in the following three.
            validateWithNextTwoDefault(val & 0x00FFFFFF, B72L, B72H);
            len = 4;
        } else if (B81L <= v0 && v0 <= B81H) {
            validateWithNextTwoDefault(val & 0x00FFFFFF, DL, DH);
            len = 4;
        } else if (v0 == B91) {
            validateWithNextTwoDefault(val & 0x00FFFFFF, B92L, B92H);
            len = 4;
        } else {
            // If we reach this point, the character is not valid UTF-8
            revert();
        }
    }

    function validateWithNextDefault(
        uint256 val,
        uint256 low,
        uint256 high
    ) private pure {
        uint256 b = (val & 0xFF00) >> 8;
        require(low <= b && b <= high);
        b = val & 0x00FF;
        require(DL <= b && b <= DH);
    }

    function validateWithNextTwoDefault(
        uint256 val,
        uint256 low,
        uint256 high
    ) private pure {
        uint256 b = (val & 0xFF0000) >> 16;
        require(low <= b && b <= high);
        b = (val & 0x00FF00) >> 8;
        require(DL <= b && b <= DH);
        b = val & 0x0000FF;
        require(DL <= b && b <= DH);
    }
}
